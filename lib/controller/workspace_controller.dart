import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:mds/services/subscription_service.dart';

class WorkspaceController extends GetxController {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  final RxString currentSchoolId = "".obs;
  final RxString userRole = "Owner".obs; // Default to Owner
  final RxBool isLoading = false.obs; // Changed initial value to false
  final RxBool isConnected =
      true.obs; // Owners are always "connected" to themselves

  // App Data
  final RxMap<String, dynamic> userProfileData =
      <String, dynamic>{}.obs; // Personal profile
  final RxMap<String, dynamic> companyData =
      <String, dynamic>{}.obs; // Workspace/School context
  final RxMap<String, dynamic> subscriptionData = <String, dynamic>{}.obs;
  final RxBool isAppDataLoading = false.obs;
  bool _isInitializing = false; // Added _isInitializing flag
  final SubscriptionService _subscriptionService = SubscriptionService();

  /// Returns the ID that should be used for Firestore operations.
  /// Prioritizes currentSchoolId, falls back to the logged in user's UID.
  String get targetId {
    if (currentSchoolId.value.isNotEmpty) return currentSchoolId.value;
    return _auth.currentUser?.uid ?? "";
  }

  @override
  void onInit() {
    super.onInit();
    initializeWorkspace();

    // Listen to auth changes
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        initializeWorkspace();
      } else {
        currentSchoolId.value = "";
      }
    });
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
        } else {
          // Staff is connected if their schoolId is NOT their own UID and not empty
          isConnected.value =
              schoolId != null && schoolId.isNotEmpty && schoolId != user.uid;
        }
      }

      await _fetchAllAppData();
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

  Future<void> joinSchool(String newSchoolId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      isLoading.value = true;

      // Verify if the school exists (at least one user has this schoolId or it's a valid UID)
      // For now, we assume any provided ID is a valid workspace identifier.
      // In a more robust system, we might check a 'schools' collection.

      await _firestore.collection('users').doc(user.uid).update({
        'schoolId': newSchoolId,
      });

      currentSchoolId.value = newSchoolId;
      if (userRole.value == 'Staff') {
        isConnected.value = true;
      }
      Get.snackbar("Success", "Joined school workspace successfully");
    } catch (e) {
      Get.snackbar("Error", "Failed to join school: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> leaveSchool() async {
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
      Get.snackbar("Error", "Failed to leave school: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
