import 'package:drivemate/widgets/persistent_cached_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:drivemate/screens/profile/dialog_box.dart';
import 'package:iconly/iconly.dart';
import 'package:drivemate/constants/colors.dart';
import 'package:drivemate/controller/workspace_controller.dart';
import 'package:drivemate/screens/profile/admin/branches_page.dart';
import 'package:drivemate/screens/profile/admin/manage_staff_page.dart';
import 'package:drivemate/screens/profile/admin/staff_requests_page.dart';
import 'package:drivemate/screens/profile/admin/manage_vehicles_page.dart';
import 'package:drivemate/screens/profile/edit_company_profile.dart';
import 'package:drivemate/screens/widget/custom_back_button.dart';

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
        leading: const CustomBackButton(),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        // Explicitly access reactive observables to ensure Obx tracks them
        final branchId = controller.currentBranchId.value;
        final ownedBranches = controller.ownedBranches;
        final companyData = controller.companyData;
        final staffBranchData = controller.staffBranchData;
        final isOwner = controller.userRole.value == 'Owner';
        final isConnected = controller.isConnected.value;
        
        // Compute branchData based on role
        Map<String, dynamic> branchData = {};
        if (branchId.isEmpty) {
          if (companyData.isNotEmpty) {
            branchData = {
              'id': controller.targetId,
              'branchName': companyData['companyName'] ?? companyData['branchName'] ?? 'Main Branch',
              'logoUrl': companyData['companyLogo'] ?? companyData['logoUrl'],
              'location': companyData['companyAddress'] ?? companyData['location'],
              'contactPhone': companyData['companyPhone'] ?? companyData['contactPhone'],
              'contactEmail': companyData['companyEmail'] ?? companyData['contactEmail'],
            };
          }
        } else {
          final branch = ownedBranches.firstWhere(
            (b) => b['id'] == branchId,
            orElse: () => {},
          );
          if (branch.isNotEmpty) {
            branchData = branch;
          } else if (staffBranchData.isNotEmpty) {
            branchData = staffBranchData;
          } else if (companyData.isNotEmpty) {
            // For staff connected to a branch: use companyData as fallback
            branchData = {
              'id': branchId,
              'branchName': companyData['branchName'] ?? companyData['companyName'] ?? 'Branch',
              'logoUrl': companyData['logoUrl'] ?? companyData['companyLogo'],
              'location': companyData['location'] ?? companyData['companyAddress'],
              'contactPhone': companyData['contactPhone'] ?? companyData['companyPhone'],
              'contactEmail': companyData['contactEmail'] ?? companyData['companyEmail'],
            };
          }
        }
        
        final hasBranchData = branchData.isNotEmpty;

        if (!isConnected && !hasBranchData) {
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
            ? PersistentCachedImage(
                imageUrl: url,
                fit: BoxFit.cover,
                memCacheWidth: 100,
                memCacheHeight: 100,
                placeholder:
                    const Icon(Icons.business, size: 40, color: kPrimaryColor),
                errorWidget:
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
        Row(
          children: [
            Expanded(
              child: _buildManagementTile(
                context,
                Icons.directions_car_outlined,
                'Manage\nVehicles',
                const ManageVehiclesPage(),
                Colors.blue,
                cardColor,
                textColor,
              ),
            ),
            const SizedBox(width: 12),
            const Spacer(),
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
    final isStaff = controller.userRole.value == 'Staff';
    final isConnected = controller.isConnected.value;
    final showSwitchBranch = isOwner && controller.ownedBranches.length > 1;
    final showLeaveBranch = isStaff && isConnected;

    // For disconnected staff, show join option
    if (isStaff && !isConnected) {
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
            child: _buildActionRow(
              Icons.add_business_outlined,
              'Join School Workspace',
              () => _showJoinSchoolDialog(context, controller),
              kPrimaryColor,
            ),
          ),
        ],
      );
    }

    if (!showSwitchBranch && !showLeaveBranch) {
      return const SizedBox.shrink();
    }

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
              if (showSwitchBranch)
                _buildActionRow(IconlyLight.swap, 'Switch Branch',
                    () => _showBranchSelector(context, controller), textColor),
              if (showSwitchBranch && showLeaveBranch) const Divider(height: 1),
              if (showLeaveBranch)
                _buildActionRow(IconlyLight.close_square, 'Leave Branch',
                    () => _confirmLeave(context, controller), Colors.red),
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
    showCustomConfirmationDialog(
      context,
      'Leave Branch?',
      'Are you sure you want to leave this branch? You will need an invite to join again.',
      () async {
        await controller.leaveBranch();
        // Navigator.pop(context) once will close the dialog
        // showCustomConfirmationDialog will then automatically pop AGAIN, closing the page
        Navigator.of(context).pop();
      },
      confirmText: 'Leave',
      cancelText: 'Cancel',
    );
  }

  Future<void> _showJoinSchoolDialog(
      BuildContext context, WorkspaceController controller) async {
    final TextEditingController idController = TextEditingController();
    final bool? confirmed = await showCustomStatefulDialogResult<bool>(
      context,
      'Join School Workspace',
      (ctx, setDialogState, choose) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          const Text(
            'Enter the School ID provided by your administrator.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: idController,
            decoration: InputDecoration(
              hintText: 'Enter School ID',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
      confirmText: 'Join',
      cancelText: 'Cancel',
      onConfirmResult: () => true,
    );
    if (confirmed == true) {
      final id = idController.text.trim();
      if (id.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a School ID')));
        return;
      }
      final result = await controller.joinSchool(id);
      if (!context.mounted) return;
      if (result['success'] == true) {
        Get.snackbar(
          'Success',
          result['message'] ?? 'Joined school workspace successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.1),
          duration: const Duration(seconds: 2),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to join school')),
        );
      }
    }
  }
}
