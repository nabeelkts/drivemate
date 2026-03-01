import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mds/screens/dashboard/list/details/vehicle_details_page.dart';
import 'package:mds/screens/widget/base_form_widget.dart';
import 'package:get/get.dart';
import 'package:mds/controller/workspace_controller.dart';

class EditVehicleDetailsForm extends StatefulWidget {
  final Map<String, dynamic> initialValues;
  final List<String> items;

  const EditVehicleDetailsForm({
    required this.initialValues,
    required this.items,
    super.key,
  });

  @override
  State<EditVehicleDetailsForm> createState() => _EditVehicleDetailsFormState();
}

class _EditVehicleDetailsFormState extends State<EditVehicleDetailsForm> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController fullNameController;
  late final TextEditingController mobileNumberController;
  late final TextEditingController houseNameController;
  late final TextEditingController placeController;
  late final TextEditingController postController;
  late final TextEditingController districtController;
  late final TextEditingController pinController;
  late final TextEditingController vehicleNumberController;
  late final TextEditingController vehicleModelController;
  late final TextEditingController chassisNumberController;
  late final TextEditingController engineNumberController;
  late final TextEditingController totalAmountController;
  late final TextEditingController advanceAmountController;
  late final TextEditingController balanceAmountController;
  List<String> selectedServices = [];
  late final TextEditingController otherServiceController;

  @override
  void initState() {
    super.initState();
    final v = widget.initialValues;
    fullNameController =
        TextEditingController(text: v['fullName']?.toString() ?? '');
    mobileNumberController =
        TextEditingController(text: v['mobileNumber']?.toString() ?? '');
    houseNameController =
        TextEditingController(text: v['houseName']?.toString() ?? '');
    placeController = TextEditingController(text: v['place']?.toString() ?? '');
    postController = TextEditingController(text: v['post']?.toString() ?? '');
    districtController =
        TextEditingController(text: v['district']?.toString() ?? '');
    pinController = TextEditingController(text: v['pin']?.toString() ?? '');
    vehicleNumberController =
        TextEditingController(text: v['vehicleNumber']?.toString() ?? '');
    vehicleModelController =
        TextEditingController(text: v['vehicleModel']?.toString() ?? '');
    chassisNumberController =
        TextEditingController(text: v['chassisNumber']?.toString() ?? '');
    engineNumberController =
        TextEditingController(text: v['engineNumber']?.toString() ?? '');
    totalAmountController =
        TextEditingController(text: v['totalAmount']?.toString() ?? '');
    advanceAmountController =
        TextEditingController(text: v['advanceAmount']?.toString() ?? '');
    balanceAmountController =
        TextEditingController(text: v['balanceAmount']?.toString() ?? '');

    final savedService = v['cov']?.toString() ?? 'Transfer of Ownership';

    // Parse comma-separated services into list
    if (savedService.isNotEmpty && savedService != 'null') {
      selectedServices = savedService.split(', ').map((e) => e.trim()).toList();
    } else {
      selectedServices = ['Transfer of Ownership'];
    }

    if (selectedServices.contains('Other')) {
      final otherVal = v['otherService']?.toString() ?? '';
      otherServiceController = TextEditingController(text: otherVal);
    } else {
      otherServiceController = TextEditingController();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseFormWidget(
      title: 'Edit Vehicle Details',
      onBack: () => Navigator.pop(context),
      actions: [
        IconButton(
          onPressed: () async {
            if (formKey.currentState!.validate()) {
              try {
                final user = FirebaseAuth.instance.currentUser;
                final WorkspaceController workspaceController =
                    Get.find<WorkspaceController>();
                if (user == null) return;

                final schoolId = workspaceController.currentSchoolId.value;
                final targetId = schoolId.isNotEmpty ? schoolId : user.uid;

                // Final service type logic
                final serviceTypes = selectedServices.isNotEmpty
                    ? selectedServices
                    : ['Transfer of Ownership'];
                final covString = serviceTypes.join(', ');

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
                  'cov': covString,
                  'serviceTypes': serviceTypes, // Array of services
                  'otherService': serviceTypes.contains('Other')
                      ? otherServiceController.text
                      : null,
                  'totalAmount': totalAmountController.text,
                  'advanceAmount': advanceAmountController.text,
                  'balanceAmount': balanceAmountController.text,
                  'registrationDate': DateTime.now().toIso8601String(),
                };

                // Use the WorkspaceController to handle collection separation based on status
                await workspaceController.updateDocumentWithStatus(
                  'vehicleDetails',
                  widget.initialValues['studentId'] ??
                      widget.initialValues['id'],
                  data,
                );

                Fluttertoast.showToast(
                    msg: 'Vehicle details updated successfully');
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VehicleDetailsPage(
                      vehicleDetails: data,
                    ),
                  ),
                );
              } catch (e) {
                Fluttertoast.showToast(
                    msg: 'Error updating vehicle details: $e');
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
                  if (selectedServices.contains('Other'))
                    FormTextField(
                      label: 'Specify Service',
                      controller: otherServiceController,
                      placeholder: 'Enter Service Type',
                      validator: (v) =>
                          v!.isEmpty ? 'Please specify service' : null,
                    ),
                ],
              ),
              if (selectedServices.contains('Transfer of Ownership') ||
                  selectedServices.contains('Change of Address') ||
                  selectedServices.contains('Address Change'))
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
                            double.tryParse(advanceAmountController.text) ?? 0;
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
                            double.tryParse(totalAmountController.text) ?? 0;
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
                ],
              ),
            ],
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
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Select Service Types',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: availableServices.length,
                  itemBuilder: (context, index) {
                    final service = availableServices[index];
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
                        setDialogState(() {
                          if (value == true) {
                            tempSelected.add(service);
                          } else {
                            tempSelected.remove(service);
                          }
                        });
                      },
                    );
                  },
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
                    setState(() {
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
