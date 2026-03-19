import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:drivemate/services/excel_import_service.dart';

/// Service for generating Excel template files
class TemplateService {
  /// Generate and save an Excel template file for the given import type
  /// Returns the file path
  static Future<String> generateTemplate(ImportType importType) async {
    final excel = Excel.createExcel();

    // Remove default sheet
    excel.delete('Sheet1');

    // Create new sheet
    final sheet = excel[importType.displayName];

    // Add headers
    final headers = _getTemplateHeaders(importType);
    for (int i = 0; i < headers.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .value = TextCellValue(headers[i]);
    }

    // Add sample data (1 example row)
    final sampleData = _getSampleData(importType);
    for (int i = 0; i < sampleData.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1))
          .value = TextCellValue(sampleData[i]);
    }

    // Auto-fit columns by setting a basic width
    for (int i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 15);
    }

    // Save file
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        '${importType.displayName.replaceAll(' ', '_')}_Template.xlsx';
    final filePath = '${directory.path}/$fileName';

    final file = File(filePath);
    final bytes = excel.encode();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
    }

    return filePath;
  }

  /// Get template headers for the import type
  static List<String> _getTemplateHeaders(ImportType importType) {
    switch (importType) {
      case ImportType.student:
        return [
          'Full Name',
          'Guardian Name',
          'Date of Birth',
          'Mobile Number',
          'Emergency Number',
          'Blood Group',
          'House Name',
          'Place',
          'Post',
          'District',
          'PIN',
          'COV',
          'Total Amount',
          'Advance Amount',
          'Payment Mode',
        ];
      case ImportType.licenseOnly:
        return [
          'Full Name',
          'Guardian Name',
          'Date of Birth',
          'Mobile Number',
          'Blood Group',
          'House Name',
          'Place',
          'Post',
          'District',
          'PIN',
          'COV',
          'Total Amount',
          'Advance Amount',
          'Payment Mode',
        ];
      case ImportType.endorsement:
        return [
          'Full Name',
          'Guardian Name',
          'Date of Birth',
          'Mobile Number',
          'License Number',
          'COV',
          'Total Amount',
          'Advance Amount',
          'Payment Mode',
        ];
      case ImportType.dlService:
        return [
          'Full Name',
          'Guardian Name',
          'Date of Birth',
          'Mobile Number',
          'License Number',
          'Service Type',
          'Total Amount',
          'Advance Amount',
          'Payment Mode',
        ];
      case ImportType.vehicleDetails:
        return [
          'Full Name',
          'Mobile Number',
          'House Name',
          'Place',
          'Post',
          'District',
          'PIN',
          'Vehicle Number',
          'Vehicle Model',
          'Chassis Number',
          'Engine Number',
          'Total Amount',
          'Advance Amount',
          'Payment Mode',
        ];
      case ImportType.rcDetails:
        return [
          'Full Name',
          'Mobile Number',
          'Vehicle Number',
          'Chassis Number',
          'Engine Number',
          'Total Amount',
          'Advance Amount',
          'Payment Mode',
        ];
    }
  }

  /// Get sample data for the import type
  static List<String> _getSampleData(ImportType importType) {
    switch (importType) {
      case ImportType.student:
        return [
          'John Doe',
          'James Doe',
          '01-01-2000',
          '9876543210',
          '9876543211',
          'O+ve',
          '123 Main Street',
          'Kochi',
          '682001',
          'Ernakulam',
          '682001',
          'MCWG',
          '5000',
          '2000',
          'Cash',
        ];
      case ImportType.licenseOnly:
        return [
          'Jane Smith',
          'Robert Smith',
          '15-06-1995',
          '9876543212',
          'B+ve',
          '456 Oak Avenue',
          'Thiruvananthapuram',
          '695001',
          'Thiruvananthapuram',
          '695001',
          'LMV',
          '3500',
          '1000',
          'Online',
        ];
      case ImportType.endorsement:
        return [
          'Mike Johnson',
          'David Johnson',
          '20-03-1990',
          '9876543213',
          'KL01 2021 1234567890',
          'MCWG',
          '4000',
          '1500',
          'Cash',
        ];
      case ImportType.dlService:
        return [
          'Sarah Williams',
          'Thomas Williams',
          '10-10-1988',
          '9876543214',
          'KL01 2020 9876543210',
          'License Renewal',
          '2500',
          '500',
          'Online',
        ];
      case ImportType.vehicleDetails:
        return [
          'Car Owner',
          '9876543215',
          '789 Pine Road',
          'Kollam',
          '691001',
          'Kollam',
          '691001',
          'KL01 AB 1234',
          'Maruti Swift',
          'MA3E123456789012',
          'MA3E123456789012',
          '50000',
          '10000',
          'Cash',
        ];
      case ImportType.rcDetails:
        return [
          'Vehicle Owner',
          '9876543216',
          'KL01 CD 5678',
          'MA3E123456789012',
          'MA3E123456789012',
          '3000',
          '1000',
          'Cash',
        ];
    }
  }

  /// Get directory path for templates
  static Future<String> getTemplateDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final templateDir = Directory('${directory.path}/templates');
    if (!await templateDir.exists()) {
      await templateDir.create(recursive: true);
    }
    return templateDir.path;
  }
}
