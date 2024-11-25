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
  _EditEndorsementDetailsFormState createState() => _EditEndorsementDetailsFormState();
}

class _EditEndorsementDetailsFormState extends State<EditEndorsementDetailsForm> {
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
    studentIdController = TextEditingController(text: widget.initialValues['studentId']);
    fullNameController = TextEditingController(text: widget.initialValues['fullName']);
    guardianNameController = TextEditingController(text: widget.initialValues['guardianName']);
    dobController = TextEditingController(text: widget.initialValues['dob']);
    mobileNumberController = TextEditingController(text: widget.initialValues['mobileNumber']);
    emergencyNumberController = TextEditingController(text: widget.initialValues['emergencyNumber']);
    bloodGroupController = TextEditingController(text: widget.initialValues['bloodGroup']);
    houseController = TextEditingController(text: widget.initialValues['house']);
    placeController = TextEditingController(text: widget.initialValues['place']);
    postController = TextEditingController(text: widget.initialValues['post']);
    districtController = TextEditingController(text: widget.initialValues['district']);
    pinController = TextEditingController(text: widget.initialValues['pin']);
    licenseController = TextEditingController(text: widget.initialValues['license']);
    totalAmountController = TextEditingController(text: widget.initialValues['totalAmount']);
    advanceAmountController = TextEditingController(text: widget.initialValues['advanceAmount']);
    secondInstallmentController = TextEditingController(text: widget.initialValues['secondInstallment']);
    thirdInstallmentController = TextEditingController(text: widget.initialValues['thirdInstallment']);
    balanceAmountController = TextEditingController(text: widget.initialValues['balanceAmount']);
    covController = TextEditingController(text: widget.initialValues['cov']);
    scrollController = FixedExtentScrollController(
      initialItem: widget.items.indexOf(widget.initialValues['cov']),
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
    final secondInstallment = double.tryParse(secondInstallmentController.text) ?? 0.0;
    final thirdInstallment = double.tryParse(thirdInstallmentController.text) ?? 0.0;
    final balanceAmount = totalAmount - advanceAmount - secondInstallment - thirdInstallment;
    balanceAmountController.text = balanceAmount.toString();
  }

  Future<void> _getImageFromGallery() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _getImageFromCamera() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Endorsement Details'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            buildProfileImageSection(),
            buildPersonalDetailsSection(textColor),
            buildClassOfVehicleSection(textColor),
            buildAddressSection(textColor),
            buildFeesSection(textColor),
            buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget buildProfileImageSection() {
    return buildSectionContainer(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: _image != null
                  ? FileImage(_image!)
                  : (widget.initialValues['image'] != null &&
                          widget.initialValues['image'].isNotEmpty
                      ? NetworkImage(widget.initialValues['image'])
                      : const AssetImage('assets/icons/user.png')) as ImageProvider,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.image),
              onPressed: _getImageFromGallery,
            ),
            IconButton(
              icon: const Icon(Icons.camera_alt),
              onPressed: _getImageFromCamera,
            ),
          ],
        ),
      ],
    );
  }

  Widget buildPersonalDetailsSection(Color textColor) {
    return buildSection('Personal Details', [
      buildTextField('Full Name', fullNameController, 'Enter Full Name', textColor),
      buildTextField('Guardian Name', guardianNameController, 'Enter Guardian Name', textColor),
      buildTextField('Date of Birth', dobController, 'DD-MM-YYYY', textColor, keyboardType: TextInputType.number),
      buildTextField('Mobile Number', mobileNumberController, 'Enter Mobile Number', textColor, keyboardType: TextInputType.number),
      buildTextField('Emergency Number', emergencyNumberController, '(Optional)', textColor, keyboardType: TextInputType.number),
      buildTextField('Blood Group', bloodGroupController, 'Enter Blood Group', textColor),
      buildTextField('License Number', licenseController, 'KL102023000123', textColor),
    ]);
  }

  Widget buildClassOfVehicleSection(Color textColor) {
    return buildSectionContainer(
      children: [
        Text(
          'Class of Vehicle',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 10),
        CupertinoTextField(
          onTap: () {
            scrollController.dispose();
            scrollController = FixedExtentScrollController(
                initialItem: widget.items.indexOf(covController.text));
            showCupertinoModalPopup(
              context: context,
              builder: (context) => CupertinoActionSheet(
                actions: [buildPicker()],
                cancelButton: CupertinoActionSheetAction(
                  child: const Text('Done'),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            );
          },
          controller: covController,
          readOnly: true,
          enableInteractiveSelection: false,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget buildAddressSection(Color textColor) {
    return buildSection('Address', [
      buildTextField('House', houseController, 'Enter House Name', textColor),
      buildTextField('Place', placeController, 'Enter Place', textColor),
      buildTextField('Post', postController, 'Enter Post Office', textColor),
      buildTextField('District', districtController, 'Enter District Name', textColor),
      buildTextField('Pin', pinController, 'Enter Pin Code', textColor, keyboardType: TextInputType.number),
    ]);
  }

  Widget buildFeesSection(Color textColor) {
    return buildSection('Fees', [
      buildTextField('Total', totalAmountController, 'Enter Total Amount', textColor, keyboardType: TextInputType.number),
      buildTextField('Advance', advanceAmountController, 'Enter Advance Amount', textColor, keyboardType: TextInputType.number),
      buildTextField('Second Installment', secondInstallmentController, 'Enter Second Installment', textColor, keyboardType: TextInputType.number),
      buildTextField('Third Installment', thirdInstallmentController, 'Enter Third Installment', textColor, keyboardType: TextInputType.number),
      buildTextField('Balance', balanceAmountController, 'Balance Amount', textColor, readOnly: true),
    ]);
  }

  Widget buildTextField(String label, TextEditingController controller, String placeholder, Color textColor,
      {TextInputType keyboardType = TextInputType.text, bool readOnly = false}) {
    return CupertinoFormRow(
      prefix: Text(label, style: TextStyle(color: textColor)),
      child: CupertinoTextFormFieldRow(
        controller: controller,
        placeholder: placeholder,
        keyboardType: keyboardType,
        readOnly: readOnly,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Enter $label';
          }
          return null;
        },
        style: TextStyle(color: textColor),
      ),
    );
  }

  Widget buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: MyButton(
        onTap: isLoading ? null : handleSubmit,
        text: 'Update',
        isLoading: isLoading,
        isEnabled: !isLoading,
      ),
    );
  }

  Widget buildSection(String title, List<Widget> children) {
    return buildSectionContainer(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 10),
        ...children,
      ],
    );
  }

  Widget buildSectionContainer({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget buildPicker() => SizedBox(
        height: 350,
        child: CupertinoPicker(
          scrollController: scrollController,
          itemExtent: 64,
          onSelectedItemChanged: (index) {
            setState(() {
              widget.index = index;
              covController.text = widget.items[index];
            });
          },
          children: widget.items.map((item) => Center(child: Text(item, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)))).toList(),
        ),
      );

  Future<void> handleSubmit() async {
    if (!formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      final endorsement = await updateEndorsementData();
      await updateFirestore(endorsement);
      showSuccessMessage();
      Navigator.pop(context);
    } catch (error) {
      showErrorMessage(error.toString());
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> updateEndorsementData() async {
    String imageUrl = widget.initialValues['image'] ?? '';

    if (_image != null) {
      imageUrl = await uploadImage();
    }

    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

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
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      final String studentId = studentIdController.text;
      final String imagePath = 'images/${user?.uid}/$studentId.png';
      
      final Reference storageReference = FirebaseStorage.instance.ref().child(imagePath);
      final UploadTask uploadTask = storageReference.putFile(_image!);
      
      await uploadTask.whenComplete(() => null);
      return await storageReference.getDownloadURL();
    } catch (e) {
      throw 'Failed to upload image: $e';
    }
  }

  Future<void> updateFirestore(Map<String, dynamic> endorsement) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      final endorsementDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .collection('endorsement')
          .doc(endorsement['studentId']);

      await endorsementDoc.update(endorsement);

      // Add notifications for installment updates if amount is greater than zero
      double secondInstallment = double.tryParse(secondInstallmentController.text) ?? 0.0;
      double thirdInstallment = double.tryParse(thirdInstallmentController.text) ?? 0.0;

      if (secondInstallmentChanged && secondInstallment > 0) {
        await notificationsCollection.add({
          'title': 'Second Installment Updated',
          'date': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
          'details': 'Second installment updated for: ${endorsement['fullName']}',
        });
      }

      if (thirdInstallmentChanged && thirdInstallment > 0) {
        await notificationsCollection.add({
          'title': 'Third Installment Updated',
          'date': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
          'details': 'Third installment updated for: ${endorsement['fullName']}',
        });
      }
    } catch (e) {
      throw 'Failed to update endorsement data: $e';
    }
  }

  void showSuccessMessage() {
    Fluttertoast.showToast(
      msg: 'Endorsement Details Updated Successfully',
      fontSize: 18,
    );
  }

  void showErrorMessage(String error) {
    Fluttertoast.showToast(
      msg: error,
      fontSize: 18,
      backgroundColor: Colors.red,
    );
  }
}
