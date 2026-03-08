import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drivemate/constants/colors.dart';
import 'package:drivemate/services/soft_delete_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// SoftDeleteButton - A reusable widget for adding soft delete functionality to any screen
class SoftDeleteButton extends StatelessWidget {
  final DocumentReference docRef;
  final String documentName;
  final VoidCallback? onDeleteSuccess;

  const SoftDeleteButton({
    required this.docRef,
    required this.documentName,
    this.onDeleteSuccess,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.delete_outline),
      tooltip: 'Move to Recycle Bin',
      onPressed: () => _confirmSoftDelete(context),
    );
  }

  void _confirmSoftDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Move to Recycle Bin?'),
        content: Text(
            'Move "$documentName" to recycle bin?\n\nIt will be automatically deleted after 90 days if not restored.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _performSoftDelete();
            },
            icon: const Icon(Icons.delete),
            label: const Text('Move to Recycle Bin'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performSoftDelete() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      await SoftDeleteService.softDelete(
        docRef: docRef,
        userId: user.uid,
        documentName: documentName, // Pass the document name
      );

      if (onDeleteSuccess != null) {
        onDeleteSuccess!();
      } else {
        Get.back(); // Close current screen/dialog
      }

      Get.snackbar(
        'Success',
        'Moved to recycle bin',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to move to recycle bin: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
