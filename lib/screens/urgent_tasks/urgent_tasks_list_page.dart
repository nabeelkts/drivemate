import 'package:flutter/material.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/models/urgent_task_model.dart';
import 'package:mds/services/urgent_task_service.dart';
import 'package:mds/screens/dashboard/list/details/students_details_page.dart';
import 'package:mds/screens/dashboard/list/details/license_only_details_page.dart';
import 'package:mds/screens/dashboard/list/details/endorsement_details_page.dart';
import 'package:mds/screens/dashboard/list/details/dl_service_details_page.dart';
import 'package:mds/screens/dashboard/list/details/rc_details_page.dart';
import 'package:mds/screens/widget/custom_back_button.dart';
import 'package:get/get.dart';
import 'package:mds/controller/workspace_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Full list page showing all urgent tasks sorted by expiry date
class UrgentTasksListPage extends StatefulWidget {
  const UrgentTasksListPage({super.key});

  @override
  State<UrgentTasksListPage> createState() => _UrgentTasksListPageState();
}

class _UrgentTasksListPageState extends State<UrgentTasksListPage>
    with SingleTickerProviderStateMixin {
  final UrgentTaskService _service = UrgentTaskService();
  final WorkspaceController _workspaceController =
      Get.find<WorkspaceController>();

  List<UrgentTaskModel> _allTasks = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<UrgentTaskModel> get _activeTasks {
    return _allTasks.where((task) => task.daysRemaining >= 0).toList();
  }

  List<UrgentTaskModel> get _expiredTasks {
    return _allTasks.where((task) => task.daysRemaining < 0).toList();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);

    try {
      final tasks = await _service.fetchAllUrgentTasks(
        userId: _workspaceController.currentSchoolId.value.isNotEmpty
            ? _workspaceController.currentSchoolId.value
            : '',
        schoolId: _workspaceController.currentSchoolId.value,
        branchId: _workspaceController.currentBranchId.value,
      );

      setState(() {
        _allTasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading tasks: $e')),
      );
    }
  }

  Color _getUrgencyColor(String urgencyLevel) {
    switch (urgencyLevel) {
      case 'expired':
        return Colors.red.shade700;
      case 'critical':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      default:
        return Colors.amber;
    }
  }

  String _getDaysText(int days) {
    if (days < 0) return 'Expired';
    if (days == 0) return 'Today';
    if (days == 1) return '1 day left';
    return '$days days left';
  }

  Future<void> _navigateToDetail(UrgentTaskModel task) async {
    try {
      // Get base path
      final schoolId = _workspaceController.currentSchoolId.value;
      final basePath = schoolId.isNotEmpty
          ? 'users/$schoolId'
          : 'users/${FirebaseAuth.instance.currentUser?.uid ?? ''}';

      // Try to fetch from the collection specified in the task first
      // This is the actual collection where the document was found
      var doc = await FirebaseFirestore.instance
          .doc('$basePath/${task.collection}/${task.documentId}')
          .get();

      // If not found in the specified collection, try the opposite (active/deactivated)
      if (!doc.exists) {
        String alternateCollection;
        if (task.collection.startsWith('deactivated_')) {
          // If it was in a deactivated collection, try the active one
          alternateCollection =
              task.collection.substring(12); // Remove 'deactivated_' prefix
        } else {
          // If it was in an active collection, try the deactivated one
          alternateCollection = 'deactivated_${task.collection}';
        }

        doc = await FirebaseFirestore.instance
            .doc('$basePath/$alternateCollection/${task.documentId}')
            .get();
      }

      if (!doc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document not found')),
        );
        return;
      }

      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;

      Widget? detailPage;

      // Handle both active and deactivated collection names
      String collectionType = task.collection;
      if (collectionType.startsWith('deactivated_')) {
        collectionType =
            collectionType.substring(12); // Remove 'deactivated_' prefix
      }

      switch (collectionType) {
        case 'students':
          detailPage = StudentDetailsPage(studentDetails: data);
          break;
        case 'licenseonly':
          detailPage = LicenseOnlyDetailsPage(licenseDetails: data);
          break;
        case 'endorsement':
          detailPage = EndorsementDetailsPage(endorsementDetails: data);
          break;
        case 'dl_services':
          detailPage = DlServiceDetailsPage(serviceDetails: data);
          break;
        case 'vehicleDetails':
          detailPage = RCDetailsPage(vehicleDetails: data);
          break;
      }

      if (detailPage != null) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => detailPage!),
        );

        // Refresh list when returning
        _loadTasks();

        // Return true to indicate refresh needed
        if (mounted && result == true) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      print('Navigation error: $e'); // Print to console for debugging
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening details: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text('Urgent Tasks', style: TextStyle(color: textColor)),
        elevation: 0,
        leading: const CustomBackButton(),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: textColor),
            onPressed: _loadTasks,
          ),
        ],
        bottom: _isLoading || _allTasks.isEmpty
            ? null
            : TabBar(
                controller: _tabController,
                indicatorColor: kPrimaryColor,
                labelColor: kPrimaryColor,
                unselectedLabelColor: textColor.withOpacity(0.6),
                tabs: [
                  Tab(
                    text: 'Active (${_activeTasks.length})',
                    icon: const Icon(Icons.access_time),
                  ),
                  Tab(
                    text: 'Expired (${_expiredTasks.length})',
                    icon: const Icon(Icons.warning),
                  ),
                ],
              ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allTasks.isEmpty
              ? _buildEmptyState()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Active Tasks Tab
                    _activeTasks.isEmpty
                        ? _buildEmptyTabState('No active urgent tasks')
                        : RefreshIndicator(
                            onRefresh: _loadTasks,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _activeTasks.length,
                              itemBuilder: (context, index) {
                                final task = _activeTasks[index];
                                return _buildTaskTile(task);
                              },
                            ),
                          ),
                    // Expired Tasks Tab
                    _expiredTasks.isEmpty
                        ? _buildEmptyTabState('No expired tasks')
                        : RefreshIndicator(
                            onRefresh: _loadTasks,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _expiredTasks.length,
                              itemBuilder: (context, index) {
                                final task = _expiredTasks[index];
                                return _buildTaskTile(task);
                              },
                            ),
                          ),
                  ],
                ),
    );
  }

  Widget _buildTaskTile(UrgentTaskModel task) {
    final urgencyColor = _getUrgencyColor(task.urgencyLevel);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToDetail(task),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Photo or avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: urgencyColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: task.photoUrl != null && task.photoUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          task.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.person,
                            color: urgencyColor,
                            size: 28,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.person,
                        color: urgencyColor,
                        size: 28,
                      ),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      task.expiryType,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Expires: ${task.expiryDate}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),

              // Days remaining badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: urgencyColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getDaysText(task.daysRemaining),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: urgencyColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Colors.green.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Urgent Tasks',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All items are up to date',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTabState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
