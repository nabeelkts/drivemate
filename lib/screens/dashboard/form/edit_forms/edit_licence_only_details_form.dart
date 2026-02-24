import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
// Import for date formatting
import 'package:mds/screens/widget/common_form.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:mds/controller/workspace_controller.dart';
import 'package:mds/screens/widget/base_form_widget.dart';
import 'package:mds/services/storage_service.dart';

// ignore: must_be_immutable
class EditLicenseOnlyForm extends StatefulWidget {
  final Map<String, dynamic> initialValues;
  final List<String> items;
  int? index;

  EditLicenseOnlyForm({
    required this.initialValues,
    required this.items,
    super.key,
  });

  @override
  _EditLicenseOnlyFormState createState() => _EditLicenseOnlyFormState();
}

class _EditLicenseOnlyFormState extends State<EditLicenseOnlyForm> {
  final GlobalKey<CommonFormState> formKey = GlobalKey<CommonFormState>();
  bool isLoading = false;
  File? _image;

  late TextEditingController studentIdController;
  late TextEditingController fullNameController;
  late TextEditingController guardianNameController;
  late TextEditingController dobController;
  late TextEditingController mobileNumberController;
  late TextEditingController emergencyNumberController;
  late TextEditingController bloodGroupController;
  late TextEditingController houseController;
  late TextEditingController placeController;
  late TextEditingController postController;
  late TextEditingController districtController;
  late TextEditingController pinController;
  late TextEditingController totalAmountController;
  late TextEditingController advanceAmountController;
  late TextEditingController secondInstallmentController;
  late TextEditingController thirdInstallmentController;
  late TextEditingController balanceAmountController;
  late TextEditingController covController;
  late FixedExtentScrollController scrollController;

  bool secondInstallmentChanged = false;
  bool thirdInstallmentChanged = false;

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
    dobController = TextEditingController(
        text: widget.initialValues['dob']?.toString() ?? '');
    mobileNumberController = TextEditingController(
        text: widget.initialValues['mobileNumber']?.toString() ?? '');
    emergencyNumberController = TextEditingController(
        text: widget.initialValues['emergencyNumber']?.toString() ?? '');
    bloodGroupController = TextEditingController(
        text: widget.initialValues['bloodGroup']?.toString() ?? '');
    houseController = TextEditingController(
        text: widget.initialValues['house']?.toString() ?? '');
    placeController = TextEditingController(
        text: widget.initialValues['place']?.toString() ?? '');
    postController = TextEditingController(
        text: widget.initialValues['post']?.toString() ?? '');
    districtController = TextEditingController(
        text: widget.initialValues['district']?.toString() ?? '');
    pinController = TextEditingController(
        text: widget.initialValues['pin']?.toString() ?? '');
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
    scrollController = FixedExtentScrollController(
      initialItem:
          widget.items.indexOf(widget.initialValues['cov']?.toString() ?? ''),
    );
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
    balanceAmountController.text = balanceAmount.toString();
  }

  Future<void> _getImageFromGallery() async {
    final pickedFile = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _getImageFromCamera() async {
    final pickedFile = await ImagePicker()
        .pickImage(source: ImageSource.camera, imageQuality: 50);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  void dispose() {
    disposeControllers();
    super.dispose();
  }

  void disposeControllers() {
    studentIdController.dispose();
    fullNameController.dispose();
    guardianNameController.dispose();
    dobController.dispose();
    mobileNumberController.dispose();
    emergencyNumberController.dispose();
    bloodGroupController.dispose();
    houseController.dispose();
    placeController.dispose();
    postController.dispose();
    districtController.dispose();
    pinController.dispose();
    totalAmountController.dispose();
    advanceAmountController.dispose();
    secondInstallmentController.dispose();
    thirdInstallmentController.dispose();
    balanceAmountController.dispose();
    covController.dispose();
    scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    final WorkspaceController workspaceController =
        Get.find<WorkspaceController>();
    final CollectionReference usersCollection =
        FirebaseFirestore.instance.collection('users');

    final schoolId = workspaceController.currentSchoolId.value;
    final targetId = schoolId.isNotEmpty ? schoolId : user?.uid;

    return BaseFormWidget(
      title: 'Edit License Only Details',
      onBack: () => Navigator.pop(context),
      actions: [
        IconButton(
          onPressed: () => formKey.currentState?.submitForm(),
          icon: const Icon(Icons.check, color: Colors.white),
        ),
      ],
      children: [
        CommonForm(
          key: formKey,
          items: widget.items,
          index: widget.items.indexOf(widget.initialValues['cov']),
          showLicenseField: false,
          initialValues: widget.initialValues,
          onFormSubmit: (licenseonly) async {
            try {
              await usersCollection
                  .doc(targetId)
                  .collection('licenseonly')
                  .doc(licenseonly['studentId'])
                  .update(licenseonly);

              Fluttertoast.showToast(
                msg: 'License Only Details Updated Successfully',
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
              );

              if (context.mounted) {
                Navigator.pop(context);
              }
            } catch (error) {
              if (kDebugMode) {
                print('Error updating license details: $error');
              }
              Fluttertoast.showToast(
                msg: 'Failed to update license details: $error',
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
              );
            }
          },
        ),
      ],
    );
  }

  Future<Map<String, dynamic>> updateStudentData() async {
    String imageUrl = widget.initialValues['image'] ?? '';

    if (_image != null) {
      try {
        imageUrl = await uploadImage();
      } catch (uploadError) {
        final errorString = uploadError.toString().toLowerCase();
        final isOfflineError = errorString.contains('network') ||
            errorString.contains('socket') ||
            errorString.contains('connection') ||
            errorString.contains('unreachable') ||
            errorString.contains('offline');

        if (isOfflineError) {
          // If offline, keep existing image
          imageUrl = widget.initialValues['image'] ?? '';
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Image upload skipped (offline). Changes will be saved.'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        } else {
          // For non-offline errors, rethrow
          throw uploadError;
        }
      }
    }

    final now = DateTime.now();
    final formattedDate = now.toIso8601String();

    Map<String, dynamic> updatedData = {
      'studentId': studentIdController.text,
      'fullName': fullNameController.text,
      'guardianName': guardianNameController.text,
      'dob': dobController.text,
      'mobileNumber': mobileNumberController.text,
      'emergencyNumber': emergencyNumberController.text,
      'bloodGroup': bloodGroupController.text,
      'house': houseController.text,
      'place': placeController.text,
      'post': postController.text,
      'district': districtController.text,
      'pin': pinController.text,
      'totalAmount': totalAmountController.text,
      'advanceAmount': advanceAmountController.text,
      'secondInstallment': secondInstallmentController.text,
      'thirdInstallment': thirdInstallmentController.text,
      'balanceAmount': balanceAmountController.text,
      'cov': covController.text,
      'image': imageUrl,
      'registrationDate': widget.initialValues['registrationDate'],
    };

    if (secondInstallmentChanged) {
      updatedData['secondInstallmentTime'] = formattedDate;
    }

    if (thirdInstallmentChanged) {
      updatedData['thirdInstallmentTime'] = formattedDate;
    }

    return updatedData;
  }

  Future<String> uploadImage() async {
    if (_image == null) return '';

    try {
      final storageService = StorageService();
      // Convert File to XFile for StorageService
      final xFile = XFile(_image!.path);
      return await storageService.uploadStudentImage(xFile);
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading image: $e');
      }
      // Rethrow to let caller handle the error properly
      throw Exception('Failed to upload image: $e');
    }
  }
}
