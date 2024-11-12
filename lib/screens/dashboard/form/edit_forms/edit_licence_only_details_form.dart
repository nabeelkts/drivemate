import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';

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
  File? _image;
  bool isLoading = false;
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
  final formKey = GlobalKey<FormState>();
  Future<void> _getImageFromGallery() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _getImageFromCamera() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
    );

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    studentIdController =
        TextEditingController(text: widget.initialValues['studentId']);
    fullNameController =
        TextEditingController(text: widget.initialValues['fullName']);
    guardianNameController =
        TextEditingController(text: widget.initialValues['guardianName']);
    dobController = TextEditingController(text: widget.initialValues['dob']);
    mobileNumberController =
        TextEditingController(text: widget.initialValues['mobileNumber']);
    emergencyNumberController =
        TextEditingController(text: widget.initialValues['emergencyNumber']);
    bloodGroupController =
        TextEditingController(text: widget.initialValues['bloodGroup']);
    houseController =
        TextEditingController(text: widget.initialValues['house']);
    placeController =
        TextEditingController(text: widget.initialValues['place']);
    postController = TextEditingController(text: widget.initialValues['post']);
    districtController =
        TextEditingController(text: widget.initialValues['district']);
    pinController = TextEditingController(text: widget.initialValues['pin']);
    licenseController =
        TextEditingController(text: widget.initialValues['license']);
    totalAmountController =
        TextEditingController(text: widget.initialValues['totalAmount']);
    advanceAmountController =
        TextEditingController(text: widget.initialValues['advanceAmount']);
    secondInstallmentController =
        TextEditingController(text: widget.initialValues['secondInstallment']);
    thirdInstallmentController =
        TextEditingController(text: widget.initialValues['thirdInstallment']);
    balanceAmountController =
        TextEditingController(text: widget.initialValues['balanceAmount']);
    covController = TextEditingController(text: widget.initialValues['cov']);
    scrollController = FixedExtentScrollController(
        initialItem: widget.items.indexOf(widget.initialValues['cov']));
    totalAmountController.addListener(updateBalanceAmount);
    advanceAmountController.addListener(updateBalanceAmount);
    secondInstallmentController.addListener(updateBalanceAmount);
    thirdInstallmentController.addListener(updateBalanceAmount);
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

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
        backgroundColor: CupertinoColors.systemGroupedBackground,
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Edit Licence Only Details'),
        ),
        child: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.all(
              12,
            ),
            children: [
              CupertinoFormSection.insetGrouped(
                  header: const Text(
                    'Licence Only Details',
                    style: TextStyle(fontSize: 16),
                  ),
                  children: [
                    // Image Picker Section
                    CupertinoFormSection.insetGrouped(
                      margin: const EdgeInsets.all(12),
                      header: const Text(
                        'Profile Image',
                        style: TextStyle(fontSize: 16),
                      ),
                      children: [
                        CupertinoFormRow(
                          prefix: const Text('Select Image'),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              CupertinoButton(
                                onPressed: _getImageFromGallery,
                                child: const Column(
                                  children: [
                                    Icon(Icons.image),
                                    SizedBox(height: 4),
                                    Text('Gallery'),
                                  ],
                                ),
                              ),
                              CupertinoButton(
                                onPressed: _getImageFromCamera,
                                child: const Column(
                                  children: [
                                    Icon(Icons.camera_alt),
                                    SizedBox(height: 4),
                                    Text('Camera'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Load and display the image from Firestore if available
                        if (_image != null ||
                            widget.initialValues['image'] != null)
                          Container(
                            padding: const EdgeInsets.all(8),
                            child: _image != null
                                ? Image.file(_image!)
                                : Image.network(
                                    widget.initialValues['image'],
                                    loadingBuilder: (BuildContext context,
                                        Widget child,
                                        ImageChunkEvent? loadingProgress) {
                                      if (loadingProgress == null) {
                                        return child;
                                      }
                                      return const Center(
                                        child: CupertinoActivityIndicator(),
                                      );
                                    },
                                  ),
                          ),
                      ],
                    ),
                    CupertinoFormRow(
                      prefix: const Text('Full Name'),
                      child: CupertinoTextFormFieldRow(
                        textInputAction: TextInputAction.next,
                        placeholder: 'Full Name',
                        controller: fullNameController,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (fullName) {
                          if (fullName == null || fullName.isEmpty) {
                            return 'Enter Full Name';
                          } else if (fullName.length < 4) {
                            return 'Must be at least 4 characters long';
                          } else {
                            return null;
                          }
                        },
                      ),
                    ),
                    CupertinoFormRow(
                      prefix: const Text("Guardian Name"),
                      child: CupertinoTextFormFieldRow(
                        textInputAction: TextInputAction.next,
                        placeholder: 'S/O , W/O , C/O',
                        controller: guardianNameController,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (guardianName) {
                          if (guardianName == null || guardianName.isEmpty) {
                            return 'Enter Guardian Name';
                          } else if (guardianName.length < 4) {
                            return 'Must be at least 4 characters long';
                          } else {
                            return null;
                          }
                        },
                      ),
                    ),
                    CupertinoFormRow(
                      prefix: const Text("Date of Birth"),
                      child: CupertinoTextFormFieldRow(
                        textInputAction: TextInputAction.next,
                        placeholder: 'DD-MM-YYYY',
                        controller: dobController,
                        keyboardType: const TextInputType.numberWithOptions(),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (dob) {
                          if (dob == null || dob.isEmpty) {
                            return 'Enter Date of Birth';
                          } else if (dob.length < 4) {
                            return 'Must be a Valid Date of Birth';
                          } else {
                            return null;
                          }
                        },
                      ),
                    ),
                    CupertinoFormRow(
                      prefix: const Text('Mobile Number'),
                      child: CupertinoTextFormFieldRow(
                        textInputAction: TextInputAction.next,
                        placeholder: 'Mobile Number',
                        controller: mobileNumberController,
                        keyboardType: TextInputType.number,
                        maxLength: 10,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (mobileNumber) {
                          if (mobileNumber == null || mobileNumber.isEmpty) {
                            return 'Enter Valid Mobile Number';
                          } else if (mobileNumber.length < 10) {
                            return 'Must be at least 10 characters long';
                          } else {
                            return null;
                          }
                        },
                      ),
                    ),
                    CupertinoFormRow(
                      prefix: const Text('Emergency Number'),
                      child: CupertinoTextFormFieldRow(
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.number,
                        maxLength: 10,
                        placeholder: ' (Optional)',
                        controller: emergencyNumberController,
                      ),
                    ),
                    CupertinoFormRow(
                      prefix: const Text('Blood Group'),
                      child: CupertinoTextFormFieldRow(
                        textInputAction: TextInputAction.next,
                        maxLength: 10,
                        placeholder: 'Blood Group',
                        controller: bloodGroupController,
                      ),
                    ),
                    CupertinoFormRow(
                      prefix: const Text('License Number'),
                      child: CupertinoTextFormFieldRow(
                        textInputAction: TextInputAction.next,
                        maxLength: 14,
                        placeholder: 'KL102023000123 ',
                        controller: licenseController,
                      ),
                    ),
                  ]),
              CupertinoFormSection.insetGrouped(
                margin: const EdgeInsets.all(12),
                header: const Text(
                  'Class of Vehicle',
                  style: TextStyle(fontSize: 16),
                ),
                children: [
                  CupertinoFormRow(
                    child: Center(
                      child: CupertinoTextField(
                        onTap: () {
                          scrollController.dispose();
                          scrollController = FixedExtentScrollController(
                              initialItem:
                                  widget.items.indexOf(covController.text));
                          showCupertinoModalPopup(
                            context: context,
                            builder: (context) => CupertinoActionSheet(
                              actions: [buildPicker()],
                              cancelButton: CupertinoActionSheetAction(
                                child: const Text('Done'),
                                onPressed: () async {
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                          );
                        },
                        controller: covController,
                        readOnly: true,
                        enableInteractiveSelection: false,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              CupertinoFormSection.insetGrouped(
                  margin: const EdgeInsets.all(12),
                  header: const Text(
                    'Address',
                    style: TextStyle(fontSize: 16),
                  ),
                  children: [
                    CupertinoFormRow(
                      prefix: const Text('House'),
                      child: CupertinoTextFormFieldRow(
                        textInputAction: TextInputAction.next,
                        placeholder: 'House Name',
                        controller: houseController,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (houseName) {
                          if (houseName == null || houseName.isEmpty) {
                            return 'Enter House Name';
                          } else if (houseName.length < 4) {
                            return 'Must be at least 4 characters long';
                          } else {
                            return null;
                          }
                        },
                      ),
                    ),
                    CupertinoFormRow(
                      prefix: const Text('Place'),
                      child: CupertinoTextFormFieldRow(
                        textInputAction: TextInputAction.next,
                        placeholder: 'Place',
                        controller: placeController,
                      ),
                    ),
                    CupertinoFormRow(
                      prefix: const Text('Post'),
                      child: CupertinoTextFormFieldRow(
                        textInputAction: TextInputAction.next,
                        placeholder: 'Post Office',
                        controller: postController,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (post) {
                          if (post == null || post.isEmpty) {
                            return 'Enter Post Office';
                          } else if (post.length < 4) {
                            return 'Must be at least 4 characters long';
                          } else {
                            return null;
                          }
                        },
                      ),
                    ),
                    CupertinoFormRow(
                      prefix: const Text('District'),
                      child: CupertinoTextFormFieldRow(
                        textInputAction: TextInputAction.next,
                        placeholder: 'District',
                        controller: districtController,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (district) {
                          if (district == null || district.isEmpty) {
                            return 'Enter District Name';
                          } else if (district.length < 4) {
                            return 'Must be at least 4 characters long';
                          } else {
                            return null;
                          }
                        },
                      ),
                    ),
                    CupertinoFormRow(
                      prefix: const Text('Pin'),
                      child: CupertinoTextFormFieldRow(
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        placeholder: 'Pin Code',
                        controller: pinController,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (pin) {
                          if (pin == null || pin.isEmpty) {
                            return 'Enter Pin code ';
                          } else if (pin.length < 6) {
                            return 'Must be at least 6 numbers long';
                          } else {
                            return null;
                          }
                        },
                      ),
                    )
                  ]),
              CupertinoFormSection.insetGrouped(
                  margin: const EdgeInsets.all(12),
                  header: const Text(
                    'Fees',
                    style: TextStyle(fontSize: 16),
                  ),
                  children: [
                    CupertinoFormRow(
                      prefix: const Text('Total'),
                      child: CupertinoTextFormFieldRow(
                        keyboardType: TextInputType.number,
                        controller: totalAmountController,
                        maxLength: 5,
                        textInputAction: TextInputAction.next,
                        placeholder: 'Total Amount',
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (totalAmount) {
                          if (totalAmount == null || totalAmount.isEmpty) {
                            return 'Enter Total Amount';
                          } else {
                            return null;
                          }
                        },
                      ),
                    ),
                    CupertinoFormRow(
                      prefix: const Text('Advance'),
                      child: CupertinoTextFormFieldRow(
                        keyboardType: TextInputType.number,
                        maxLength: 5,
                        controller: advanceAmountController,
                        placeholder: 'Advance Amount',
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (advanceAmount) {
                          if (advanceAmount == null || advanceAmount.isEmpty) {
                            return 'Enter Advance Amount';
                          } else {
                            return null;
                          }
                        },
                      ),
                    ),
                    CupertinoFormRow(
                      prefix: const Text('Second Installment'),
                      child: CupertinoTextFormFieldRow(
                        keyboardType: TextInputType.number,
                        maxLength: 5,
                        controller: secondInstallmentController,
                        placeholder: 'Second Installment',
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (secondInstallment) {
                          if (secondInstallment == null ||
                              secondInstallment.isEmpty) {
                            return 'Enter Second Installment Amount or Enter zero';
                          } else {
                            return null;
                          }
                        },
                      ),
                    ),
                    CupertinoFormRow(
                      prefix: const Text('Third Installment'),
                      child: CupertinoTextFormFieldRow(
                        keyboardType: TextInputType.number,
                        maxLength: 5,
                        controller: thirdInstallmentController,
                        placeholder: 'Third Installment',
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (thirdInstallment) {
                          if (thirdInstallment == null ||
                              thirdInstallment.isEmpty) {
                            return 'Enter Third Installment Amount or Enter zero';
                          } else {
                            return null;
                          }
                        },
                      ),
                    ),
                    CupertinoFormRow(
                      prefix: const Text('Balance'),
                      child: CupertinoTextFormFieldRow(
                        keyboardType: TextInputType.number,
                        maxLength: 5,
                        readOnly: true,
                        enableInteractiveSelection: false,
                        controller: balanceAmountController,
                        textInputAction: TextInputAction.next,
                        placeholder: 'Balance Amount',
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (totalAmount) {
                          if (totalAmount == null || totalAmount.isEmpty) {
                            return 'Enter Total Amount & Advance Amount';
                          } else {
                            return null;
                          }
                        },
                      ),
                    ),
                  ]),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed: isLoading
                      ? null
                      : () async {
                          setState(() {
                            isLoading = true;
                          });
                          final form = formKey.currentState!;
                          if (form.validate()) {
                            String studentId = studentIdController.text;
                            String fullName = fullNameController.text;
                            String guardianName = guardianNameController.text;
                            String dob = dobController.text;
                            String mobileNumber = mobileNumberController.text;
                            String emergencyNumber =
                                emergencyNumberController.text;
                            String bloodGroup = bloodGroupController.text;
                            String house = houseController.text;
                            String place = placeController.text;
                            String post = postController.text;
                            String district = districtController.text;
                            String pin = pinController.text;
                            String license = licenseController.text;
                            String totalAmount = totalAmountController.text;
                            String advanceAmount = advanceAmountController.text;
                            String secondInstallment =
                                secondInstallmentController.text;
                            String thirdInstallment =
                                thirdInstallmentController.text;
                            String balanceAmount = balanceAmountController.text;
                            String cov = covController.text;

                            Map<String, dynamic> licenseonly = {
                              'studentId': studentId,
                              'fullName': fullName,
                              'guardianName': guardianName,
                              'dob': dob,
                              'mobileNumber': mobileNumber,
                              'emergencyNumber': emergencyNumber,
                              'bloodGroup': bloodGroup,
                              'house': house,
                              'place': place,
                              'post': post,
                              'district': district,
                              'pin': pin,
                              'license': license,
                              'totalAmount': totalAmount,
                              'advanceAmount': advanceAmount,
                              'secondInstallment': secondInstallment,
                              'thirdInstallment': thirdInstallment,
                              'balanceAmount': balanceAmount,
                              'cov': cov,
                            };

                            // Get the Firestore instance and the current user
                            var firestore = FirebaseFirestore.instance;
                            User? user = FirebaseAuth.instance.currentUser;
                            // Check if a new image is selected
                            bool isNewImageSelected = _image != null;
                            // Get the existing image URL
                            String existingImage =
                                widget.initialValues['image'];
                            // Update the Licence Only Details in Firestore
                            try {
                              await firestore
                                  .collection('users')
                                  .doc(user?.uid)
                                  .collection('licenseonly')
                                  .doc(licenseonly['studentId'])
                                  .set(licenseonly);

                              // Upload image to Firebase Storage only if a new image is selected
                              if (isNewImageSelected) {
                                String imagePath =
                                    'images/${user?.uid}/${licenseonly['studentId']}.png';
                                Reference storageReference = FirebaseStorage
                                    .instance
                                    .ref()
                                    .child(imagePath);
                                UploadTask uploadTask =
                                    storageReference.putFile(_image!);

                                await uploadTask.whenComplete(
                                  () async {
                                    // Get the download URL
                                    String image =
                                        await storageReference.getDownloadURL();
                                    // Update the image URL in Firestore
                                    await firestore
                                        .collection('users')
                                        .doc(user?.uid)
                                        .collection('licenseonly')
                                        .doc(licenseonly['studentId'])
                                        .update({'image': image});
                                  },
                                );
                              } else {
                                // Retain the existing image URL in Firestore
                                await firestore
                                    .collection('users')
                                    .doc(user?.uid)
                                    .collection('licenseonly')
                                    .doc(licenseonly['studentId'])
                                    .update({'image': existingImage});
                              }
                              // Handle the update success
                              Fluttertoast.showToast(
                                msg: 'Updated Successfully',
                                fontSize: 18,
                              );

                              // Close the form
                              Navigator.pop(context);
                            } catch (e) {
                              print('Error updating Firestore: $e');
                              // Handle the error as needed (e.g., show an error message)
                            }
                          }
                        },
                  child: isLoading
                      ? const CupertinoActivityIndicator()
                      : const Text('Update'),
                ),
              )
            ],
          ),
        ),
      );

  Widget buildPicker() => SizedBox(
        height: 350,
        child: StatefulBuilder(
          builder: (context, setState) => CupertinoPicker(
            scrollController: scrollController,
            looping: false,
            itemExtent: 64,
            children: List.generate(widget.items.length, (index) {
              final isSelected = widget.index == index;
              final item = widget.items[index];
              final color = isSelected
                  ? CupertinoColors.activeBlue
                  : CupertinoColors.black;
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
                print('Selected Item: $item');
              });
            },
          ),
        ),
      );
}
