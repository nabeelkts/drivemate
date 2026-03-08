import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drivemate/constants/colors.dart';
import 'package:drivemate/constants/constant.dart';
import 'package:drivemate/services/soft_delete_service.dart';
import 'package:drivemate/controller/workspace_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RecycleBinScreen extends StatefulWidget {
  const RecycleBinScreen({super.key});

  @override
  State<RecycleBinScreen> createState() => _RecycleBinScreenState();
}

class _RecycleBinScreenState extends State<RecycleBinScreen> {
  final WorkspaceController _workspaceController =
      Get.find<WorkspaceController>();
  final User? user = FirebaseAuth.instance.currentUser;

  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
      appBar: AppBar(
        title: const Text('Recycle Bin'),
        //backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Cleanup Expired',
            onPressed: _cleanupExpiredItems,
          ),
        ],
      ),
      body: Column(
        children: [
          // Info Banner
          _buildInfoBanner(),

          // Filter Chips
          _buildFilterChips(),

          // Deleted Items List
          Expanded(
            child: _buildDeletedItemsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kOrange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kOrange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: kOrange, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Deleted items are kept for 90 days',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Get.isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  'Items older than 90 days will be automatically deleted',
                  style: TextStyle(
                    fontSize: 12,
                    color: (Get.isDarkMode ? Colors.white : Colors.black87)
                        .withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          'All',
          'Students',
          'License',
          'Endorsement',
          'Vehicle',
          'DL Services'
        ]
            .map((filter) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: _selectedFilter == filter,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildDeletedItemsList() {
    final targetId = _workspaceController.currentSchoolId.value.isNotEmpty
        ? _workspaceController.currentSchoolId.value
        : (user?.uid ?? '');
    final branchId = _workspaceController.currentBranchId.value;
    final isOrg = _workspaceController.isOrganizationMode.value;

    return StreamBuilder<List<DeletedItem>>(
      stream: SoftDeleteService.getDeletedItems(
        userId: targetId,
        branchId: branchId,
        isOrganization: isOrg,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Error loading deleted items',
                  style: TextStyle(
                    color: Get.isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var items = snapshot.data!;

        // Apply filter
        if (_selectedFilter != 'All') {
          items = items.where((item) {
            switch (_selectedFilter) {
              case 'Students':
                return item.collectionType == 'students';
              case 'License':
                return item.collectionType == 'licenseonly';
              case 'Endorsement':
                return item.collectionType == 'endorsement';
              case 'Vehicle':
                return item.collectionType == 'vehicleDetails' ||
                    item.collectionType == 'rc_services';
              case 'DL Services':
                return item.collectionType == 'dl_services';
              default:
                return true;
            }
          }).toList();
        }

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No deleted items',
                  style: TextStyle(
                    fontSize: 16,
                    color: (Get.isDarkMode ? Colors.white : Colors.black87)
                        .withOpacity(0.5),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _buildDeletedItemCard(item);
          },
        );
      },
    );
  }

  Widget _buildDeletedItemCard(DeletedItem item) {
    final isExpiringSoon = item.daysRemaining <= 7;
    final textColor = Get.isDarkMode ? Colors.white : Colors.black87;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Colors.red[50]!,
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.red[100],
                backgroundImage:
                    item.imageUrl != null && item.imageUrl!.isNotEmpty
                        ? NetworkImage(item.imageUrl!)
                        : null,
                child: item.imageUrl == null || item.imageUrl!.isEmpty
                    ? Icon(Icons.person, color: Colors.red[700])
                    : null,
              ),
              title: Text(
                item.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: textColor,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    'Deleted on ${DateFormat('dd/MM/yyyy').format(item.deletedAt)}',
                    style: TextStyle(
                        fontSize: 12, color: textColor.withOpacity(0.6)),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: isExpiringSoon ? Colors.red : Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${item.daysRemaining} days remaining',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color:
                              isExpiringSoon ? Colors.red : Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'restore') {
                    _confirmRestore(item);
                  } else if (value == 'delete') {
                    _confirmPermanentDelete(item);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'restore',
                    child: Row(
                      children: [
                        Icon(Icons.restore, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Restore'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_forever, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete Permanently'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Action Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmRestore(item),
                      icon: const Icon(Icons.restore),
                      label: const Text('Restore'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: BorderSide(color: Colors.green),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmPermanentDelete(item),
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRestore(DeletedItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Item?'),
        content: Text('Restore "${item.name}" to its original location?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _restoreItem(item);
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  void _restoreItem(DeletedItem item) async {
    try {
      await SoftDeleteService.restoreDocument(
        docRef: item.reference,
        userId: user!.uid,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item restored successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error restoring item: $e')),
        );
      }
    }
  }

  void _confirmPermanentDelete(DeletedItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Permanently?'),
        content: Text(
            'This will permanently delete "${item.name}". This action cannot be undone!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _permanentDeleteItem(item);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _permanentDeleteItem(DeletedItem item) async {
    try {
      await SoftDeleteService.permanentDelete(
        docRef: item.reference,
        userId: user!.uid,
        documentName: item.name, // Pass the document name
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item permanently deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting item: $e')),
        );
      }
    }
  }

  void _cleanupExpiredItems() async {
    try {
      final count = await SoftDeleteService.cleanupExpiredDocuments(
        userId: user?.uid,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cleaned up $count expired items'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during cleanup: $e')),
        );
      }
    }
  }
}
