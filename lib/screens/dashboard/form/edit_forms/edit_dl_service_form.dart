import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mds/screens/widget/common_form.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:mds/controller/workspace_controller.dart';

class EditDlServiceForm extends StatefulWidget {
  final Map<String, dynamic> initialValues;
  final List<String> items;

  const EditDlServiceForm({
    required this.initialValues,
    required this.items,
    super.key,
  });

  @override
  State<EditDlServiceForm> createState() => _EditDlServiceFormState();
}

class _EditDlServiceFormState extends State<EditDlServiceForm> {
  final GlobalKey<CommonFormState> _formKey = GlobalKey<CommonFormState>();

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    final WorkspaceController workspaceController =
        Get.find<WorkspaceController>();
    final CollectionReference usersCollection =
        FirebaseFirestore.instance.collection('users');

    final schoolId = workspaceController.currentSchoolId.value;
    final targetId = schoolId.isNotEmpty ? schoolId : user?.uid;

    // Get the index, defaulting to 0 if not found
    final int selectedIndex =
        widget.items.contains(widget.initialValues['serviceType'] ?? '')
            ? widget.items.indexOf(widget.initialValues['serviceType'] ?? '')
            : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Service Details'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              if (_formKey.currentState != null) {
                _formKey.currentState!.submitForm();
              }
            },
          ),
        ],
      ),
      body: CommonForm(
        key: _formKey,
        items: widget.items,
        index: selectedIndex,
        showLicenseField: true,
        showServiceType: true,
        initialValues: widget.initialValues,
        onFormSubmit: (serviceData) async {
          try {
            await usersCollection
                .doc(targetId)
                .collection('dl_services')
                .doc(serviceData['studentId'])
                .update(serviceData);

            Fluttertoast.showToast(
              msg: 'Service Details Updated Successfully',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
            );

            if (context.mounted) {
              Navigator.pop(context);
            }
          } catch (error) {
            if (kDebugMode) {
              print('Error updating service details: $error');
            }
            Fluttertoast.showToast(
              msg: 'Failed to update service details: $error',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
            );
          }
        },
      ),
    );
  }
}
