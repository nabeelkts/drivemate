import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/controller/workspace_controller.dart';
import 'package:mds/screens/profile/dialog_box.dart';

class ManageStaffPage extends StatefulWidget {
  const ManageStaffPage({super.key});

  @override
  State<ManageStaffPage> createState() => _ManageStaffPageState();
}

class _ManageStaffPageState extends State<ManageStaffPage> {
  final WorkspaceController _workspaceController =
      Get.find<WorkspaceController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardColor = isDark ? Colors.grey.shade900 : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Staff'),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('users')
            .where('schoolId',
                isEqualTo: _workspaceController.currentSchoolId.value)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allStaff = snapshot.data?.docs ?? [];
          // Filter out the owner
          final staff = allStaff
              .where(
                  (doc) => doc.id != _workspaceController.currentSchoolId.value)
              .toList();

          if (staff.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_off_outlined,
                      size: 64, color: textColor.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  Text(
                    'No staff members joined yet',
                    style: TextStyle(
                        color: textColor.withOpacity(0.5), fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: staff.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final member = staff[index].data() as Map<String, dynamic>;
              final memberId = staff[index].id;
              final name = member['name'] ?? 'No Name';
              final email = member['email'] ?? 'No Email';
              final photoUrl = member['photoURL'] as String?;

              return Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.05),
                  ),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundImage:
                        photoUrl != null ? NetworkImage(photoUrl) : null,
                    backgroundColor: kPrimaryColor.withOpacity(0.1),
                    child: photoUrl == null
                        ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(
                                color: kPrimaryColor,
                                fontWeight: FontWeight.bold))
                        : null,
                  ),
                  title: Text(
                    name,
                    style: TextStyle(
                        color: textColor, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    email,
                    style: TextStyle(
                        color: textColor.withOpacity(0.6), fontSize: 12),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.person_remove_outlined,
                        color: Colors.red),
                    onPressed: () =>
                        _showRemoveConfirmation(context, memberId, name),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showRemoveConfirmation(
      BuildContext context, String memberId, String name) {
    showCustomConfirmationDialog(
      context,
      'Remove Staff?',
      'Are you sure you want to remove $name from this school workspace? They will return to their personal workspace.',
      () async {
        try {
          // Reset the member's schoolId to their own UID
          await _firestore.collection('users').doc(memberId).update({
            'schoolId': memberId,
          });
          Get.snackbar("Success", "$name has been removed from the workspace",
              backgroundColor: Colors.green.withOpacity(0.1),
              colorText: Colors.green);
        } catch (e) {
          Get.snackbar("Error", "Failed to remove staff: $e",
              backgroundColor: Colors.red.withOpacity(0.1),
              colorText: Colors.red);
        }
      },
    );
  }
}
