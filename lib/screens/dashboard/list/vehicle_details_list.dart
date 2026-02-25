import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mds/controller/workspace_controller.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/screens/dashboard/form/edit_forms/edit_vehicle_details_form.dart';
import 'package:mds/screens/dashboard/form/new_forms/vehicle_details_form.dart';
import 'package:mds/screens/dashboard/list/deactivated_vehicle_details_list.dart';
import 'package:mds/screens/dashboard/list/details/vehicle_details_page.dart';
import 'package:mds/screens/dashboard/list/widgets/list_item_card.dart';
import 'package:mds/screens/profile/dialog_box.dart';
import 'package:mds/screens/widget/base_list_widget.dart';

class VehicleDetailsList extends StatelessWidget {
  const VehicleDetailsList({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseListWidget(
      title: 'Vehicle Details List',
      collectionName: 'vehicleDetails',
      searchField: 'fullName',
      summaryLabel: 'Total Vehicles:',
      addButtonText: 'Create New Vehicle Details',
      onAddNew: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const VehicleDetails()),
        );
      },
      onViewDeactivated: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const DeactivatedVehicleDetailsList()),
        );
      },
      itemBuilder: (context, doc) {
        final data = doc.data();
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return ListItemCard(
          title: data['vehicleNumber'] ?? 'N/A',
          subTitle:
              'COV: ${data['cov'] ?? 'N/A'}\nMobile: ${data['mobileNumber'] ?? 'N/A'}',
          imageUrl: data['image'],
          isDark: isDark,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VehicleDetailsPage(
                  vehicleDetails: data,
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
                title: const Text('Services Completed'),
                onTap: () async {
                  Navigator.pop(context);
                  _showDeleteConfirmationDialog(context, doc.id, doc.data());
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deactivateVehicle(
      String vehicleId, Map<String, dynamic> vehicleData) async {
    final WorkspaceController workspaceController =
        Get.find<WorkspaceController>();
    final schoolId = workspaceController.currentSchoolId.value;
    final targetId =
        schoolId.isNotEmpty ? schoolId : FirebaseAuth.instance.currentUser?.uid;

    if (vehicleId.isNotEmpty && vehicleData.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetId)
          .collection('deactivated_vehicleDetails')
          .doc(vehicleId)
          .set(vehicleData);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetId)
          .collection('vehicleDetails')
          .doc(vehicleId)
          .delete();
    }
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context,
      String documentId, Map<String, dynamic> vehicleData) async {
    showCustomConfirmationDialog(
      context,
      'Confirm Services Completion',
      'Are you sure ?',
      () async {
        await _deactivateVehicle(documentId, vehicleData);
        Navigator.of(context).pop();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const DeactivatedVehicleDetailsList(),
          ),
        );
      },
    );
  }
}
