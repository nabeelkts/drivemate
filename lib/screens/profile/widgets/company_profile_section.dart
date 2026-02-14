import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/controller/workspace_controller.dart';
import 'package:mds/screens/profile/edit_company_profile.dart';

class CompanyProfileSection extends StatelessWidget {
  final Color cardColor;
  final Color textColor;

  const CompanyProfileSection({
    super.key,
    required this.cardColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final WorkspaceController workspaceController =
        Get.find<WorkspaceController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final schoolId = workspaceController.currentSchoolId.value;
      if (schoolId.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Company Profile',
              style: TextStyle(
                  color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              if (workspaceController.userRole.value == 'Staff') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Staff members cannot edit school profile')),
                );
                return;
              }
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditCompanyProfile(
                      initialData: workspaceController.companyData),
                ),
              );
              if (result == true) {
                workspaceController.refreshAppData();
              }
            },
            child: Container(
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
              child: Row(
                children: [
                  _buildCompanyLogo(workspaceController),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workspaceController.companyData['companyName'] ??
                              'Driving School Name',
                          style: TextStyle(
                              color: textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          workspaceController.companyData['companyAddress'] ??
                              'Address not set',
                          style: TextStyle(
                              color: textColor.withOpacity(0.5), fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.phone_outlined,
                                size: 12, color: textColor.withOpacity(0.4)),
                            const SizedBox(width: 4),
                            Text(
                              workspaceController.companyData['companyPhone'] ??
                                  'Phone not set',
                              style: TextStyle(
                                  color: textColor.withOpacity(0.5),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.edit_outlined,
                      size: 18, color: kPrimaryColor.withOpacity(0.7)),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildCompanyLogo(WorkspaceController controller) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: kOrange.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: kOrange.withOpacity(0.2), width: 1),
      ),
      child: Center(
        child: controller.companyData['companyLogo'] != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: Image.network(
                  controller.companyData['companyLogo'],
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              )
            : const Icon(Icons.business, color: kOrange, size: 24),
      ),
    );
  }
}
