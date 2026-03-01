import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mds/utils/revenue_utils.dart';
import 'package:mds/utils/stream_utils.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/controller/app_controller.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mds/screens/dashboard/recent_activity_screen.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:mds/controller/workspace_controller.dart';
import 'package:mds/widgets/urgent_task_card.dart';
import 'dart:math' as math;
import 'dart:async';

class DashboardLayout2 extends StatelessWidget {
  const DashboardLayout2({super.key});

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final AppController appController = Get.put(AppController());
    final WorkspaceController workspaceController =
        Get.find<WorkspaceController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return SafeArea(
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF1a1a1a) : Colors.grey.shade50,
        body: Obx(() {
          // Re-derive targetId inside Obx to trigger rebuilds
          final schoolId = workspaceController.currentSchoolId.value;
          final user = FirebaseAuth.instance.currentUser;
          final targetId = schoolId.isNotEmpty ? schoolId : user?.uid;

          if (targetId == null) return const SizedBox();

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, workspaceController, isDark, textColor),
                const SizedBox(height: 12),
                const UrgentTaskCard(),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TodayScheduleWidget(
                        controller: workspaceController,
                        isDark: isDark,
                        textColor: textColor,
                        targetId: targetId,
                      ),
                      const SizedBox(height: 12),
                      _buildQuickActions(context, isDark, textColor),
                      if (workspaceController.userRole.value == 'Owner' &&
                          workspaceController.ownedBranches.length > 1) ...[
                        const SizedBox(height: 12),
                        _buildOrgInsights(context, workspaceController, isDark,
                            textColor, targetId),
                      ],
                      const SizedBox(height: 12),
                      // _buildRevenue(context, workspaceController, isDark,
                      //     textColor, targetId),
                      // const SizedBox(height: 12),
                      _buildRecentActivity(context, workspaceController, isDark,
                          textColor, targetId),
                      const SizedBox(height: 12),
                      _buildSchoolNews(context, isDark, textColor),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WorkspaceController controller,
      bool isDark, Color textColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Obx(() {
        final isOrg = controller.isOrganizationMode.value;
        final branchData = controller.currentBranchData;
        final branchName = branchData['branchName'] ?? 'Branch';

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Drivemate',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (controller.userRole.value == 'Owner' &&
                          controller.ownedBranches.length > 1) ...[
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => controller.toggleViewMode(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isOrg
                                  ? kOrange.withOpacity(0.1)
                                  : Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isOrg
                                    ? kOrange.withOpacity(0.2)
                                    : Colors.blue.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isOrg ? Icons.business : Icons.account_tree,
                                  size: 12,
                                  color: isOrg ? kOrange : Colors.blue,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isOrg ? 'Organization' : 'Branch',
                                  style: TextStyle(
                                    color: isOrg ? kOrange : Colors.blue,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    (controller.userRole.value == 'Owner' &&
                            controller.ownedBranches.length > 1 &&
                            isOrg)
                        ? 'Consolidated Insights'
                        : branchName,
                    style: TextStyle(
                      color: textColor.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon:
                  Icon(Icons.notifications_outlined, color: kOrange, size: 26),
              onPressed: () {
                Navigator.pushNamed(context, '/notification');
              },
            ),
          ],
        );
      }),
    );
  }

  Widget _buildTodaySchedulePlaceholder() {
    return const SizedBox.shrink();
  }

  Widget _buildScheduleCard(
    BuildContext context,
    bool isDark,
    Color textColor,
    List<Map<String, dynamic>> items,
    int learnersCount,
    int drivingCount,
  ) {
    final displayItems = items.take(2).toList();

    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/today_schedule'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2a2a2a) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Today's Schedule",
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              learnersCount == 0 && drivingCount == 0
                  ? 'No sessions today'
                  : '${learnersCount > 0 ? '$learnersCount LL' : ''}${learnersCount > 0 && drivingCount > 0 ? ', ' : ''}${drivingCount > 0 ? '$drivingCount DL' : ''} test${(learnersCount + drivingCount) > 1 ? 's' : ''} today',
              style: TextStyle(
                color: textColor.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            if (displayItems.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Center(
                  child: Text(
                    'No sessions scheduled',
                    style: TextStyle(
                      color: textColor.withOpacity(0.4),
                      fontSize: 13,
                    ),
                  ),
                ),
              )
            else
              ...displayItems.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: kOrange,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${item['name']} — ${item['role']}',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          item['time'] as String,
                          style: TextStyle(
                            color: textColor.withOpacity(0.6),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(
      BuildContext context, bool isDark, Color textColor) {
    final actions = [
      {
        'icon': Icons.school,
        'label': 'Students',
        'route': '/students',
        'color': kOrange,
      },
      {
        'icon': Icons.badge,
        'label': 'License',
        'route': '/license',
        'color': Colors.blue,
      },
      {
        'icon': Icons.add_card,
        'label': 'Endorse',
        'route': '/endorse',
        'color': Colors.purple,
      },
      {
        'icon': Icons.directions_car,
        'label': 'RC',
        'route': '/rc',
        'color': Colors.green,
      },
      {
        'icon': Icons.miscellaneous_services,
        'label': 'DL Services',
        'route': '/dl_services',
        'color': Colors.orangeAccent,
      },
      {
        'icon': Icons.calendar_month,
        'label': 'Test Dates',
        'route': '/test_dates',
        'color': Colors.teal,
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2a2a2a) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: actions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 2.6, // Smaller and more compact
            ),
            itemBuilder: (context, index) {
              final action = actions[index];
              return InkWell(
                onTap: () =>
                    Navigator.pushNamed(context, action['route'] as String),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color:
                        isDark ? const Color(0xFF333333) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.02),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        action['icon'] as IconData,
                        size: 16,
                        color: action['color'] as Color,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          action['label'] as String,
                          style: TextStyle(
                            color: textColor.withOpacity(0.9),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrgInsights(BuildContext context, WorkspaceController controller,
      bool isDark, Color textColor, String targetId) {
    final isOrg = controller.isOrganizationMode.value;
    final branchId = controller.currentBranchId.value;
    final fs = FirebaseFirestore.instance;

    Query<Map<String, dynamic>> paymentsQuery =
        fs.collectionGroup('payments').where('targetId', isEqualTo: targetId);
    if (!isOrg && branchId.isNotEmpty && branchId != targetId) {
      paymentsQuery = paymentsQuery.where('branchId', isEqualTo: branchId);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Org Insights',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Aggregated from ${controller.ownedBranches.length} branches',
                    style: TextStyle(
                      color: textColor.withOpacity(0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              Icon(Icons.analytics_outlined, color: kOrange, size: 20),
            ],
          ),
          const SizedBox(height: 24),
          StreamBuilder<List<QuerySnapshot<Map<String, dynamic>>>>(
            stream: StreamUtils.combineLatest([
              controller.getFilteredCollection('students').snapshots(),
              controller.getFilteredCollection('licenseonly').snapshots(),
              controller.getFilteredCollection('endorsement').snapshots(),
              controller.getFilteredCollection('vehicleDetails').snapshots(),
              controller.getFilteredCollection('expenses').snapshots(),
              controller.getFilteredCollection('dl_services').snapshots(),
              paymentsQuery.snapshots(),
            ]),
            builder: (context, combinedSnapshot) {
              int totalStudents = 0;
              double totalRevenue = 0;

              if (combinedSnapshot.hasData) {
                final dataList = combinedSnapshot.data!;
                totalStudents = dataList[0].docs.length;

                final now = DateTime.now();
                final revenueStats = RevenueUtils.calculateMonthlyRevenue(
                  snapshots: dataList,
                  selectedDate: now,
                  months: [now],
                );
                totalRevenue = revenueStats['currentMonthRevenue'] ?? 0;
              }

              return Row(
                children: [
                  Expanded(
                    child: _buildInsightItem(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Revenue (MTD)',
                      value:
                          '₹${NumberFormat('#,##,###').format(totalRevenue)}',
                      textColor: textColor,
                    ),
                  ),
                  Container(
                    height: 40,
                    width: 1,
                    color: textColor.withOpacity(0.1),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  Expanded(
                    child: _buildInsightItem(
                      icon: Icons.school_outlined,
                      label: 'Total Students',
                      value: '$totalStudents',
                      textColor: textColor,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem({
    required IconData icon,
    required String label,
    required String value,
    required Color textColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: kOrange),
            const SizedBox(width: 8),
            Text(label,
                style:
                    TextStyle(color: textColor.withOpacity(0.5), fontSize: 11)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildRevenue(BuildContext context, WorkspaceController controller,
      bool isDark, Color textColor, String targetId) {
    final isOrg = controller.isOrganizationMode.value;
    final branchId = controller.currentBranchId.value;

    final fs = FirebaseFirestore.instance;
    final now = DateTime.now();

    // Helper to get filtered stream
    // Note: We fetch all data and filter client-side to handle legacy records without branchId
    Stream<QuerySnapshot<Map<String, dynamic>>> getFilteredStream(
        String collection) {
      Query<Map<String, dynamic>> query =
          fs.collection('users').doc(targetId).collection(collection);
      // No server-side filtering - we'll filter client-side to include legacy data
      return query.snapshots();
    }

    // Helper to check if a document belongs to the current branch
    bool belongsToBranch(Map<String, dynamic> data) {
      if (isOrg || branchId.isEmpty) return true;
      final docBranchId = data['branchId'];
      // Include if branchId matches OR if no branchId (legacy data)
      return docBranchId == branchId ||
          docBranchId == null ||
          docBranchId == '';
    }

    Query<Map<String, dynamic>> paymentsQuery =
        fs.collectionGroup('payments').where('targetId', isEqualTo: targetId);
    if (!isOrg && branchId.isNotEmpty && branchId != targetId) {
      paymentsQuery = paymentsQuery.where('branchId', isEqualTo: branchId);
    }

    return StreamBuilder<List<QuerySnapshot<Map<String, dynamic>>>>(
      stream: StreamUtils.combineLatest([
        controller.getFilteredCollection('students').snapshots(),
        controller.getFilteredCollection('licenseonly').snapshots(),
        controller.getFilteredCollection('endorsement').snapshots(),
        controller.getFilteredCollection('vehicleDetails').snapshots(),
        controller.getFilteredCollection('expenses').snapshots(),
        controller.getFilteredCollection('dl_services').snapshots(),
        paymentsQuery.snapshots(),
      ]),
      builder: (context, snapshot) {
        double totalRevenueCount = 0;
        List<double> dailyRevenue = List.filled(8, 0.0);
        double maxRevenue = 1.0;

        if (snapshot.hasData) {
          final dataList = snapshot.data!;
          final revenueStats = RevenueUtils.calculateMonthlyRevenue(
            snapshots: dataList,
            selectedDate: now,
            months: [now],
          );
          totalRevenueCount = revenueStats['currentMonthRevenue'] ?? 0;

          // Last 7 Days chart calculation (Daily)
          final today = DateTime(now.year, now.month, now.day);

          // Re-process for chart (we need daily data which calculateMonthlyRevenue doesn't return specifically in a 7-day format yet)
          // We can reuse logic or update RevenueUtils. For now, let's keep it simple or update RevenueUtils.
          // Actually, calculateMonthlyRevenue handles installments.

          void updateChart(DateTime dt, double amount) {
            if (amount <= 0) return;
            final normalized = DateTime(dt.year, dt.month, dt.day);
            final diff = today.difference(normalized).inDays;
            if (diff >= 0 && diff < 8) {
              dailyRevenue[7 - diff] += amount;
              if (dailyRevenue[7 - diff] > maxRevenue) {
                maxRevenue = dailyRevenue[7 - diff];
              }
            }
          }

          // Process snapshots for chart specifically
          final revIndices = [0, 1, 2, 3, 5];
          for (var idx in revIndices) {
            for (var doc in dataList[idx].docs) {
              final data = doc.data();
              final reg = DateTime.tryParse(data['registrationDate'] ?? '');
              final s2t =
                  DateTime.tryParse(data['secondInstallmentTime'] ?? '');
              final s3t = DateTime.tryParse(data['thirdInstallmentTime'] ?? '');
              final adv =
                  double.tryParse(data['advanceAmount']?.toString() ?? '0') ??
                      0;
              final s2a = double.tryParse(
                      data['secondInstallment']?.toString() ?? '0') ??
                  0;
              final s3a = double.tryParse(
                      data['thirdInstallment']?.toString() ?? '0') ??
                  0;

              if (reg != null) updateChart(reg, adv);
              if (s2t != null) updateChart(s2t, s2a);
              if (s3t != null) updateChart(s3t, s3a);

              for (int i = 4; i <= 20; i++) {
                final it = DateTime.tryParse(data['installment${i}Time'] ?? '');
                final ia =
                    double.tryParse(data['installment$i']?.toString() ?? '0') ??
                        0;
                if (it != null) updateChart(it, ia);
              }
            }
          }

          // Payments for chart
          for (var doc in dataList[6].docs) {
            final data = doc.data();
            double amount = double.tryParse(data['amountPaid']?.toString() ??
                    data['amount']?.toString() ??
                    '0') ??
                0;
            DateTime? pDate;
            if (data['date'] is Timestamp) {
              pDate = (data['date'] as Timestamp).toDate();
            } else {
              pDate = DateTime.tryParse(data['date']?.toString() ?? '');
            }
            if (pDate != null) updateChart(pDate, amount);
            // Note: Chart might double-count if we don't dedup here too,
            // but chart is usually less critical than the total amount and deduping it perfectly is complex without sharing countedPayments.
          }
        }

        // This block was leftover and is now removed.
        // if (diff >= 0 && diff < 8) {
        //   dailyRevenue[7 - diff] += amount;
        // }
        // updateChart(reg, advance);
        // updateChart(s2t, second);
        // updateChart(s3t, third);

        double maxVal = dailyRevenue.reduce(math.max);
        if (maxVal > 0) maxRevenue = maxVal;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2a2a2a) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Revenue',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '(This Month)',
                        style: TextStyle(
                          color: textColor.withOpacity(0.5),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '₹${NumberFormat('#,##0').format(totalRevenueCount)}',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 40,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(8, (index) {
                    final heightFactor = dailyRevenue[index] / maxRevenue;
                    final displayHeight =
                        heightFactor == 0 ? 0.05 : heightFactor;

                    return Container(
                      width: 14,
                      height: 40 * displayHeight,
                      decoration: BoxDecoration(
                        color: kOrange.withOpacity(0.6 + (0.4 * displayHeight)),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentActivity(
      BuildContext context,
      WorkspaceController controller,
      bool isDark,
      Color textColor,
      String targetId) {
    final isOrg = controller.isOrganizationMode.value;
    final branchId = controller.currentBranchId.value;

    // When not in org mode and branchId is set, we need to filter by branch
    // But we also need to include records without branchId (legacy data)
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('users')
        .doc(targetId)
        .collection('recentActivity')
        .orderBy('timestamp', descending: true)
        .limit(2); // Limit to 2 most recent activities

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        List<Map<String, dynamic>> activities = [];
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final allActivities =
              snapshot.data!.docs.map((doc) => doc.data()).toList();

          if (isOrg || branchId.isEmpty) {
            // In org mode or no branch selected, show all activities
            activities = allActivities.take(2).toList();
          } else {
            // In branch mode, filter by branchId or include records without branchId
            activities = allActivities
                .where((activity) {
                  final activityBranchId = activity['branchId'];
                  // Include if branchId matches OR if no branchId (legacy data)
                  return activityBranchId == branchId ||
                      activityBranchId == null ||
                      activityBranchId == '';
                })
                .take(2)
                .toList();
          }
        }
        return _buildActivityCard(
            context, controller, isDark, textColor, activities);
      },
    );
  }

  Widget _buildActivityRow(Map<String, dynamic> activity, Color textColor,
      WorkspaceController controller) {
    final isOrg = controller.isOrganizationMode.value;
    final name = _extractName(
        activity['details'] ?? '', activity['title'] ?? 'Activity');
    final title = activity['title'] ?? 'Activity';

    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.blueGrey.shade700,
          backgroundImage: (activity['imageUrl'] != null &&
                  activity['imageUrl'].toString().isNotEmpty)
              ? CachedNetworkImageProvider(activity['imageUrl'])
              : null,
          child: (activity['imageUrl'] == null ||
                  activity['imageUrl'].toString().isEmpty)
              ? Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : null,
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
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                isOrg && activity['branchName'] != null
                    ? '${activity['branchName']} • $title'
                    : title,
                style: TextStyle(
                  color: textColor.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityCard(
      BuildContext context,
      WorkspaceController controller,
      bool isDark,
      Color textColor,
      List<Map<String, dynamic>> activities) {
    final isOrg = controller.isOrganizationMode.value;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2a2a2a) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
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
                child: Text(
                  'View All >',
                  style: TextStyle(
                    color: kOrange,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (activities.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Text(
                  'No recent activity',
                  style: TextStyle(
                    color: textColor.withOpacity(0.4),
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            Column(
              children: [
                for (var i = 0; i < activities.length; i++) ...[
                  if (i > 0) const SizedBox(height:16 ),
                  _buildActivityRow(activities[i], textColor, controller),
                ],
              ],
            )
        ],
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

  Widget _buildSchoolNews(BuildContext context, bool isDark, Color textColor) {
    final newsItems = [
      {
        'title': 'LEARN TO DRIVE',
        'subtitle': 'Professional driving lessons',
        'icon': Icons.local_taxi,
      },
      {
        'title': 'SAFETY FIRST',
        'subtitle': 'Follow traffic rules always',
        'icon': Icons.health_and_safety,
      },
      {
        'title': 'GET LICENSED',
        'subtitle': 'Start your journey today',
        'icon': Icons.card_membership,
      },
    ];

    return CarouselSlider(
      options: CarouselOptions(
        height: 120,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 4),
        autoPlayAnimationDuration: const Duration(milliseconds: 800),
        autoPlayCurve: Curves.fastOutSlowIn,
        enlargeCenterPage: false,
        viewportFraction: 1.0,
      ),
      items: newsItems.map((news) {
        return Builder(
          builder: (BuildContext context) {
            return Container(
              width: MediaQuery.of(context).size.width,
              margin: const EdgeInsets.symmetric(horizontal: 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    // Background gradient
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            kOrange.withOpacity(0.8),
                            kOrange,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'School News & Tips',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            news['title'] as String,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            news['subtitle'] as String,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Decorative element
                    Positioned(
                      right: -20,
                      bottom: -20,
                      child: Icon(
                        news['icon'] as IconData,
                        size: 100,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }
}

class _TodayScheduleWidget extends StatefulWidget {
  final WorkspaceController controller;
  final bool isDark;
  final Color textColor;
  final String targetId;

  const _TodayScheduleWidget({
    required this.controller,
    required this.isDark,
    required this.textColor,
    required this.targetId,
  });

  @override
  State<_TodayScheduleWidget> createState() => _TodayScheduleWidgetState();
}

class _TodayScheduleWidgetState extends State<_TodayScheduleWidget> {
  static final DateFormat _storageDateFormat = DateFormat('yyyy-MM-dd');
  final Map<String, List<DocumentSnapshot>> _learnersDocsMap = {
    'students': [],
    'licenseonly': [],
    'endorsement': []
  };
  final Map<String, List<DocumentSnapshot>> _drivingDocsMap = {
    'students': [],
    'licenseonly': [],
    'endorsement': []
  };
  final List<StreamSubscription> _subscriptions = [];
  bool _isLoading = true;
  List<Map<String, dynamic>> _items = [];
  int _learnersCount = 0;
  int _drivingCount = 0;

  @override
  void initState() {
    super.initState();
    _setupStreams();
  }

  void _setupStreams() {
    final dateStr = _storageDateFormat.format(DateTime.now());
    final isOrg = widget.controller.isOrganizationMode.value;
    final branchId = widget.controller.currentBranchId.value;
    final collections = ['students', 'licenseonly', 'endorsement'];

    for (String col in collections) {
      Query<Map<String, dynamic>> learnersQuery = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.targetId)
          .collection(col)
          .where('learnersTestDate', isEqualTo: dateStr);

      Query<Map<String, dynamic>> drivingQuery = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.targetId)
          .collection(col)
          .where('drivingTestDate', isEqualTo: dateStr);

      if (!isOrg && branchId.isNotEmpty) {
        learnersQuery = learnersQuery.where('branchId', isEqualTo: branchId);
        drivingQuery = drivingQuery.where('branchId', isEqualTo: branchId);
      }

      _subscriptions.add(learnersQuery.snapshots().listen((snapshot) {
        _learnersDocsMap[col] = snapshot.docs;
        _updateItems();
      }));

      _subscriptions.add(drivingQuery.snapshots().listen((snapshot) {
        _drivingDocsMap[col] = snapshot.docs;
        _updateItems();
      }));
    }
  }

  void _updateItems() {
    if (!mounted) return;
    final allLearners = _learnersDocsMap.values.expand((x) => x).toList();
    final allDriving = _drivingDocsMap.values.expand((x) => x).toList();

    final List<Map<String, dynamic>> newItems = [];
    final timeSlots = [
      '09:00 AM',
      '10:00 AM',
      '11:00 AM',
      '12:00 PM',
      '01:00 PM',
      '02:00 PM',
      '03:00 PM',
      '04:00 PM',
    ];
    int slot = 0;

    for (var doc in allLearners) {
      final d = doc.data() as Map<String, dynamic>?;
      if (d != null && slot < timeSlots.length) {
        newItems.add({
          'time': timeSlots[slot],
          'name': d['fullName'] ?? 'N/A',
          'role': 'LL',
          'profileUrl': d['profileImageUrl'],
          'type': 'learners',
        });
        slot++;
      }
    }
    for (var doc in allDriving) {
      final d = doc.data() as Map<String, dynamic>?;
      if (d != null && slot < timeSlots.length) {
        newItems.add({
          'time': timeSlots[slot],
          'name': d['fullName'] ?? 'N/A',
          'role': 'DL',
          'profileUrl': d['profileImageUrl'],
          'type': 'driving',
        });
        slot++;
      }
    }

    setState(() {
      _items = newItems;
      _learnersCount = allLearners.length;
      _drivingCount = allDriving.length;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    final displayItems = _items.take(2).toList();
    final kOrange =
        const Color(0xFFFF5722); // Assuming kOrange based on mdscolors

    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/today_schedule'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: widget.isDark ? const Color(0xFF2a2a2a) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Today's Schedule",
              style: TextStyle(
                color: widget.textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _learnersCount + _drivingCount == 0
                        ? 'No sessions today'
                        : '${_learnersCount + _drivingCount} session${(_learnersCount + _drivingCount) != 1 ? 's' : ''} scheduled',
                    style: TextStyle(
                      color: widget.textColor.withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: widget.textColor.withOpacity(0.3),
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
