import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:mds/services/subscription_service.dart';
import 'package:mds/services/storage_service.dart';
import 'package:get_storage/get_storage.dart';

class WorkspaceController extends GetxController {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _storage = GetStorage();

  final RxString currentSchoolId = "".obs;
  final RxString userRole = "Owner".obs; // Default to Owner
  final RxBool isLoading = false.obs; // Changed initial value to false
  final RxBool isConnected =
      true.obs; // Owners are always "connected" to themselves
  final RxBool isOrganizationMode =
      false.obs; // Toggle between Branch vs Org context

  // App Data
  final RxMap<String, dynamic> userProfileData =
      <String, dynamic>{}.obs; // Personal profile
  final RxMap<String, dynamic> companyData =
      <String, dynamic>{}.obs; // Workspace/School context
  final RxMap<String, dynamic> subscriptionData = <String, dynamic>{}.obs;
  final RxBool isAppDataLoading = false.obs;
  bool _isInitializing = false;
  final SubscriptionService _subscriptionService = SubscriptionService();

  // Branch Management State
  final RxList<Map<String, dynamic>> ownedBranches =
      <Map<String, dynamic>>[].obs;
  final RxString currentBranchId = "".obs;

  /// Returns the data for the currently active branch
  Map<String, dynamic> get currentBranchData {
    if (currentBranchId.value.isEmpty) return {};
    return ownedBranches.firstWhere(
      (b) => b['id'] == currentBranchId.value,
      orElse: () => {},
    );
  }

  /// Returns the ID that should be used for Firestore operations.
  /// Prioritizes currentSchoolId, falls back to the logged in user's UID.
  String get targetId {
    if (currentSchoolId.value.isNotEmpty) return currentSchoolId.value;
    return _auth.currentUser?.uid ?? "";
  }

  @override
  void onInit() {
    super.onInit();
    _loadMode(); // Load persisted mode
    initializeWorkspace();

    // Listen to auth changes
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        initializeWorkspace();
      } else {
        currentSchoolId.value = "";
      }
    });

    // Handle mode persistence
    ever(isOrganizationMode, (bool val) {
      _storage.write('isOrganizationMode', val);
    });

    ever(currentBranchId, (String val) {
      _storage.write('currentBranchId', val);
    });
  }

  void _loadMode() {
    isOrganizationMode.value = _storage.read('isOrganizationMode') ?? false;
    currentBranchId.value = _storage.read('currentBranchId') ?? "";
  }

  Future<void> initializeWorkspace() async {
    print(
        "DEBUG: WorkspaceController: initializeWorkspace called. user: ${_auth.currentUser?.uid}, isInitializing: $_isInitializing");
    if (_isInitializing) return;

    // Hard fail-safe: Force loading to false after 10 seconds no matter what
    Future.delayed(const Duration(seconds: 10), () {
      if (isLoading.value || isAppDataLoading.value) {
        print(
            "DEBUG: WorkspaceController: Hard fail-safe triggered! Forcing loading to false.");
        isLoading.value = false;
        isAppDataLoading.value = false;
        _isInitializing = false;
      }
    });

    final user = _auth.currentUser;
    if (user == null) {
      print("DEBUG: WorkspaceController: No user found, stopping init.");
      isLoading.value = false;
      return;
    }

    try {
      _isInitializing = true;
      isLoading.value = true;
      print("DEBUG: WorkspaceController: Fetching main user doc...");
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 15));
      print(
          "DEBUG: WorkspaceController: Main user doc fetched. exists: ${doc.exists}");

      if (doc.exists) {
        final data = doc.data();
        String? schoolId = data?['schoolId'];
        String? role = data?['role'];

        if (role == null || role.isEmpty) {
          role = 'Owner';
          await _firestore
              .collection('users')
              .doc(user.uid)
              .update({'role': role});
        }
        userRole.value = role;

        if (schoolId == null || schoolId.isEmpty) {
          if (role == 'Owner') {
            // Initialize with own UID if no schoolId exists for Owner
            schoolId = user.uid;
            await _firestore.collection('users').doc(user.uid).update({
              'schoolId': schoolId,
            });
          }
        }
        currentSchoolId.value = schoolId ?? "";

        // Determine connection status
        if (role == 'Owner') {
          isConnected.value = true;
          // For owners, the default branch is their own UID if no branches exist,
          // but we'll load the actual branches subcollection in _fetchAllAppData
        } else {
          // Staff is connected if their schoolId is NOT their own UID and not empty
          isConnected.value =
              schoolId != null && schoolId.isNotEmpty && schoolId != user.uid;
        }
      }

      await _fetchAllAppData();
      // Load branches if Owner
      if (userRole.value == 'Owner') {
        await _fetchBranches();
      }
    } catch (e) {
      print("Error initializing workspace: $e");
    } finally {
      isLoading.value = false;
      _isInitializing = false;
    }
  }

  Future<void> _fetchAllAppData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      isAppDataLoading.value = true;
      final targetIdValue = targetId;
      print(
          "DEBUG: WorkspaceController: Fetching app data for targetId: $targetIdValue");

      // Parallelize fetching staff profile, target workspace, and subscription
      final results = await Future.wait([
        _firestore
            .collection('users')
            .doc(user.uid)
            .get(), // Always the logged-in user
        _firestore
            .collection('users')
            .doc(targetIdValue)
            .get(), // Workspace context (owner or self)
        _subscriptionService.checkSubscription(targetIdValue),
      ]).timeout(const Duration(seconds: 15));
      print("DEBUG: WorkspaceController: All app data fetched successfully.");

      final personalDoc = results[0] as DocumentSnapshot<Map<String, dynamic>>;
      final workspaceDoc = results[1] as DocumentSnapshot<Map<String, dynamic>>;
      final subResult = results[2] as Map<String, dynamic>;

      if (personalDoc.exists) {
        userProfileData.value = personalDoc.data() ?? {};

        // Self-healing: Sync missing fields from FirebaseAuth
        final data = personalDoc.data();
        if (data != null) {
          final userDataToUpdate = <String, dynamic>{};
          if (data['email'] == null) {
            userDataToUpdate['email'] = user.email;
          }
          if (data['name'] == null || data['name'].toString().isEmpty) {
            userDataToUpdate['name'] = user.displayName ?? '';
          }

          if (userDataToUpdate.isNotEmpty) {
            await _firestore
                .collection('users')
                .doc(user.uid)
                .set(userDataToUpdate, SetOptions(merge: true));
            userProfileData.value = {...userProfileData, ...userDataToUpdate};
          }
        }
      }

      if (workspaceDoc.exists) {
        companyData.value = workspaceDoc.data() ?? {};
      }

      subscriptionData.value = subResult;
    } catch (e) {
      print("Error fetching app data: $e");
    } finally {
      isAppDataLoading.value = false;
    }
  }

  Future<void> refreshAppData() async {
    await _fetchAllAppData();
  }

  /// Validates and joins a school workspace
  /// Returns a map with 'success' (bool) and 'message' (String)
  Future<Map<String, dynamic>> joinSchool(String newSchoolId) async {
    final user = _auth.currentUser;
    if (user == null) {
      return {
        'success': false,
        'message': 'No user logged in',
      };
    }

    // Validate input
    if (newSchoolId.trim().isEmpty) {
      return {
        'success': false,
        'message': 'School ID cannot be empty',
      };
    }

    try {
      isLoading.value = true;

      // Validate that the school ID exists in the database
      final schoolDoc = await _firestore
          .collection('users')
          .doc(newSchoolId.trim())
          .get()
          .timeout(const Duration(seconds: 10));

      if (!schoolDoc.exists) {
        return {
          'success': false,
          'message': 'Invalid School ID. This school does not exist.',
        };
      }

      // Optional: Verify the school has basic setup (company data)
      final schoolData = schoolDoc.data();
      if (schoolData == null) {
        return {
          'success': false,
          'message':
              'School data is incomplete. Please contact the school administrator.',
        };
      }

      // Update user's schoolId
      await _firestore.collection('users').doc(user.uid).update({
        'schoolId': newSchoolId.trim(),
      });

      currentSchoolId.value = newSchoolId.trim();
      if (userRole.value == 'Staff') {
        isConnected.value = true;
      }

      // Refresh app data to load the new school's information
      await _fetchAllAppData();

      return {
        'success': true,
        'message': 'Successfully joined school workspace',
      };
    } catch (e) {
      print("Error joining school: $e");
      return {
        'success': false,
        'message':
            'Failed to join school. Please check your connection and try again.',
      };
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> leaveSchool() async {
    await leaveBranch();
  }

  Future<void> leaveBranch() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      isLoading.value = true;
      // Revert to personal workspace (own UID)
      final personalId = user.uid;
      await _firestore.collection('users').doc(user.uid).update({
        'schoolId': personalId,
      });
      currentSchoolId.value = personalId;
      if (userRole.value == 'Staff') {
        isConnected.value = false;
      }
      Get.snackbar("Success", "Returned to personal workspace");
    } catch (e) {
      Get.snackbar("Error", "Failed to leave workspace: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // --- Branch Management Methods ---

  Future<void> _fetchBranches() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('branches')
          .get();

      final branches = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      ownedBranches.assignAll(branches);

      // Set default branch if none selected
      if (currentBranchId.value.isEmpty && branches.isNotEmpty) {
        currentBranchId.value = branches[0]['id'];
      } else if (currentBranchId.value.isEmpty) {
        // If no branches, owner's own UID acts as the primary "branch" or organization context
        currentBranchId.value = user.uid;
      }
    } catch (e) {
      print("Error fetching branches: $e");
    }
  }

  Future<Map<String, dynamic>> createBranch({
    required String branchName,
    String? location,
    String? contactEmail,
    String? contactPhone,
    dynamic logoFile,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return {'success': false, 'message': 'Not logged in'};

    try {
      isLoading.value = true;
      String? logoUrl;
      if (logoFile != null) {
        final storageService = StorageService();
        logoUrl = await storageService.uploadCompanyLogo(user.uid, logoFile);
      }

      final branchData = {
        'branchName': branchName,
        'location': location,
        'contactEmail': contactEmail,
        'contactPhone': contactPhone,
        'logoUrl': logoUrl,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('branches')
          .add(branchData);

      await _fetchBranches();
      return {
        'success': true,
        'message': 'Branch created successfully',
        'id': docRef.id
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>> updateBranchProfile(
      String branchId, Map<String, dynamic> updates,
      {dynamic logoFile}) async {
    final user = _auth.currentUser;
    if (user == null) return {'success': false, 'message': 'Not logged in'};

    try {
      isLoading.value = true;
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('branches')
          .doc(branchId)
          .update(updates);

      await _fetchBranches();
      return {'success': true, 'message': 'Branch updated successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>> deleteBranch(String branchId) async {
    final user = _auth.currentUser;
    if (user == null) return {'success': false, 'message': 'Not logged in'};

    try {
      isLoading.value = true;
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('branches')
          .doc(branchId)
          .delete();

      if (currentBranchId.value == branchId) {
        currentBranchId.value = "";
      }
      await _fetchBranches();
      return {'success': true, 'message': 'Branch deleted successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    } finally {
      isLoading.value = false;
    }
  }

  void switchBranch(String branchId) {
    currentBranchId.value = branchId;
    isOrganizationMode.value = false; // Switching branch exits Org mode
  }

  void toggleViewMode() {
    isOrganizationMode.toggle();
  }

  // --- Staff Request Management ---

  Stream<QuerySnapshot> getJoinRequests() {
    return _firestore
        .collection('users')
        .doc(targetId)
        .collection('join_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Stream<QuerySnapshot> getBranchJoinRequests(String branchId) {
    return _firestore
        .collection('users')
        .doc(targetId)
        .collection('join_requests')
        .where('branchId', isEqualTo: branchId)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Future<Map<String, dynamic>> approveStaffRequest(
      String requestId, String staffUid) async {
    try {
      isLoading.value = true;
      // Get the request data
      final requestDoc = await _firestore
          .collection('users')
          .doc(targetId)
          .collection('join_requests')
          .doc(requestId)
          .get();

      if (!requestDoc.exists)
        return {'success': false, 'message': 'Request not found'};

      // Update staff user document
      await _firestore.collection('users').doc(staffUid).update({
        'schoolId': targetId,
        'role': 'Staff',
      });

      // Mark request as approved
      await _firestore
          .collection('users')
          .doc(targetId)
          .collection('join_requests')
          .doc(requestId)
          .update({'status': 'approved'});

      return {'success': true, 'message': 'Staff request approved'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>> rejectStaffRequest(
      String requestId, String staffUid) async {
    try {
      isLoading.value = true;
      await _firestore
          .collection('users')
          .doc(targetId)
          .collection('join_requests')
          .doc(requestId)
          .update({'status': 'rejected'});

      return {'success': true, 'message': 'Staff request rejected'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>> sendBranchJoinRequest(String schoolId) async {
    final user = _auth.currentUser;
    if (user == null) return {'success': false, 'message': 'Not logged in'};

    try {
      isLoading.value = true;
      await _firestore
          .collection('users')
          .doc(schoolId)
          .collection('join_requests')
          .add({
        'staffId': user.uid,
        'staffName': userProfileData['name'] ?? user.displayName ?? 'Unknown',
        'staffEmail': user.email,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return {'success': true, 'message': 'Join request sent successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    } finally {
      isLoading.value = false;
    }
  }
}
