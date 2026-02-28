import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/services/additional_info_service.dart';
import 'package:mds/utils/date_input_formatter.dart';

enum AdditionalInfoType {
  student, // Student, License Only, Endorsement
  dlService, // DL Service
  rcService, // RC Service
}

class AdditionalInfoSheet extends StatefulWidget {
  final AdditionalInfoType type;
  final String collection;
  final String documentId;
  final Map<String, dynamic>? existingData;

  const AdditionalInfoSheet({
    super.key,
    required this.type,
    required this.collection,
    required this.documentId,
    this.existingData,
  });

  @override
  State<AdditionalInfoSheet> createState() => _AdditionalInfoSheetState();
}

class _AdditionalInfoSheetState extends State<AdditionalInfoSheet> {
  final _service = AdditionalInfoService();
  bool _isLoading = false;

  // Controllers for Student Type
  final _applicationNumberController = TextEditingController();
  final _learnersLicenseNumberController = TextEditingController();
  final _learnersLicenseExpiryController = TextEditingController();
  final _drivingLicenseNumberController = TextEditingController();
  final _drivingLicenseExpiryController = TextEditingController();

  // Controllers for DL Service
  final _licenseNumberController = TextEditingController();
  final _licenseExpiryController = TextEditingController();

  // Controllers for RC Service
  final _registrationFitnessExpiryController = TextEditingController();
  final _insuranceExpiryController = TextEditingController();
  final _taxExpiryController = TextEditingController();
  final _pollutionExpiryController = TextEditingController();
  final _permitExpiryController = TextEditingController();

  // Custom fields
  final List<Map<String, dynamic>> _customFields = [];
  final List<TextEditingController> _customFieldControllers = [];

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    final data = widget.existingData;
    debugPrint('=== LOADING EXISTING DATA ===');
    debugPrint('Data: $data');
    if (data == null) {
      debugPrint('No existing data found');
      return;
    }

    if (widget.type == AdditionalInfoType.student) {
      _applicationNumberController.text = data['applicationNumber'] ?? '';
      _learnersLicenseNumberController.text =
          data['learnersLicenseNumber'] ?? '';
      _learnersLicenseExpiryController.text =
          data['learnersLicenseExpiry'] ?? '';
      _drivingLicenseNumberController.text = data['drivingLicenseNumber'] ?? '';
      _drivingLicenseExpiryController.text = data['drivingLicenseExpiry'] ?? '';
    } else if (widget.type == AdditionalInfoType.dlService) {
      _applicationNumberController.text = data['applicationNumber'] ?? '';
      _licenseNumberController.text = data['licenseNumber'] ?? '';
      _licenseExpiryController.text = data['licenseExpiry'] ?? '';
    } else if (widget.type == AdditionalInfoType.rcService) {
      _registrationFitnessExpiryController.text =
          data['registrationRenewalOrFitnessExpiry'] ?? '';
      _insuranceExpiryController.text = data['insuranceExpiry'] ?? '';
      _taxExpiryController.text = data['taxExpiry'] ?? '';
      _pollutionExpiryController.text = data['pollutionExpiry'] ?? '';
      _permitExpiryController.text = data['permitExpiry'] ?? '';
    }

    // Load custom fields
    final customFields = data['customFields'] as Map<String, dynamic>?;
    if (customFields != null) {
      customFields.forEach((key, value) {
        final controller = TextEditingController(text: value.toString());
        _customFieldControllers.add(controller);
        _customFields.add({'key': key, 'controller': controller});
      });
    }
  }

  @override
  void dispose() {
    _applicationNumberController.dispose();
    _learnersLicenseNumberController.dispose();
    _learnersLicenseExpiryController.dispose();
    _drivingLicenseNumberController.dispose();
    _drivingLicenseExpiryController.dispose();
    _licenseNumberController.dispose();
    _licenseExpiryController.dispose();
    _registrationFitnessExpiryController.dispose();
    _insuranceExpiryController.dispose();
    _taxExpiryController.dispose();
    _pollutionExpiryController.dispose();
    _permitExpiryController.dispose();
    for (var c in _customFieldControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);

    try {
      // Debug logging
      debugPrint('=== ADDITIONAL INFO SAVE DEBUG ===');
      debugPrint('Type: ${widget.type}');
      debugPrint('Collection: ${widget.collection}');
      debugPrint('Document ID: ${widget.documentId}');

      // Build custom fields map
      final customFieldsMap = <String, dynamic>{};
      for (var field in _customFields) {
        final key = field['key'] as String;
        final controller = field['controller'] as TextEditingController;
        if (key.isNotEmpty) {
          customFieldsMap[key] = controller.text;
        }
      }

      debugPrint('Application Number: ${_applicationNumberController.text}');
      debugPrint('Learners Expiry: ${_learnersLicenseExpiryController.text}');
      debugPrint('Driving Expiry: ${_drivingLicenseExpiryController.text}');
      debugPrint('Custom Fields: $customFieldsMap');

      if (widget.type == AdditionalInfoType.student) {
        await _service.saveStudentTypeAdditionalInfo(
          collection: widget.collection,
          documentId: widget.documentId,
          applicationNumber: _applicationNumberController.text,
          learnersLicenseNumber: _learnersLicenseNumberController.text,
          learnersLicenseExpiry: _learnersLicenseExpiryController.text,
          drivingLicenseNumber: _drivingLicenseNumberController.text,
          drivingLicenseExpiry: _drivingLicenseExpiryController.text,
          customFields: customFieldsMap,
        );
      } else if (widget.type == AdditionalInfoType.dlService) {
        await _service.saveDlServiceAdditionalInfo(
          documentId: widget.documentId,
          applicationNumber: _applicationNumberController.text,
          licenseNumber: _licenseNumberController.text,
          licenseExpiry: _licenseExpiryController.text,
          customFields: customFieldsMap,
        );
      } else if (widget.type == AdditionalInfoType.rcService) {
        await _service.saveRcServiceAdditionalInfo(
          documentId: widget.documentId,
          registrationRenewalOrFitnessExpiry:
              _registrationFitnessExpiryController.text,
          insuranceExpiry: _insuranceExpiryController.text,
          taxExpiry: _taxExpiryController.text,
          pollutionExpiry: _pollutionExpiryController.text,
          permitExpiry: _permitExpiryController.text,
          customFields: customFieldsMap,
        );
      }

      debugPrint('=== SAVE SUCCESSFUL ===');

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e, stackTrace) {
      debugPrint('=== SAVE ERROR ===');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addCustomField() {
    showDialog(
      context: context,
      builder: (context) {
        final keyController = TextEditingController();
        return AlertDialog(
          title: const Text('Add New Field'),
          content: TextField(
            controller: keyController,
            decoration: const InputDecoration(
              labelText: 'Field Name',
              hintText: 'e.g., Reference Number',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (keyController.text.isNotEmpty) {
                  setState(() {
                    final controller = TextEditingController();
                    _customFieldControllers.add(controller);
                    _customFields.add({
                      'key': keyController.text,
                      'controller': controller,
                    });
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _removeCustomField(int index) {
    setState(() {
      final field = _customFields.removeAt(index);
      final controller = field['controller'] as TextEditingController;
      controller.dispose();
      _customFieldControllers.remove(controller);
    });
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool isDate = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: isDate ? TextInputType.number : TextInputType.text,
        inputFormatters: isDate
            ? [DateInputFormatter(), LengthLimitingTextInputFormatter(10)]
            : null,
        style: const TextStyle(color: Colors.black, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          hintText: isDate ? 'DD-MM-YYYY' : null,
          labelStyle: const TextStyle(color: Colors.black87),
          hintStyle: TextStyle(color: Colors.grey[500]),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCustomField(int index) {
    final field = _customFields[index];
    final key = field['key'] as String;
    final controller = field['controller'] as TextEditingController;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.black, fontSize: 16),
              decoration: InputDecoration(
                labelText: key,
                labelStyle: const TextStyle(color: Colors.black87),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _removeCustomField(index),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFields() {
    final fields = <Widget>[];

    if (widget.type == AdditionalInfoType.student) {
      fields.add(
          _buildTextField('Application Number', _applicationNumberController));
      fields.add(_buildTextField(
          'Learners License Number', _learnersLicenseNumberController));
      fields.add(_buildTextField(
          'Learners License Expiry', _learnersLicenseExpiryController,
          isDate: true));
      fields.add(_buildTextField(
          'Driving License Number', _drivingLicenseNumberController));
      fields.add(_buildTextField(
          'Driving License Expiry', _drivingLicenseExpiryController,
          isDate: true));
    } else if (widget.type == AdditionalInfoType.dlService) {
      fields.add(
          _buildTextField('Application Number', _applicationNumberController));
      fields.add(_buildTextField('License Number', _licenseNumberController));
      fields.add(_buildTextField('License Expiry', _licenseExpiryController,
          isDate: true));
    } else if (widget.type == AdditionalInfoType.rcService) {
      fields.add(_buildTextField(
          'Registration/Fitness Expiry', _registrationFitnessExpiryController,
          isDate: true));
      fields.add(_buildTextField('Insurance Expiry', _insuranceExpiryController,
          isDate: true));
      fields.add(
          _buildTextField('Tax Expiry', _taxExpiryController, isDate: true));
      fields.add(_buildTextField('Pollution Expiry', _pollutionExpiryController,
          isDate: true));
      fields.add(_buildTextField('Permit Expiry', _permitExpiryController,
          isDate: true));
    }

    // Add custom fields
    for (int i = 0; i < _customFields.length; i++) {
      fields.add(_buildCustomField(i));
    }

    return fields;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Additional Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addCustomField,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Field'),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Form fields
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: _buildFields(),
              ),
            ),
          ),

          // Save button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Save',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper function to show the additional info sheet
Future<bool?> showAdditionalInfoSheet({
  required BuildContext context,
  required AdditionalInfoType type,
  required String collection,
  required String documentId,
  Map<String, dynamic>? existingData,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: AdditionalInfoSheet(
        type: type,
        collection: collection,
        documentId: documentId,
        existingData: existingData,
      ),
    ),
  );
}
