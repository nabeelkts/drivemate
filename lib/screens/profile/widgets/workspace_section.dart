import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/controller/workspace_controller.dart';
import 'package:mds/screens/profile/admin/manage_staff_page.dart';

class WorkspaceSection extends StatelessWidget {
  final Color cardColor;
  final Color borderColor;
  final Color textColor;
  final VoidCallback onJoinSchool;

  const WorkspaceSection({
    super.key,
    required this.cardColor,
    required this.borderColor,
    required this.textColor,
    required this.onJoinSchool,
  });

  @override
  Widget build(BuildContext context) {
    final WorkspaceController workspaceController =
        Get.find<WorkspaceController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final schoolId = workspaceController.currentSchoolId.value;
      final isStaff = workspaceController.userRole.value == 'Staff';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('School Workspace',
              style: TextStyle(
                  color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
                width: 1,
              ),
            ),
            child: schoolId.isEmpty
                ? _buildEmptyState(textColor)
                : _buildConnectedState(
                    context, workspaceController, schoolId, isStaff),
          ),
        ],
      );
    });
  }

  Widget _buildEmptyState(Color textColor) {
    return Column(
      children: [
        Icon(Icons.school_outlined,
            size: 40, color: textColor.withOpacity(0.2)),
        const SizedBox(height: 8),
        Text('Not connected to any school',
            style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 12)),
        const SizedBox(height: 12),
        _buildActionChip(
          icon: Icons.add,
          label: 'Join School',
          onTap: onJoinSchool,
        ),
      ],
    );
  }

  Widget _buildConnectedState(BuildContext context,
      WorkspaceController controller, String schoolId, bool isStaff) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.school, color: kPrimaryColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Connected School',
                      style: TextStyle(
                          color: textColor.withOpacity(0.5), fontSize: 11)),
                  Text(
                    schoolId,
                    style: TextStyle(
                        color: textColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: schoolId));
                Get.snackbar(
                  "Copied",
                  "School ID copied to clipboard",
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: kPrimaryColor.withOpacity(0.1),
                  colorText: textColor,
                  duration: const Duration(seconds: 1),
                );
              },
              icon: Icon(Icons.copy_rounded,
                  size: 18, color: kPrimaryColor.withOpacity(0.7)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            if (isStaff || controller.userRole.value == 'Owner')
              _buildActionChip(
                icon: Icons.swap_horiz,
                label: 'Switch',
                onTap: onJoinSchool,
              ),
            if (isStaff && controller.userRole.value == 'Owner')
              const SizedBox(width: 8),
            if (controller.userRole.value == 'Owner')
              _buildActionChip(
                icon: Icons.people_outline,
                label: 'Manage Staff',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ManageStaffPage(),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: kPrimaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: kPrimaryColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: kPrimaryColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: kPrimaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
