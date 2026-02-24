import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/controller/workspace_controller.dart';
import 'package:intl/intl.dart';
import 'package:mds/screens/widget/custom_back_button.dart';

class BranchesPage extends StatelessWidget {
  const BranchesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final WorkspaceController controller = Get.find<WorkspaceController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Branches'),
        leading: const CustomBackButton(),
        actions: [
          IconButton(
            onPressed: () => _showBranchForm(context),
            icon: const Icon(Icons.add_business),
            tooltip: 'Add Branch',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.ownedBranches.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_tree_outlined,
                    size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'No branches found',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('Create your first branch to get started'),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _showBranchForm(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Branch'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.ownedBranches.length,
          itemBuilder: (context, index) {
            final branch = controller.ownedBranches[index];
            final bool isActive =
                branch['id'] == controller.currentBranchId.value;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: isActive ? 4 : 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: isActive
                    ? const BorderSide(color: kPrimaryColor, width: 2)
                    : BorderSide.none,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                branch['branchName'] ?? 'Unnamed Branch',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (isActive) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Active',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showBranchForm(context, branch: branch);
                            } else if (value == 'delete') {
                              _confirmDelete(context, branch);
                            } else if (value == 'copy_id') {
                              _copyBranchId(context, branch['id']);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'copy_id',
                              child: Row(
                                children: [
                                  Icon(Icons.copy, size: 20),
                                  SizedBox(width: 8),
                                  Text('Copy Branch ID'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 20),
                                  SizedBox(width: 8),
                                  Text('Edit Branch'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete,
                                      size: 20, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete Branch',
                                      style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    if (branch['location'] != null &&
                        branch['location'].toString().isNotEmpty)
                      _buildInfoRow(
                          Icons.location_on_outlined, branch['location']),
                    if (branch['contactPhone'] != null &&
                        branch['contactPhone'].toString().isNotEmpty)
                      _buildInfoRow(
                          Icons.phone_outlined, branch['contactPhone']),
                    if (branch['contactEmail'] != null &&
                        branch['contactEmail'].toString().isNotEmpty)
                      _buildInfoRow(
                          Icons.email_outlined, branch['contactEmail']),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: isActive
                                ? null
                                : () => controller.switchBranch(branch['id']),
                            icon: const Icon(Icons.swap_horiz),
                            label: Text(isActive
                                ? 'Currently Active'
                                : 'Switch to Branch'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                                  isActive ? Colors.grey : kPrimaryColor,
                              side: BorderSide(
                                  color:
                                      isActive ? Colors.grey : kPrimaryColor),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey[800], fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showBranchForm(BuildContext context, {Map<String, dynamic>? branch}) {
    final WorkspaceController controller = Get.find<WorkspaceController>();

    // Form controllers
    final nameController = TextEditingController(text: branch?['branchName']);
    final locationController = TextEditingController(text: branch?['location']);
    final emailController =
        TextEditingController(text: branch?['contactEmail']);
    final phoneController =
        TextEditingController(text: branch?['contactPhone']);
    // String selectedType = branch?['branchType'] ?? 'Campus'; // Removed

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        bool isSubmitting = false;
        XFile? selectedLogo;
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickLogo() async {
              final ImagePicker picker = ImagePicker();
              final XFile? image = await picker.pickImage(
                  source: ImageSource.gallery, imageQuality: 50);
              if (image != null) {
                setModalState(() => selectedLogo = image);
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      branch == null ? 'Add New Branch' : 'Edit Branch',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: GestureDetector(
                        onTap: isSubmitting ? null : pickLogo,
                        child: Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: selectedLogo != null
                                    ? Image.file(File(selectedLogo!.path),
                                        fit: BoxFit.cover)
                                    : (branch?['logoUrl'] != null &&
                                            branch!['logoUrl'].isNotEmpty
                                        ? CachedNetworkImage(
                                            key: ValueKey(branch['logoUrl']),
                                            imageUrl: branch['logoUrl'],
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                const Icon(Icons.add_a_photo,
                                                    size: 40,
                                                    color: Colors.grey),
                                            errorWidget: (context, url,
                                                    error) =>
                                                const Icon(Icons.add_a_photo,
                                                    size: 40,
                                                    color: Colors.grey))
                                        : const Icon(Icons.add_a_photo,
                                            size: 40, color: Colors.grey)),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                    color: kPrimaryColor,
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.edit,
                                    size: 16, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: nameController,
                      enabled: !isSubmitting,
                      decoration: const InputDecoration(
                        labelText: 'Branch Name*',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business),
                      ),
                    ),
                    const SizedBox(height: 16),
                    /* Removed branchType dropdown */
                    const SizedBox(height: 16),
                    TextField(
                      controller: locationController,
                      enabled: !isSubmitting,
                      decoration: const InputDecoration(
                        labelText: 'Location/Address',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: emailController,
                      enabled: !isSubmitting,
                      decoration: const InputDecoration(
                        labelText: 'Contact Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: phoneController,
                      enabled: !isSubmitting,
                      decoration: const InputDecoration(
                        labelText: 'Contact Phone',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (nameController.text.trim().isEmpty) {
                                  Get.snackbar(
                                      'Error', 'Branch name is required',
                                      snackPosition: SnackPosition.BOTTOM);
                                  return;
                                }

                                setModalState(() => isSubmitting = true);

                                Map<String, dynamic> result;
                                try {
                                  if (branch == null) {
                                    result = await controller.createBranch(
                                      branchName: nameController.text.trim(),
                                      location: locationController.text.trim(),
                                      contactEmail: emailController.text.trim(),
                                      contactPhone: phoneController.text.trim(),
                                      logoFile: selectedLogo,
                                    );
                                  } else {
                                    result =
                                        await controller.updateBranchProfile(
                                      branch['id'],
                                      {
                                        'branchName':
                                            nameController.text.trim(),
                                        'location':
                                            locationController.text.trim(),
                                        'contactEmail':
                                            emailController.text.trim(),
                                        'contactPhone':
                                            phoneController.text.trim(),
                                      },
                                      logoFile: selectedLogo,
                                    );
                                  }

                                  if (result['success']) {
                                    Navigator.pop(context);
                                    Get.snackbar('Success', result['message'],
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor:
                                            Colors.green.withOpacity(0.1));
                                  } else {
                                    Get.snackbar('Error', result['message'],
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor:
                                            Colors.red.withOpacity(0.1));
                                  }
                                } finally {
                                  if (context.mounted) {
                                    setModalState(() => isSubmitting = false);
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Text(branch == null
                                ? 'Create Branch'
                                : 'Save Changes'),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, Map<String, dynamic> branch) {
    final WorkspaceController controller = Get.find<WorkspaceController>();

    Get.dialog(
      AlertDialog(
        title: const Text('Delete Branch?'),
        content: Text(
            'Are you sure you want to delete ${branch['branchName']}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              final result = await controller.deleteBranch(branch['id']);
              if (result['success']) {
                Get.snackbar('Success', result['message'],
                    backgroundColor: Colors.green.withOpacity(0.1));
              } else {
                Get.snackbar('Error', result['message'],
                    backgroundColor: Colors.red.withOpacity(0.1));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _copyBranchId(BuildContext context, String id) {
    final WorkspaceController controller = Get.find<WorkspaceController>();
    final schoolId = controller.currentSchoolId.value;
    final joinId = id == schoolId ? id : '$schoolId:$id';

    Clipboard.setData(ClipboardData(text: joinId));

    Get.snackbar(
      'Join ID Copied',
      joinId,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.white.withOpacity(0.9),
      colorText: kPrimaryColor,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.copy, color: kPrimaryColor),
    );
  }
}
