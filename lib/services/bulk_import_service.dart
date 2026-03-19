import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:drivemate/controller/workspace_controller.dart';
import 'package:drivemate/services/excel_import_service.dart';

/// Result of an import operation
class ImportResult {
  final int totalRecords;
  final int successCount;
  final int failureCount;
  final int duplicateCount;
  final List<ImportError> errors;
  final List<String> createdIds;

  ImportResult({
    required this.totalRecords,
    required this.successCount,
    required this.failureCount,
    required this.duplicateCount,
    required this.errors,
    required this.createdIds,
  });

  bool get isFullySuccessful => failureCount == 0;
  bool get hasFailures => failureCount > 0;
}

/// Error details for a failed import
class ImportError {
  final int rowNumber;
  final String message;
  final Map<String, dynamic>? data;

  ImportError({
    required this.rowNumber,
    required this.message,
    this.data,
  });
}

/// Service for bulk importing records to Firestore
class BulkImportService {
  final ExcelImportService _excelService = ExcelImportService();

  /// Import students from parsed data
  Future<ImportResult> importStudents(
    List<Map<String, dynamic>> data,
    String targetId,
  ) async {
    final List<ImportError> errors = [];
    final List<String> createdIds = [];
    int successCount = 0;

    final usersCollection = FirebaseFirestore.instance.collection('users');
    final workspaceController = Get.find<WorkspaceController>();
    final branchId = workspaceController.currentBranchId.value;
    final branchData = workspaceController.currentBranchData;
    final branchName = branchData['branchName'] ?? 'Main';

    for (int i = 0; i < data.length; i++) {
      try {
        final row = data[i];
        final rowNumber = i + 2; // +2 because Excel is 1-indexed and has header

        // Validate row
        final validationErrors =
            _excelService.validateRow(row, ImportType.student);
        if (validationErrors.isNotEmpty) {
          errors.add(ImportError(
            rowNumber: rowNumber,
            message: validationErrors.join(', '),
            data: row,
          ));
          continue;
        }

        // Check for duplicate (mobile + name combination)
        final mobileNumber = row['mobileNumber']?.toString().trim() ?? '';
        final fullName = row['fullName']?.toString().trim() ?? '';
        final isDuplicate = await _checkForDuplicate(
          targetId: targetId,
          collectionName: 'students',
          mobileNumber: mobileNumber,
          fullName: fullName,
        );
        if (isDuplicate) {
          errors.add(ImportError(
            rowNumber: rowNumber,
            message:
                'Duplicate: A record with this mobile number and name already exists',
            data: row,
          ));
          continue;
        }

        // Generate student ID
        String studentId = row['studentId']?.toString() ?? '';
        if (studentId.isEmpty) {
          studentId = await _generateRecordId(targetId);
          row['studentId'] = studentId;
        }

        // Add registration date - use existing if provided in Excel, otherwise use current date
        if (row['registrationDate'] == null ||
            row['registrationDate'].toString().isEmpty) {
          row['registrationDate'] = DateTime.now().toIso8601String();
        }

        // Add branch info
        row['branchId'] = branchId;
        row['branchName'] = branchName;

        // Add to Firestore
        await usersCollection
            .doc(targetId)
            .collection('students')
            .doc(studentId)
            .set(row);

        // Record payment if advance amount exists
        final advance =
            double.tryParse(row['advanceAmount']?.toString() ?? '0') ?? 0;
        if (advance > 0) {
          await usersCollection
              .doc(targetId)
              .collection('students')
              .doc(studentId)
              .collection('payments')
              .add({
            'amount': advance,
            'mode': row['paymentMode'] ?? 'Cash',
            'date': Timestamp.now(),
            'description': 'Initial Advance',
            'createdAt': FieldValue.serverTimestamp(),
            'targetId': targetId,
            'recordId': studentId,
            'recordName': row['fullName'],
            'category': 'students',
            'branchId': branchId,
            'branchName': branchName,
          });
        }

        createdIds.add(studentId);
        successCount++;

        if (kDebugMode) {
          print('Imported student: ${row['fullName']} with ID: $studentId');
        }
      } catch (e) {
        errors.add(ImportError(
          rowNumber: i + 2,
          message: e.toString(),
          data: data[i],
        ));
      }
    }

    return ImportResult(
      totalRecords: data.length,
      successCount: successCount,
      failureCount: errors.length,
      duplicateCount:
          errors.where((e) => e.message.contains('Duplicate:')).length,
      errors: errors,
      createdIds: createdIds,
    );
  }

  /// Import license only records from parsed data
  Future<ImportResult> importLicenseOnly(
    List<Map<String, dynamic>> data,
    String targetId,
  ) async {
    final List<ImportError> errors = [];
    final List<String> createdIds = [];
    int successCount = 0;

    final usersCollection = FirebaseFirestore.instance.collection('users');
    final workspaceController = Get.find<WorkspaceController>();
    final branchId = workspaceController.currentBranchId.value;

    for (int i = 0; i < data.length; i++) {
      try {
        final row = data[i];
        final rowNumber = i + 2;

        // Validate row
        final validationErrors =
            _excelService.validateRow(row, ImportType.licenseOnly);
        if (validationErrors.isNotEmpty) {
          errors.add(ImportError(
            rowNumber: rowNumber,
            message: validationErrors.join(', '),
            data: row,
          ));
          continue;
        }

        // Check for duplicate (mobile + name combination)
        final mobileNumber = row['mobileNumber']?.toString().trim() ?? '';
        final fullName = row['fullName']?.toString().trim() ?? '';
        final isDuplicate = await _checkForDuplicate(
          targetId: targetId,
          collectionName: 'licenseonly',
          mobileNumber: mobileNumber,
          fullName: fullName,
        );
        if (isDuplicate) {
          errors.add(ImportError(
            rowNumber: rowNumber,
            message:
                'Duplicate: A record with this mobile number and name already exists',
            data: row,
          ));
          continue;
        }

        // Generate ID
        String recordId = row['studentId']?.toString() ?? '';
        if (recordId.isEmpty) {
          recordId = await _generateRecordId(targetId);
          row['studentId'] = recordId;
        }

        // Add registration date - use existing if provided in Excel, otherwise use current date
        if (row['registrationDate'] == null ||
            row['registrationDate'].toString().isEmpty) {
          row['registrationDate'] = DateTime.now().toIso8601String();
        }

        // Add branch info
        row['branchId'] = branchId;

        // Add to Firestore
        await usersCollection
            .doc(targetId)
            .collection('licenseonly')
            .doc(recordId)
            .set(row);

        // Record payment if advance amount exists
        final advance =
            double.tryParse(row['advanceAmount']?.toString() ?? '0') ?? 0;
        if (advance > 0) {
          await usersCollection
              .doc(targetId)
              .collection('licenseonly')
              .doc(recordId)
              .collection('payments')
              .add({
            'amount': advance,
            'mode': row['paymentMode'] ?? 'Cash',
            'date': Timestamp.now(),
            'description': 'Initial Advance',
            'createdAt': FieldValue.serverTimestamp(),
            'targetId': targetId,
            'recordId': recordId,
            'recordName': row['fullName'],
            'category': 'licenseonly',
            'branchId': branchId,
          });
        }

        createdIds.add(recordId);
        successCount++;
      } catch (e) {
        errors.add(ImportError(
          rowNumber: i + 2,
          message: e.toString(),
          data: data[i],
        ));
      }
    }

    return ImportResult(
      totalRecords: data.length,
      successCount: successCount,
      failureCount: errors.length,
      duplicateCount:
          errors.where((e) => e.message.contains('Duplicate:')).length,
      errors: errors,
      createdIds: createdIds,
    );
  }

  /// Import endorsement records from parsed data
  Future<ImportResult> importEndorsement(
    List<Map<String, dynamic>> data,
    String targetId,
  ) async {
    final List<ImportError> errors = [];
    final List<String> createdIds = [];
    int successCount = 0;

    final usersCollection = FirebaseFirestore.instance.collection('users');
    final workspaceController = Get.find<WorkspaceController>();
    final branchId = workspaceController.currentBranchId.value;

    for (int i = 0; i < data.length; i++) {
      try {
        final row = data[i];
        final rowNumber = i + 2;

        // Validate row
        final validationErrors =
            _excelService.validateRow(row, ImportType.endorsement);
        if (validationErrors.isNotEmpty) {
          errors.add(ImportError(
            rowNumber: rowNumber,
            message: validationErrors.join(', '),
            data: row,
          ));
          continue;
        }

        // Check for duplicate (mobile + name combination)
        final mobileNumber = row['mobileNumber']?.toString().trim() ?? '';
        final fullName = row['fullName']?.toString().trim() ?? '';
        final isDuplicate = await _checkForDuplicate(
          targetId: targetId,
          collectionName: 'endorsement',
          mobileNumber: mobileNumber,
          fullName: fullName,
        );
        if (isDuplicate) {
          errors.add(ImportError(
            rowNumber: rowNumber,
            message:
                'Duplicate: A record with this mobile number and name already exists',
            data: row,
          ));
          continue;
        }

        // Generate ID
        String recordId = row['studentId']?.toString() ?? '';
        if (recordId.isEmpty) {
          recordId = await _generateRecordId(targetId);
          row['studentId'] = recordId;
        }

        // Add registration date - use existing if provided in Excel, otherwise use current date
        if (row['registrationDate'] == null ||
            row['registrationDate'].toString().isEmpty) {
          row['registrationDate'] = DateTime.now().toIso8601String();
        }

        // Add branch info
        row['branchId'] = branchId;

        // Add to Firestore
        await usersCollection
            .doc(targetId)
            .collection('endorsement')
            .doc(recordId)
            .set(row);

        // Record payment if advance amount exists
        final advance =
            double.tryParse(row['advanceAmount']?.toString() ?? '0') ?? 0;
        if (advance > 0) {
          await usersCollection
              .doc(targetId)
              .collection('endorsement')
              .doc(recordId)
              .collection('payments')
              .add({
            'amount': advance,
            'mode': row['paymentMode'] ?? 'Cash',
            'date': Timestamp.now(),
            'description': 'Initial Advance',
            'createdAt': FieldValue.serverTimestamp(),
            'targetId': targetId,
            'recordId': recordId,
            'recordName': row['fullName'],
            'category': 'endorsement',
            'branchId': branchId,
          });
        }

        createdIds.add(recordId);
        successCount++;
      } catch (e) {
        errors.add(ImportError(
          rowNumber: i + 2,
          message: e.toString(),
          data: data[i],
        ));
      }
    }

    return ImportResult(
      totalRecords: data.length,
      successCount: successCount,
      failureCount: errors.length,
      duplicateCount:
          errors.where((e) => e.message.contains('Duplicate:')).length,
      errors: errors,
      createdIds: createdIds,
    );
  }

  /// Import DL service records from parsed data
  Future<ImportResult> importDLService(
    List<Map<String, dynamic>> data,
    String targetId,
  ) async {
    final List<ImportError> errors = [];
    final List<String> createdIds = [];
    int successCount = 0;

    final usersCollection = FirebaseFirestore.instance.collection('users');
    final workspaceController = Get.find<WorkspaceController>();
    final branchId = workspaceController.currentBranchId.value;

    for (int i = 0; i < data.length; i++) {
      try {
        final row = data[i];
        final rowNumber = i + 2;

        // Validate row
        final validationErrors =
            _excelService.validateRow(row, ImportType.dlService);
        if (validationErrors.isNotEmpty) {
          errors.add(ImportError(
            rowNumber: rowNumber,
            message: validationErrors.join(', '),
            data: row,
          ));
          continue;
        }

        // Check for duplicate (mobile + name combination)
        final mobileNumber = row['mobileNumber']?.toString().trim() ?? '';
        final fullName = row['fullName']?.toString().trim() ?? '';
        final isDuplicate = await _checkForDuplicate(
          targetId: targetId,
          collectionName: 'dlservices',
          mobileNumber: mobileNumber,
          fullName: fullName,
        );
        if (isDuplicate) {
          errors.add(ImportError(
            rowNumber: rowNumber,
            message:
                'Duplicate: A record with this mobile number and name already exists',
            data: row,
          ));
          continue;
        }

        // Generate ID
        String recordId = row['studentId']?.toString() ?? '';
        if (recordId.isEmpty) {
          recordId = await _generateRecordId(targetId);
          row['studentId'] = recordId;
        }

        // Add registration date - use existing if provided in Excel, otherwise use current date
        if (row['registrationDate'] == null ||
            row['registrationDate'].toString().isEmpty) {
          row['registrationDate'] = DateTime.now().toIso8601String();
        }

        // Add branch info
        row['branchId'] = branchId;

        // Add to Firestore
        await usersCollection
            .doc(targetId)
            .collection('dlservices')
            .doc(recordId)
            .set(row);

        // Record payment if advance amount exists
        final advance =
            double.tryParse(row['advanceAmount']?.toString() ?? '0') ?? 0;
        if (advance > 0) {
          await usersCollection
              .doc(targetId)
              .collection('dlservices')
              .doc(recordId)
              .collection('payments')
              .add({
            'amount': advance,
            'mode': row['paymentMode'] ?? 'Cash',
            'date': Timestamp.now(),
            'description': 'Initial Advance',
            'createdAt': FieldValue.serverTimestamp(),
            'targetId': targetId,
            'recordId': recordId,
            'recordName': row['fullName'],
            'category': 'dlservices',
            'branchId': branchId,
          });
        }

        createdIds.add(recordId);
        successCount++;
      } catch (e) {
        errors.add(ImportError(
          rowNumber: i + 2,
          message: e.toString(),
          data: data[i],
        ));
      }
    }

    return ImportResult(
      totalRecords: data.length,
      successCount: successCount,
      failureCount: errors.length,
      duplicateCount:
          errors.where((e) => e.message.contains('Duplicate:')).length,
      errors: errors,
      createdIds: createdIds,
    );
  }

  /// Import vehicle details records from parsed data
  Future<ImportResult> importVehicleDetails(
    List<Map<String, dynamic>> data,
    String targetId,
  ) async {
    final List<ImportError> errors = [];
    final List<String> createdIds = [];
    int successCount = 0;

    final usersCollection = FirebaseFirestore.instance.collection('users');
    final workspaceController = Get.find<WorkspaceController>();
    final branchId = workspaceController.currentBranchId.value;

    for (int i = 0; i < data.length; i++) {
      try {
        final row = data[i];
        final rowNumber = i + 2;

        // Validate row
        final validationErrors =
            _excelService.validateRow(row, ImportType.vehicleDetails);
        if (validationErrors.isNotEmpty) {
          errors.add(ImportError(
            rowNumber: rowNumber,
            message: validationErrors.join(', '),
            data: row,
          ));
          continue;
        }

        // Check for duplicate (mobile + name combination)
        final mobileNumber = row['mobileNumber']?.toString().trim() ?? '';
        final fullName = row['fullName']?.toString().trim() ?? '';
        final isDuplicate = await _checkForDuplicate(
          targetId: targetId,
          collectionName: 'vehicledetails',
          mobileNumber: mobileNumber,
          fullName: fullName,
        );
        if (isDuplicate) {
          errors.add(ImportError(
            rowNumber: rowNumber,
            message:
                'Duplicate: A record with this mobile number and name already exists',
            data: row,
          ));
          continue;
        }

        // Generate ID
        String recordId = row['vehicleNumber']?.toString() ?? '';
        if (recordId.isEmpty) {
          recordId = await _generateRecordId(targetId);
        }

        // Add registration date - use existing if provided in Excel, otherwise use current date
        if (row['registrationDate'] == null ||
            row['registrationDate'].toString().isEmpty) {
          row['registrationDate'] = DateTime.now().toIso8601String();
        }

        // Add branch info
        row['branchId'] = branchId;

        // Add to Firestore
        await usersCollection
            .doc(targetId)
            .collection('vehicledetails')
            .doc(recordId)
            .set(row);

        // Record payment if advance amount exists
        final advance =
            double.tryParse(row['advanceAmount']?.toString() ?? '0') ?? 0;
        if (advance > 0) {
          await usersCollection
              .doc(targetId)
              .collection('vehicledetails')
              .doc(recordId)
              .collection('payments')
              .add({
            'amount': advance,
            'mode': row['paymentMode'] ?? 'Cash',
            'date': Timestamp.now(),
            'description': 'Initial Advance',
            'createdAt': FieldValue.serverTimestamp(),
            'targetId': targetId,
            'recordId': recordId,
            'recordName': row['fullName'],
            'category': 'vehicledetails',
            'branchId': branchId,
          });
        }

        createdIds.add(recordId);
        successCount++;
      } catch (e) {
        errors.add(ImportError(
          rowNumber: i + 2,
          message: e.toString(),
          data: data[i],
        ));
      }
    }

    return ImportResult(
      totalRecords: data.length,
      successCount: successCount,
      failureCount: errors.length,
      duplicateCount:
          errors.where((e) => e.message.contains('Duplicate:')).length,
      errors: errors,
      createdIds: createdIds,
    );
  }

  /// Import RC details records from parsed data
  Future<ImportResult> importRCDetails(
    List<Map<String, dynamic>> data,
    String targetId,
  ) async {
    final List<ImportError> errors = [];
    final List<String> createdIds = [];
    int successCount = 0;

    final usersCollection = FirebaseFirestore.instance.collection('users');
    final workspaceController = Get.find<WorkspaceController>();
    final branchId = workspaceController.currentBranchId.value;

    for (int i = 0; i < data.length; i++) {
      try {
        final row = data[i];
        final rowNumber = i + 2;

        // Validate row
        final validationErrors =
            _excelService.validateRow(row, ImportType.rcDetails);
        if (validationErrors.isNotEmpty) {
          errors.add(ImportError(
            rowNumber: rowNumber,
            message: validationErrors.join(', '),
            data: row,
          ));
          continue;
        }

        // Check for duplicate (mobile + name combination)
        final mobileNumber = row['mobileNumber']?.toString().trim() ?? '';
        final fullName = row['fullName']?.toString().trim() ?? '';
        final isDuplicate = await _checkForDuplicate(
          targetId: targetId,
          collectionName: 'rcdetails',
          mobileNumber: mobileNumber,
          fullName: fullName,
        );
        if (isDuplicate) {
          errors.add(ImportError(
            rowNumber: rowNumber,
            message:
                'Duplicate: A record with this mobile number and name already exists',
            data: row,
          ));
          continue;
        }

        // Generate ID
        String recordId = row['vehicleNumber']?.toString() ?? '';
        if (recordId.isEmpty) {
          recordId = await _generateRecordId(targetId);
        }

        // Add registration date - use existing if provided in Excel, otherwise use current date
        if (row['registrationDate'] == null ||
            row['registrationDate'].toString().isEmpty) {
          row['registrationDate'] = DateTime.now().toIso8601String();
        }

        // Add branch info
        row['branchId'] = branchId;

        // Add to Firestore
        await usersCollection
            .doc(targetId)
            .collection('rcdetails')
            .doc(recordId)
            .set(row);

        // Record payment if advance amount exists
        final advance =
            double.tryParse(row['advanceAmount']?.toString() ?? '0') ?? 0;
        if (advance > 0) {
          await usersCollection
              .doc(targetId)
              .collection('rcdetails')
              .doc(recordId)
              .collection('payments')
              .add({
            'amount': advance,
            'mode': row['paymentMode'] ?? 'Cash',
            'date': Timestamp.now(),
            'description': 'Initial Advance',
            'createdAt': FieldValue.serverTimestamp(),
            'targetId': targetId,
            'recordId': recordId,
            'recordName': row['fullName'],
            'category': 'rcdetails',
            'branchId': branchId,
          });
        }

        createdIds.add(recordId);
        successCount++;
      } catch (e) {
        errors.add(ImportError(
          rowNumber: i + 2,
          message: e.toString(),
          data: data[i],
        ));
      }
    }

    return ImportResult(
      totalRecords: data.length,
      successCount: successCount,
      failureCount: errors.length,
      duplicateCount:
          errors.where((e) => e.message.contains('Duplicate:')).length,
      errors: errors,
      createdIds: createdIds,
    );
  }

  /// Get target ID from current user
  Future<String> getTargetId() async {
    final user = FirebaseAuth.instance.currentUser;
    final workspaceController = Get.find<WorkspaceController>();
    final schoolId = workspaceController.currentSchoolId.value;
    return schoolId.isNotEmpty ? schoolId : user?.uid ?? '';
  }

  /// Generate a unique record ID
  Future<String> _generateRecordId(String targetId) async {
    final now = DateTime.now();
    final dateLabel =
        '${now.day.toString().padLeft(2, '0')}${now.month.toString().padLeft(2, '0')}${now.year}';
    final timeLabel =
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    return '$dateLabel$timeLabel';
  }

  /// Check if a record with the same mobile number and full name already exists
  /// Returns true if duplicate found, false otherwise
  Future<bool> _checkForDuplicate({
    required String targetId,
    required String collectionName,
    required String mobileNumber,
    required String fullName,
  }) async {
    if (mobileNumber.isEmpty || fullName.isEmpty) {
      return false; // Can't check without both values
    }

    // Normalize the values for comparison
    final normalizedMobile = mobileNumber.trim().toLowerCase();
    final normalizedName = fullName.trim().toLowerCase();

    final usersCollection = FirebaseFirestore.instance.collection('users');

    // Query for records where mobileNumber matches
    final querySnapshot = await usersCollection
        .doc(targetId)
        .collection(collectionName)
        .where('mobileNumber', isEqualTo: normalizedMobile)
        .get();

    // Check if any of the matched records also have the same full name
    for (final doc in querySnapshot.docs) {
      final existingName =
          (doc.data()['fullName'] as String?)?.trim().toLowerCase() ?? '';
      if (existingName == normalizedName) {
        return true; // Duplicate found
      }
    }

    return false; // No duplicate
  }
}
