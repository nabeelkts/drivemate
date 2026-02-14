import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/controller/workspace_controller.dart';
import 'package:mds/screens/profile/edit_user_profile.dart';

class ProfileHeader extends StatelessWidget {
  final User? currentUser;
  final Color cardColor;
  final Color textColor;
  final String lastLoginTime;

  const ProfileHeader({
    super.key,
    required this.currentUser,
    required this.cardColor,
    required this.textColor,
    required this.lastLoginTime,
  });

  @override
  Widget build(BuildContext context) {
    final WorkspaceController workspaceController =
        Get.find<WorkspaceController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () async {
        if (workspaceController.userRole.value == 'Staff') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Staff members cannot edit profile details')),
          );
          return;
        }
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditUserProfile(
                initialData: workspaceController.userProfileData),
          ),
        );
        if (result == true) {
          workspaceController.refreshAppData();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
            width: 1.5,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            _buildAvatar(workspaceController),
            const SizedBox(width: 20),
            _buildUserInfo(workspaceController),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: textColor.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(WorkspaceController workspaceController) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: kOrange.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: CircleAvatar(
        radius: 38,
        backgroundColor: kPrimaryColor.withOpacity(0.1),
        backgroundImage: currentUser?.photoURL != null
            ? CachedNetworkImageProvider(currentUser!.photoURL!)
            : null,
        child: currentUser?.photoURL == null
            ? Obx(() {
                final profileData = workspaceController.userProfileData;
                return Text(
                  (profileData['name']?.isNotEmpty ?? false)
                      ? profileData['name'][0].toUpperCase()
                      : ((currentUser?.displayName?.isNotEmpty ?? false)
                          ? currentUser!.displayName![0].toUpperCase()
                          : '?'),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                );
              })
            : null,
      ),
    );
  }

  Widget _buildUserInfo(WorkspaceController workspaceController) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() {
            return Text(
              workspaceController.userProfileData['name'] ??
                  currentUser?.displayName ??
                  'User',
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            );
          }),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              currentUser?.email ?? 'N/A',
              style: const TextStyle(
                color: kPrimaryColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.history, size: 12, color: textColor.withOpacity(0.4)),
              const SizedBox(width: 4),
              Text(
                'Last Login: $lastLoginTime',
                style: TextStyle(
                  color: textColor.withOpacity(0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
