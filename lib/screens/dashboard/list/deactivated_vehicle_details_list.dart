import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/screens/dashboard/list/details/vehicle_details_page.dart';
import 'package:mds/screens/profile/dialog_box.dart';
import 'package:mds/screens/dashboard/list/widgets/list_item_card.dart';
import 'package:mds/screens/widget/base_list_widget.dart';
import 'package:get/get.dart';
import 'package:mds/controller/workspace_controller.dart';

class DeactivatedVehicleDetailsList extends StatelessWidget {
  const DeactivatedVehicleDetailsList({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseListWidget(
      title: 'Services Completed Vehicles',
      collectionName: 'deactivated_vehicleDetails',
      searchField: 'fullName',
      onAddNew: null,
      onViewDeactivated: null,
      itemBuilder: (context, doc) {
        try {
          final data = Map<String, dynamic>.from(doc.data());
          data['id'] = doc.id; // Add document ID to data map

          final isDark = Theme.of(context).brightness == Brightness.dark;
          return ListItemCard(
            title: data['fullName'] ?? 'No Name',
            subTitle:
                'COV: ${data['cov'] ?? 'N/A'}\nMobile: ${data['mobileNumber'] ?? 'N/A'}',
            imageUrl: data['image'],
            isDark: isDark,
            onTap: () {
              try {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VehicleDetailsPage(
                      vehicleDetails: data,
                    ),
                  ),
                );
              } catch (e) {
                _showErrorSnackBar(
                    context, 'Failed to view vehicle details: $e');
              }
            },
            onMenuPressed: () {
              _showMenuOptions(context, doc);
            },
          );
        } catch (e) {
          return _buildErrorCard(context, e.toString());
        }
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
                leading: const Icon(Icons.directions_car, color: kPrimaryColor),
                title: const Text('Reactivate Vehicle'),
                onTap: () async {
                  Navigator.pop(context);
                  await _showReactivateConfirmationDialog(
                      context, doc.id, doc.data());
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _getInitial(String? name) {
    if (name == null || name.isEmpty) return '?';
    try {
      return name.substring(0, 1).toUpperCase();
    } catch (e) {
      return '?';
    }
  }

  String _formatBalance(dynamic balance) {
    try {
      if (balance == null) return '0';
      return balance.toString();
    } catch (e) {
      return '0';
    }
  }

  Widget _buildErrorCard(BuildContext context, String error) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          color: kRedInactiveTextColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kRedInactiveTextColor),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: kRedInactiveTextColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Error loading vehicle: $error',
                  style: const TextStyle(color: kRedInactiveTextColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _reactivateVehicle(
      String vehicleId, Map<String, dynamic> vehicleData) async {
    if (vehicleId.isEmpty) {
      throw Exception('Invalid vehicle ID');
    }
    if (vehicleData.isEmpty) {
      throw Exception('Vehicle data is empty');
    }

    final user = FirebaseAuth.instance.currentUser;
    final WorkspaceController workspaceController =
        Get.find<WorkspaceController>();
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final schoolId = workspaceController.currentSchoolId.value;
    final targetId = schoolId.isNotEmpty ? schoolId : user.uid;

    try {
      // Check if vehicle already exists in active collection
      final existingDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(targetId)
          .collection('vehicleDetails')
          .doc(vehicleId)
          .get();

      if (existingDoc.exists) {
        throw Exception('Vehicle is already active');
      }

      // Add to active vehicles
      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetId)
          .collection('vehicleDetails')
          .doc(vehicleId)
          .set(vehicleData);

      // Remove from deactivated vehicles
      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetId)
          .collection('deactivated_vehicleDetails')
          .doc(vehicleId)
          .delete();
    } on FirebaseException catch (e) {
      throw Exception('Firebase error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to reactivate vehicle: $e');
    }
  }

  Future<void> _showReactivateConfirmationDialog(BuildContext context,
      String documentId, Map<String, dynamic> vehicleData) async {
    try {
      showCustomConfirmationDialog(
        context,
        'Confirm Reactivation?',
        'Are you sure you want to reactivate this vehicle?',
        () async {
          try {
            await _reactivateVehicle(documentId, vehicleData);
            if (context.mounted) {
              Navigator.of(context).pop(); // Close dialog
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const DeactivatedVehicleDetailsList(),
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              Navigator.of(context).pop(); // Close dialog
              _showErrorSnackBar(context, e.toString());
            }
          }
        },
      );
    } catch (e) {
      _showErrorSnackBar(context, 'Failed to show confirmation dialog: $e');
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: kRedInactiveTextColor,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: kWhite,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
