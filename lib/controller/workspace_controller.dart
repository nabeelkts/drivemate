import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:mds/services/subscription_service.dart';
import 'package:mds/services/storage_service.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mds/features/tracking/services/location_tracking_service.dart';

class WorkspaceController extends GetxController {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _storage = GetStorage();

  final RxString currentSchoolId = "".obs;
  final RxString userRole = "Owner".obs;
  final RxBool isLoading = false.obs;
  final RxBool isConnected = true.obs;
  final RxBool isOrganizationMode = false.obs;

  // App Data
  final RxMap<String, dynamic> userProfileData = <String, dynamic>{}.obs;
  final RxMap<String, dynamic> companyData = <String, dynamic>{}.obs;
  final RxMap<String, dynamic> subscriptionData = <String, dynamic>{}.obs;
  final RxBool isAppDataLoading = false.obs;
  bool _isInitializing = false;
  bool _trackingStarted = false; // Prevent duplicate tracking starts
  final SubscriptionService _subscriptionService = SubscriptionService();
  StreamSubscription? _userDocSubscription;

  // Branch Management State
  final RxList<Map<String, dynamic>> ownedBranches =
      <Map<String, dynamic>>[].obs;
  final RxString currentBranchId = "".obs;

  // Staff branch data - fetched from school's branches collection
  final RxMap<String, dynamic> staffBranchData = <String, dynamic>{}.obs;

  /// Returns the data for the currently active branch
  /// For owners: looks in ownedBranches
  /// For staff: returns staffBranchData or companyData with branch info
  Map<String, dynamic> get currentBranchData {
    if (currentBranchId.value.isEmpty) {
      if (companyData.isNotEmpty) {
        return _normalizeCompanyData(companyData);
      }
      return {};
    }

    // For owners/admins: look in ownedBranches
    final branch = ownedBranches.firstWhere(
      (b) => b['id'] == currentBranchId.value,
      orElse: () => {},
    );

    if (branch.isNotEmpty) return branch;

    // For staff: if we have fetched branch data, use it
    if (staffBranchData.isNotEmpty) {
      return staffBranchData;
    }

    // For staff: if branch not in ownedBranches, use companyData with branchId
    // This happens when staff is connected to a branch they don't own
    if (companyData.isNotEmpty) {
      final normalized = _normalizeCompanyData(companyData);
      // Add branchId to the data so staff knows which branch they're assigned to
      normalized['id'] = currentBranchId.value;
      return normalized;
    }

    return {};
  }

  /// Fetches branch data for staff from the school's branches collection
  Future<void> fetchStaffBranchData() async {
    if (userRole.value != 'Staff' || currentBranchId.value.isEmpty) {
      return;
    }

    try {
      final schoolId = currentSchoolId.value;
      if (schoolId.isEmpty) return;

      final branchDoc = await _firestore
          .collection('users')
          .doc(schoolId)
          .collection('branches')
          .doc(currentBranchId.value)
          .get();

      if (branchDoc.exists) {
        final data = branchDoc.data() ?? {};
        // Normalize field names to match expected format
        staffBranchData.value = {
          'id': branchDoc.id,
          'branchName':
              data['branchName'] ?? data['companyName'] ?? 'Main Branch',
          'logoUrl': data['logoUrl'] ?? data['companyLogo'],
          'location':
              data['location'] ?? data['companyAddress'] ?? data['address'],
          'contactPhone':
              data['contactPhone'] ?? data['companyPhone'] ?? data['phone'],
          'contactEmail':
              data['contactEmail'] ?? data['companyEmail'] ?? data['email'],
        };
        print('DEBUG: Fetched staff branch data: ${staffBranchData.value}');
      } else {
        // If branch doc not found, try to get from companyData
        staffBranchData.value = {
          'id': currentBranchId.value,
          'branchName': companyData['companyName'] ?? 'Main Branch',
          'logoUrl': companyData['companyLogo'],
          'location': companyData['companyAddress'],
          'contactPhone': companyData['companyPhone'],
          'contactEmail': companyData['companyEmail'],
        };
      }
    } catch (e) {
      print('Error fetching staff branch data: $e');
    }
  }

  Map<String, dynamic> _normalizeCompanyData(Map<String, dynamic> data) {
    return {
      'id': targetId,
      'branchName': data['companyName'] ?? data['branchName'] ?? 'Main Branch',
      'logoUrl': data['companyLogo'] ?? data['logoUrl'],
      'location': data['companyAddress'] ?? data['location'],
      'contactPhone': data['contactPhone'] ?? data['companyPhone'],
      'contactEmail': data['contactEmail'] ?? data['companyEmail'],
    };
  }

  /// Returns the ID used for Firestore operations.
  String get targetId {
    if (currentSchoolId.value.isNotEmpty) return currentSchoolId.value;
    return _auth.currentUser?.uid ?? "";
  }

  /// Helper to get a filtered Query for any top-level collection
  Query<Map<String, dynamic>> getFilteredCollection(String collectionName) {
    Query<Map<String, dynamic>> query =
        _firestore.collection('users').doc(targetId).collection(collectionName);

    if (!isOrganizationMode.value &&
        currentBranchId.value.isNotEmpty &&
        currentBranchId.value != targetId) {
      query = query.where('branchId', isEqualTo: currentBranchId.value);
    }

    return query;
  }

  @override
  void onInit() {
    super.onInit();
    _loadMode();
    initializeWorkspace();

    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _trackingStarted = false; // Reset on re-login
        initializeWorkspace();
        _listenToUserDoc(user.uid);
      } else {
        currentSchoolId.value = "";
        _trackingStarted = false;
        _userDocSubscription?.cancel();
      }
    });

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

    // Hard fail-safe
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

    // Persist userId immediately for background tracking service
    _storage.write('userId', user.uid);

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
            schoolId = user.uid;
            await _firestore.collection('users').doc(user.uid).update({
              'schoolId': schoolId,
            });
          }
        }
        currentSchoolId.value = schoolId ?? "";
        currentBranchId.value = data?['branchId'] ?? "";

        if (role == 'Owner') {
          isConnected.value = true;
        } else {
          isConnected.value =
              schoolId != null && schoolId.isNotEmpty && schoolId != user.uid;
        }

        // Persist for background service
        if (schoolId != null && schoolId.isNotEmpty) {
          _storage.write('schoolId', schoolId);
        }
        final branchId = data?['branchId'] as String?;
        if (branchId != null && branchId.isNotEmpty) {
          _storage.write('branchId', branchId);
        }
        final driverName = data?['name'] as String?;
        if (driverName != null && driverName.isNotEmpty) {
          _storage.write('driverName', driverName);
        }
      }

      await _fetchAllAppData();

      if (userRole.value == 'Owner' ||
          userRole.value == 'Admin' ||
          userRole.value == 'Staff') {
        await _fetchBranches();
      }

      // For staff: fetch the specific branch data they're assigned to
      if (userRole.value == 'Staff' && isConnected.value) {
        await fetchStaffBranchData();
      }
    } catch (e) {
      print("Error initializing workspace: $e");
    } finally {
      isLoading.value = false;
      _isInitializing = false;

      // -------------------------------------------------------
      // START FOREGROUND TRACKING FOR STAFF
      // Only staff members share their location.
      // This runs in the foreground isolate so the background
      // service is only needed when the app is fully closed.
      // -------------------------------------------------------
      if (userRole.value == 'Staff' && !_trackingStarted) {
        final uid = _auth.currentUser?.uid;
        if (uid != null) {
          try {
            final trackingService = Get.find<LocationTrackingService>();
            _trackingStarted = true;
            await trackingService.observeLessonStatus(uid);
            print('DEBUG: Foreground tracking started for uid=$uid '
                'schoolId=${_storage.read('schoolId')} '
                'branchId=${_storage.read('branchId')} '
                'driverName=${_storage.read('driverName')}');
          } catch (e) {
            print('DEBUG: Could not start foreground tracking: $e');
            _trackingStarted = false;
          }
        }
      }
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

      final results = await Future.wait([
        _firestore.collection('users').doc(user.uid).get(),
        _firestore.collection('users').doc(targetIdValue).get(),
        _subscriptionService.checkSubscription(targetIdValue),
      ]).timeout(const Duration(seconds: 15));
      print("DEBUG: WorkspaceController: All app data fetched successfully.");

      final personalDoc = results[0] as DocumentSnapshot<Map<String, dynamic>>;
      final workspaceDoc = results[1] as DocumentSnapshot<Map<String, dynamic>>;
      final subResult = results[2] as Map<String, dynamic>;

      if (personalDoc.exists) {
        userProfileData.value = personalDoc.data() ?? {};

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

      // Persist driver metadata for background tracking service
      final driverName = userProfileData['name'] as String?;
      final persistedSchoolId = currentSchoolId.value.isNotEmpty
          ? currentSchoolId.value
          : _auth.currentUser?.uid;
      if (driverName != null && driverName.isNotEmpty) {
        _storage.write('driverName', driverName);
      }
      if (persistedSchoolId != null && persistedSchoolId.isNotEmpty) {
        _storage.write('schoolId', persistedSchoolId);
      }
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
  Future<Map<String, dynamic>> joinSchool(String newSchoolId) async {
    final user = _auth.currentUser;
    if (user == null) {
      return {'success': false, 'message': 'No user logged in'};
    }

    if (newSchoolId.trim().isEmpty) {
      return {'success': false, 'message': 'School ID cannot be empty'};
    }

    try {
      isLoading.value = true;

      final String rawId = newSchoolId.trim();
      String finalSchoolId = rawId;
      String? finalBranchId;

      if (rawId.contains(':')) {
        final parts = rawId.split(':');
        finalSchoolId = parts[0].trim();
        finalBranchId = parts[1].trim();
      }

      final schoolDoc = await _firestore
          .collection('users')
          .doc(finalSchoolId)
          .get()
          .timeout(const Duration(seconds: 10));

      if (!schoolDoc.exists) {
        return {
          'success': false,
          'message': 'Invalid School ID. This school does not exist.',
        };
      }

      final schoolData = schoolDoc.data();
      if (schoolData == null) {
        return {'success': false, 'message': 'School data is incomplete.'};
      }

      final updates = <String, dynamic>{'schoolId': finalSchoolId};
      if (finalBranchId != null) {
        updates['branchId'] = finalBranchId;
      }

      await _firestore.collection('users').doc(user.uid).update(updates);

      currentSchoolId.value = finalSchoolId;
      if (finalBranchId != null) {
        currentBranchId.value = finalBranchId;
      }

      if (userRole.value == 'Staff') {
        isConnected.value = true;
      }

      // Reset tracking so it restarts with new schoolId
      _trackingStarted = false;

      await _fetchAllAppData();

      return {
        'success': true,
        'message': 'Successfully joined school workspace'
      };
    } catch (e) {
      print("Error joining school: $e");
      return {
        'success': false,
        'message': 'Failed to join school. Please check your connection.',
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
          .doc(targetId)
          .collection('branches')
          .get();

      final List<Map<String, dynamic>> branches = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      if (userRole.value == 'Owner') {
        branches.removeWhere((b) => b['id'] == targetId);
        final mainBranch = _normalizeCompanyData(companyData);
        mainBranch['id'] = targetId;
        mainBranch['isMain'] = true;
        branches.insert(0, mainBranch);
      }

      ownedBranches.assignAll(branches);

      final isValid = branches.any((b) => b['id'] == currentBranchId.value);
      if (currentBranchId.value.isEmpty || !isValid) {
        if (userRole.value == 'Owner') {
          currentBranchId.value = targetId;
        } else {
          currentBranchId.value = "";
        }
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
          .doc(targetId)
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
          .doc(targetId)
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
          .doc(targetId)
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
    isOrganizationMode.value = false;
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
      final requestDoc = await _firestore
          .collection('users')
          .doc(targetId)
          .collection('join_requests')
          .doc(requestId)
          .get();

      if (!requestDoc.exists) {
        return {'success': false, 'message': 'Request not found'};
      }

      await _firestore.collection('users').doc(staffUid).update({
        'schoolId': targetId,
        'role': 'Staff',
      });

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

  void _listenToUserDoc(String uid) {
    _userDocSubscription?.cancel();
    _userDocSubscription =
        _firestore.collection('users').doc(uid).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        final newSchoolId = data?['schoolId'] ?? "";
        final newBranchId = data?['branchId'] ?? "";
        final newRole = data?['role'] ?? "Owner";

        bool needsRefresh = false;
        if (newSchoolId != currentSchoolId.value) {
          currentSchoolId.value = newSchoolId;
          needsRefresh = true;
        }
        if (newBranchId != currentBranchId.value) {
          currentBranchId.value = newBranchId;
          needsRefresh = true;
        }
        if (newRole != userRole.value) {
          userRole.value = newRole;
          needsRefresh = true;
        }

        if (needsRefresh) {
          print("DEBUG: User doc changed, refreshing workspace...");
          _trackingStarted = false; // Allow tracking to restart with new data
          initializeWorkspace();
        }
      }
    });
  }

  @override
  void onClose() {
    _userDocSubscription?.cancel();
    super.onClose();
  }
}
