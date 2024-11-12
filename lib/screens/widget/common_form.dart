import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

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
  late TextEditingController balanceAmountController;

  late TextEditingController covController;
  late FixedExtentScrollController scrollController;
  late TextEditingController studentIdController;

  final formKey = GlobalKey<FormState>();
  String imageUrl = '';
  File? _image;
  Future<void> _getImageFromGallery() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      // Crop the image
      // final croppedFile = await _cropImage(imageFile);

      // Compress the image before setting it to _image
      final compressedImage = await compressImage(imageFile);

      setState(() {
        _image = compressedImage;
      });
    }
  }

  Future<void> _getImageFromCamera() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
    );

    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);

      // Compress the image before setting it to _image
      final compressedImage = await compressImage(imageFile);

      setState(() {
        _image = compressedImage;
      });
    }
  }

  Future<File> compressImage(File imageFile) async {
    final decodedImage = img.decodeImage(await imageFile.readAsBytes());

    // Compress the image to a specific width
    final compressedImage = img.copyResize(decodedImage!, width: 800);

    final compressedImageFile = File(imageFile.path)
      ..writeAsBytesSync(img.encodeJpg(compressedImage));

    return compressedImageFile;
  }

  @override
  void initState() {
    super.initState();
    fullNameController = TextEditingController();
    guardianNameController = TextEditingController();
    dobController = TextEditingController();
    mobileNumberController = TextEditingController();
    emergencyNumberController = TextEditingController();
    bloodGroupController = TextEditingController();
    houseController = TextEditingController();
    placeController = TextEditingController();
    postController = TextEditingController();
    districtController = TextEditingController();
    pinController = TextEditingController();
    licenseController = TextEditingController();

    covController = TextEditingController(text: widget.items[widget.index]);
    scrollController = FixedExtentScrollController(initialItem: widget.index);
    totalAmountController = TextEditingController();
    advanceAmountController = TextEditingController();
    balanceAmountController = TextEditingController();
    totalAmountController.addListener(updateBalanceAmount);
    advanceAmountController.addListener(updateBalanceAmount);
    studentIdController =
        TextEditingController(text: generateRandomStudentID());
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

  void formatDOB(String input) {
    String numericInput = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (numericInput.length > 8) {
      numericInput = numericInput.substring(0, 8);
    }

    String formattedDOB = '';
    for (int i = 0; i < numericInput.length; i++) {
      if (i == 2 || i == 4) {
        formattedDOB += '-';
      }
      formattedDOB += numericInput[i];
    }

    dobController.value = TextEditingValue(
      text: formattedDOB,
      selection: TextSelection.fromPosition(
        TextPosition(offset: formattedDOB.length),
      ),
    );
  }

  @override
  void dispose() {
    covController.dispose();
    scrollController.dispose();
    studentIdController.dispose();
    super.dispose();
  }

  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');

  @override
  Widget build(BuildContext context) => Form(
        key: formKey,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            CupertinoFormSection.insetGrouped(
              margin: const EdgeInsets.all(12),
              children: [
                CupertinoFormRow(
                  prefix: const Text('Student ID'),
                  child: CupertinoTextFormFieldRow(
                    readOnly: true,
                    controller: studentIdController,
                  ),
                ),
              ],
            ),
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
                        child: Column(
                          children: [
                            const Icon(Icons.image),
                            const SizedBox(height: 4),
                            const Text('Gallery'),
                          ],
                        ),
                      ),
                      CupertinoButton(
                        onPressed: _getImageFromCamera,
                        child: Column(
                          children: [
                            const Icon(Icons.camera_alt),
                            const SizedBox(height: 4),
                            const Text('Camera'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_image != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: Image.file(_image!),
                  ),
              ],
            ),
            CupertinoFormSection.insetGrouped(
              margin: const EdgeInsets.all(12),
              header: const Text(
                'Personal Details',
                style: TextStyle(fontSize: 16),
              ),
              children: [
                CupertinoFormRow(
                  prefix: const Text('Full Name'),
                  child: CupertinoTextFormFieldRow(
                    textCapitalization: TextCapitalization.words,
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
                    textCapitalization: TextCapitalization.words,
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
                  prefix: const Text('Date of Birth'),
                  child: CupertinoTextFormFieldRow(
                    textInputAction: TextInputAction.next,
                    placeholder: 'DD-MM-YYYY',
                    controller: dobController,
                    keyboardType: const TextInputType.numberWithOptions(),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (dob) {
                      if (dob == null || dob.isEmpty) {
                        return 'Enter Date of Birth';
                      } else if (dob.length < 10) {
                        return 'Must be a Valid Date of Birth';
                      } else {
                        return null;
                      }
                    },
                    onChanged: (value) {
                      formatDOB(value);
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
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    maxLength: 10,
                    placeholder: 'Blood Group',
                    controller: bloodGroupController,
                  ),
                ),
              ],
            ),
            if (widget.showLicenseField)
              CupertinoFormRow(
                prefix: const Text('License Number'),
                child: CupertinoTextFormFieldRow(
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.next,
                  maxLength: 14,
                  placeholder: 'KL102023000123 ',
                  controller: licenseController,
                ),
              ),
            CupertinoFormSection.insetGrouped(
              margin: const EdgeInsets.all(12),
              header: const Text(
                'Class of Vehicle',
                style: TextStyle(fontSize: 16),
              ),
              children: [
                CupertinoFormRow(
                  padding: EdgeInsets.all(8),
                  child: Center(
                    child: CupertinoTextField(
                      onTap: () {
                        scrollController.dispose();
                        scrollController = FixedExtentScrollController(
                            initialItem: widget.index);
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
                    textCapitalization: TextCapitalization.words,
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
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    placeholder: 'Place',
                    controller: placeController,
                  ),
                ),
                CupertinoFormRow(
                  prefix: const Text('Post'),
                  child: CupertinoTextFormFieldRow(
                    textCapitalization: TextCapitalization.words,
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
                    textCapitalization: TextCapitalization.words,
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
              ],
            ),
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
                child: isLoading
                    ? CupertinoActivityIndicator()
                    : const Text('Submit'),
                onPressed: isLoading
                    ? null
                    : () async {
                        setState(() {
                          isLoading = true;
                        });
                        // Validate the form
                        if (formKey.currentState?.validate() != true) {
                          // Form validation failed, do not proceed with submission
                          setState(() {
                            isLoading = false;
                          });
                          return;
                        }
                        try {
                          if (_image != null) {
                            // If an image is already selected, upload it to Firebase Storage
                            String uniqueFileName = DateTime.now()
                                .millisecondsSinceEpoch
                                .toString();
                            Reference referenceRoot =
                                FirebaseStorage.instance.ref();
                            Reference referenceDirImages =
                                referenceRoot.child('images');
                            Reference referenceImageToUpload =
                                referenceDirImages.child(uniqueFileName);

                            List<int> imageBytes =
                                await File(_image!.path).readAsBytes();
                            Uint8List uint8List =
                                Uint8List.fromList(imageBytes);
                            await referenceImageToUpload.putData(uint8List);

                            // Get the image download URL
                            imageUrl =
                                await referenceImageToUpload.getDownloadURL();
                          }
                        } catch (error) {
                          // Handle the error
                          print('Error uploading image: $error');
                        }

                        // Now, you can submit the form data to Firebase Database
                        String studentId = studentIdController.text;
                        String fullName = fullNameController.text;
                        String guardianName = guardianNameController.text;
                        String dob = dobController.text;
                        String mobileNumber = mobileNumberController.text;
                        String emergencyNumber = emergencyNumberController.text;
                        String bloodGroup = bloodGroupController.text;
                        String house = houseController.text;
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
                          'house': house,
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

                        Map<String, dynamic> licenseOnly = {
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
                          'balanceAmount': balanceAmount,
                          'cov': cov,
                          'image': imageUrl,
                        };
                        widget.onFormSubmit(licenseOnly);

                        Map<String, dynamic> endorsement = {
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
                          'balanceAmount': balanceAmount,
                          'cov': cov,
                          'image': imageUrl,
                        };
                        widget.onFormSubmit(endorsement);

                        setState(() {
                          isLoading = false;
                        });
                      },
              ),
            ),
            const SizedBox(
              height: 30,
            ),
          ],
        ),
      );
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
                ('Selected Item:$item');
              });
            },
          ),
        ),
      );
}
