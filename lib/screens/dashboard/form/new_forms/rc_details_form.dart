import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mds/screens/authentication/widgets/my_button.dart';
import 'package:mds/screens/dashboard/list/details/rc_details_page.dart';

class RcDetails extends StatefulWidget {
  const RcDetails({super.key});

  @override
  State<RcDetails> createState() => _RcDetailsState();
}

class _RcDetailsState extends State<RcDetails> {
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;

  late TextEditingController vehicleNumberController;
  late TextEditingController chassisNumberController;
  late TextEditingController engineNumberController;
  late TextEditingController mobileNumberController;
  late TextEditingController serviceController;
  late TextEditingController totalAmountController;
  late TextEditingController advanceAmountController;
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
  int index = 0;

  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');
  final CollectionReference notificationsCollection =
      FirebaseFirestore.instance.collection('notifications');

  @override
  void initState() {
    super.initState();
    initializeControllers();
    setupListeners();
  }

  void initializeControllers() {
    vehicleNumberController = TextEditingController();
    chassisNumberController = TextEditingController();
    engineNumberController = TextEditingController();
    mobileNumberController = TextEditingController();
    serviceController = TextEditingController(text: items[index]);
    scrollController = FixedExtentScrollController(initialItem: index);
    totalAmountController = TextEditingController();
    advanceAmountController = TextEditingController();
    balanceAmountController = TextEditingController();
  }

  void setupListeners() {
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
    balanceAmountController.dispose();
    scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: const Text('RC Details'),
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
      buildTextField('Vehicle Number', vehicleNumberController, 'KL10AA1111', textColor),
      buildTextField('Chassis Number', chassisNumberController, 'Last 5 digits', textColor, maxLength: 5),
      buildTextField('Engine Number', engineNumberController, 'Last 5 digits', textColor, maxLength: 5),
      buildTextField('Mobile Number', mobileNumberController, 'Mobile Number', textColor, keyboardType: TextInputType.number, maxLength: 10),
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
            scrollController = FixedExtentScrollController(initialItem: index);
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
      buildTextField('Total', totalAmountController, 'Total Amount', textColor, keyboardType: TextInputType.number),
      buildTextField('Advance', advanceAmountController, 'Advance Amount', textColor, keyboardType: TextInputType.number),
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
      child: MyButton(
        onTap: isLoading ? null : handleSubmit,
        text: 'Submit',
        isLoading: isLoading,
        isEnabled: !isLoading,
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
        height: 250,
        child: CupertinoPicker(
          scrollController: scrollController,
          itemExtent: 64,
          onSelectedItemChanged: (index) {
            setState(() {
              this.index = index;
              serviceController.text = items[index];
            });
          },
          children: items.map((item) => Center(child: Text(item, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)))).toList(),
        ),
      );

  Future<void> handleSubmit() async {
    if (!formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
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
        'image': 'assets/icons/vehicle_rc.png', // Default image
      };

      String documentId = vehicleDetails['vehicleNumber'];
      DateTime currentDate = DateTime.now();
      String formattedDate = currentDate.toLocal().toString();
      vehicleDetails['registrationDate'] = formattedDate;

      await usersCollection
          .doc(user?.uid)
          .collection('vehicleDetails')
          .doc(documentId)
          .set(vehicleDetails);

      // Add notification to Firestore
      await notificationsCollection.add({
        'title': 'New RC Registration',
        'date': formattedDate,
        'details': 'Vehicle Number: ${vehicleDetails['vehicleNumber']}\nService: ${vehicleDetails['service']}',
      });

      Fluttertoast.showToast(
        msg: 'Registration is Successful',
        fontSize: 18,
      );
      // ignore: use_build_context_synchronously
      Navigator.pushReplacement(
        context,
        CupertinoPageRoute(
            builder: (context) => RCDetailsPage(vehicleDetails: vehicleDetails)),
      );
    } catch (error) {
      if (kDebugMode) {
        print('Failed to add vehicle details: $error');
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
}
