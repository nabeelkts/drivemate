import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';

/// Enum representing different import types
enum ImportType {
  student,
  licenseOnly,
  endorsement,
  dlService,
  vehicleDetails,
  rcDetails,
}

/// Extension to get display name and collection path for each type
extension ImportTypeExtension on ImportType {
  String get displayName {
    switch (this) {
      case ImportType.student:
        return 'Student';
      case ImportType.licenseOnly:
        return 'License Only';
      case ImportType.endorsement:
        return 'Endorsement';
      case ImportType.dlService:
        return 'DL Service';
      case ImportType.vehicleDetails:
        return 'Vehicle Details';
      case ImportType.rcDetails:
        return 'RC Details';
    }
  }

  String get collectionName {
    switch (this) {
      case ImportType.student:
        return 'students';
      case ImportType.licenseOnly:
        return 'licenseonly';
      case ImportType.endorsement:
        return 'endorsement';
      case ImportType.dlService:
        return 'dl_services';
      case ImportType.vehicleDetails:
        return 'vehicleDetails';
      case ImportType.rcDetails:
        return 'rcdetails';
    }
  }

  /// Get the expected column mappings for this import type
  Map<String, String> get columnMapping {
    switch (this) {
      case ImportType.student:
        return _studentColumnMapping;
      case ImportType.licenseOnly:
        return _licenseOnlyColumnMapping;
      case ImportType.endorsement:
        return _endorsementColumnMapping;
      case ImportType.dlService:
        return _dlServiceColumnMapping;
      case ImportType.vehicleDetails:
        return _vehicleColumnMapping;
      case ImportType.rcDetails:
        return _rcColumnMapping;
    }
  }

  /// Required columns for validation
  List<String> get requiredColumns {
    switch (this) {
      case ImportType.student:
        return ['fullName', 'mobileNumber', 'cov'];
      case ImportType.licenseOnly:
        return ['fullName', 'cov'];
      case ImportType.endorsement:
        return ['fullName', 'cov', 'license'];
      case ImportType.dlService:
        return ['fullName'];
      case ImportType.vehicleDetails:
        return ['fullName', 'vehicleNumber'];
      case ImportType.rcDetails:
        return ['fullName', 'vehicleNumber'];
    }
  }
}

/// Column mappings for each import type
/// Maps Excel column headers to Firestore field names
/// Supports both display names (Full Name) and field names (fullName)
const Map<String, String> _studentColumnMapping = {
  // Display names
  'full name': 'fullName',
  'guardian name': 'guardianName',
  'date of birth': 'dob',
  'mobile number': 'mobileNumber',
  'emergency number': 'emergencyNumber',
  'emergency contact': 'emergencyNumber',
  'blood group': 'bloodGroup',
  'house name': 'house',
  'address': 'house',
  'place': 'place',
  'city': 'place',
  'post': 'post',
  'post office': 'post',
  'district': 'district',
  'pin': 'pin',
  'pincode': 'pin',
  'cov': 'cov',
  'class of vehicle': 'cov',
  'course': 'cov',
  'service': 'cov',
  'total amount': 'totalAmount',
  'fees': 'totalAmount',
  'advance amount': 'advanceAmount',
  'payment mode': 'paymentMode',
  'payment': 'paymentMode',
  // Field names (from export)
  'fullname': 'fullName',
  'name': 'fullName',
  'guardian': 'guardianName',
  'guardianname': 'guardianName',
  'fathername': 'guardianName',
  'father name': 'guardianName',
  'dob': 'dob',
  'birthdate': 'dob',
  'birth date': 'dob',
  'mobile': 'mobileNumber',
  'mobilenumber': 'mobileNumber',
  'phone': 'mobileNumber',
  'contact': 'mobileNumber',
  'emergencynumber': 'emergencyNumber',
  'emergencycontact': 'emergencyNumber',
  'bloodgroup': 'bloodGroup',
  'blood': 'bloodGroup',
  'house': 'house',
  'total': 'totalAmount',
  'advance': 'advanceAmount',
  'paymentmode': 'paymentMode',
  'mode': 'paymentMode',
  'balanceamount': 'balanceAmount',
  'balance amount': 'balanceAmount',
  'balance': 'balanceAmount',
  'registrationdate': 'registrationDate',
  'registration date': 'registrationDate',
};

const Map<String, String> _licenseOnlyColumnMapping = {
  // Display names
  'full name': 'fullName',
  'guardian name': 'guardianName',
  'date of birth': 'dob',
  'mobile number': 'mobileNumber',
  'blood group': 'bloodGroup',
  'house name': 'house',
  'address': 'house',
  'place': 'place',
  'city': 'place',
  'post': 'post',
  'district': 'district',
  'pin': 'pin',
  'pincode': 'pin',
  'cov': 'cov',
  'class of vehicle': 'cov',
  'license type': 'cov',
  'total amount': 'totalAmount',
  'fees': 'totalAmount',
  'advance amount': 'advanceAmount',
  'payment mode': 'paymentMode',
  'payment': 'paymentMode',
  // Field names (from export)
  'fullname': 'fullName',
  'name': 'fullName',
  'guardian': 'guardianName',
  'guardianname': 'guardianName',
  'fathername': 'guardianName',
  'father name': 'guardianName',
  'dob': 'dob',
  'birthdate': 'dob',
  'birth date': 'dob',
  'mobile': 'mobileNumber',
  'mobilenumber': 'mobileNumber',
  'phone': 'mobileNumber',
  'contact': 'mobileNumber',
  'bloodgroup': 'bloodGroup',
  'blood': 'bloodGroup',
  'house': 'house',
  'total': 'totalAmount',
  'advance': 'advanceAmount',
  'paymentmode': 'paymentMode',
  'mode': 'paymentMode',
  'balanceamount': 'balanceAmount',
  'balance amount': 'balanceAmount',
  'balance': 'balanceAmount',
  'registrationdate': 'registrationDate',
  'registration date': 'registrationDate',
};

const Map<String, String> _endorsementColumnMapping = {
  // Display names
  'full name': 'fullName',
  'guardian name': 'guardianName',
  'date of birth': 'dob',
  'mobile number': 'mobileNumber',
  'license number': 'license',
  'cov': 'cov',
  'class of vehicle': 'cov',
  'endorsement type': 'cov',
  'total amount': 'totalAmount',
  'fees': 'totalAmount',
  'advance amount': 'advanceAmount',
  'payment mode': 'paymentMode',
  'payment': 'paymentMode',
  // Field names (from export)
  'fullname': 'fullName',
  'name': 'fullName',
  'guardian': 'guardianName',
  'guardianname': 'guardianName',
  'dob': 'dob',
  'birthdate': 'dob',
  'birth date': 'dob',
  'mobile': 'mobileNumber',
  'mobilenumber': 'mobileNumber',
  'phone': 'mobileNumber',
  'contact': 'mobileNumber',
  'license': 'license',
  'licensenumber': 'license',
  'dl number': 'license',
  'dlno': 'license',
  'existing license': 'license',
  'total': 'totalAmount',
  'advance': 'advanceAmount',
  'paymentmode': 'paymentMode',
  'mode': 'paymentMode',
  'balanceamount': 'balanceAmount',
  'balance amount': 'balanceAmount',
  'balance': 'balanceAmount',
  'registrationdate': 'registrationDate',
  'registration date': 'registrationDate',
};

const Map<String, String> _dlServiceColumnMapping = {
  // Display names
  'full name': 'fullName',
  'guardian name': 'guardianName',
  'date of birth': 'dob',
  'mobile number': 'mobileNumber',
  'license number': 'license',
  'service type': 'serviceType',
  'service': 'serviceType',
  'total amount': 'totalAmount',
  'fees': 'totalAmount',
  'advance amount': 'advanceAmount',
  'payment mode': 'paymentMode',
  'payment': 'paymentMode',
  // Field names (from export)
  'fullname': 'fullName',
  'name': 'fullName',
  'guardian': 'guardianName',
  'guardianname': 'guardianName',
  'dob': 'dob',
  'birthdate': 'dob',
  'birth date': 'dob',
  'mobile': 'mobileNumber',
  'mobilenumber': 'mobileNumber',
  'phone': 'mobileNumber',
  'contact': 'mobileNumber',
  'license': 'license',
  'licensenumber': 'license',
  'dl number': 'license',
  'servicetype': 'serviceType',
  'total': 'totalAmount',
  'advance': 'advanceAmount',
  'paymentmode': 'paymentMode',
  'mode': 'paymentMode',
  'balanceamount': 'balanceAmount',
  'balance amount': 'balanceAmount',
  'balance': 'balanceAmount',
  'registrationdate': 'registrationDate',
  'registration date': 'registrationDate',
};

const Map<String, String> _vehicleColumnMapping = {
  // Display names
  'full name': 'fullName',
  'mobile number': 'mobileNumber',
  'house name': 'house',
  'address': 'house',
  'place': 'place',
  'city': 'place',
  'post': 'post',
  'district': 'district',
  'pin': 'pin',
  'pincode': 'pin',
  'vehicle number': 'vehicleNumber',
  'vehicleno': 'vehicleNumber',
  'vehicle': 'vehicleNumber',
  'registration number': 'vehicleNumber',
  'vehicle model': 'vehicleModel',
  'model': 'vehicleModel',
  'chassis number': 'chassisNumber',
  'chassis': 'chassisNumber',
  'engine number': 'engineNumber',
  'engine': 'engineNumber',
  'total amount': 'totalAmount',
  'fees': 'totalAmount',
  'advance amount': 'advanceAmount',
  'payment mode': 'paymentMode',
  'payment': 'paymentMode',
  // Field names (from export)
  'fullname': 'fullName',
  'name': 'fullName',
  'mobile': 'mobileNumber',
  'mobilenumber': 'mobileNumber',
  'phone': 'mobileNumber',
  'contact': 'mobileNumber',
  'house': 'house',
  'vehiclenumber': 'vehicleNumber',
  'vehiclemodel': 'vehicleModel',
  'chassisnumber': 'chassisNumber',
  'enginenumber': 'engineNumber',
  'total': 'totalAmount',
  'advance': 'advanceAmount',
  'paymentmode': 'paymentMode',
  'mode': 'paymentMode',
  'balanceamount': 'balanceAmount',
  'balance amount': 'balanceAmount',
  'balance': 'balanceAmount',
  'registrationdate': 'registrationDate',
  'registration date': 'registrationDate',
};

const Map<String, String> _rcColumnMapping = {
  // Display names
  'full name': 'fullName',
  'mobile number': 'mobileNumber',
  'vehicle number': 'vehicleNumber',
  'vehicleno': 'vehicleNumber',
  'vehicle': 'vehicleNumber',
  'registration number': 'vehicleNumber',
  'chassis number': 'chassisNumber',
  'chassis': 'chassisNumber',
  'engine number': 'engineNumber',
  'engine': 'engineNumber',
  'total amount': 'totalAmount',
  'fees': 'totalAmount',
  'advance amount': 'advanceAmount',
  'payment mode': 'paymentMode',
  'payment': 'paymentMode',
  // Field names (from export)
  'fullname': 'fullName',
  'name': 'fullName',
  'mobile': 'mobileNumber',
  'mobilenumber': 'mobileNumber',
  'phone': 'mobileNumber',
  'contact': 'mobileNumber',
  'vehiclenumber': 'vehicleNumber',
  'vehiclemodel': 'vehicleModel',
  'chassisnumber': 'chassisNumber',
  'enginenumber': 'engineNumber',
  'total': 'totalAmount',
  'advance': 'advanceAmount',
  'paymentmode': 'paymentMode',
  'mode': 'paymentMode',
  'balanceamount': 'balanceAmount',
  'balance amount': 'balanceAmount',
  'balance': 'balanceAmount',
  'registrationdate': 'registrationDate',
  'registration date': 'registrationDate',
};

/// Service class for parsing Excel files
class ExcelImportService {
  /// Parse an Excel file from bytes (for web platform support)
  Future<List<Map<String, dynamic>>> parseExcelFileFromBytes(
    List<int> bytes,
    ImportType importType,
  ) async {
    try {
      final excel = Excel.decodeBytes(bytes as List<int>);

      final List<Map<String, dynamic>> results = [];

      // Get the first sheet
      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName];

      if (sheet == null) {
        throw Exception('No sheets found in Excel file');
      }

      // Get headers from first row
      final headers = <String>[];
      final firstRow = sheet.rows.first;

      for (final cell in firstRow) {
        final value = cell?.value?.toString().trim().toLowerCase() ?? '';
        headers.add(value);
      }

      if (kDebugMode) {
        print('Excel headers: $headers');
      }

      // Process remaining rows
      for (int i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        final Map<String, dynamic> rowData = {};

        for (int j = 0; j < headers.length && j < row.length; j++) {
          final header = headers[j];
          final cell = row[j];

          if (header.isEmpty) continue;

          // Get the mapped field name
          final mappedField = _getMappedField(header, importType);
          if (mappedField == null) continue;

          // Get cell value
          dynamic value;
          if (cell?.value != null) {
            value = _extractCellValue(cell!.value);
          }

          if (value != null && value.toString().isNotEmpty) {
            rowData[mappedField] = value;
          }
        }

        // Only add non-empty rows
        if (rowData.isNotEmpty) {
          results.add(rowData);
        }
      }

      if (kDebugMode) {
        print('Parsed ${results.length} rows from Excel (from bytes)');
      }

      return results;
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing Excel file from bytes: $e');
      }
      rethrow;
    }
  }

  /// Parse an Excel file and return list of maps
  Future<List<Map<String, dynamic>>> parseExcelFile(
    File file,
    ImportType importType,
  ) async {
    try {
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      final List<Map<String, dynamic>> results = [];

      // Get the first sheet
      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName];

      if (sheet == null) {
        throw Exception('No sheets found in Excel file');
      }

      // Get headers from first row
      final headers = <String>[];
      final firstRow = sheet.rows.first;

      for (final cell in firstRow) {
        final value = cell?.value?.toString().trim().toLowerCase() ?? '';
        headers.add(value);
      }

      if (kDebugMode) {
        print('Excel headers: $headers');
      }

      // Process remaining rows
      for (int i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        final Map<String, dynamic> rowData = {};

        for (int j = 0; j < headers.length && j < row.length; j++) {
          final header = headers[j];
          final cell = row[j];

          if (header.isEmpty) continue;

          // Get the mapped field name
          final mappedField = _getMappedField(header, importType);
          if (mappedField == null) continue;

          // Get cell value
          dynamic value;
          if (cell?.value != null) {
            value = _extractCellValue(cell!.value);
          }

          if (value != null && value.toString().isNotEmpty) {
            rowData[mappedField] = value;
          }
        }

        // Only add non-empty rows
        if (rowData.isNotEmpty) {
          results.add(rowData);
        }
      }

      if (kDebugMode) {
        print('Parsed ${results.length} rows from Excel');
      }

      return results;
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing Excel file: $e');
      }
      rethrow;
    }
  }

  /// Extract value from Excel cell
  dynamic _extractCellValue(dynamic cellValue) {
    if (cellValue == null) return null;

    if (cellValue is TextCellValue) {
      return cellValue.value.toString().trim();
    } else if (cellValue is IntCellValue) {
      return cellValue.value.toString();
    } else if (cellValue is DoubleCellValue) {
      return cellValue.value.toString();
    } else if (cellValue is DateCellValue) {
      return '${cellValue.day.toString().padLeft(2, '0')}-${cellValue.month.toString().padLeft(2, '0')}-${cellValue.year}';
    } else if (cellValue is TimeCellValue) {
      return '${cellValue.hour}:${cellValue.minute}';
    } else if (cellValue is BoolCellValue) {
      return cellValue.value;
    }

    return cellValue.toString().trim();
  }

  /// Get the mapped field name from header
  String? _getMappedField(String header, ImportType importType) {
    final mapping = importType.columnMapping;
    return mapping[header.toLowerCase()];
  }

  /// Validate a single row of data
  List<String> validateRow(Map<String, dynamic> row, ImportType importType) {
    final List<String> errors = [];
    final requiredColumns = importType.requiredColumns;

    for (final required in requiredColumns) {
      if (!row.containsKey(required) ||
          row[required] == null ||
          row[required].toString().isEmpty) {
        errors.add('Missing required field: $required');
      }
    }

    // Validate mobile number format if present
    if (row.containsKey('mobileNumber') && row['mobileNumber'] != null) {
      final mobile = row['mobileNumber'].toString();
      if (mobile.isNotEmpty && !_isValidMobile(mobile)) {
        errors.add('Invalid mobile number: $mobile');
      }
    }

    // Validate amount fields
    if (row.containsKey('totalAmount') && row['totalAmount'] != null) {
      if (double.tryParse(row['totalAmount'].toString()) == null) {
        errors.add('Invalid total amount: ${row['totalAmount']}');
      }
    }

    if (row.containsKey('advanceAmount') && row['advanceAmount'] != null) {
      if (double.tryParse(row['advanceAmount'].toString()) == null) {
        errors.add('Invalid advance amount: ${row['advanceAmount']}');
      }
    }

    return errors;
  }

  /// Check if mobile number is valid (basic validation)
  bool _isValidMobile(String mobile) {
    // Remove any spaces or special characters
    final cleaned = mobile.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    // Check if it's 10-15 digits
    return RegExp(r'^\d{10,15}$').hasMatch(cleaned);
  }

  /// Get sample template data for an import type
  List<String> getTemplateHeaders(ImportType importType) {
    return importType.requiredColumns;
  }
}
