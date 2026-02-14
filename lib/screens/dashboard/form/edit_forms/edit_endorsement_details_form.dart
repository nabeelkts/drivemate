import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart'; // Import for date formatting
import 'package:mds/screens/authentication/widgets/my_button.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mds/screens/widget/common_form.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:mds/controller/workspace_controller.dart';

// ignore: must_be_immutable
class EditEndorsementDetailsForm extends StatefulWidget {
  final Map<String, dynamic> initialValues;
  final List<String> items;
  int? index;

  EditEndorsementDetailsForm({
    required this.initialValues,
    required this.items,
    super.key,
  });

  @override
  // ignore: library_private_types_in_public_api
  _EditEndorsementDetailsFormState createState() =>
      _EditEndorsementDetailsFormState();
}

class _EditEndorsementDetailsFormState
    extends State<EditEndorsementDetailsForm> {
  final formKey = GlobalKey<FormState>();
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
  late TextEditingController licenseController;
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
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _getImageFromCamera() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.camera);
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
    licenseController.dispose();
    totalAmountController.dispose();
    advanceAmountController.dispose();
    secondInstallmentController.dispose();
    thirdInstallmentController.dispose();
    balanceAmountController.dispose();
    covController.dispose();
    scrollController.dispose();
  }

  Future<Map<String, dynamic>> updateStudentData() async {
    String imageUrl = widget.initialValues['image'] ?? '';

    if (_image != null) {
      imageUrl = await uploadImage();
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
      'license': licenseController.text,
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
      final storageRef = FirebaseStorage.instance.ref();
      final imageRef = storageRef
          .child('images/${DateTime.now().millisecondsSinceEpoch}.jpg');

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
      );

      await imageRef.putFile(_image!, metadata);
      return await imageRef.getDownloadURL();
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading image: $e');
      }
      return '';
    }
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

    // Get the index, defaulting to 0 if not found
    final int selectedIndex =
        widget.items.contains(widget.initialValues['cov'] ?? '')
            ? widget.items.indexOf(widget.initialValues['cov'] ?? '')
            : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Endorsement Details'),
        elevation: 0,
      ),
      body: CommonForm(
        items: widget.items,
        index: selectedIndex,
        showLicenseField: true,
        initialValues: widget.initialValues,
        onFormSubmit: (endorsement) async {
          try {
            await usersCollection
                .doc(targetId)
                .collection('endorsement')
                .doc(endorsement['studentId'])
                .update(endorsement);

            Fluttertoast.showToast(
              msg: 'Endorsement Details Updated Successfully',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
            );

            if (context.mounted) {
              Navigator.pop(context);
            }
          } catch (error) {
            if (kDebugMode) {
              print('Error updating endorsement details: $error');
            }
            Fluttertoast.showToast(
              msg: 'Failed to update endorsement details: $error',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
            );
          }
        },
      ),
    );
  }
}
