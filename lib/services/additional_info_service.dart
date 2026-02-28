import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:mds/controller/workspace_controller.dart';

/// Service for managing additional information across all detail pages
class AdditionalInfoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final WorkspaceController _workspaceController =
      Get.find<WorkspaceController>();

  /// Get the base path for collections based on workspace
  String _getBasePath() {
    final schoolId = _workspaceController.currentSchoolId.value;
    if (schoolId.isNotEmpty) {
      return 'users/$schoolId';
    }
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    return 'users/$userId';
  }

  // ==================== STUDENT TYPE (Student, License Only, Endorsement) ====================

  /// Save additional info for Student/License Only/Endorsement
  Future<void> saveStudentTypeAdditionalInfo({
    required String collection,
    required String documentId,
    required String? applicationNumber,
    required String? learnersLicenseNumber,
    required String? learnersLicenseExpiry,
    required String? drivingLicenseNumber,
    required String? drivingLicenseExpiry,
    required Map<String, dynamic> customFields,
  }) async {
    final data = {
      'applicationNumber': applicationNumber ?? '',
      'learnersLicenseNumber': learnersLicenseNumber ?? '',
      'learnersLicenseExpiry': learnersLicenseExpiry ?? '',
      'drivingLicenseNumber': drivingLicenseNumber ?? '',
      'drivingLicenseExpiry': drivingLicenseExpiry ?? '',
      'customFields': customFields,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final basePath = _getBasePath();
    await _firestore
        .doc('$basePath/$collection/$documentId')
        .set({'additionalInfo': data}, SetOptions(merge: true));
  }

  /// Get additional info for Student/License Only/Endorsement
  Future<Map<String, dynamic>?> getStudentTypeAdditionalInfo({
    required String collection,
    required String documentId,
  }) async {
    final basePath = _getBasePath();
    final doc = await _firestore.doc('$basePath/$collection/$documentId').get();
    if (!doc.exists) return null;

    final data = doc.data();
    return data?['additionalInfo'] as Map<String, dynamic>?;
  }

  // ==================== DL SERVICE ====================

  /// Save additional info for DL Service
  Future<void> saveDlServiceAdditionalInfo({
    required String documentId,
    required String? applicationNumber,
    required String? licenseNumber,
    required String? licenseExpiry,
    required Map<String, dynamic> customFields,
  }) async {
    final data = {
      'applicationNumber': applicationNumber ?? '',
      'licenseNumber': licenseNumber ?? '',
      'licenseExpiry': licenseExpiry ?? '',
      'customFields': customFields,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final basePath = _getBasePath();
    await _firestore
        .doc('$basePath/dl_services/$documentId')
        .set({'additionalInfo': data}, SetOptions(merge: true));
  }

  /// Get additional info for DL Service
  Future<Map<String, dynamic>?> getDlServiceAdditionalInfo({
    required String documentId,
  }) async {
    final basePath = _getBasePath();
    final doc = await _firestore.doc('$basePath/dl_services/$documentId').get();
    if (!doc.exists) return null;

    final data = doc.data();
    return data?['additionalInfo'] as Map<String, dynamic>?;
  }

  // ==================== RC SERVICE ====================

  /// Save additional info for RC Service
  Future<void> saveRcServiceAdditionalInfo({
    required String documentId,
    required String? registrationRenewalOrFitnessExpiry,
    required String? insuranceExpiry,
    required String? taxExpiry,
    required String? pollutionExpiry,
    required String? permitExpiry,
    required Map<String, dynamic> customFields,
  }) async {
    final data = {
      'registrationRenewalOrFitnessExpiry':
          registrationRenewalOrFitnessExpiry ?? '',
      'insuranceExpiry': insuranceExpiry ?? '',
      'taxExpiry': taxExpiry ?? '',
      'pollutionExpiry': pollutionExpiry ?? '',
      'permitExpiry': permitExpiry ?? '',
      'customFields': customFields,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final basePath = _getBasePath();
    await _firestore
        .doc('$basePath/vehicleDetails/$documentId')
        .set({'additionalInfo': data}, SetOptions(merge: true));
  }

  /// Get additional info for RC Service
  Future<Map<String, dynamic>?> getRcServiceAdditionalInfo({
    required String documentId,
  }) async {
    final basePath = _getBasePath();
    final doc =
        await _firestore.doc('$basePath/vehicleDetails/$documentId').get();
    if (!doc.exists) return null;

    final data = doc.data();
    return data?['additionalInfo'] as Map<String, dynamic>?;
  }
}
