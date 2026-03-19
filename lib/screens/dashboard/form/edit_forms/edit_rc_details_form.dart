import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:drivemate/screens/widget/common_form.dart';
import 'package:get/get.dart';
import 'package:drivemate/controller/workspace_controller.dart';

class EditRCDetailsForm extends StatelessWidget {
  final Map<String, dynamic> initialValues;
  final List<String> items;

  const EditRCDetailsForm({
    required this.initialValues,
    required this.items,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    final WorkspaceController workspaceController =
        Get.find<WorkspaceController>();
    final CollectionReference usersCollection =
        FirebaseFirestore.instance.collection('users');

    final schoolId = workspaceController.currentSchoolId.value;
    final targetId = schoolId.isNotEmpty ? schoolId : user?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit RC Details'),
        elevation: 0,
      ),
      body: CommonForm(
        items: items,
        index: items.indexOf(initialValues['cov']),
        showLicenseField: false,
        initialValues: initialValues,
        onFormSubmit: (vehicleData) async {
          try {
            // Preserve the status/deactivated field to ensure correct collection is used
            if (initialValues['status'] != null) {
              vehicleData['status'] = initialValues['status'];
            }
            if (initialValues['deactivated'] != null) {
              vehicleData['deactivated'] = initialValues['deactivated'];
            }

            // Use the WorkspaceController to handle collection separation based on status
            await workspaceController.updateDocumentWithStatus(
              'vehicleDetails',
              vehicleData['studentId'] ?? vehicleData['id'],
              vehicleData,
            );

            Fluttertoast.showToast(
              msg: 'Vehicle Details Updated Successfully',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
            );

            if (context.mounted) {
              Navigator.pop(context);
            }
          } catch (error) {
            if (kDebugMode) {
              print('Error updating vehicle details: $error');
            }
            Fluttertoast.showToast(
              msg: 'Failed to update vehicle details: $error',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
            );
          }
        },
      ),
    );
  }
}
