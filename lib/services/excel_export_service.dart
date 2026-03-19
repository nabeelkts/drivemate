import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:drivemate/services/excel_import_service.dart';
import 'package:drivemate/controller/workspace_controller.dart';

/// Export filter options
enum ExportFilter {
  all,
  pendingDues,
  testPassed,
  testFailed,
  byDateRange,
}

/// Extension to get display name for filter
extension ExportFilterExtension on ExportFilter {
  String get displayName {
    switch (this) {
      case ExportFilter.all:
        return 'All Records';
      case ExportFilter.pendingDues:
        return 'With Pending Dues';
      case ExportFilter.testPassed:
        return 'Test Passed';
      case ExportFilter.testFailed:
        return 'Test Failed';
      case ExportFilter.byDateRange:
        return 'By Date Range';
    }
  }
}

/// Service class for exporting data to Excel files
class ExcelExportService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID
  String get currentUserId {
    final user = _auth.currentUser;
    return user?.uid ?? '';
  }

  /// Get the target ID (workspace or user) using WorkspaceController
  String getTargetId() {
    try {
      final workspaceController = Get.find<WorkspaceController>();
      final targetId = workspaceController.targetId;
      if (kDebugMode) {
        print('WorkspaceController targetId: $targetId');
      }
      return targetId;
    } catch (e) {
      if (kDebugMode) {
        print('WorkspaceController not found, error: $e');
      }
      return '';
    }
  }

  /// Export data to Excel file
  Future<File> exportToExcel({
    required ImportType exportType,
    required ExportFilter filter,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Fetch data from Firestore
    final data = await _fetchData(exportType, filter, startDate, endDate);

    // Create Excel file
    final excel = Excel.createExcel();

    // Get all existing sheets and remove them
    final existingSheets = excel.tables.keys.toList();
    for (final sheetName in existingSheets) {
      excel.delete(sheetName);
    }

    // Create new sheet with the export type name (this will create a new Sheet1 first, then we rename)
    var sheet = excel['Sheet1'];

    // Rename the sheet to our export type name
    excel.rename('Sheet1', exportType.displayName);
    sheet = excel[exportType.displayName];

    // Add headers
    _addHeaders(sheet, exportType);

    // Add data rows
    _addDataRows(sheet, data, exportType);

    if (kDebugMode) {
      print('Excel sheet created with ${data.length} rows');
      print('Sheet name: ${exportType.displayName}');
      print('Headers: ${_getExportHeaders(exportType)}');
    }

    // Save file
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${exportType.displayName}_$timestamp.xlsx';
    final file = File('${directory.path}/$fileName');

    final bytes = excel.encode();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
    }

    return file;
  }

  /// Fetch data from Firestore based on filter
  Future<List<Map<String, dynamic>>> _fetchData(
    ImportType exportType,
    ExportFilter filter,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    final targetId = getTargetId();

    if (targetId.isEmpty) {
      throw Exception(
          'No target ID found. Please login or select a workspace.');
    }

    final collectionName = exportType.collectionName;

    if (kDebugMode) {
      print('=== Export Debug ===');
      print('targetId: $targetId');
      print('collection: $collectionName');
    }

    // Build the correct Firestore path: users/{targetId}/{collectionName}
    final CollectionReference<Map<String, dynamic>> collectionRef =
        FirebaseFirestore.instance
            .collection('users')
            .doc(targetId)
            .collection(collectionName);

    if (kDebugMode) {
      print('Path: users/$targetId/$collectionName');
    }

    final snapshot = await collectionRef.get();

    if (kDebugMode) {
      print('Found ${snapshot.docs.length} documents in $collectionName');
    }

    var documents = snapshot.docs.map((doc) => doc.data()).toList();

    // Apply filters
    documents = _applyFilter(documents, filter, startDate, endDate);

    if (kDebugMode) {
      print('After filtering: ${documents.length} documents');
    }

    return documents;
  }

  /// Apply filter to documents
  List<Map<String, dynamic>> _applyFilter(
    List<Map<String, dynamic>> documents,
    ExportFilter filter,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    switch (filter) {
      case ExportFilter.all:
        return documents;
      case ExportFilter.pendingDues:
        return documents.where((doc) {
          final balance =
              double.tryParse(doc['balanceAmount']?.toString() ?? '0') ?? 0;
          return balance > 0;
        }).toList();
      case ExportFilter.testPassed:
        return documents.where((doc) {
          final status = doc['testStatus']?.toString().toLowerCase() ?? '';
          return status == 'passed';
        }).toList();
      case ExportFilter.testFailed:
        return documents.where((doc) {
          final status = doc['testStatus']?.toString().toLowerCase() ?? '';
          return status == 'failed';
        }).toList();
      case ExportFilter.byDateRange:
        if (startDate == null || endDate == null) return documents;
        return documents.where((doc) {
          final regDate = doc['registrationDate']?.toString() ?? '';
          if (regDate.isEmpty) return false;
          try {
            final docDate = DateTime.parse(regDate);
            return docDate
                    .isAfter(startDate.subtract(const Duration(days: 1))) &&
                docDate.isBefore(endDate.add(const Duration(days: 1)));
          } catch (e) {
            return false;
          }
        }).toList();
    }
  }

  /// Add headers to sheet
  void _addHeaders(Sheet sheet, ImportType exportType) {
    final headers = _getExportHeaders(exportType);
    for (int i = 0; i < headers.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .value = TextCellValue(headers[i]);
    }
  }

  /// Add data rows to sheet
  void _addDataRows(
    Sheet sheet,
    List<Map<String, dynamic>> data,
    ImportType exportType,
  ) {
    final headers = _getExportHeaders(exportType);

    if (kDebugMode) {
      print('Adding ${data.length} rows to Excel');
      if (data.isNotEmpty) {
        print('First document keys: ${data[0].keys.toList()}');
      }
    }

    for (int rowIndex = 0; rowIndex < data.length; rowIndex++) {
      final doc = data[rowIndex];
      for (int colIndex = 0; colIndex < headers.length; colIndex++) {
        final header = headers[colIndex];
        final value = doc[header]?.toString() ?? '';

        if (kDebugMode && rowIndex == 0) {
          print('Column $header = "$value"');
        }

        sheet
            .cell(CellIndex.indexByColumnRow(
                columnIndex: colIndex, rowIndex: rowIndex + 1))
            .value = TextCellValue(value);
      }
    }

    if (kDebugMode) {
      print('Finished adding rows');
    }
  }

  /// Get export headers based on import type
  List<String> _getExportHeaders(ImportType exportType) {
    switch (exportType) {
      case ImportType.student:
        return [
          'fullName',
          'guardianName',
          'dob',
          'mobileNumber',
          'emergencyNumber',
          'bloodGroup',
          'house',
          'place',
          'post',
          'district',
          'pin',
          'cov',
          'totalAmount',
          'advanceAmount',
          'balanceAmount',
          'paymentMode',
          'registrationDate',
        ];
      case ImportType.licenseOnly:
        return [
          'fullName',
          'guardianName',
          'dob',
          'mobileNumber',
          'bloodGroup',
          'house',
          'place',
          'post',
          'district',
          'pin',
          'cov',
          'totalAmount',
          'advanceAmount',
          'balanceAmount',
          'paymentMode',
          'registrationDate',
        ];
      case ImportType.endorsement:
        return [
          'fullName',
          'guardianName',
          'dob',
          'mobileNumber',
          'license',
          'cov',
          'totalAmount',
          'advanceAmount',
          'balanceAmount',
          'paymentMode',
          'registrationDate',
        ];
      case ImportType.dlService:
        return [
          'fullName',
          'guardianName',
          'dob',
          'mobileNumber',
          'license',
          'serviceType',
          'totalAmount',
          'advanceAmount',
          'balanceAmount',
          'paymentMode',
          'registrationDate',
        ];
      case ImportType.vehicleDetails:
        return [
          'fullName',
          'mobileNumber',
          'house',
          'place',
          'post',
          'district',
          'pin',
          'vehicleNumber',
          'vehicleModel',
          'chassisNumber',
          'engineNumber',
          'totalAmount',
          'advanceAmount',
          'balanceAmount',
          'paymentMode',
          'registrationDate',
        ];
      case ImportType.rcDetails:
        return [
          'fullName',
          'mobileNumber',
          'vehicleNumber',
          'chassisNumber',
          'engineNumber',
          'totalAmount',
          'advanceAmount',
          'balanceAmount',
          'paymentMode',
          'registrationDate',
        ];
    }
  }

  /// Get export file name
  String getExportFileName(ImportType exportType) {
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    return '${exportType.displayName}_$timestamp.xlsx';
  }
}
