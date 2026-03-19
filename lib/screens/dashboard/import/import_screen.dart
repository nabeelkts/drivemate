import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:drivemate/controller/workspace_controller.dart';
import 'package:drivemate/services/excel_import_service.dart';
import 'package:drivemate/services/bulk_import_service.dart';
import 'package:drivemate/services/template_service.dart';
import 'package:drivemate/screens/widget/custom_back_button.dart';
import 'package:drivemate/constants/colors.dart';

/// Screen for importing records from Excel file
class ImportScreen extends StatefulWidget {
  final ImportType importType;

  const ImportScreen({
    super.key,
    required this.importType,
  });

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  bool _isLoading = false;
  String? _selectedFileName;
  File? _selectedFile;
  List<int>? _selectedFileBytes; // For web platform

  final BulkImportService _bulkImportService = BulkImportService();
  final ExcelImportService _excelService = ExcelImportService();

  /// Check if we're running on web
  bool get _isWeb => kIsWeb;

  /// Check if a file is selected (works for both web and native)
  bool get _hasFile =>
      _isWeb ? _selectedFileBytes != null : _selectedFile != null;

  @override
  void initState() {
    super.initState();
    // Auto-open file picker on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pickFile();
    });
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final platformFile = result.files.first;

        if (_isWeb) {
          // Web platform: use bytes instead of path
          if (platformFile.bytes != null) {
            setState(() {
              _selectedFileBytes = platformFile.bytes;
              _selectedFileName = platformFile.name;
            });
          } else {
            Fluttertoast.showToast(
              msg: 'Error: Could not read file bytes',
              backgroundColor: Colors.red,
            );
          }
        } else {
          // Native platform: use file path
          if (platformFile.path != null) {
            final file = File(platformFile.path!);
            setState(() {
              _selectedFile = file;
              _selectedFileName = platformFile.name;
            });
          }
        }
      } else {
        // User cancelled - go back
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error selecting file: $e',
        backgroundColor: Colors.red,
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _processImport() async {
    if (!_hasFile) {
      Fluttertoast.showToast(
        msg: 'Please select a file first',
        backgroundColor: Colors.red,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Parse Excel file - handle both web (bytes) and native (file)
      final parsedData = _isWeb
          ? await _excelService.parseExcelFileFromBytes(
              _selectedFileBytes!,
              widget.importType,
            )
          : await _excelService.parseExcelFile(
              _selectedFile!,
              widget.importType,
            );

      if (parsedData.isEmpty) {
        Fluttertoast.showToast(
          msg: 'No data found in Excel file',
          backgroundColor: Colors.orange,
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Get target ID
      final targetId = await _bulkImportService.getTargetId();

      if (kDebugMode) {
        print(
            'Importing ${parsedData.length} records as ${widget.importType.displayName}');
      }

      // Import based on type
      ImportResult result;

      switch (widget.importType) {
        case ImportType.student:
          result =
              await _bulkImportService.importStudents(parsedData, targetId);
          break;
        case ImportType.licenseOnly:
          result =
              await _bulkImportService.importLicenseOnly(parsedData, targetId);
          break;
        case ImportType.endorsement:
          result =
              await _bulkImportService.importEndorsement(parsedData, targetId);
          break;
        case ImportType.dlService:
          result =
              await _bulkImportService.importDLService(parsedData, targetId);
          break;
        case ImportType.vehicleDetails:
          result = await _bulkImportService.importVehicleDetails(
              parsedData, targetId);
          break;
        case ImportType.rcDetails:
          result =
              await _bulkImportService.importRCDetails(parsedData, targetId);
          break;
      }

      // Navigate to results screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ImportResultScreen(
              result: result,
              importType: widget.importType,
            ),
          ),
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error processing file: $e',
        backgroundColor: Colors.red,
      );
      if (kDebugMode) {
        print('Import error: $e');
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadTemplate() async {
    try {
      setState(() => _isLoading = true);

      final filePath =
          await TemplateService.generateTemplate(widget.importType);

      Fluttertoast.showToast(
        msg: 'Template saved to: $filePath',
        backgroundColor: Colors.green,
        toastLength: Toast.LENGTH_LONG,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error generating template: $e',
        backgroundColor: Colors.red,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Import ${widget.importType.displayName}'),
        leading: const CustomBackButton(),
        actions: [
          if (_selectedFile != null && !_isLoading)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _processImport,
              tooltip: 'Start Import',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing import...'),
                ],
              ),
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.upload_file,
                      size: 80,
                      color: kPrimaryColor,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _selectedFileName ?? 'No file selected',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Selected: ${widget.importType.displayName}',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _pickFile,
                          icon: const Icon(Icons.folder_open),
                          label: const Text('Change File'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _hasFile ? _processImport : null,
                          icon: const Icon(Icons.upload),
                          label: const Text('Import'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),
                    // Show expected columns
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Expected Columns:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: widget.importType.requiredColumns
                                  .map((col) => Chip(
                                        label: Text(col),
                                        backgroundColor: Colors.grey[200],
                                      ))
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Screen showing import results
class ImportResultScreen extends StatelessWidget {
  final ImportResult result;
  final ImportType importType;

  const ImportResultScreen({
    super.key,
    required this.result,
    required this.importType,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Results'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Summary Card
            Card(
              color: result.isFullySuccessful
                  ? Colors.green[50]
                  : Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(
                      result.isFullySuccessful
                          ? Icons.check_circle
                          : Icons.warning_amber,
                      size: 60,
                      color: result.isFullySuccessful
                          ? Colors.green
                          : Colors.orange,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      result.isFullySuccessful
                          ? 'Import Successful!'
                          : 'Import Completed with Errors',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatCard(
                          'Total',
                          result.totalRecords.toString(),
                          Colors.blue,
                        ),
                        _buildStatCard(
                          'Success',
                          result.successCount.toString(),
                          Colors.green,
                        ),
                        _buildStatCard(
                          'Duplicates',
                          result.duplicateCount.toString(),
                          result.duplicateCount > 0
                              ? Colors.orange
                              : Colors.grey,
                        ),
                        _buildStatCard(
                          'Failed',
                          result.failureCount.toString(),
                          result.failureCount > 0 ? Colors.red : Colors.grey,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Error Details (if any)
            if (result.hasFailures) ...[
              const Text(
                'Error Details:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...result.errors.map((error) => Card(
                    color: Colors.red[50],
                    child: ListTile(
                      leading:
                          const Icon(Icons.error_outline, color: Colors.red),
                      title: Text('Row ${error.rowNumber}'),
                      subtitle: Text(error.message),
                      trailing: error.data != null
                          ? IconButton(
                              icon: const Icon(Icons.visibility),
                              onPressed: () {
                                _showErrorDataDialog(context, error);
                              },
                            )
                          : null,
                    ),
                  )),
            ],

            const SizedBox(height: 24),

            // Done Button
            ElevatedButton(
              onPressed: () {
                // Go back to the list
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Done',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  void _showErrorDataDialog(BuildContext context, ImportError error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Row ${error.rowNumber} Data'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: error.data?.entries
                    .map((e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text('${e.key}: ${e.value}'),
                        ))
                    .toList() ??
                [],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
