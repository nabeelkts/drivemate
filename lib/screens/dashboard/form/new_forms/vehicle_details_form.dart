import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:mds/controller/workspace_controller.dart';
import 'package:mds/screens/dashboard/list/details/vehicle_details_page.dart';
import 'package:mds/screens/widget/base_form_widget.dart';
import 'package:mds/screens/widget/utils.dart';

class VehicleDetails extends StatefulWidget {
  const VehicleDetails({super.key});

  @override
  State<VehicleDetails> createState() => _VehicleDetailsState();
}

class _VehicleDetailsState extends State<VehicleDetails> {
  bool isLoading = false;
  List<String> selectedServices = [];
  String selectedPaymentMode = 'Cash';
  final WorkspaceController _workspaceController =
      Get.find<WorkspaceController>();

  // Move controllers to state level to preserve data during rebuilds
  late TextEditingController fullNameController;
  late TextEditingController mobileNumberController;
  late TextEditingController houseNameController;
  late TextEditingController placeController;
  late TextEditingController postController;
  late TextEditingController districtController;
  late TextEditingController pinController;
  late TextEditingController vehicleNumberController;
  late TextEditingController vehicleModelController;
  late TextEditingController chassisNumberController;
  late TextEditingController engineNumberController;
  late TextEditingController totalAmountController;
  late TextEditingController advanceAmountController;
  late TextEditingController balanceAmountController;
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Initialize controllers in initState
    fullNameController = TextEditingController();
    mobileNumberController = TextEditingController();
    houseNameController = TextEditingController();
    placeController = TextEditingController();
    postController = TextEditingController();
    districtController = TextEditingController();
    pinController = TextEditingController();
    vehicleNumberController = TextEditingController();
    vehicleModelController = TextEditingController();
    chassisNumberController = TextEditingController();
    engineNumberController = TextEditingController();
    totalAmountController = TextEditingController();
    advanceAmountController = TextEditingController();
    balanceAmountController = TextEditingController();
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    fullNameController.dispose();
    mobileNumberController.dispose();
    houseNameController.dispose();
    placeController.dispose();
    postController.dispose();
    districtController.dispose();
    pinController.dispose();
    vehicleNumberController.dispose();
    vehicleModelController.dispose();
    chassisNumberController.dispose();
    engineNumberController.dispose();
    totalAmountController.dispose();
    advanceAmountController.dispose();
    balanceAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        BaseFormWidget(
          title: 'Vehicle Details',
          onBack: () => Navigator.pop(context),
          actions: [
            IconButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      // Validate form fields first
                      if (!formKey.currentState!.validate()) {
                        return; // Don't proceed if form validation fails
                      }

                      // Check if at least one service type is selected
                      if (selectedServices.isEmpty) {
                        Fluttertoast.showToast(
                            msg: 'Please select at least one service type');
                        return;
                      }

                      setState(() {
                        isLoading = true;
                      });
                      bool navigated = false;
                      try {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) return;

                        final schoolId =
                            _workspaceController.currentSchoolId.value;
                        final targetId =
                            schoolId.isNotEmpty ? schoolId : user.uid;

                        final generatedId = await generateStudentId(targetId);
                        // Service types are now stored as array
                        final serviceTypes = selectedServices.isNotEmpty
                            ? selectedServices
                            : ['Transfer of Ownership'];
                        final data = {
                          'fullName': fullNameController.text,
                          'mobileNumber': mobileNumberController.text,
                          'houseName': houseNameController.text,
                          'place': placeController.text,
                          'post': postController.text,
                          'district': districtController.text,
                          'pin': pinController.text,
                          'vehicleNumber': vehicleNumberController.text,
                          'vehicleModel': vehicleModelController.text,
                          'chassisNumber': chassisNumberController.text,
                          'engineNumber': engineNumberController.text,
                          'serviceTypes': serviceTypes, // Array of services
                          'cov': serviceTypes
                              .join(', '), // For backward compatibility
                          'totalAmount': totalAmountController.text,
                          'advanceAmount': advanceAmountController.text,
                          'balanceAmount': balanceAmountController.text,
                          'registrationDate': DateTime.now().toIso8601String(),
                          'studentId': generatedId,
                        };

                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(targetId)
                            .collection('vehicleDetails')
                            .doc(generatedId)
                            .set(data);

                        // Record initial payment transaction if any
                        final advance =
                            double.tryParse(advanceAmountController.text) ?? 0;
                        if (advance > 0) {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(targetId)
                              .collection('vehicleDetails')
                              .doc(generatedId)
                              .collection('payments')
                              .add({
                            'amount': advance,
                            'mode': selectedPaymentMode,
                            'date': Timestamp.now(),
                            'description': 'Initial Advance',
                            'createdAt': FieldValue.serverTimestamp(),
                            'targetId': targetId,
                            'recordId': generatedId,
                            'recordName':
                                data['vehicleNumber'] ?? data['fullName'],
                            'category': 'vehicleDetails',
                          });
                        }

                        Fluttertoast.showToast(
                            msg: 'Vehicle details added successfully');
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                VehicleDetailsPage(vehicleDetails: data),
                          ),
                        );
                        navigated = true;
                      } catch (e) {
                        Fluttertoast.showToast(
                            msg: 'Error adding vehicle details: $e');
                      } finally {
                        if (!navigated && mounted) {
                          setState(() {
                            isLoading = false;
                          });
                        }
                      }
                    },
              icon: const Icon(Icons.check),
            ),
          ],
          children: [
            Form(
              key: formKey,
              child: Column(
                children: [
                  FormSection(
                    title: 'Personal Details',
                    children: [
                      FormTextField(
                        label: 'Full Name',
                        controller: fullNameController,
                        placeholder: 'Enter Full Name',
                        forceUppercase: true,
                      ),
                      FormTextField(
                        label: 'Mobile Number',
                        controller: mobileNumberController,
                        placeholder: 'Enter Mobile Number',
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                  FormSection(
                    title: 'Vehicle Details',
                    children: [
                      FormTextField(
                        label: 'Vehicle Number',
                        controller: vehicleNumberController,
                        placeholder: 'Enter Vehicle Number',
                        keyboardType: TextInputType.text,
                        forceUppercase: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vehicle number is required';
                          }
                          return null;
                        },
                      ),
                      FormTextField(
                        label: 'Vehicle Model',
                        controller: vehicleModelController,
                        placeholder: 'Enter Vehicle Model',
                        forceUppercase: true,
                      ),
                      FormTextField(
                        label: 'Chassis Number',
                        controller: chassisNumberController,
                        placeholder: 'Enter Chassis Number',
                        keyboardType: TextInputType.text,
                        forceUppercase: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Chassis number is required';
                          }
                          if (value.trim().length < 5) {
                            return 'Minimum 5 characters required';
                          }
                          return null;
                        },
                      ),
                      FormTextField(
                        label: 'Engine Number',
                        controller: engineNumberController,
                        placeholder: 'Enter Engine Number',
                        keyboardType: TextInputType.text,
                        forceUppercase: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Engine number is required';
                          }
                          if (value.trim().length < 5) {
                            return 'Minimum 5 characters required';
                          }
                          return null;
                        },
                      ),
                      InkWell(
                        onTap: () => _showServiceSelectionDialog(context),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Service Types',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.arrow_drop_down),
                          ),
                          child: Text(
                            selectedServices.isEmpty
                                ? 'Select Services'
                                : selectedServices.join(', '),
                            style: TextStyle(
                              color: selectedServices.isEmpty
                                  ? Colors.grey.shade600
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (selectedServices.contains('Transfer of Ownership') ||
                      selectedServices.contains('Address Change'))
                    FormSection(
                      title: 'Address',
                      children: [
                        FormTextField(
                          label: 'House Name',
                          controller: houseNameController,
                          placeholder: 'Enter House Name',
                          keyboardType: TextInputType.text,
                          forceUppercase: true,
                        ),
                        FormTextField(
                          label: 'Place',
                          controller: placeController,
                          placeholder: 'Enter Place',
                          keyboardType: TextInputType.text,
                          forceUppercase: true,
                        ),
                        FormTextField(
                          label: 'Post',
                          controller: postController,
                          placeholder: 'Enter Post Office',
                          keyboardType: TextInputType.text,
                          forceUppercase: true,
                        ),
                        FormTextField(
                          label: 'District',
                          controller: districtController,
                          placeholder: 'Enter District',
                          keyboardType: TextInputType.text,
                          forceUppercase: true,
                        ),
                        FormTextField(
                          label: 'PIN',
                          controller: pinController,
                          placeholder: 'Enter PIN Code',
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  FormSection(
                    title: 'Fees',
                    children: [
                      FormTextField(
                        label: 'Total Amount',
                        controller: totalAmountController,
                        placeholder: 'Enter Total Amount',
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          if (value.isNotEmpty &&
                              advanceAmountController.text.isNotEmpty) {
                            final total = double.tryParse(value) ?? 0;
                            final advance =
                                double.tryParse(advanceAmountController.text) ??
                                    0;
                            balanceAmountController.text =
                                (total - advance).toString();
                          }
                        },
                      ),
                      FormTextField(
                        label: 'Advance Amount',
                        controller: advanceAmountController,
                        placeholder: 'Enter Advance Amount',
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          if (value.isNotEmpty &&
                              totalAmountController.text.isNotEmpty) {
                            final total =
                                double.tryParse(totalAmountController.text) ??
                                    0;
                            final advance = double.tryParse(value) ?? 0;
                            balanceAmountController.text =
                                (total - advance).toString();
                          }
                        },
                      ),
                      FormTextField(
                        label: 'Balance Amount',
                        controller: balanceAmountController,
                        placeholder: 'Balance Amount',
                        readOnly: true,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedPaymentMode,
                        decoration: const InputDecoration(
                          labelText: 'Payment Mode (for Advance)',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          'Cash',
                          'GPay',
                          'PhonePe',
                          'Paytm',
                          'Bank Transfer',
                          'Other'
                        ]
                            .map((mode) => DropdownMenuItem(
                                value: mode, child: Text(mode)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              selectedPaymentMode = val;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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

  void _showServiceSelectionDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<String> availableServices = [
      'Transfer of Ownership',
      'Change of Address',
      'Hypothecation Termination',
      'Hypothecation Addition',
      'TO + HP Cancellation',
      'NOC',
      'FITNESS',
      'Fresh Permit',
      'Permit Renewal',
      'Registration Renewal',
      'RC CANCELLATION',
      'DUPLICATE RC',
      'CONVERSION',
      'ALTERATION',
      'WELFARE',
      'TAX',
      'GREENTAX',
      'CHECKPOST TAX',
      'POLLUTION',
      'INSURANCE',
      'Otherstate Conversion',
      'Echellan',
      'OTHER',
    ];

    List<String> tempSelected = List.from(selectedServices);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'Select Service Types',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: availableServices.map((service) {
                    final isSelected = tempSelected.contains(service);
                    return CheckboxListTile(
                      title: Text(
                        service,
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      value: isSelected,
                      activeColor: const Color(0xFFFF6B2C),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            tempSelected.add(service);
                          } else {
                            tempSelected.remove(service);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B2C),
                  ),
                  onPressed: () {
                    this.setState(() {
                      selectedServices = tempSelected;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Confirm',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
