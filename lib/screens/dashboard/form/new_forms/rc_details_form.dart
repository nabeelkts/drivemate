import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mds/screens/dashboard/list/details/rc_details_page.dart';
import 'package:mds/screens/widget/common_form.dart';
import 'package:get/get.dart';
import 'package:mds/controller/workspace_controller.dart';
import 'package:mds/screens/widget/custom_back_button.dart';

class RCDetailsForm extends StatefulWidget {
  const RCDetailsForm({super.key});

  @override
  State<RCDetailsForm> createState() => _RCDetailsFormState();
}

class _RCDetailsFormState extends State<RCDetailsForm> {
  final GlobalKey<CommonFormState> _formKey = GlobalKey<CommonFormState>();
  final WorkspaceController _workspaceController =
      Get.find<WorkspaceController>();

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    final CollectionReference usersCollection =
        FirebaseFirestore.instance.collection('users');

    final schoolId = _workspaceController.currentSchoolId.value;
    final targetId = schoolId.isNotEmpty ? schoolId : user?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('RC Details'),
        leading: const CustomBackButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined),
            onPressed: () => _formKey.currentState?.smartFill(),
            tooltip: 'Smart Fill',
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => _formKey.currentState?.submitForm(),
          ),
        ],
        elevation: 0,
      ),
      body: CommonForm(
        key: _formKey,
        items: const [
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
        ],
        index: 0,
        showLicenseField: false,
        onFormSubmit: (vehicleData) async {
          String vehicleNumber = vehicleData['vehicleNumber'];
          DateTime currentDate = DateTime.now();
          String formattedDate = currentDate.toIso8601String();

          vehicleData['registrationDate'] = formattedDate;

          try {
            await usersCollection
                .doc(targetId)
                .collection('vehicleDetails')
                .doc(vehicleNumber)
                .set(vehicleData);

            // Add to user's notifications subcollection
            await usersCollection
                .doc(targetId)
                .collection('notifications')
                .add({
              'title': 'New Vehicle Registration',
              'date': formattedDate,
              'details':
                  'Vehicle Number: ${vehicleData['vehicleNumber']}\nService: ${vehicleData['cov']}',
            });

            // Add to user's recent activity subcollection
            final branchId = _workspaceController.currentBranchId.value;

            await usersCollection
                .doc(targetId)
                .collection('recentActivity')
                .add({
              'title': 'New Vehicle Registration',
              'date': formattedDate,
              'details':
                  'Vehicle Number: ${vehicleData['vehicleNumber']}\nService: ${vehicleData['cov']}',
              'timestamp': FieldValue.serverTimestamp(),
              'imageUrl': vehicleData['image'],
              'branchId': branchId.isNotEmpty ? branchId : targetId,
            });

            Fluttertoast.showToast(
              msg: 'Vehicle Registration Completed',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
            );

            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => RCDetailsPage(
                    vehicleDetails: vehicleData,
                  ),
                ),
              );
            }
          } catch (error) {
            if (kDebugMode) {
              print('Error in vehicle registration: $error');
            }
            Fluttertoast.showToast(
              msg: 'Failed to register vehicle: $error',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
            );
          }
        },
      ),
    );
  }
}
