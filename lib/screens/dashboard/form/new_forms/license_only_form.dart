import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:mds/controller/workspace_controller.dart';
import 'package:mds/screens/dashboard/list/details/license_only_details_page.dart';
import 'package:mds/screens/widget/common_form.dart';
import 'package:mds/screens/widget/custom_back_button.dart';
import 'package:mds/screens/widget/utils.dart';

class LicenseOnly extends StatefulWidget {
  const LicenseOnly({super.key});

  @override
  State<LicenseOnly> createState() => _LicenseOnlyState();
}

class _LicenseOnlyState extends State<LicenseOnly> {
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
        title: const Text('New License Only'),
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
          'M/C',
          'M/C WOG',
          'LMV ',
          'LMV + M/C',
          'LMV + M/C WOG',
        ],
        index: 0,
        showLicenseField: false,
        onFormSubmit: (license) async {
          try {
            final cov = license['cov']?.toString() ?? '';
            final fullName = license['fullName']?.toString() ?? '';
            if (fullName.isEmpty) {
              Fluttertoast.showToast(msg: 'Enter full name');
              return;
            }
            if (cov.isEmpty || cov == 'Select your cov') {
              Fluttertoast.showToast(msg: 'Please select class of vehicle');
              return;
            }

            String licenseId = license['studentId']?.toString() ?? '';
            if (licenseId.isEmpty) {
              if (user == null) {
                Fluttertoast.showToast(msg: 'User not authenticated');
                return;
              }
              licenseId = await generateStudentId(targetId!);
              license['studentId'] = licenseId;
            }
            final formattedDate = DateTime.now().toIso8601String();
            license['registrationDate'] = formattedDate;

            await usersCollection
                .doc(targetId)
                .collection('licenseonly')
                .doc(licenseId)
                .set(license);

            // Record initial payment transaction if any
            final advance =
                double.tryParse(license['advanceAmount']?.toString() ?? '0') ??
                    0;
            if (advance > 0) {
              await usersCollection
                  .doc(targetId)
                  .collection('licenseonly')
                  .doc(licenseId)
                  .collection('payments')
                  .add({
                'amount': advance,
                'mode': license['paymentMode'] ?? 'Cash',
                'date': Timestamp.now(),
                'description': 'Initial Advance',
                'createdAt': FieldValue.serverTimestamp(),
                'targetId': targetId!,
                'recordId': licenseId,
                'recordName': fullName,
                'category': 'licenseonly',
              });
            }

            await usersCollection
                .doc(targetId)
                .collection('notifications')
                .add({
              'title': 'New License Registration',
              'date': formattedDate,
              'details': 'Name: $fullName\nType: $cov',
            });

            final branchId = _workspaceController.currentBranchId.value;

            await usersCollection
                .doc(targetId)
                .collection('recentActivity')
                .add({
              'title': 'New License Registration',
              'details': '$fullName\n$cov',
              'timestamp': FieldValue.serverTimestamp(),
              'branchId': branchId.isNotEmpty ? branchId : targetId,
            });

            Fluttertoast.showToast(
              msg: 'New License Registration Completed',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
            );
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      LicenseOnlyDetailsPage(licenseDetails: license),
                ),
              );
            }
          } catch (error) {
            if (kDebugMode) {
              print('Failed to add license: $error');
            }
            Fluttertoast.showToast(msg: 'Failed: $error');
          }
        },
      ),
    );
  }
}
