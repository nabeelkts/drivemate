import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:mds/screens/widget/common_form.dart';
import 'package:mds/utils/date_utils.dart' as app_date_utils;
import 'package:get/get.dart';
import 'package:mds/controller/workspace_controller.dart';

// ignore: must_be_immutable
class EditStudentDetailsForm extends StatefulWidget {
  final Map<String, dynamic> initialValues;
  final List<String> items;
  final int? index;

  const EditStudentDetailsForm({
    super.key,
    required this.initialValues,
    required this.items,
    this.index,
  });

  @override
  // ignore: library_private_types_in_public_api
  _EditStudentDetailsFormState createState() => _EditStudentDetailsFormState();
}

class _EditStudentDetailsFormState extends State<EditStudentDetailsForm> {
  bool isLoading = false;
  bool secondInstallmentChanged = false;
  bool thirdInstallmentChanged = false;
  final GlobalKey<CommonFormState> _formKey = GlobalKey<CommonFormState>();

  late TextEditingController studentIdController;
  late TextEditingController fullNameController;
  late TextEditingController guardianNameController;
  late TextEditingController dobController;
  late TextEditingController mobileNumberController;
  late TextEditingController emergencyNumberController;
  late TextEditingController bloodGroupController;
  late TextEditingController houseNameController;
  late TextEditingController placeController;
  late TextEditingController postController;
  late TextEditingController districtController;
  late TextEditingController pinController;
  late TextEditingController licenseController;
  late TextEditingController totalAmountController;
  late TextEditingController advanceAmountController;
  late TextEditingController secondInstallmentController;
  late TextEditingController thirdInstallmentController;
  late TextEditingController balanceAmountController;
  late TextEditingController covController;
  late TextEditingController learnersTestDateController;
  late TextEditingController drivingTestDateController;
  late FixedExtentScrollController scrollController;

  final CollectionReference notificationsCollection =
      FirebaseFirestore.instance.collection('notifications');

  @override
  void initState() {
    super.initState();
    initializeControllers();
    setupListeners();
  }

  void initializeControllers() {
    studentIdController = TextEditingController(
        text: widget.initialValues['studentId']?.toString() ?? '');
    fullNameController = TextEditingController(
        text: widget.initialValues['fullName']?.toString() ?? '');
    guardianNameController = TextEditingController(
        text: widget.initialValues['guardianName']?.toString() ?? '');

    // Initialize DOB with proper date format using utility
    dobController = TextEditingController(
      text: app_date_utils.AppDateUtils.formatDateForDisplay(
          widget.initialValues['dob']?.toString()),
    );

    mobileNumberController = TextEditingController(
        text: widget.initialValues['mobileNumber']?.toString() ?? '');
    emergencyNumberController = TextEditingController(
        text: widget.initialValues['emergencyNumber']?.toString() ?? '');
    bloodGroupController = TextEditingController(
        text: widget.initialValues['bloodGroup']?.toString() ?? '');
    houseNameController = TextEditingController(
        text: widget.initialValues['house']?.toString() ?? '');
    placeController = TextEditingController(
        text: widget.initialValues['place']?.toString() ?? '');
    postController = TextEditingController(
        text: widget.initialValues['post']?.toString() ?? '');
    districtController = TextEditingController(
        text: widget.initialValues['district']?.toString() ?? '');
    pinController = TextEditingController(
        text: widget.initialValues['pin']?.toString() ?? '');
    licenseController = TextEditingController(
        text: widget.initialValues['license']?.toString() ?? '');
    totalAmountController = TextEditingController(
        text: widget.initialValues['totalAmount']?.toString() ?? '');
    advanceAmountController = TextEditingController(
        text: widget.initialValues['advanceAmount']?.toString() ?? '');
    secondInstallmentController = TextEditingController(
        text: widget.initialValues['secondInstallment']?.toString() ?? '');
    thirdInstallmentController = TextEditingController(
        text: widget.initialValues['thirdInstallment']?.toString() ?? '');
    balanceAmountController = TextEditingController(
        text: widget.initialValues['balanceAmount']?.toString() ?? '');
    covController = TextEditingController(
        text: widget.initialValues['cov']?.toString() ?? '');

    // Initialize test dates with proper date format using utility
    learnersTestDateController = TextEditingController(
      text: app_date_utils.AppDateUtils.formatDateForDisplay(
          widget.initialValues['learnersTestDate']?.toString()),
    );
    drivingTestDateController = TextEditingController(
      text: app_date_utils.AppDateUtils.formatDateForDisplay(
          widget.initialValues['drivingTestDate']?.toString()),
    );

    scrollController = FixedExtentScrollController(
        initialItem: widget.items.indexOf(widget.initialValues['cov'] ?? ''));
  }

  void setupListeners() {
    totalAmountController.addListener(updateBalanceAmount);
    advanceAmountController.addListener(updateBalanceAmount);
    secondInstallmentController.addListener(() {
      updateBalanceAmount();
      secondInstallmentChanged = true;
    });
    thirdInstallmentController.addListener(() {
      updateBalanceAmount();
      thirdInstallmentChanged = true;
    });
  }

  void updateBalanceAmount() {
    final totalAmount = double.tryParse(totalAmountController.text) ?? 0.0;
    final advanceAmount = double.tryParse(advanceAmountController.text) ?? 0.0;
    final secondInstallment =
        double.tryParse(secondInstallmentController.text) ?? 0.0;
    final thirdInstallment =
        double.tryParse(thirdInstallmentController.text) ?? 0.0;
    final balanceAmount =
        totalAmount - advanceAmount - secondInstallment - thirdInstallment;

    // Use setState to avoid direct controller manipulation issues
    if (mounted) {
      setState(() {
        balanceAmountController.text = balanceAmount.toStringAsFixed(2);
      });
    }
  }

  @override
  void dispose() {
    studentIdController.dispose();
    fullNameController.dispose();
    guardianNameController.dispose();
    dobController.dispose();
    mobileNumberController.dispose();
    emergencyNumberController.dispose();
    bloodGroupController.dispose();
    houseNameController.dispose();
    placeController.dispose();
    postController.dispose();
    districtController.dispose();
    pinController.dispose();
    licenseController.dispose();
    totalAmountController.dispose();
    advanceAmountController.dispose();
    secondInstallmentController.dispose();
    thirdInstallmentController.dispose();
    balanceAmountController.dispose();
    covController.dispose();
    learnersTestDateController.dispose();
    drivingTestDateController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  /// Builds a date picker field widget
  /// Uses AppDateUtils for consistent date parsing and formatting
  Widget buildDateField(
      String label, TextEditingController controller, String placeholder) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: placeholder,
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: () => _selectDate(controller),
        ),
      ),
      textInputAction: TextInputAction.next,
      readOnly: true,
      onTap: () => _selectDate(controller),
    );
  }

  /// Handles date selection using AppDateUtils for parsing
  Future<void> _selectDate(TextEditingController controller) async {
    final initialDate =
        app_date_utils.AppDateUtils.parseDisplayDate(controller.text);

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: app_date_utils.AppDateUtils.firstDate,
      lastDate: app_date_utils.AppDateUtils.lastDate,
    );

    if (date != null && mounted) {
      setState(() {
        controller.text =
            DateFormat(app_date_utils.AppDateUtils.displayFormat).format(date);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Student Details'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined),
            onPressed: () => _formKey.currentState?.smartFill(),
            tooltip: 'Smart Fill',
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => _formKey.currentState?.submitForm(),
          ),
        ],
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: CommonForm(
        key: _formKey,
        items: widget.items,
        index: widget.items.indexOf(widget.initialValues['cov'] ?? ''),
        showLicenseField: false,
        initialValues: widget.initialValues,
        onFormSubmit: (student) async {
          setState(() {
            isLoading = true;
          });

          try {
            // Initiate update but don't await full server confirmation to keep UI fast
            unawaited(updateFirestore(student).then((_) {
              if (kDebugMode) print('Update completed in background');
            }).catchError((e) {
              if (kDebugMode) print('Background update error: $e');
            }));

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Update initiated...')),
            );
            Navigator.pop(context);
          } catch (error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $error')),
            );
          } finally {
            setState(() {
              isLoading = false;
            });
          }
        },
      ),
    );
  }

  /// Updates Firestore with student data
  /// Formats dates and numeric fields before saving
  Future<void> updateFirestore(Map<String, dynamic> updatedStudent) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      final WorkspaceController workspaceController =
          Get.find<WorkspaceController>();

      if (user == null) {
        throw Exception('User not authenticated');
      }

      final schoolId = workspaceController.currentSchoolId.value;
      final targetId = schoolId.isNotEmpty ? schoolId : user.uid;

      final studentId = widget.initialValues['studentId'];
      if (studentId == null || studentId.toString().isEmpty) {
        throw Exception('Student ID is required');
      }

      // Dates are already formatted for storage by CommonForm
      // Convert numeric fields to proper types
      _convertNumericFields(updatedStudent);

      if (kDebugMode) {
        print('Updating Firestore document:');
        print('User ID: ${user.uid}');
        print('Student ID: $studentId');
        print('Updated data: $updatedStudent');
      }

      // Update the student document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetId)
          .collection('students')
          .doc(studentId.toString())
          .update(updatedStudent);

      if (kDebugMode) {
        print('Student document updated successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating Firestore: $e');
      }
      throw Exception('Failed to update Firestore: $e');
    }
  }

  /// Converts string numeric fields to double values
  void _convertNumericFields(Map<String, dynamic> data) {
    final numericFields = [
      'totalAmount',
      'advanceAmount',
      'secondInstallment',
      'thirdInstallment',
      'balanceAmount',
    ];

    for (final field in numericFields) {
      if (data[field] != null) {
        data[field] = double.tryParse(data[field].toString()) ?? 0.0;
      }
    }
  }

  void showSuccessMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Student details updated successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void showErrorMessage(BuildContext context, String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $message'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
