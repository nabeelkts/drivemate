import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:drivemate/constants/colors.dart';
import 'package:drivemate/controller/workspace_controller.dart';
import 'package:drivemate/screens/profile/admin/school_vehicle_form.dart';
import 'package:drivemate/screens/profile/dialog_box.dart';
import 'package:drivemate/screens/widget/custom_back_button.dart';
import 'package:intl/intl.dart';

class ManageVehiclesPage extends StatelessWidget {
  const ManageVehiclesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final workspaceController = Get.find<WorkspaceController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardColor = isDark ? Colors.grey.shade900 : Colors.white;

    final schoolId = workspaceController.currentSchoolId.value;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final targetId = schoolId.isNotEmpty ? schoolId : userId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage School Vehicles'),
        leading: const CustomBackButton(),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(targetId)
            .collection('school_vehicles')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_car_outlined,
                      size: 80, color: textColor.withOpacity(0.1)),
                  const SizedBox(height: 16),
                  Text('No school vehicles added yet',
                      style: TextStyle(color: textColor.withOpacity(0.5))),
                ],
              ),
            );
          }

          final vehicles = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              final vehicle = vehicles[index].data() as Map<String, dynamic>;
              final id = vehicles[index].id;

              return _buildVehicleCard(
                  context, vehicle, id, cardColor, textColor);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SchoolVehicleForm()),
        ),
        backgroundColor: kPrimaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Vehicle', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildVehicleCard(BuildContext context, Map<String, dynamic> data,
      String id, Color cardColor, Color textColor) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: textColor.withOpacity(0.1)),
      ),
      color: cardColor,
      child: ExpansionTile(
        title: Text(data['vehicleNumber'] ?? 'N/A',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(data['model'] ?? 'N/A',
            style: TextStyle(color: textColor.withOpacity(0.6))),
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined, size: 20),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  SchoolVehicleForm(initialData: data, vehicleId: id),
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildExpiryRow(
                    'Fitness Expiry', data['fitnessExpiry'], textColor),
                const Divider(),
                _buildExpiryRow(
                    'Insurance Expiry', data['insuranceExpiry'], textColor),
                const Divider(),
                _buildExpiryRow(
                    'Pollution Expiry', data['pollutionExpiry'], textColor),
                const Divider(),
                _buildExpiryRow('Tax Expiry', data['taxExpiry'], textColor),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _confirmDelete(context, id),
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.red, size: 18),
                    label: const Text('Delete Vehicle',
                        style: TextStyle(color: Colors.red, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiryRow(String label, dynamic timestamp, Color textColor) {
    DateTime? date;
    if (timestamp != null) {
      date = (timestamp as Timestamp).toDate();
    }

    final isUrgent =
        date != null && date.difference(DateTime.now()).inDays <= 30;
    final color = isUrgent ? Colors.red : textColor.withOpacity(0.6);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  TextStyle(color: textColor.withOpacity(0.5), fontSize: 13)),
          Text(
            date != null ? DateFormat('dd MMM yyyy').format(date) : 'Not set',
            style: TextStyle(
              color: color,
              fontWeight: isUrgent ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showCustomConfirmationDialog(
      context,
      'Delete Vehicle?',
      'Are you sure you want to remove this vehicle from school fleet?',
      () async {
        final workspaceController = Get.find<WorkspaceController>();
        final targetId = workspaceController.currentSchoolId.value.isNotEmpty
            ? workspaceController.currentSchoolId.value
            : FirebaseAuth.instance.currentUser?.uid;

        if (targetId != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(targetId)
              .collection('school_vehicles')
              .doc(id)
              .delete();
          Get.snackbar('Deleted', 'Vehicle removed successfully',
              backgroundColor: Colors.red, colorText: Colors.white);
        }
      },
      confirmText: 'Delete',
      cancelText: 'Cancel',
    );
  }
}
