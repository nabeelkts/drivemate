import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mds/screens/dashboard/list/vehicle_details_list.dart';

class EditVehicleDetailsForm extends StatefulWidget {
  final Map<String, dynamic> initialData;

  const EditVehicleDetailsForm({required this.initialData, Key? key})
      : super(key: key);

  @override
  _EditRcDetailsFormState createState() => _EditRcDetailsFormState();
}

class _EditRcDetailsFormState extends State<EditVehicleDetailsForm> {
  int index = 0;
  late TextEditingController vehicleNumberController;
  late TextEditingController chassisNumberController;
  late TextEditingController engineNumberController;
  late TextEditingController mobileNumberController;
  late TextEditingController serviceController;
  late TextEditingController totalAmountController;
  late TextEditingController advanceAmountController;
  late TextEditingController secondInstallmentController;
  late TextEditingController thirdInstallmentController;
  late TextEditingController balanceAmountController;

  late FixedExtentScrollController scrollController;
  final formKey = GlobalKey<FormState>();
  final items = [
    'Transfer of Ownership ',
    'Change of Address',
    'Hypothecation Termination ',
    'Hypothecation Addition',
    'TO + HP Cancellation',
    'NOC',
    'FITNESS',
    'RC RENEWAL',
    'RC CANCELLATION',
    'DUPLICATE RC',
    'CONVERSION',
    'ALTERATION',
    'PERMIT RENEWAL',
    'TAX',
    'INSURANCE',
  ];

  @override
  void initState() {
    super.initState();
    vehicleNumberController = TextEditingController();
    chassisNumberController = TextEditingController();
    engineNumberController = TextEditingController();
    mobileNumberController = TextEditingController();
    serviceController = TextEditingController();
    scrollController = FixedExtentScrollController();
    totalAmountController = TextEditingController();
    advanceAmountController = TextEditingController();
    secondInstallmentController = TextEditingController();
    thirdInstallmentController = TextEditingController();
    balanceAmountController = TextEditingController();
    totalAmountController.addListener(updateBalanceAmount);
    advanceAmountController.addListener(updateBalanceAmount);

    // Set initial values from the provided data
    vehicleNumberController.text = widget.initialData['vehicleNumber'] ?? '';
    chassisNumberController.text = widget.initialData['chassisNumber'] ?? '';
    engineNumberController.text = widget.initialData['engineNumber'] ?? '';
    mobileNumberController.text = widget.initialData['mobileNumber'] ?? '';
    serviceController.text = widget.initialData['service'] ?? '';
    totalAmountController.text = widget.initialData['totalAmount'] ?? '';
    advanceAmountController.text = widget.initialData['advanceAmount'] ?? '';
    secondInstallmentController.text =
        widget.initialData['secondInstallment'] ?? '';
    thirdInstallmentController.text =
        widget.initialData['thirdInstallment'] ?? '';
    balanceAmountController.text = widget.initialData['balanceAmount'] ?? '';

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
  Widget build(BuildContext context) => CupertinoPageScaffold(
        backgroundColor: CupertinoColors.systemGroupedBackground,
        navigationBar: CupertinoNavigationBar(
          middle: Text('Edit Rc Details'),
        ),
        child: Form(
          key: formKey,
          child: ListView(
            padding: EdgeInsets.all(12),
            children: [
              CupertinoFormSection.insetGrouped(
                header: Text(
                  'Vehicle Details',
                  style: TextStyle(fontSize: 16),
                ),
                children: [
                  CupertinoFormRow(
                    prefix: Text('Vehicle Number'),
                    child: CupertinoTextFormFieldRow(
                      textInputAction: TextInputAction.next,
                      controller: vehicleNumberController,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (vehicleNumber) {
                        if (vehicleNumber == null || vehicleNumber.isEmpty) {
                          return 'Enter Vehicle Number';
                        } else if (vehicleNumber.length < 4) {
                          return 'Must be at least 4 characters long';
                        } else {
                          return null;
                        }
                      },
                    ),
                  ),
                  CupertinoFormRow(
                    prefix: const Text("Chassis Number"),
                    child: CupertinoTextFormFieldRow(
                      textInputAction: TextInputAction.next,
                      placeholder: 'Last 5 digits',
                      controller: chassisNumberController,
                      maxLength: 5,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (chassisNumber) {
                        if (chassisNumber == null || chassisNumber.isEmpty) {
                          return 'Enter Chassis Name';
                        } else if (chassisNumber.length < 5) {
                          return 'Must be at least 5 characters long';
                        } else {
                          return null;
                        }
                      },
                    ),
                  ),
                  CupertinoFormRow(
                    prefix: const Text("Engine Number"),
                    child: CupertinoTextFormFieldRow(
                      textInputAction: TextInputAction.next,
                      placeholder: 'Last 5 digits',
                      controller: engineNumberController,
                      maxLength: 5,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (engineNumber) {
                        if (engineNumber == null || engineNumber.isEmpty) {
                          return 'Enter Engine Number';
                        } else if (engineNumber.length < 5) {
                          return 'Must be at least 5 characters long';
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
                ],
              ),
              CupertinoFormSection.insetGrouped(
                header: Text(
                  'Service',
                  style: TextStyle(fontSize: 16),
                ),
                children: [
                  CupertinoFormRow(
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 30),
                      child: Center(
                        child: CupertinoTextField(
                          onTap: () {
                            scrollController.dispose();
                            scrollController = FixedExtentScrollController(
                                initialItem:
                                    items.indexOf(serviceController.text));
                            showCupertinoModalPopup(
                              context: context,
                              builder: (context) => CupertinoActionSheet(
                                actions: [buildPicker()],
                                cancelButton: CupertinoActionSheetAction(
                                  child: Text('Done'),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                            );
                          },
                          controller: serviceController,
                          readOnly: true,
                          enableInteractiveSelection: false,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              CupertinoFormSection.insetGrouped(
                header: Text(
                  'Fees',
                  style: TextStyle(fontSize: 16),
                ),
                children: [
                  CupertinoFormRow(
                    prefix: Text('Total'),
                    child: CupertinoTextFormFieldRow(
                      keyboardType: TextInputType.number,
                      controller: totalAmountController,
                      maxLength: 5,
                      textInputAction: TextInputAction.next,
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
                    prefix: Text('Advance'),
                    child: CupertinoTextFormFieldRow(
                      keyboardType: TextInputType.number,
                      maxLength: 5,
                      controller: advanceAmountController,
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
                    prefix: Text('Balance'),
                    child: CupertinoTextFormFieldRow(
                      keyboardType: TextInputType.number,
                      maxLength: 5,
                      readOnly: true,
                      enableInteractiveSelection: false,
                      controller: balanceAmountController,
                      textInputAction: TextInputAction.next,
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
                ],
              ),
              CupertinoButton.filled(
                child: Text('Update'),
                onPressed: () {
                  final form = formKey.currentState!;
                  if (form.validate()) {
                    // Call a function to update the data in Firestore
                    _updateData();
                  }
                },
              ),
              const SizedBox(height: 30),
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
            children: List.generate(items.length, (index) {
              final isSelected = this.index == index;
              final item = items[index];
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
              setState(() => this.index = index);
              final item = items[index];
              serviceController.text = item;
              if (kDebugMode) {
                print('Selected Item: $item');
              }
            },
          ),
        ),
      );

  void _updateData() async {
    try {
      // Update the data in Firestore using the provided document ID
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .collection('vehicleDetails')
          .doc(widget.initialData['vehicleNumber'])
          .update({
        'vehicleNumber': vehicleNumberController.text,
        'chassisNumber': chassisNumberController.text,
        'engineNumber': engineNumberController.text,
        'mobileNumber': mobileNumberController.text,
        'service': serviceController.text,
        'totalAmount': totalAmountController.text,
        'advanceAmount': advanceAmountController.text,
        'secondInstallment': secondInstallmentController.text,
        'thirdInstallment': thirdInstallmentController.text,
        'balanceAmount': balanceAmountController.text,
        // Add other fields as needed
      });

      print('Update Successful');

      Fluttertoast.showToast(
        msg: 'Updated Successfully',
        fontSize: 18,
      );

      // Close the edit form
      Navigator.pop(context);
    } catch (e) {
      print('Update Failed: $e');
      Fluttertoast.showToast(
        msg: 'Update Failed. Please try again.',
        fontSize: 18,
      );
      Navigator.pop(context);
    }
  }
}
