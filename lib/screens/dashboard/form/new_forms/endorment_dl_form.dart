import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:mds/controller/workspace_controller.dart';
import 'package:mds/screens/dashboard/list/details/endorsement_details_page.dart';
import 'package:mds/screens/widget/common_form.dart';
import 'package:mds/screens/widget/custom_back_button.dart';
import 'package:mds/screens/widget/utils.dart';

class EndorsementDL extends StatefulWidget {
  const EndorsementDL({super.key});

  @override
  State<EndorsementDL> createState() => _EndorsementDLState();
}

class _EndorsementDLState extends State<EndorsementDL> {
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
        title: const Text('Endorsement to DL'),
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
          'MC',
          'MCWOG',
          'LMV',
          'LMV + MC ',
          'LMV + MCWOG',
          'ADAPTED VEHICLE',
          'TRANS',
          'TRANS + MC',
          'TRANS + MCWOG',
          'EXCAVATOR',
          'CRANE',
          'FORKLIFT',
          'CONSTRUCTION EQUIPMENT',
          'TOW TRUCK',
          'TRAILER',
          'AGRICULTURAL TRACTOR',
        ],
        index: 1,
        showLicenseField: true,
        onFormSubmit: (endorsement) async {
          try {
            final cov = endorsement['cov']?.toString() ?? '';
            final fullName = endorsement['fullName']?.toString() ?? '';
            if (fullName.isEmpty) {
              Fluttertoast.showToast(msg: 'Enter full name');
              return;
            }
            if (cov.isEmpty || cov == 'Select your cov') {
              Fluttertoast.showToast(msg: 'Please select class of vehicle');
              return;
            }

            String studentId = endorsement['studentId']?.toString() ?? '';
            if (studentId.isEmpty) {
              if (user == null) {
                Fluttertoast.showToast(msg: 'User not authenticated');
                return;
              }
              studentId = await generateStudentId(targetId!);
              endorsement['studentId'] = studentId;
            }
            final formattedDate = DateTime.now().toIso8601String();
            endorsement['registrationDate'] = formattedDate;

            await usersCollection
                .doc(targetId)
                .collection('endorsement')
                .doc(studentId)
                .set(endorsement);

            // Record initial payment transaction if any
            final advance = double.tryParse(
                    endorsement['advanceAmount']?.toString() ?? '0') ??
                0;
            if (advance > 0) {
              await usersCollection
                  .doc(targetId)
                  .collection('endorsement')
                  .doc(studentId)
                  .collection('payments')
                  .add({
                'amount': advance,
                'mode': endorsement['paymentMode'] ?? 'Cash',
                'date': Timestamp.now(),
                'description': 'Initial Advance',
                'createdAt': FieldValue.serverTimestamp(),
                'targetId': targetId!,
                'recordId': studentId,
                'recordName': fullName,
                'category': 'endorsement',
              });
            }

            await usersCollection
                .doc(targetId)
                .collection('notifications')
                .add({
              'title': 'New Endorsement Registration',
              'date': formattedDate,
              'details': 'Name: $fullName\nType: $cov',
            });

            final branchId = _workspaceController.currentBranchId.value;

            await usersCollection
                .doc(targetId)
                .collection('recentActivity')
                .add({
              'title': 'New Endorsement Registration',
              'details': '$fullName\n$cov',
              'timestamp': FieldValue.serverTimestamp(),
              'branchId': branchId.isNotEmpty ? branchId : targetId,
            });

            Fluttertoast.showToast(
              msg: 'New Endorsement Registration Completed',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
            );
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      EndorsementDetailsPage(endorsementDetails: endorsement),
                ),
              );
            }
          } catch (error) {
            if (kDebugMode) {
              print('Failed to add endorsement: $error');
            }
            Fluttertoast.showToast(msg: 'Failed: $error');
          }
        },
      ),
    );
  }
}
