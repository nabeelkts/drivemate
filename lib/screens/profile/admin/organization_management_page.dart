import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/controller/workspace_controller.dart';
import 'package:mds/screens/profile/admin/branches_page.dart';
import 'package:mds/screens/profile/admin/manage_staff_page.dart';
import 'package:mds/screens/profile/admin/staff_requests_page.dart';
import 'package:mds/screens/profile/edit_company_profile.dart';

class OrganizationManagementPage extends StatelessWidget {
  const OrganizationManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final WorkspaceController controller = Get.find<WorkspaceController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardColor = isDark ? Colors.grey.shade900 : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.userRole.value == 'Owner'
            ? 'Organization Management'
            : 'My Workplace')),
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final branchData = controller.currentBranchData;
        final branchId = controller.currentBranchId.value;
        final isOwner = controller.userRole.value == 'Owner';

        if (branchId.isEmpty) {
          return _buildNotConnectedState(context, controller, textColor);
        }

        return RefreshIndicator(
          onRefresh: () => controller.initializeWorkspace(),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context, controller, branchData, branchId,
                          isOwner, cardColor, textColor),
                      const SizedBox(height: 24),
                      _buildInfoSection(context, controller, branchData,
                          isOwner, cardColor, textColor),
                      const SizedBox(height: 24),
                      if (isOwner) ...[
                        _buildManagementSection(
                            context, controller, cardColor, textColor),
                        const SizedBox(height: 24),
                      ],
                      _buildActionSection(
                          context, controller, isOwner, cardColor, textColor),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildNotConnectedState(
      BuildContext context, WorkspaceController controller, Color textColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_outlined,
                size: 80, color: textColor.withOpacity(0.1)),
            const SizedBox(height: 24),
            Text(
              'No Active Workspace',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 12),
            Text(
              'You are not currently connected to any driving school branch.',
              textAlign: TextAlign.center,
              style: TextStyle(color: textColor.withOpacity(0.6)),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showJoinDialog(context, controller),
              icon: const Icon(Icons.add),
              label: const Text('Join a Branch'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WorkspaceController controller,
    Map<String, dynamic> data,
    String id,
    bool isOwner,
    Color cardColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildLogo(data['logoUrl'], 80),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['branchName'] ?? 'Unnamed Organization',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () {
                    final clipboardText = id == controller.currentSchoolId.value
                        ? id
                        : '${controller.currentSchoolId.value}:$id';
                    Clipboard.setData(ClipboardData(text: clipboardText));
                    Get.snackbar('Copied', 'ID copied to clipboard',
                        snackPosition: SnackPosition.TOP,
                        backgroundColor: Colors.white,
                        colorText: kPrimaryColor);
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          id == controller.currentSchoolId.value
                              ? 'School ID: $id'
                              : 'Branch Join ID: ${controller.currentSchoolId.value}:$id',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.copy,
                          size: 11, color: Colors.white.withOpacity(0.8)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(String? url, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: (url != null && url.isNotEmpty)
            ? CachedNetworkImage(
                key: ValueKey(url),
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    const Icon(Icons.business, size: 40, color: kPrimaryColor),
                errorWidget: (context, url, error) =>
                    const Icon(Icons.business, size: 40, color: kPrimaryColor),
              )
            : const Icon(Icons.business, size: 40, color: kPrimaryColor),
      ),
    );
  }

  Widget _buildInfoSection(
    BuildContext context,
    WorkspaceController controller,
    Map<String, dynamic> data,
    bool isOwner,
    Color cardColor,
    Color textColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
            'Active Branch Details',
            isOwner
                ? () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => EditCompanyProfile(
                                  initialData: data,
                                )));
                  }
                : null,
            isOwner ? 'Edit' : null),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: textColor.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              _buildInfoRow(IconlyLight.location, 'Address',
                  data['location'] ?? 'Not set', textColor),
              const Divider(height: 32),
              _buildInfoRow(IconlyLight.call, 'Phone',
                  data['contactPhone'] ?? 'Not set', textColor),
              const Divider(height: 32),
              _buildInfoRow(IconlyLight.message, 'Email',
                  data['contactEmail'] ?? 'Not set', textColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildManagementSection(
    BuildContext context,
    WorkspaceController controller,
    Color cardColor,
    Color textColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Management', null, null),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildManagementTile(
                context,
                IconlyLight.category,
                'Manage\nBranches',
                const BranchesPage(),
                kPrimaryColor,
                cardColor,
                textColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildManagementTile(
                context,
                IconlyLight.user_1,
                'Manage\nStaff',
                const ManageStaffPage(),
                Colors.orange,
                cardColor,
                textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildStaffRequestsTile(context, controller, cardColor, textColor),
      ],
    );
  }

  Widget _buildActionSection(
    BuildContext context,
    WorkspaceController controller,
    bool isOwner,
    Color cardColor,
    Color textColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Actions', null, null),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: textColor.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              _buildActionRow(IconlyLight.swap, 'Switch Branch',
                  () => _showBranchSelector(context, controller), textColor),
              if (!isOwner) ...[
                const Divider(height: 1),
                _buildActionRow(IconlyLight.close_square, 'Leave Branch',
                    () => _confirmLeave(context, controller), Colors.red),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(
      String title, VoidCallback? onAction, String? actionLabel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        if (onAction != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!,
                style: const TextStyle(fontSize: 13, color: kPrimaryColor)),
          ),
      ],
    );
  }

  Widget _buildInfoRow(
      IconData icon, String label, String value, Color textColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: textColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: textColor.withOpacity(0.7)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: textColor.withOpacity(0.5), fontSize: 11)),
              const SizedBox(height: 2),
              Text(value,
                  style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildManagementTile(
    BuildContext context,
    IconData icon,
    String label,
    Widget page,
    Color color,
    Color cardColor,
    Color textColor,
  ) {
    return InkWell(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (context) => page)),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: textColor.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  height: 1.2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffRequestsTile(
    BuildContext context,
    WorkspaceController controller,
    Color cardColor,
    Color textColor,
  ) {
    return StreamBuilder(
      stream:
          controller.getBranchJoinRequests(controller.currentBranchId.value),
      builder: (context, snapshot) {
        final count =
            snapshot.hasData ? (snapshot.data as dynamic).docs.length : 0;
        return InkWell(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const StaffRequestsPage())),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: textColor.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(IconlyLight.add_user,
                      color: Colors.blue, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Staff Requests',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(
                        count > 0
                            ? '$count pending requests'
                            : 'No pending requests',
                        style: TextStyle(
                            color: textColor.withOpacity(0.5), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                if (count > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20)),
                    child: Text('$count',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: textColor.withOpacity(0.3)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionRow(
      IconData icon, String label, VoidCallback onTap, Color color) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color.withOpacity(0.7), size: 20),
      title: Text(label,
          style: TextStyle(
              color: color, fontSize: 14, fontWeight: FontWeight.w500)),
      trailing:
          Icon(Icons.chevron_right, color: color.withOpacity(0.3), size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  void _showBranchSelector(
      BuildContext context, WorkspaceController controller) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Switch Branch',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: controller.ownedBranches.length,
                itemBuilder: (context, index) {
                  final branch = controller.ownedBranches[index];
                  final isCurrent =
                      branch['id'] == controller.currentBranchId.value;
                  return ListTile(
                    leading: _buildLogo(branch['logoUrl'], 40),
                    title: Text(branch['branchName'] ?? 'Unnamed Branch'),
                    trailing: isCurrent
                        ? const Icon(Icons.check_circle, color: kPrimaryColor)
                        : null,
                    onTap: () {
                      controller.switchBranch(branch['id']);
                      Get.back();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showJoinDialog(BuildContext context, WorkspaceController controller) {
    final TextEditingController idController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text('Join a Branch'),
        content: TextField(
          controller: idController,
          decoration: const InputDecoration(
            labelText: 'Branch ID',
            hintText: 'Enter the ID provided by your school owner',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (idController.text.trim().isEmpty) return;
              final result = await controller
                  .sendBranchJoinRequest(idController.text.trim());
              Get.back();
              Get.snackbar(
                  result['success'] ? 'Success' : 'Error', result['message']);
            },
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }

  void _confirmLeave(BuildContext context, WorkspaceController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Leave Branch?'),
        content: const Text(
            'Are you sure you want to leave this branch? You will need an invite to join again.'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await controller.leaveBranch();
              Get.back();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }
}
