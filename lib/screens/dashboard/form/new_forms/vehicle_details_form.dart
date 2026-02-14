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
  String selectedService = 'Transfer of Ownership';
  String selectedPaymentMode = 'Cash';
  final WorkspaceController _workspaceController =
      Get.find<WorkspaceController>();

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final fullNameController = TextEditingController();
    final mobileNumberController = TextEditingController();
    final houseNameController = TextEditingController();
    final placeController = TextEditingController();
    final postController = TextEditingController();
    final districtController = TextEditingController();
    final pinController = TextEditingController();
    final vehicleNumberController = TextEditingController();
    final vehicleModelController = TextEditingController();
    final chassisNumberController = TextEditingController();
    final engineNumberController = TextEditingController();
    final totalAmountController = TextEditingController();
    final advanceAmountController = TextEditingController();
    final balanceAmountController = TextEditingController();
    final otherServiceController = TextEditingController();

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
                      if (formKey.currentState!.validate()) {
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
                          final serviceType = selectedService == 'Other'
                              ? otherServiceController.text
                              : selectedService;
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
                            'cov': serviceType,
                            'totalAmount': totalAmountController.text,
                            'advanceAmount': advanceAmountController.text,
                            'balanceAmount': balanceAmountController.text,
                            'registrationDate':
                                DateTime.now().toIso8601String(),
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
                              double.tryParse(advanceAmountController.text) ??
                                  0;
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
                      ),
                      FormTextField(
                        label: 'Vehicle Model',
                        controller: vehicleModelController,
                        placeholder: 'Enter Vehicle Model',
                      ),
                      FormTextField(
                        label: 'Chassis Number',
                        controller: chassisNumberController,
                        placeholder: 'Enter Chassis Number',
                      ),
                      FormTextField(
                        label: 'Engine Number',
                        controller: engineNumberController,
                        placeholder: 'Enter Engine Number',
                      ),
                      DropdownButtonFormField<String>(
                        value: selectedService,
                        decoration: const InputDecoration(
                          labelText: 'Service Type',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          'Transfer of Ownership',
                          'Address Change',
                          'Hypothecation Cancellation',
                          'Hypothecation Addition',
                          'Fitness Certificate',
                          'Tax',
                          'Insurance',
                          'Fresh Permit',
                          'Permit Renewal',
                          'Registration Renewal',
                          'Other'
                        ].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedService = newValue;
                            });
                          }
                        },
                      ),
                      if (selectedService == 'Other')
                        FormTextField(
                          label: 'Specify Service',
                          controller: otherServiceController,
                          placeholder: 'Enter Service Type',
                          validator: (v) =>
                              v!.isEmpty ? 'Please specify service' : null,
                        ),
                    ],
                  ),
                  if (selectedService == 'Transfer of Ownership' ||
                      selectedService == 'Address Change')
                    FormSection(
                      title: 'Address',
                      children: [
                        FormTextField(
                          label: 'House Name',
                          controller: houseNameController,
                          placeholder: 'Enter House Name',
                        ),
                        FormTextField(
                          label: 'Place',
                          controller: placeController,
                          placeholder: 'Enter Place',
                        ),
                        FormTextField(
                          label: 'Post',
                          controller: postController,
                          placeholder: 'Enter Post Office',
                        ),
                        FormTextField(
                          label: 'District',
                          controller: districtController,
                          placeholder: 'Enter District',
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
}
