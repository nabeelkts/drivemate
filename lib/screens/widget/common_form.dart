/* lib/screens/widget/common_form.dart */
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/screens/authentication/widgets/my_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:mds/utils/date_utils.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:mds/services/storage_service.dart';
import 'package:mds/services/ocr_service.dart';

// ignore: must_be_immutable
class CommonForm extends StatefulWidget {
  final List<String> items;
  final int index;
  final bool showLicenseField;
  final bool showServiceType;
  final Map<String, dynamic>? initialValues;
  final Future<void> Function(Map<String, dynamic>) onFormSubmit;
  final VoidCallback? onSubmitPressed;

  const CommonForm({
    super.key,
    required this.items,
    required this.index,
    required this.showLicenseField,
    this.showServiceType = false,
    this.initialValues,
    required this.onFormSubmit,
    this.onSubmitPressed,
  });

  @override
  State<CommonForm> createState() => CommonFormState();
}

class CommonFormState extends State<CommonForm> {
  final formKey = GlobalKey<FormState>();
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
  late TextEditingController balanceAmountController;
  late TextEditingController covController;
  late TextEditingController otherServiceController;
  late FixedExtentScrollController scrollController;
  XFile? _pickedFile;
  String imageUrl = '';
  bool isLoading = false;
  late int _currentIndex;
  String _selectedPaymentMode = 'Cash';
  String? _selectedBloodGroup;

  final StorageService _storageService = StorageService();
  final OCRService _ocrService = OCRService();
  final List<String> _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-'
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.index;
    scrollController = FixedExtentScrollController(initialItem: _currentIndex);

    // Initialize all controllers
    studentIdController = TextEditingController();
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
    covController = TextEditingController();
    otherServiceController = TextEditingController();

    // Initialize values
    _initializeControllers();

    // Add listeners for balance calculation and UI updates
    totalAmountController.addListener(_calculateBalance);
    advanceAmountController.addListener(_calculateBalance);
    fullNameController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  void _initializeControllers() {
    studentIdController = TextEditingController(
        text: widget.initialValues?['studentId']?.toString() ?? '');
    fullNameController = TextEditingController(
        text: widget.initialValues?['fullName']?.toString() ?? '');
    guardianNameController = TextEditingController(
        text: widget.initialValues?['guardianName']?.toString() ?? '');

    // Initialize DOB directly from Firestore
    dobController = TextEditingController(
        text: AppDateUtils.formatDateForDisplay(
            widget.initialValues?['dob']?.toString()));

    mobileNumberController = TextEditingController(
        text: widget.initialValues?['mobileNumber']?.toString() ?? '');
    emergencyNumberController = TextEditingController(
        text: widget.initialValues?['emergencyNumber']?.toString() ?? '');
    bloodGroupController = TextEditingController(
        text: widget.initialValues?['bloodGroup']?.toString() ?? '');
    if (bloodGroupController.text.isNotEmpty &&
        _bloodGroups.contains(bloodGroupController.text)) {
      _selectedBloodGroup = bloodGroupController.text;
    }
    houseNameController = TextEditingController(
        text: widget.initialValues?['house']?.toString() ?? '');
    placeController = TextEditingController(
        text: widget.initialValues?['place']?.toString() ?? '');
    postController = TextEditingController(
        text: widget.initialValues?['post']?.toString() ?? '');
    districtController = TextEditingController(
        text: widget.initialValues?['district']?.toString() ?? '');
    pinController = TextEditingController(
        text: widget.initialValues?['pin']?.toString() ?? '');
    licenseController = TextEditingController(
        text: widget.initialValues?['license']?.toString() ?? '');
    totalAmountController = TextEditingController(
        text: widget.initialValues?['totalAmount']?.toString() ?? '');
    advanceAmountController = TextEditingController(
        text: widget.initialValues?['advanceAmount']?.toString() ?? '');
    balanceAmountController = TextEditingController(
        text: widget.initialValues?['balanceAmount']?.toString() ?? '');
    covController = TextEditingController(
        text: widget.initialValues?['cov']?.toString() ??
            widget.initialValues?['serviceType']?.toString() ??
            '');
    otherServiceController = TextEditingController(
        text: widget.initialValues?['otherService']?.toString() ?? '');
    if (covController.text.isEmpty || covController.text == 'null') {
      covController.text = 'Select your cov';
    }

    final initItem = widget.items.indexOf(widget.initialValues?['cov'] ?? '');
    scrollController = FixedExtentScrollController(
        initialItem: initItem >= 0 ? initItem : widget.index);
  }

  void _calculateBalance() {
    final totalAmount = double.tryParse(totalAmountController.text) ?? 0.0;
    final advanceAmount = double.tryParse(advanceAmountController.text) ?? 0.0;
    final balanceAmount = max(0.0, totalAmount - advanceAmount);
    setState(() {
      balanceAmountController.text = balanceAmount.toString();
    });
  }

  Future<void> _getImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _pickedFile = image;
      });
    }
  }

  Future<void> _getImageFromCamera() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _pickedFile = image;
      });
    }
  }

  Future<void> smartFill() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await showDialog<XFile?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Smart Fill'),
        content: const Text('Choose a document image to auto-fill details'),
        actions: [
          TextButton(
            child: const Text('Gallery'),
            onPressed: () async {
              final XFile? img =
                  await picker.pickImage(source: ImageSource.gallery);
              if (context.mounted) Navigator.pop(context, img);
            },
          ),
          TextButton(
            child: const Text('Camera'),
            onPressed: () async {
              final XFile? img =
                  await picker.pickImage(source: ImageSource.camera);
              if (context.mounted) Navigator.pop(context, img);
            },
          ),
        ],
      ),
    );

    if (image == null) return;

    setState(() => isLoading = true);

    try {
      final results = await _ocrService.parseDocument(image);

      if (results.containsKey('fullName'))
        fullNameController.text = results['fullName']!;
      if (results.containsKey('guardianName'))
        guardianNameController.text = results['guardianName']!;
      if (results.containsKey('dob')) dobController.text = results['dob']!;
      if (results.containsKey('pin')) pinController.text = results['pin']!;
      if (results.containsKey('house'))
        houseNameController.text = results['house']!;
      if (results.containsKey('place'))
        placeController.text = results['place']!;
      if (results.containsKey('post')) postController.text = results['post']!;
      if (results.containsKey('district'))
        districtController.text = results['district']!;

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Verify Details'),
            content: const Text(
                'Details have been auto-filled from the document. Please verify and correct if necessary.'),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) print('OCR Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to parse document: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<String> uploadImage() async {
    if (_pickedFile == null) {
      return widget.initialValues?['image'] ?? '';
    }
    return _storageService.uploadStudentImage(_pickedFile!);
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
    balanceAmountController.dispose();
    covController.dispose();
    otherServiceController.dispose();
    scrollController.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  // Public method to submit the form - can be called from parent via GlobalKey
  Future<void> submitForm() async {
    if (!formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }
    if (covController.text.trim().isEmpty ||
        covController.text.trim() == 'Select your cov') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(widget.showServiceType
                ? 'Please select a service'
                : 'Please select class of vehicle')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Upload image first if picked
      final String uploadedImageUrl = await uploadImage();
      setState(() {
        imageUrl = uploadedImageUrl;
      });

      // Calculate balance amount
      final totalAmount = double.tryParse(totalAmountController.text) ?? 0.0;
      final advanceAmount =
          double.tryParse(advanceAmountController.text) ?? 0.0;
      final balanceAmount = totalAmount - advanceAmount;
      balanceAmountController.text = balanceAmount.toString();

      if (kDebugMode) {
        print('Form validation passed');
        print('Full Name: ${fullNameController.text}');
        print('COV: ${covController.text}');
      }

      Map<String, dynamic> student = {
        'studentId': studentIdController.text,
        'fullName': fullNameController.text,
        'guardianName': guardianNameController.text,
        'dob': AppDateUtils.formatDateForStorage(dobController.text),
        'mobileNumber': mobileNumberController.text,
        'emergencyNumber': emergencyNumberController.text.trim().isEmpty
            ? null
            : emergencyNumberController.text.trim(),
        'bloodGroup': bloodGroupController.text,
        'house': houseNameController.text,
        'place': placeController.text,
        'post': postController.text,
        'district': districtController.text,
        'pin': pinController.text,
        'license': licenseController.text,
        'totalAmount': totalAmount,
        'advanceAmount': advanceAmount,
        'balanceAmount': balanceAmount,
        'paymentMode': _selectedPaymentMode,
        'cov': covController.text,
        'serviceType': widget.showServiceType ? covController.text : null,
        'otherService': widget.showServiceType && covController.text == 'Other'
            ? otherServiceController.text
            : null,
        'image': uploadedImageUrl,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };

      if (kDebugMode) {
        print('Submitting student data:');
        print('Student ID: ${student['studentId']}');
        print('Full Name: ${student['fullName']}');
        print('COV: ${student['cov']}');
        print('Image URL: ${student['image']}');
        print('DOB: ${student['dob']}');
      }

      await widget.onFormSubmit(student);
    } catch (e) {
      if (kDebugMode) {
        print('Error in form submission: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    // ignore: unused_local_variable
    final backgroundColor = theme.cardColor;

    return Stack(
      children: [
        AbsorbPointer(
          absorbing: isLoading,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  buildProfileImageSection(),
                  buildPersonalDetailsSection(),
                  if (widget.showServiceType)
                    buildServiceTypeSection()
                  else
                    buildClassOfVehicleSection(),
                  buildSection('Address', [
                    buildTextField('House', houseNameController,
                        'Enter House Name', textColor),
                    buildTextField(
                        'Place', placeController, 'Enter Place', textColor),
                    buildTextField(
                        'Post', postController, 'Enter Post Office', textColor),
                    buildTextField('District', districtController,
                        'Enter District Name', textColor),
                    buildTextField(
                        'Pin', pinController, 'Enter Pin Code', textColor,
                        keyboardType: TextInputType.number),
                  ]),
                  buildSection('Fees', [
                    buildTextField('Total', totalAmountController,
                        'Enter Total Amount', textColor,
                        keyboardType: TextInputType.number),
                    buildTextField('Advance', advanceAmountController,
                        'Enter Advance Amount', textColor,
                        keyboardType: TextInputType.number),
                    buildTextField('Balance', balanceAmountController,
                        'Balance Amount', textColor,
                        readOnly: true),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: DropdownButtonFormField<String>(
                        value: _selectedPaymentMode,
                        decoration: InputDecoration(
                          labelText: 'Payment Mode (for Advance)',
                          labelStyle:
                              TextStyle(color: textColor.withOpacity(0.7)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        dropdownColor: Theme.of(context).cardColor,
                        style: TextStyle(color: textColor),
                        items: [
                          'Cash',
                          'GPay',
                          'PhonePe',
                          'Paytm',
                          'Bank Transfer',
                          'Other'
                        ]
                            .map((mode) => DropdownMenuItem(
                                value: mode,
                                child: Text(mode,
                                    style: TextStyle(color: textColor))))
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedPaymentMode = val!;
                          });
                        },
                      ),
                    ),
                  ]),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Submitting...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget buildPersonalDetailsSection() {
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    return buildSection('Personal Details', [
      buildTextField(
          'Full Name', fullNameController, 'Enter Full Name', textColor),
      buildTextField('Guardian Name', guardianNameController,
          'Enter Guardian Name', textColor),
      buildDateField('DOB', dobController, 'DD-MM-YYYY', textColor,
          lastDate: AppDateUtils.dobLastDate),
      buildTextField('Mobile Number', mobileNumberController,
          'Enter Mobile Number', textColor,
          keyboardType: TextInputType.number),
      buildTextField('Emergency Number', emergencyNumberController,
          '(Optional)', textColor,
          keyboardType: TextInputType.number),
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: DropdownButtonFormField<String>(
          value: _selectedBloodGroup,
          decoration: InputDecoration(
            labelText: 'Blood Group',
            labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          dropdownColor: Theme.of(context).cardColor,
          icon: Icon(Icons.keyboard_arrow_down, color: textColor),
          style: TextStyle(color: textColor),
          items: _bloodGroups
              .map((bg) => DropdownMenuItem(
                    value: bg,
                    child: Text(bg, style: TextStyle(color: textColor)),
                  ))
              .toList(),
          onChanged: (val) {
            setState(() {
              _selectedBloodGroup = val;
              bloodGroupController.text = val ?? '';
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a blood group';
            }
            return null;
          },
        ),
      ),
      if (widget.showLicenseField)
        buildTextField(
            'License Number', licenseController, 'KL102023000123', textColor),
    ]);
  }

  Widget buildClassOfVehicleSection() {
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
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
            scrollController =
                FixedExtentScrollController(initialItem: _currentIndex);
            showCupertinoModalPopup(
              context: context,
              builder: (context) => CupertinoActionSheet(
                actions: [buildPicker()],
                cancelButton: CupertinoActionSheetAction(
                  child: const Text('Select'),
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

  Widget buildServiceTypeSection() {
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    // Ensure specific logic for "Other"
    bool isOtherSelected = covController.text == 'Other';

    return buildSectionContainer(
      children: [
        Text(
          'Service Type',
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
            scrollController =
                FixedExtentScrollController(initialItem: _currentIndex);
            showCupertinoModalPopup(
              context: context,
              builder: (context) => CupertinoActionSheet(
                actions: [buildPicker()],
                cancelButton: CupertinoActionSheetAction(
                  child: const Text('Select'),
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
        if (isOtherSelected) ...[
          const SizedBox(height: 10),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Specify Service',
              labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            style: TextStyle(color: textColor),
            onChanged: (value) {
              // You might need a way to pass this back up if it's not in the main controller list
              // For now, let's assume we might need a controller for this if we want to save it cleanly
              // specific handling for Other field saving in main submit
              // But CommonForm structure is rigid.
              // Let's add 'otherService' to the map in submit if needed,
              // but we need a controller for it.
            },
            // We need a controller for this.
            // Let's add `otherServiceController` to CommonForm state.
            controller: otherServiceController,
          ),
        ]
      ],
    );
  }

  Widget buildTextField(String label, TextEditingController controller,
      String placeholder, Color? textColor,
      {TextInputType keyboardType = TextInputType.text,
      bool readOnly = false}) {
    List<TextInputFormatter> formatters = [];
    TextCapitalization capitalization = TextCapitalization.none;
    final normalizedLabel = label.toLowerCase();

    if (normalizedLabel.contains('mobile') ||
        normalizedLabel.contains('emergency') ||
        normalizedLabel.contains('phone')) {
      formatters.add(LengthLimitingTextInputFormatter(10));
      keyboardType = TextInputType.phone;
    } else if (normalizedLabel.contains('pin')) {
      formatters.add(LengthLimitingTextInputFormatter(6));
      keyboardType = TextInputType.number;
    } else if (keyboardType == TextInputType.text) {
      capitalization = TextCapitalization.words;
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: (textColor ?? Colors.black).withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: textColor ?? Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration.collapsed(
                    hintText: placeholder,
                    hintStyle: TextStyle(
                      color: (textColor ?? Colors.black).withOpacity(0.3),
                      fontSize: 16,
                    ),
                  ),
                  keyboardType: keyboardType,
                  readOnly: readOnly,
                  textCapitalization: capitalization,
                  inputFormatters: formatters,
                  onChanged: (value) {
                    setState(() {}); // Rebuild to update checkmark
                  },
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (normalizedLabel.contains('emergency')) {
                      if (v.isEmpty) return null;
                      if (!RegExp(r'^\d{10}$').hasMatch(v)) {
                        return 'Invalid number';
                      }
                      return null;
                    }
                    if (normalizedLabel.contains('mobile') ||
                        normalizedLabel.contains('phone')) {
                      if (!RegExp(r'^\d{10}$').hasMatch(v)) {
                        return 'Invalid number';
                      }
                      return null;
                    }
                    if (normalizedLabel.contains('pin')) {
                      if (!RegExp(r'^\d{6}$').hasMatch(v)) {
                        return 'Invalid PIN';
                      }
                      return null;
                    }
                    if (v.isEmpty) return 'Required';
                    return null;
                  },
                ),
              ),
              if (controller.text.isNotEmpty && !readOnly)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.check,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
        Divider(
          height: 1,
          color: Colors.white.withOpacity(0.1),
        ),
      ],
    );
  }

  Widget buildSection(String title, List<Widget> children) {
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    return buildSectionContainer(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 10),
        ...children,
      ],
    );
  }

  Widget buildDateField(String label, TextEditingController controller,
      String placeholder, Color? textColor,
      {DateTime? firstDate, DateTime? lastDate}) {
    return Column(
      children: [
        InkWell(
          onTap: () async {
            final DateTime pickerFirstDate =
                firstDate ?? AppDateUtils.firstDate;
            final DateTime pickerLastDate = lastDate ?? AppDateUtils.lastDate;

            DateTime initialDate =
                AppDateUtils.parseDisplayDate(controller.text);

            if (initialDate.isBefore(pickerFirstDate)) {
              initialDate = pickerFirstDate;
            } else if (initialDate.isAfter(pickerLastDate)) {
              initialDate = pickerLastDate;
            }

            final date = await showDatePicker(
              context: context,
              initialDate: initialDate,
              firstDate: pickerFirstDate,
              lastDate: pickerLastDate,
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.fromSeed(
                      seedColor: Theme.of(context).primaryColor,
                      brightness: Theme.of(context).brightness,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (date != null) {
              setState(() {
                controller.text = DateFormat('dd-MM-yyyy').format(date);
              });
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: (textColor ?? Colors.black).withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  controller.text.isEmpty ? placeholder : controller.text,
                  style: TextStyle(
                    color: controller.text.isEmpty
                        ? (textColor ?? Colors.black).withOpacity(0.3)
                        : textColor ?? Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (controller.text.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.check,
                      color: Colors.green,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
        Divider(
          height: 1,
          color: Colors.white.withOpacity(0.1),
        ),
      ],
    );
  }

  Widget buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'New Student',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Scan document or fill manually',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildProfileImageSection() {
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    return Container(
      margin: const EdgeInsets.all(12),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: const Color(0xFF2C2C2C),
                builder: (BuildContext context) {
                  return SafeArea(
                    child: Wrap(
                      children: <Widget>[
                        ListTile(
                          leading: const Icon(Icons.photo_library,
                              color: Colors.white),
                          title: const Text('Photo Library',
                              style: TextStyle(color: Colors.white)),
                          onTap: () {
                            _getImageFromGallery();
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.photo_camera,
                              color: Colors.white),
                          title: const Text('Camera',
                              style: TextStyle(color: Colors.white)),
                          onTap: () {
                            _getImageFromCamera();
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: kPrimaryColor,
                  child: _pickedFile != null
                      ? ClipOval(
                          child: Image.file(
                            File(_pickedFile!.path),
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        )
                      : (widget.initialValues?['image'] != null &&
                              (widget.initialValues?['image'] as String)
                                  .isNotEmpty)
                          ? ClipOval(
                              child: Image(
                                image: CachedNetworkImageProvider(
                                  widget.initialValues?['image'] as String,
                                ),
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Center(
                              child: Text(
                                fullNameController.text.isNotEmpty
                                    ? fullNameController.text[0].toUpperCase()
                                    : '',
                                style: const TextStyle(
                                  fontSize: 48,
                                  color: kWhite,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: kPrimaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_pickedFile != null) ...[
            const SizedBox(height: 12),
            Text(
              'Selected image will be uploaded with form.',
              style: TextStyle(
                color: textColor.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ],
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
              final isSelected = _currentIndex == index;
              final item = widget.items[index];
              final color = isSelected
                  ? CupertinoColors.activeBlue
                  : Theme.of(context).textTheme.bodyLarge?.color ??
                      CupertinoColors.black;
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
                _currentIndex = index;
                final item = widget.items[index];
                covController.text = item;
              });
            },
          ),
        ),
      );

  Widget buildSectionContainer({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD32F2F).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Future<void> updateFirestore(Map<String, dynamic> updatedStudent) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final studentId = widget.initialValues?['studentId'];
      if (studentId == null || studentId.toString().isEmpty) {
        throw Exception('Student ID is required');
      }

      // Convert numeric fields to proper types
      if (updatedStudent['totalAmount'] != null) {
        updatedStudent['totalAmount'] =
            double.tryParse(updatedStudent['totalAmount'].toString()) ?? 0.0;
      }
      if (updatedStudent['advanceAmount'] != null) {
        updatedStudent['advanceAmount'] =
            double.tryParse(updatedStudent['advanceAmount'].toString()) ?? 0.0;
      }
      if (updatedStudent['balanceAmount'] != null) {
        updatedStudent['balanceAmount'] =
            double.tryParse(updatedStudent['balanceAmount'].toString()) ?? 0.0;
      }

      if (kDebugMode) {
        print('Updating Firestore document:');
        print('User ID: ${user.uid}');
        print('Student ID: $studentId');
        print('Updated data: $updatedStudent');
      }

      // Update the student document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
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
}
