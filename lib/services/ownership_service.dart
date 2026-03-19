import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

/// Service to validate data ownership and prevent IDOR vulnerabilities
/// Ensures users can only access data they own or have permission to access
class OwnershipService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Validates if the current user has access to the specified school's data
  ///
  /// For Owners: They must own the schoolId (their UID matches schoolId)
  /// For Staff: They must have schoolId in their user profile matching the target school
  /// For Students: They must have the target schoolId in their profile
  Future<bool> canAccessSchool(String schoolId) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    if (schoolId.isEmpty) return false;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;
      final userRole = userData['role'] as String?;
      final userSchoolId = userData['schoolId'] as String?;

      switch (userRole) {
        case 'Owner':
          // Owner can access their own school (UID matches schoolId)
          return user.uid == schoolId;
        case 'Staff':
          // Staff can access the school they're assigned to
          return userSchoolId == schoolId;
        case 'Student':
          // Student can access their assigned school
          return userSchoolId == schoolId;
        default:
          return false;
      }
    } catch (e) {
      print('Error validating school access: $e');
      return false;
    }
  }

  /// Validates if the current user can access a specific document
  /// This is an additional layer of security beyond canAccessSchool
  Future<bool> canAccessDocument(
      String schoolId, String collectionName, String docId) async {
    // First verify school access
    if (!await canAccessSchool(schoolId)) {
      return false;
    }

    try {
      // Additional validation: verify the document exists and belongs to the school
      final doc = await _firestore
          .collection('users')
          .doc(schoolId)
          .collection(collectionName)
          .doc(docId)
          .get();

      return doc.exists;
    } catch (e) {
      print('Error validating document access: $e');
      return false;
    }
  }

  /// Validates if the current user can modify (update/delete) a document
  Future<bool> canModifyDocument(
      String schoolId, String collectionName, String docId) async {
    // For modification, we need stricter validation
    // Only Owner and Staff can modify data
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;
      final userRole = userData['role'] as String?;

      // Students cannot modify any data
      if (userRole == 'Student') {
        return false;
      }

      // Owners and Staff can modify if they have school access
      return await canAccessSchool(schoolId);
    } catch (e) {
      print('Error validating modify access: $e');
      return false;
    }
  }

  /// Gets the allowed school ID for the current user
  /// Returns the schoolId from user profile or user's UID for owners
  Future<String?> getAllowedSchoolId() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) return null;

      final userData = userDoc.data()!;
      final userRole = userData['role'] as String?;
      final userSchoolId = userData['schoolId'] as String?;

      if (userRole == 'Owner') {
        // Owner owns their own school (UID)
        return user.uid;
      } else {
        // Staff/Student have assigned schoolId
        return userSchoolId;
      }
    } catch (e) {
      print('Error getting allowed schoolId: $e');
      return null;
    }
  }

  /// Validates that a staff member is actually assigned to the target school
  /// This prevents staff from accessing other schools' data even if they know the schoolId
  Future<bool> isStaffAssignedToSchool(
      String staffUid, String targetSchoolId) async {
    try {
      final staffDoc = await _firestore.collection('users').doc(staffUid).get();

      if (!staffDoc.exists) return false;

      final staffData = staffDoc.data()!;
      final staffRole = staffData['role'] as String?;
      final staffSchoolId = staffData['schoolId'] as String?;

      // Only staff members need this validation
      if (staffRole != 'Staff') return true;

      // Staff must be assigned to the target school
      return staffSchoolId == targetSchoolId;
    } catch (e) {
      print('Error validating staff assignment: $e');
      return false;
    }
  }

  /// Securely queries data with ownership validation
  /// This should be used instead of direct Firestore queries
  Future<QuerySnapshot?> secureQuery({
    required String schoolId,
    required String collectionName,
    bool requireWriteAccess = false,
  }) async {
    // Validate access first
    if (requireWriteAccess) {
      if (!await canModifyDocument(schoolId, collectionName, '')) {
        return null;
      }
    } else {
      if (!await canAccessSchool(schoolId)) {
        return null;
      }
    }

    try {
      return await _firestore
          .collection('users')
          .doc(schoolId)
          .collection(collectionName)
          .get();
    } catch (e) {
      print('Error in secure query: $e');
      return null;
    }
  }
}
