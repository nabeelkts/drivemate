import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mds/controller/workspace_controller.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/screens/dashboard/form/new_forms/new_dl_service_form.dart';
import 'package:mds/screens/dashboard/list/deactivated_dl_services_list.dart';
import 'package:mds/screens/dashboard/list/details/dl_service_details_page.dart';
import 'package:mds/screens/dashboard/list/widgets/list_item_card.dart';
import 'package:mds/screens/widget/base_list_widget.dart';
import 'package:mds/screens/profile/dialog_box.dart';

class DlServicesList extends StatelessWidget {
  final String userId;

  const DlServicesList({required this.userId, super.key});

  @override
  Widget build(BuildContext context) {
    return BaseListWidget(
      title: 'DL Services List',
      collectionName: 'dl_services',
      searchField: 'fullName',
      addButtonText: 'Create New Service',
      onAddNew: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NewDlServiceForm()),
        );
      },
      onViewDeactivated: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const DeactivatedDlServicesList()),
        );
      },
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
            _showMenuOptions(context, doc);
          },
        );
      },
    );
  }

  void _showMenuOptions(
      BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> doc) {
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
                leading: const Icon(Icons.check_circle_outline,
                    color: kPrimaryColor),
                title: const Text('Mark as Completed'),
                onTap: () async {
                  Navigator.pop(context);
                  await _showDeleteConfirmationDialog(
                      context, doc.id, doc.data());
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context,
      String documentId, Map<String, dynamic> serviceData) async {
    showCustomConfirmationDialog(
      context,
      'Confirm Service Completion',
      'Are you sure you want to mark this service as completed?',
      () async {
        await _deleteData(documentId, serviceData);
        if (context.mounted) {
          Navigator.of(context).pop();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const DeactivatedDlServicesList(),
            ),
          );
        }
      },
    );
  }

  Future<void> _deleteData(
      String serviceId, Map<String, dynamic> serviceData) async {
    final WorkspaceController workspaceController =
        Get.find<WorkspaceController>();
    final schoolId = workspaceController.currentSchoolId.value;
    final targetId = schoolId.isNotEmpty ? schoolId : userId;

    if (serviceId.isNotEmpty && serviceData.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetId)
          .collection('deactivated_dl_services')
          .doc(serviceId)
          .set(serviceData);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetId)
          .collection('dl_services')
          .doc(serviceId)
          .delete();
    }
  }
}
