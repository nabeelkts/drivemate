/* lib/screens/widget/common_form.dart */
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:mds/screens/authentication/widgets/my_button.dart';

// ignore: must_be_immutable
class CommonForm extends StatefulWidget {
  CommonForm({
    required this.items,
    required this.index,
    required this.onFormSubmit,
    this.showLicenseField = false,
    super.key,
  });

  final List<String> items;
  int index;
  bool showLicenseField;
  final void Function(Map<String, dynamic> student) onFormSubmit;

  @override
  State<CommonForm> createState() => _CommonFormState();
}

class _CommonFormState extends State<CommonForm> {
  bool isLoading = false;
  final formKey = GlobalKey<FormState>();
  String imageUrl = '';
  File? _image;

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
  late TextEditingController balanceAmountController;
  late TextEditingController covController;
  late FixedExtentScrollController scrollController;
  late TextEditingController studentIdController;

  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');

  @override
  void initState() {
    super.initState();
    initializeControllers();
    setupListeners();
  }

  void initializeControllers() {
    fullNameController = TextEditingController();
    guardianNameController = TextEditingController();
    dobController = TextEditingController();
    mobileNumberController = TextEditingController();
    emergencyNumberController = TextEditingController();
    bloodGroupController = TextEditingController();
    houseNameController = TextEditingController();
    placeController = TextEditingController();
    postController = TextEditingController();
    districtController = TextEditingController();
    pinController = TextEditingController();
    licenseController = TextEditingController();
    totalAmountController = TextEditingController();
    advanceAmountController = TextEditingController();
    balanceAmountController = TextEditingController();
    covController = TextEditingController(text: widget.items[widget.index]);
    scrollController = FixedExtentScrollController(initialItem: widget.index);
    studentIdController = TextEditingController(text: generateRandomStudentID());
  }

  void setupListeners() {
    totalAmountController.addListener(updateBalanceAmount);
    advanceAmountController.addListener(updateBalanceAmount);
  }

  String generateRandomStudentID() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  void updateBalanceAmount() {
    final totalAmount = double.tryParse(totalAmountController.text) ?? 0.0;
    final advanceAmount = double.tryParse(advanceAmountController.text) ?? 0.0;
    final balanceAmount = max(0.0, totalAmount - advanceAmount);
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

  Future<File> compressImage(File imageFile) async {
    final decodedImage = img.decodeImage(await imageFile.readAsBytes());
    final compressedImage = img.copyResize(decodedImage!, width: 800);
    final compressedImageFile = File(imageFile.path)
      ..writeAsBytesSync(img.encodeJpg(compressedImage));
    return compressedImageFile;
  }

  @override
  void dispose() {
    disposeControllers();
    super.dispose();
  }

  void disposeControllers() {
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
    balanceAmountController.dispose();
    covController.dispose();
    scrollController.dispose();
    studentIdController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    // ignore: unused_local_variable
    final backgroundColor = theme.cardColor;

    return Form(
      key: formKey,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          buildProfileImageSection(),
          buildPersonalDetailsSection(),
          buildClassOfVehicleSection(),
          buildSection('Address', [
            buildTextField('House', houseNameController, 'Enter House Name', textColor),
            buildTextField('Place', placeController, 'Enter Place', textColor),
            buildTextField('Post', postController, 'Enter Post Office', textColor),
            buildTextField('District', districtController, 'Enter District Name', textColor),
            buildTextField('Pin', pinController, 'Enter Pin Code', textColor, keyboardType: TextInputType.number),
          ]),
          buildSection('Fees', [
            buildTextField('Total', totalAmountController, 'Enter Total Amount', textColor, keyboardType: TextInputType.number),
            buildTextField('Advance', advanceAmountController, 'Enter Advance Amount', textColor, keyboardType: TextInputType.number),
            buildTextField('Balance', balanceAmountController, 'Balance Amount', textColor, readOnly: true),
          ]),
          buildSubmitButton(),
        ],
      ),
    );
  }

  Widget buildProfileImageSection() {
    return buildSectionContainer(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: _image != null
                  ? FileImage(_image!)
                  : const NetworkImage('https://placeholder.pics/svg/120') as ImageProvider,
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

  Widget buildPersonalDetailsSection() {
    return buildSection('Personal Details', [
      buildTextField('Full Name', fullNameController, 'Enter Full Name', Theme.of(context).textTheme.bodyLarge?.color),
      buildTextField('Guardian Name', guardianNameController, 'Enter Guardian Name', Theme.of(context).textTheme.bodyLarge?.color),
      buildTextField('Date of Birth', dobController, 'DD-MM-YYYY', Theme.of(context).textTheme.bodyLarge?.color, keyboardType: TextInputType.number),
      buildTextField('Mobile Number', mobileNumberController, 'Enter Mobile Number', Theme.of(context).textTheme.bodyLarge?.color, keyboardType: TextInputType.number),
      buildTextField('Emergency Number', emergencyNumberController, '(Optional)', Theme.of(context).textTheme.bodyLarge?.color, keyboardType: TextInputType.number),
      buildTextField('Blood Group', bloodGroupController, 'Enter Blood Group', Theme.of(context).textTheme.bodyLarge?.color),
      if (widget.showLicenseField) buildTextField('License Number', licenseController, 'KL102023000123', Theme.of(context).textTheme.bodyLarge?.color),
    ]);
  }

  Widget buildClassOfVehicleSection() {
    return buildSectionContainer(
      children: [
        Text(
          'Class of Vehicle',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 10),
        CupertinoTextField(
          onTap: () {
            scrollController.dispose();
            scrollController = FixedExtentScrollController(initialItem: widget.index);
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
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );
  }

  Widget buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: MyButton(
        onTap: isLoading
            ? null
            : () async {
                setState(() {
                  isLoading = true;
                });
                if (formKey.currentState?.validate() != true) {
                  setState(() {
                    isLoading = false;
                  });
                  return;
                }
                try {
                  if (_image != null) {
                    String uniqueFileName = DateTime.now().millisecondsSinceEpoch.toString();
                    Reference referenceRoot = FirebaseStorage.instance.ref();
                    Reference referenceDirImages = referenceRoot.child('images');
                    Reference referenceImageToUpload = referenceDirImages.child(uniqueFileName);

                    List<int> imageBytes = await File(_image!.path).readAsBytes();
                    Uint8List uint8List = Uint8List.fromList(imageBytes);
                    await referenceImageToUpload.putData(uint8List);

                    imageUrl = await referenceImageToUpload.getDownloadURL();
                  }
                } catch (error) {
                  if (kDebugMode) {
                    print('Error uploading image: $error');
                  }
                }

                String studentId = studentIdController.text;
                String fullName = fullNameController.text;
                String guardianName = guardianNameController.text;
                String dob = dobController.text;
                String mobileNumber = mobileNumberController.text;
                String emergencyNumber = emergencyNumberController.text;
                String bloodGroup = bloodGroupController.text;
                String houseName = houseNameController.text;
                String place = placeController.text;
                String post = postController.text;
                String district = districtController.text;
                String pin = pinController.text;
                String license = licenseController.text;
                String totalAmount = totalAmountController.text;
                String advanceAmount = advanceAmountController.text;
                String balanceAmount = balanceAmountController.text;
                String cov = covController.text;

                Map<String, dynamic> student = {
                  'studentId': studentId,
                  'fullName': fullName,
                  'guardianName': guardianName,
                  'dob': dob,
                  'mobileNumber': mobileNumber,
                  'emergencyNumber': emergencyNumber,
                  'bloodGroup': bloodGroup,
                  'houseName': houseName,
                  'place': place,
                  'post': post,
                  'district': district,
                  'pin': pin,
                  'license': license,
                  'totalAmount': totalAmount,
                  'advanceAmount': advanceAmount,
                  'balanceAmount': balanceAmount,
                  'cov': cov,
                  'image': imageUrl,
                };

                widget.onFormSubmit(student);

                setState(() {
                  isLoading = false;
                });
              },
        text: 'Submit',
        isLoading: isLoading,
        isEnabled: !isLoading,
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller, String placeholder, Color? textColor, {TextInputType keyboardType = TextInputType.text, bool readOnly = false}) {
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
        children: children,
      ),
    );
  }

  Widget buildPicker() => SizedBox(
        height: 350,
        child: StatefulBuilder(
          builder: (context, setState) => CupertinoPicker(
            scrollController: scrollController,
            looping: true,
            itemExtent: 64,
            children: List.generate(widget.items.length, (index) {
              final isSelected = widget.index == index;
              final item = widget.items[index];
              final color = isSelected
                  ? CupertinoColors.activeBlue
                  : Theme.of(context).textTheme.bodyLarge?.color ?? CupertinoColors.black;
              return Center(
                child: Text(
                  item,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                  ),
                ),
              );
            }),
            onSelectedItemChanged: (index) {
              setState(() {
                widget.index = index;
                final item = widget.items[index];
                covController.text = item;
              });
            },
          ),
        ),
      );
}
