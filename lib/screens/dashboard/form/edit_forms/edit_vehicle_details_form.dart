/* lib/screens/dashboard/form/edit_forms/edit_vehicle_details_form.dart */
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class EditVehicleDetailsForm extends StatefulWidget {
  final Map<String, dynamic> initialData;

  const EditVehicleDetailsForm({required this.initialData, super.key});

  @override
  // ignore: library_private_types_in_public_api
  _EditVehicleDetailsFormState createState() => _EditVehicleDetailsFormState();
}

class _EditVehicleDetailsFormState extends State<EditVehicleDetailsForm> {
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;

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
  final items = [
    'Transfer of Ownership',
    'Change of Address',
    'Hypothecation Termination',
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
    initializeControllers();
    setupListeners();
  }

  void initializeControllers() {
    vehicleNumberController = TextEditingController(text: widget.initialData['vehicleNumber']);
    chassisNumberController = TextEditingController(text: widget.initialData['chassisNumber']);
    engineNumberController = TextEditingController(text: widget.initialData['engineNumber']);
    mobileNumberController = TextEditingController(text: widget.initialData['mobileNumber']);
    serviceController = TextEditingController(text: widget.initialData['service']);
    totalAmountController = TextEditingController(text: widget.initialData['totalAmount']);
    advanceAmountController = TextEditingController(text: widget.initialData['advanceAmount']);
    secondInstallmentController = TextEditingController(text: widget.initialData['secondInstallment']);
    thirdInstallmentController = TextEditingController(text: widget.initialData['thirdInstallment']);
    balanceAmountController = TextEditingController(text: widget.initialData['balanceAmount']);
    scrollController = FixedExtentScrollController(
      initialItem: items.indexOf(serviceController.text),
    );
  }

  void setupListeners() {
    totalAmountController.addListener(updateBalanceAmount);
    advanceAmountController.addListener(updateBalanceAmount);
    secondInstallmentController.addListener(updateBalanceAmount);
    thirdInstallmentController.addListener(updateBalanceAmount);
  }

  void updateBalanceAmount() {
    final totalAmount = double.tryParse(totalAmountController.text) ?? 0.0;
    final advanceAmount = double.tryParse(advanceAmountController.text) ?? 0.0;
    final secondInstallment = double.tryParse(secondInstallmentController.text) ?? 0.0;
    final thirdInstallment = double.tryParse(thirdInstallmentController.text) ?? 0.0;
    final balanceAmount = totalAmount - advanceAmount - secondInstallment - thirdInstallment;
    balanceAmountController.text = balanceAmount.toString();
  }

  @override
  void dispose() {
    disposeControllers();
    super.dispose();
  }

  void disposeControllers() {
    vehicleNumberController.dispose();
    chassisNumberController.dispose();
    engineNumberController.dispose();
    mobileNumberController.dispose();
    serviceController.dispose();
    totalAmountController.dispose();
    advanceAmountController.dispose();
    secondInstallmentController.dispose();
    thirdInstallmentController.dispose();
    balanceAmountController.dispose();
    scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Vehicle Details'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            buildVehicleDetailsSection(textColor),
            buildServiceSection(textColor),
            buildFeesSection(textColor),
            buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget buildVehicleDetailsSection(Color textColor) {
    return buildSection('Vehicle Details', [
      buildTextField('Vehicle Number', vehicleNumberController, 'Enter Vehicle Number', textColor),
      buildTextField('Chassis Number', chassisNumberController, 'Last 5 digits', textColor, maxLength: 5),
      buildTextField('Engine Number', engineNumberController, 'Last 5 digits', textColor, maxLength: 5),
      buildTextField('Mobile Number', mobileNumberController, 'Enter Mobile Number', textColor, keyboardType: TextInputType.number, maxLength: 10),
    ]);
  }

  Widget buildServiceSection(Color textColor) {
    return buildSectionContainer(
      children: [
        Text(
          'Service',
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
                initialItem: items.indexOf(serviceController.text));
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
          controller: serviceController,
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
      {TextInputType keyboardType = TextInputType.text, bool readOnly = false, int? maxLength}) {
    return CupertinoFormRow(
      prefix: Text(label, style: TextStyle(color: textColor)),
      child: CupertinoTextFormFieldRow(
        controller: controller,
        placeholder: placeholder,
        keyboardType: keyboardType,
        readOnly: readOnly,
        maxLength: maxLength,
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
      child: CupertinoButton.filled(
        onPressed: isLoading ? null : handleSubmit,
        child: isLoading ? const CupertinoActivityIndicator() : const Text('Update'),
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
              serviceController.text = items[index];
            });
          },
          children: items.map((item) => Center(child: Text(item, style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color)))).toList(),
        ),
      );

  Future<void> handleSubmit() async {
    if (!formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      await updateVehicleData();
      showSuccessMessage();
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
    } catch (error) {
      showErrorMessage(error.toString());
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> updateVehicleData() async {
    final User? user = FirebaseAuth.instance.currentUser;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user?.uid)
        .collection('vehicleDetails')
        .doc(vehicleNumberController.text)
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
    });
  }

  void showSuccessMessage() {
    Fluttertoast.showToast(
      msg: 'Vehicle Details Updated Successfully',
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
