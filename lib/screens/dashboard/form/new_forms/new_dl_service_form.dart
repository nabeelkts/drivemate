import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:mds/controller/workspace_controller.dart';
import 'package:mds/screens/dashboard/list/details/dl_service_details_page.dart';
import 'package:mds/screens/widget/common_form.dart';
import 'package:mds/screens/widget/custom_back_button.dart';
import 'package:mds/screens/widget/utils.dart';

class NewDlServiceForm extends StatefulWidget {
  const NewDlServiceForm({super.key});

  @override
  State<NewDlServiceForm> createState() => _NewDlServiceFormState();
}

class _NewDlServiceFormState extends State<NewDlServiceForm> {
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
        title: const Text('New DL Service'),
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
          'Renewal Of DL',
          'Change of Address',
          'Change of Name',
          'Change of Photo & Signature',
          'Duplicate License',
          'Change of DOB',
          'Endorsement to DL',
          'Issue of PSV Badge',
          'Other',
        ],
        index: 0,
        showLicenseField: true,
        showServiceType: true, // Indicates this is a service form
        onFormSubmit: (serviceData) async {
          try {
            final serviceType = serviceData['serviceType']?.toString() ?? '';
            final fullName = serviceData['fullName']?.toString() ?? '';

            if (fullName.isEmpty) {
              Fluttertoast.showToast(msg: 'Enter full name');
              return;
            }

            String serviceId = serviceData['studentId']?.toString() ?? '';
            if (serviceId.isEmpty) {
              if (user == null) {
                Fluttertoast.showToast(msg: 'User not authenticated');
                return;
              }
              // reusing generateStudentId but naming it serviceId contextually
              serviceId = await generateStudentId(targetId!);
              serviceData['studentId'] = serviceId;
            }
            final formattedDate = DateTime.now().toIso8601String();
            serviceData['registrationDate'] = formattedDate;

            await usersCollection
                .doc(targetId)
                .collection('dl_services')
                .doc(serviceId)
                .set(serviceData);

            // Record initial payment transaction if any
            final advance = double.tryParse(
                    serviceData['advanceAmount']?.toString() ?? '0') ??
                0;
            if (advance > 0) {
              await usersCollection
                  .doc(targetId)
                  .collection('dl_services')
                  .doc(serviceId)
                  .collection('payments')
                  .add({
                'amount': advance,
                'amountPaid': advance, // supporting both fields
                'mode': serviceData['paymentMode'] ?? 'Cash',
                'date': Timestamp.now(),
                'description': 'Initial Advance',
                'createdAt': FieldValue.serverTimestamp(),
                'targetId': targetId, // CRITICAL for collectionGroup filtering
                'recordName': fullName, // Helpful for display
              });
            }

            await usersCollection
                .doc(targetId)
                .collection('notifications')
                .add({
              'title': 'New DL Service Request',
              'date': formattedDate,
              'details': 'Name: $fullName\nService: $serviceType',
            });

            final branchId = _workspaceController.currentBranchId.value;

            await usersCollection
                .doc(targetId)
                .collection('recentActivity')
                .add({
              'title': 'New DL Service',
              'details': '$fullName\n$serviceType',
              'timestamp': FieldValue.serverTimestamp(),
              'imageUrl': serviceData['image'],
              'branchId': branchId.isNotEmpty ? branchId : targetId,
            });

            Fluttertoast.showToast(
              msg: 'Service Request Added Successfully',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
            );
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      DlServiceDetailsPage(serviceDetails: serviceData),
                ),
              );
            }
          } catch (error) {
            if (kDebugMode) {
              print('Failed to add service: $error');
            }
            Fluttertoast.showToast(msg: 'Failed: $error');
          }
        },
      ),
    );
  }
}
