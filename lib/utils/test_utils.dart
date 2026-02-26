import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:mds/utils/date_utils.dart';
import 'package:mds/controller/workspace_controller.dart';

class TestUtils {
  static Future<void> showUpdateTestDateDialog({
    required BuildContext context,
    required Map<String, dynamic> item,
    required String collection,
    required String studentId,
    VoidCallback? onUpdate,
  }) async {
    final WorkspaceController workspaceController =
        Get.find<WorkspaceController>();

    final llDisplayController = TextEditingController(
        text: AppDateUtils.formatDateForDisplay(
            item['learnersTestDate']?.toString()));
    final dlDisplayController = TextEditingController(
        text: AppDateUtils.formatDateForDisplay(
            item['drivingTestDate']?.toString()));

    String tempLLStorage = item['learnersTestDate']?.toString() ?? '';
    String tempDLStorage = item['drivingTestDate']?.toString() ?? '';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Update Test Dates\n${item['fullName']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDateField(
                  context, 'Learners Test (LL)', llDisplayController,
                  (storageDate) {
                tempLLStorage = storageDate;
              }),
              const SizedBox(height: 16),
              _buildDateField(context, 'Driving Test (DL)', dlDisplayController,
                  (storageDate) {
                tempDLStorage = storageDate;
              }),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                await _updateDates(
                  context: context,
                  workspaceController: workspaceController,
                  collection: collection,
                  studentId: studentId,
                  llDate: tempLLStorage,
                  dlDate: tempDLStorage,
                );
                Navigator.pop(context);
                if (onUpdate != null) onUpdate();
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildDateField(
      BuildContext context,
      String label,
      TextEditingController displayController,
      Function(String) onDateSelected) {
    return TextFormField(
      controller: displayController,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(IconlyLight.calendar),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onTap: () async {
        final initialDate = displayController.text.isNotEmpty
            ? AppDateUtils.parseDisplayDate(displayController.text)
            : DateTime.now();

        final date = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: AppDateUtils.firstDate,
          lastDate: AppDateUtils.lastDate,
        );
        if (date != null) {
          final storageDate =
              DateFormat(AppDateUtils.storageFormat).format(date);
          final displayDate =
              DateFormat(AppDateUtils.displayFormat).format(date);
          displayController.text = displayDate;
          onDateSelected(storageDate);
        }
      },
    );
  }

  static Future<void> _updateDates({
    required BuildContext context,
    required WorkspaceController workspaceController,
    required String collection,
    required String studentId,
    required String llDate,
    required String dlDate,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final schoolId = workspaceController.currentSchoolId.value;
    final targetId = schoolId.isNotEmpty ? schoolId : user.uid;

    try {
      // The document ID is studentId (the internal doc ID)
      // Usually in detail pages, studentDetails['studentId'] is passed or we have the doc ID.
      // We need the ACTUAL Firestore document ID.

      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetId)
          .collection(collection)
          .doc(studentId)
          .update({
        'learnersTestDate': llDate,
        'drivingTestDate': dlDate,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dates updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating dates: $e')),
      );
    }
  }
}
