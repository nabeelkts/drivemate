import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mds/controller/workspace_controller.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/screens/dashboard/form/edit_forms/edit_endorsement_details_form.dart';
import 'package:mds/screens/dashboard/form/new_forms/endorment_dl_form.dart';
import 'package:mds/screens/dashboard/list/deactivated_endorsement_list.dart';
import 'package:mds/screens/dashboard/list/details/endorsement_details_page.dart';
import 'package:mds/screens/dashboard/list/widgets/list_item_card.dart';
import 'package:mds/screens/profile/dialog_box.dart';
import 'package:mds/screens/widget/base_list_widget.dart';

class EndorsementList extends StatelessWidget {
  final String userId;

  const EndorsementList({required this.userId, super.key});

  @override
  Widget build(BuildContext context) {
    return BaseListWidget(
      title: 'Endorsement List',
      collectionName: 'endorsement',
      searchField: 'fullName',
      addButtonText: 'Create New Endorsement',
      onAddNew: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const EndorsementDL()),
        );
      },
      onViewDeactivated: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const DeactivatedEndorsementList()),
        );
      },
      itemBuilder: (context, doc) {
        final data = doc.data();
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return ListItemCard(
          title: data['fullName'] ?? 'N/A',
          subTitle:
              'COV: ${data['cov'] ?? 'N/A'}\nMobile: ${data['mobileNumber'] ?? 'N/A'}',
          imageUrl: data['image'],
          isDark: isDark,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EndorsementDetailsPage(
                  endorsementDetails: data,
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
                title: const Text('Mark as Course Completed'),
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

  Widget _buildInitials(Map<String, dynamic> data) {
    final fullName = data['fullName'];
    return Center(
      child: Text(
        fullName != null && fullName.toString().isNotEmpty
            ? fullName[0].toUpperCase()
            : '',
        style: const TextStyle(
          fontSize: 28,
          color: kPrimaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context,
      String documentId, Map<String, dynamic> endorsementData) async {
    showCustomConfirmationDialog(
      context,
      'Confirm Course Completion',
      'Are you sure ?',
      () async {
        await _deleteData(documentId, endorsementData);
        Navigator.of(context).pop();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const DeactivatedEndorsementList(),
          ),
        );
      },
    );
  }

  Future<void> _deleteData(
      String endorsementId, Map<String, dynamic> endorsementData) async {
    final WorkspaceController workspaceController =
        Get.find<WorkspaceController>();
    final schoolId = workspaceController.currentSchoolId.value;
    final targetId = schoolId.isNotEmpty ? schoolId : userId;

    if (endorsementId.isNotEmpty && endorsementData.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetId)
          .collection('deactivated_endorsement')
          .doc(endorsementId)
          .set(endorsementData);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetId)
          .collection('endorsement')
          .doc(endorsementId)
          .delete();
    }
  }
}
