import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mds/controller/workspace_controller.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/screens/dashboard/list/widgets/list_item_card.dart';
import 'package:mds/screens/widget/base_list_widget.dart';
import 'package:mds/screens/profile/dialog_box.dart';
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
      // No add button for deactivated list
      itemBuilder: (context, doc) {
        final data = doc.data();
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return ListItemCard(
          title: data['fullName'] ?? 'N/A',
          subTitle:
              'Service: ${data['serviceType'] ?? 'N/A'}\nMobile: ${data['mobileNumber'] ?? 'N/A'}',
          imageUrl: data['image'],
          isDark: isDark,
          onTap: () {
            // Optional: Show details or restore
            // For now, just showing a dialog to restore
            _showMenuOptions(context, doc, userId);
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
        if (context.mounted) {
          Navigator.of(context).pop();
        }
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
        if (context.mounted) {
          Navigator.of(context).pop();
        }
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
