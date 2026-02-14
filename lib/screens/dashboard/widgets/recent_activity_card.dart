import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/screens/dashboard/recent_activity_screen.dart';
import 'package:get/get.dart';
import 'package:mds/controller/workspace_controller.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animate_do/animate_do.dart';

class RecentActivityCard extends StatelessWidget {
  const RecentActivityCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.white;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _buildCard(context, textColor, []);
    }

    final WorkspaceController workspaceController =
        Get.find<WorkspaceController>();

    return Obx(() {
      final schoolId = workspaceController.currentSchoolId.value;
      final targetId = schoolId.isNotEmpty ? schoolId : user.uid;

      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(targetId)
            .collection('recentActivity')
            .orderBy('timestamp', descending: true)
            .limit(2)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState(context);
          }

          List<Map<String, dynamic>> activities = [];
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            activities = snapshot.data!.docs.map((doc) => doc.data()).toList();
          }

          return _buildCard(context, textColor, activities);
        },
      );
    });
  }

  Widget _buildLoadingState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[850]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[800]! : Colors.grey[100]!;

    return _buildCard(
      context,
      Colors.transparent,
      [],
      isLoading: true,
      shimmerBase: baseColor,
      shimmerHighlight: highlightColor,
    );
  }

  Widget _buildCard(
    BuildContext context,
    Color textColor,
    List<Map<String, dynamic>> activities, {
    bool isLoading = false,
    Color? shimmerBase,
    Color? shimmerHighlight,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF252525),
                  const Color(0xFF1A1A1A),
                ]
              : [
                  Colors.white,
                  const Color(0xFFF8F9FA),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.05),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: -2,
          ),
        ],
      ),
      child: FadeInUp(
        duration: const Duration(milliseconds: 600),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.history,
                              color: Colors.purple, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Recent Activity',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RecentActivityScreen(),
                        ),
                      );
                    },
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'View All',
                        style: TextStyle(
                          color: kOrange,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (isLoading)
                Column(
                  children: List.generate(
                    2,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Shimmer.fromColors(
                        baseColor: shimmerBase!,
                        highlightColor: shimmerHighlight!,
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              else if (activities.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'No recent items',
                      style: TextStyle(
                        color: textColor.withOpacity(0.4),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
              else
                ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: activities.length > 2 ? 2 : activities.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    return _ActivityRow(
                      name: _extractName(activity['details'] ?? '',
                          activity['title'] ?? 'Activity'),
                      title: activity['title'] ?? 'Activity',
                      textColor: textColor,
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _extractName(String details, String fallback) {
    if (details.isEmpty) return fallback;
    final lines = details.split('\n');
    for (var line in lines) {
      if (line.contains('Name:') || line.contains('name:')) {
        return line.split(':').length > 1
            ? line.split(':').sublist(1).join(':').trim()
            : fallback;
      }
    }
    return lines.isNotEmpty ? lines[0].trim() : fallback;
  }
}

class _ActivityRow extends StatelessWidget {
  final String name;
  final String title;
  final Color textColor;

  const _ActivityRow({
    required this.name,
    required this.title,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blueGrey.withOpacity(0.1),
            border: Border.all(
              color: Colors.blueGrey.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                color: textColor.withOpacity(0.8),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  color: textColor.withOpacity(0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
