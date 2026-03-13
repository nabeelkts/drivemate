import 'package:drivemate/screens/dashboard/list/details/dl_service_details_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:drivemate/controller/workspace_controller.dart';
import 'package:drivemate/constants/colors.dart';
import 'package:drivemate/screens/dashboard/list/widgets/list_item_card.dart';
import 'package:drivemate/screens/widget/base_list_widget.dart';
import 'package:drivemate/screens/profile/dialog_box.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;

class DeactivatedDlServicesList extends StatelessWidget {
  const DeactivatedDlServicesList({super.key});

  @override
  Widget build(BuildContext context) {
    final WorkspaceController workspaceController =
        Get.find<WorkspaceController>();
    final String userId = workspaceController.currentSchoolId.value.isNotEmpty
        ? workspaceController.currentSchoolId.value
        : (FirebaseAuth.instance.currentUser?.uid ?? '');

    return BaseListWidget(
      title: 'Completed DL Services',
      collectionName: 'deactivated_dl_services',
      searchField: 'fullName',
      secondarySearchField: 'mobileNumber', // Add mobile number search
      summaryLabel: 'Total Completed:',
      // No add button for deactivated list
      itemBuilder: (context, doc) {
        final data = Map<String, dynamic>.from(doc.data());
        // Inject document ID for navigation to details pages
        data['studentId'] = doc.id;
        data['recordId'] = doc.id;
        data['id'] = doc.id;

        final isDark = Theme.of(context).brightness == Brightness.dark;
        return ListItemCard(
          title: data['fullName'] ?? 'N/A',
          subTitle:
              'Service: ${data['serviceType'] ?? 'N/A'}\nMobile: ${data['mobileNumber'] ?? 'N/A'}',
          imageUrl: data['image'],
          isDark: isDark,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DlServiceDetailsPage(
                  serviceDetails: data,
                ),
              ),
            );
          },
          onMenuPressed: () {
            _showMenuOptions(context, doc, userId);
          },
        );
      },
    );
  }

  void _showMenuOptions(BuildContext context,
      QueryDocumentSnapshot<Map<String, dynamic>> doc, String userId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.restore, color: kPrimaryColor),
                title: const Text('Restore to Active'),
                onTap: () async {
                  Navigator.pop(context);
                  await _showRestoreConfirmationDialog(
                      context, doc.id, doc.data(), userId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Delete Permanently'),
                onTap: () async {
                  Navigator.pop(context);
                  await _showDeleteForeverConfirmationDialog(
                      context, doc.id, userId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showRestoreConfirmationDialog(
      BuildContext context,
      String documentId,
      Map<String, dynamic> serviceData,
      String userId) async {
    showCustomConfirmationDialog(
      context,
      'Confirm Restore',
      'Are you sure you want to restore this service to active list?',
      () async {
        await _restoreData(documentId, serviceData, userId);
        // Navigator.pop is now handled automatically by showCustomConfirmationDialog
      },
    );
  }

  Future<void> _showDeleteForeverConfirmationDialog(
      BuildContext context, String documentId, String userId) async {
    showCustomConfirmationDialog(
      context,
      'Confirm Delete',
      'Are you sure you want to PERMANENTLY delete this record?',
      () async {
        await _deleteForever(documentId, userId);
        // Navigator.pop is now handled automatically by showCustomConfirmationDialog
      },
    );
  }

  Future<void> _restoreData(String serviceId, Map<String, dynamic> serviceData,
      String targetId) async {
    if (serviceId.isNotEmpty && serviceData.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetId)
          .collection('dl_services')
          .doc(serviceId)
          .set(serviceData);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetId)
          .collection('deactivated_dl_services')
          .doc(serviceId)
          .delete();
    }
  }

  Future<void> _deleteForever(String serviceId, String targetId) async {
    if (serviceId.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetId)
          .collection('deactivated_dl_services')
          .doc(serviceId)
          .delete();
    }
  }
}
