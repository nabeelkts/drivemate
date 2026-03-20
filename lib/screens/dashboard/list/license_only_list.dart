import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:drivemate/controller/workspace_controller.dart';
import 'package:drivemate/constants/colors.dart';
import 'package:drivemate/screens/dashboard/form/edit_forms/edit_licence_only_details_form.dart';
import 'package:drivemate/screens/dashboard/form/new_forms/license_only_form.dart';
import 'package:drivemate/screens/dashboard/list/deactivated_licenseonly_list.dart';
import 'package:drivemate/screens/dashboard/list/details/license_only_details_page.dart';
import 'package:drivemate/screens/dashboard/list/widgets/list_item_card.dart';
import 'package:drivemate/screens/profile/dialog_box.dart';
import 'package:drivemate/screens/widget/base_list_widget.dart';
import 'package:drivemate/services/excel_import_service.dart';
import 'package:drivemate/screens/dashboard/import/import_screen.dart';

class LicenseOnlyList extends StatelessWidget {
  final String userId;

  const LicenseOnlyList({required this.userId, super.key});

  @override
  Widget build(BuildContext context) {
    return BaseListWidget(
      title: 'License Only List',
      collectionName: 'licenseonly',
      searchField: 'fullName',
      secondarySearchField: 'mobileNumber', // Mobile number search
      summaryLabel: 'Total:',
      addButtonText: 'Create New License Only',
      onAddNew: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LicenseOnly()),
        );
      },
      onViewDeactivated: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const DeactivatedLicenseOnlyList()),
        );
      },
      onImport: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ImportScreen(
              importType: ImportType.licenseOnly,
            ),
          ),
        );
      },
      exportType: ImportType.licenseOnly,
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
              'COV: ${data['cov'] ?? 'N/A'}\nMobile: ${data['mobileNumber'] ?? 'N/A'}',
          imageUrl: data['image'],
          isDark: isDark,
          status: data['testStatus'],
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LicenseOnlyDetailsPage(
                  licenseDetails: data,
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
              const Padding(
                padding: EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Student Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Test Passed'),
                onTap: () async {
                  Navigator.pop(context);
                  await _showStatusConfirmationDialog(
                      context, doc.id, doc.data(), 'passed');
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.red),
                title: const Text('Test Failed'),
                onTap: () async {
                  Navigator.pop(context);
                  await _showStatusConfirmationDialog(
                      context, doc.id, doc.data(), 'failed');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateLicenseStatus(
      String licenseId, Map<String, dynamic> licenseData, String status) async {
    final WorkspaceController workspaceController =
        Get.find<WorkspaceController>();
    final schoolId = workspaceController.currentSchoolId.value;
    final targetId = schoolId.isNotEmpty ? schoolId : userId;

    if (licenseId.isNotEmpty && licenseData.isNotEmpty) {
      // Add status to license data
      licenseData['testStatus'] = status;
      licenseData['testDate'] = DateTime.now().toIso8601String();

      if (status == 'passed') {
        // Move to course completed (deactivated_licenseOnly)
        await FirebaseFirestore.instance
            .collection('users')
            .doc(targetId)
            .collection('deactivated_licenseOnly')
            .doc(licenseId)
            .set(licenseData);

        await FirebaseFirestore.instance
            .collection('users')
            .doc(targetId)
            .collection('licenseonly')
            .doc(licenseId)
            .delete();
      } else {
        // Just update the status in place for failed
        await FirebaseFirestore.instance
            .collection('users')
            .doc(targetId)
            .collection('licenseonly')
            .doc(licenseId)
            .update({
          'testStatus': status,
          'testDate': DateTime.now().toIso8601String(),
        });
      }
    }
  }

  Future<void> _showStatusConfirmationDialog(
      BuildContext context,
      String documentId,
      Map<String, dynamic> licenseData,
      String status) async {
    final isPassed = status == 'passed';
    showCustomConfirmationDialog(
      context,
      isPassed ? 'Confirm Test Passed' : 'Confirm Test Failed',
      isPassed
          ? 'Are you sure the student passed the test? This will move them to Course Completed.'
          : 'Are you sure the student failed the test? A failed badge will be shown.',
      () async {
        await _updateLicenseStatus(documentId, licenseData, status);
        // Navigator.pop is now handled automatically by showCustomConfirmationDialog

        // Navigate to deactivated list after a brief delay
        if (isPassed && context.mounted) {
          // Use Get.off for safer navigation
          Get.off(() => const DeactivatedLicenseOnlyList());
        }
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
}
