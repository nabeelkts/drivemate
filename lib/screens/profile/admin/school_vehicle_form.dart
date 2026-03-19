import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:drivemate/constants/colors.dart';
import 'package:drivemate/controller/workspace_controller.dart';
import 'package:drivemate/screens/widget/custom_back_button.dart';
import 'package:drivemate/screens/widget/base_form_widget.dart';

class SchoolVehicleForm extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final String? vehicleId;

  const SchoolVehicleForm({this.initialData, this.vehicleId, super.key});

  @override
  State<SchoolVehicleForm> createState() => _SchoolVehicleFormState();
}

class _SchoolVehicleFormState extends State<SchoolVehicleForm> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleNumberController = TextEditingController();
  final _modelController = TextEditingController();
  final _fitnessExpiryController = TextEditingController();
  final _insuranceExpiryController = TextEditingController();
  final _pollutionExpiryController = TextEditingController();
  final _taxExpiryController = TextEditingController();

  DateTime? _fitnessExpiry;
  DateTime? _insuranceExpiry;
  DateTime? _pollutionExpiry;
  DateTime? _taxExpiry;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _vehicleNumberController.text = widget.initialData!['vehicleNumber'] ?? '';
      _modelController.text = widget.initialData!['model'] ?? '';
      
      if (widget.initialData!['fitnessExpiry'] != null) {
        _fitnessExpiry = (widget.initialData!['fitnessExpiry'] as Timestamp).toDate();
        _fitnessExpiryController.text = DateFormat('dd-MM-yyyy').format(_fitnessExpiry!);
      }
      if (widget.initialData!['insuranceExpiry'] != null) {
        _insuranceExpiry = (widget.initialData!['insuranceExpiry'] as Timestamp).toDate();
        _insuranceExpiryController.text = DateFormat('dd-MM-yyyy').format(_insuranceExpiry!);
      }
      if (widget.initialData!['pollutionExpiry'] != null) {
        _pollutionExpiry = (widget.initialData!['pollutionExpiry'] as Timestamp).toDate();
        _pollutionExpiryController.text = DateFormat('dd-MM-yyyy').format(_pollutionExpiry!);
      }
      if (widget.initialData!['taxExpiry'] != null) {
        _taxExpiry = (widget.initialData!['taxExpiry'] as Timestamp).toDate();
        _taxExpiryController.text = DateFormat('dd-MM-yyyy').format(_taxExpiry!);
      }
    }
  }

  Future<void> _selectDate(BuildContext context, String type) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        final dateStr = DateFormat('dd-MM-yyyy').format(picked);
        switch (type) {
          case 'fitness':
            _fitnessExpiry = picked;
            _fitnessExpiryController.text = dateStr;
            break;
          case 'insurance':
            _insuranceExpiry = picked;
            _insuranceExpiryController.text = dateStr;
            break;
          case 'pollution':
            _pollutionExpiry = picked;
            _pollutionExpiryController.text = dateStr;
            break;
          case 'tax':
            _taxExpiry = picked;
            _taxExpiryController.text = dateStr;
            break;
        }
      });
    }
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final workspaceController = Get.find<WorkspaceController>();
      final schoolId = workspaceController.currentSchoolId.value;
      final userId = FirebaseAuth.instance.currentUser?.uid;
      final targetId = schoolId.isNotEmpty ? schoolId : userId;

      if (targetId == null) throw Exception('User not authenticated');

      final data = {
        'vehicleNumber': _vehicleNumberController.text.trim().toUpperCase(),
        'model': _modelController.text.trim(),
        'fitnessExpiry': _fitnessExpiry != null ? Timestamp.fromDate(_fitnessExpiry!) : null,
        'insuranceExpiry': _insuranceExpiry != null ? Timestamp.fromDate(_insuranceExpiry!) : null,
        'pollutionExpiry': _pollutionExpiry != null ? Timestamp.fromDate(_pollutionExpiry!) : null,
        'taxExpiry': _taxExpiry != null ? Timestamp.fromDate(_taxExpiry!) : null,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.vehicleId == null) {
        data['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance
            .collection('users')
            .doc(targetId)
            .collection('school_vehicles')
            .add(data);
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(targetId)
            .collection('school_vehicles')
            .doc(widget.vehicleId)
            .update(data);
      }

      Get.back(result: true);
      Get.snackbar('Success', 'Vehicle saved successfully',
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Failed to save vehicle: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vehicleId == null ? 'Add School Vehicle' : 'Edit School Vehicle'),
        leading: const CustomBackButton(),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _vehicleNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Vehicle Number',
                        hintText: 'e.g. KL 01 AB 1234',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _modelController,
                      decoration: const InputDecoration(
                        labelText: 'Vehicle Model',
                        hintText: 'e.g. Maruti Swift',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildDatePicker('Fitness Expiry', _fitnessExpiryController, 'fitness'),
                    const SizedBox(height: 16),
                    _buildDatePicker('Insurance Expiry', _insuranceExpiryController, 'insurance'),
                    const SizedBox(height: 16),
                    _buildDatePicker('Pollution Expiry', _pollutionExpiryController, 'pollution'),
                    const SizedBox(height: 16),
                    _buildDatePicker('Tax Expiry', _taxExpiryController, 'tax'),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveVehicle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Save Vehicle',
                            style: TextStyle(fontSize: 16, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDatePicker(String label, TextEditingController controller, String type) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: () => _selectDate(context, type),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.calendar_today),
      ),
      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
    );
  }
}
