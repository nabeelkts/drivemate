import 'package:cloud_firestore/cloud_firestore.dart'; // Import the Cloud Firestore package
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mds/screens/dashboard/list/details/rc_details_page.dart';

class RcDetails extends StatefulWidget {
  const RcDetails({Key? key});

  @override
  State<RcDetails> createState() => _LicenseOnlyState();
}

class _LicenseOnlyState extends State<RcDetails> {
  late TextEditingController vehicleNumberController;
  late TextEditingController chassisNumberController;
  late TextEditingController engineNumberController;
  late TextEditingController mobileNumberController;
  late TextEditingController serviceController;
  late TextEditingController totalAmountController;
  late TextEditingController advanceAmountController;
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
  int index = 0;

  // Add the CollectionReference for Firestore
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');

  @override
  void initState() {
    super.initState();
    vehicleNumberController = TextEditingController(); // Initialize controllers
    chassisNumberController = TextEditingController();
    engineNumberController = TextEditingController();
    mobileNumberController = TextEditingController();
    serviceController = TextEditingController(text: items[index]);
    scrollController = FixedExtentScrollController(initialItem: index);
    totalAmountController = TextEditingController();
    advanceAmountController = TextEditingController();
    balanceAmountController = TextEditingController();
    totalAmountController.addListener(updateBalanceAmount);
    advanceAmountController.addListener(updateBalanceAmount);
  }

  void updateBalanceAmount() {
    final totalAmount = double.tryParse(totalAmountController.text) ?? 0.0;
    final advanceAmount = double.tryParse(advanceAmountController.text) ?? 0.0;
    final balanceAmount = totalAmount - advanceAmount;
    balanceAmountController.text = balanceAmount.toString();
  }

  @override
  void dispose() {
    // Dispose controllers
    vehicleNumberController.dispose();
    chassisNumberController.dispose();
    engineNumberController.dispose();
    mobileNumberController.dispose();
    serviceController.dispose();
    totalAmountController.dispose();
    advanceAmountController.dispose();
    balanceAmountController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
        backgroundColor: CupertinoColors.systemGroupedBackground,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            const CupertinoSliverNavigationBar(
              backgroundColor: Colors.transparent,
              largeTitle: Text(
                'Rc Details',
                style: TextStyle(fontSize: 25),
              ),
              border: Border(),
            ),
          ],
          body: Form(
            key: formKey,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                CupertinoFormSection.insetGrouped(
                    margin: const EdgeInsets.all(12),
                    header: const Text(
                      'Vehicle Details',
                      style: TextStyle(fontSize: 16),
                    ),
                    children: [
                      CupertinoFormRow(
                        prefix: const Text('Vehicle Number'),
                        child: CupertinoTextFormFieldRow(
                            textInputAction: TextInputAction.next,
                            placeholder: 'KL10AA1111',
                            controller: vehicleNumberController,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            validator: (vehicleNumber) {
                              if (vehicleNumber == null ||
                                  vehicleNumber.isEmpty) {
                                return 'Enter Vehicle Number';
                              } else if (vehicleNumber.length < 4) {
                                return 'Must be at least 4 characters long';
                              } else {
                                return null;
                              }
                            }),
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
                            if (chassisNumber == null ||
                                chassisNumber.isEmpty) {
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
                    ]),
                CupertinoFormSection.insetGrouped(
                    margin: const EdgeInsets.all(12),
                    header: const Text(
                      'Service',
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
                                  initialItem: index);
                              showCupertinoModalPopup(
                                  context: context,
                                  builder: (context) => CupertinoActionSheet(
                                        actions: [buildPicker()],
                                        cancelButton:
                                            CupertinoActionSheetAction(
                                          child: const Text('Done'),
                                          onPressed: () =>
                                              Navigator.pop(context),
                                        ),
                                      ));
                            },
                            controller: serviceController,
                            readOnly: true,
                            enableInteractiveSelection: false,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
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
                            if (advanceAmount == null ||
                                advanceAmount.isEmpty) {
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
                              return 'Enter Total Amount';
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
                    child: const Text('Submit'),
                    onPressed: () {
                      final form = formKey.currentState!;
                      if (form.validate()) {
                        User? user = FirebaseAuth.instance.currentUser;
                        String vehicleNumber = vehicleNumberController.text;
                        String chassisNumber = chassisNumberController.text;
                        String engineNumber = engineNumberController.text;
                        String mobileNumber = mobileNumberController.text;
                        String service = serviceController.text;
                        String totalAmount = totalAmountController.text;
                        String advanceAmount = advanceAmountController.text;
                        String balanceAmount = balanceAmountController.text;
                        Map<String, dynamic> vehicleDetails = {
                          'vehicleNumber': vehicleNumber,
                          'chassisNumber': chassisNumber,
                          'engineNumber': engineNumber,
                          'mobileNumber': mobileNumber,
                          'totalAmount': totalAmount,
                          'advanceAmount': advanceAmount,
                          'balanceAmount': balanceAmount,
                          'service': service,
                        };
                        String documentId = vehicleDetails['vehicleNumber'];
// Get the current date and time
                        DateTime currentDate = DateTime.now();
                        String formattedDate = currentDate.toLocal().toString();

                        // Include the date and time in the student data
                        vehicleDetails['registrationDate'] = formattedDate;
                        // ignore: avoid_single_cascade_in_expression_statements
                        usersCollection
                            .doc(user?.uid)
                            .collection('vehicleDetails')
                          ..doc(documentId) // Set the document ID as the studentId
                              .set(vehicleDetails)
                              .then((value) {
                            Fluttertoast.showToast(
                              msg: 'Registration is Successful',
                              fontSize: 18,
                            );
                            // Navigate to the dashboard
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => RCDetailsPage(
                                      vehicleDetails: vehicleDetails)),
                            );
                          }).catchError((error) {
                            // Handle errors
                            if (kDebugMode) {
                              print('Failed to add vehicle details: $error');
                            }
                          });
                      }
                    },
                  ),
                ),
                const SizedBox(
                  height: 30,
                )
              ],
            ),
          ),
        ),
      );

  Widget buildPicker() => SizedBox(
        height: 350,
        child: StatefulBuilder(
          builder: (context, setState) => CupertinoPicker(
            scrollController: scrollController,
            looping: true,
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
}
