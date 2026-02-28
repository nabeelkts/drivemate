import 'package:flutter/material.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/models/urgent_task_model.dart';
import 'package:mds/services/urgent_task_service.dart';
import 'package:mds/screens/urgent_tasks/urgent_tasks_list_page.dart';
import 'package:get/get.dart';
import 'package:mds/controller/workspace_controller.dart';

/// Card widget to display on home page showing urgent tasks count and preview
class UrgentTaskCard extends StatefulWidget {
  const UrgentTaskCard({super.key});

  @override
  State<UrgentTaskCard> createState() => _UrgentTaskCardState();
}

class _UrgentTaskCardState extends State<UrgentTaskCard> {
  final UrgentTaskService _service = UrgentTaskService();
  final WorkspaceController _workspaceController =
      Get.find<WorkspaceController>();

  List<UrgentTaskModel> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
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

      // Filter to only show active tasks (not expired) on home screen
      final activeTasks = tasks.where((t) => t.daysRemaining >= 0).toList();

      setState(() {
        _tasks = activeTasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
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
    if (days == 1) return '1 day';
    return '$days days';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    if (_isLoading) {
      return _buildLoadingCard(isDark);
    }

    if (_tasks.isEmpty) {
      return const SizedBox.shrink(); // Don't show if no urgent tasks
    }

    final displayTasks = _tasks.take(4).toList();
    final remainingCount = _tasks.length - displayTasks.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(isDark ? 0.2 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.red.withOpacity(isDark ? 0.3 : 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.05),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Urgent Tasks',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Text(
                        '${_tasks.length} item${_tasks.length > 1 ? 's' : ''} expiring soon',
                        style: TextStyle(
                          fontSize: 12,
                          color: subTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UrgentTasksListPage(),
                      ),
                    );
                    if (result == true) {
                      _loadTasks();
                    }
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
          ),

          // Task list
          ...displayTasks.map(
              (task) => _buildTaskItem(task, textColor, subTextColor, isDark)),

          // View all button if more tasks
          if (remainingCount > 0)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: Text(
                  '+ $remainingCount more',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(
      UrgentTaskModel task, Color textColor, Color? subTextColor, bool isDark) {
    final urgencyColor = _getUrgencyColor(task.urgencyLevel);

    return InkWell(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const UrgentTasksListPage(),
          ),
        );
        if (result == true) {
          _loadTasks();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom:
                BorderSide(color: Colors.grey.withOpacity(isDark ? 0.2 : 0.1)),
          ),
        ),
        child: Row(
          children: [
            // Avatar or placeholder
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: urgencyColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: task.photoUrl != null && task.photoUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        task.photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.person,
                          color: urgencyColor,
                          size: 20,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.person,
                      color: urgencyColor,
                      size: 20,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    task.expiryType,
                    style: TextStyle(
                      fontSize: 12,
                      color: subTextColor,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: urgencyColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getDaysText(task.daysRemaining),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: urgencyColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(isDark ? 0.2 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text('Loading urgent tasks...'),
        ],
      ),
    );
  }
}
