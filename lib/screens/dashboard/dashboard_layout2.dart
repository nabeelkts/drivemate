import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/controller/app_controller.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mds/screens/dashboard/recent_activity_screen.dart';
import 'package:carousel_slider/carousel_slider.dart';

import 'package:mds/controller/workspace_controller.dart';
import 'dart:math' as math;

class DashboardLayout2 extends StatelessWidget {
  const DashboardLayout2({super.key});

  static final DateFormat _storageDateFormat = DateFormat('yyyy-MM-dd');

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
                _buildHeader(context, isDark, textColor),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTodaySchedule(context, isDark, textColor, targetId),
                      const SizedBox(height: 12),
                      _buildQuickActions(context, isDark, textColor),
                      const SizedBox(height: 12),
                      _buildRevenue(context, isDark, textColor, targetId),
                      const SizedBox(height: 12),
                      _buildRecentActivity(
                          context, isDark, textColor, targetId),
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

  Widget _buildHeader(BuildContext context, bool isDark, Color textColor) {
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 2),
              Text(
                'Manage your driving school',
                style: TextStyle(
                  color: textColor.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: kOrange, size: 26),
            onPressed: () {
              Navigator.pushNamed(context, '/notification');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySchedule(
      BuildContext context, bool isDark, Color textColor, String targetId) {
    final dateStr = _storageDateFormat.format(DateTime.now());
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(targetId)
          .collection('students')
          .where('learnersTestDate', isEqualTo: dateStr)
          .snapshots(),
      builder: (context, learnersSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(targetId)
              .collection('students')
              .where('drivingTestDate', isEqualTo: dateStr)
              .snapshots(),
          builder: (context, drivingSnapshot) {
            final learners = learnersSnapshot.data?.docs ?? [];
            final driving = drivingSnapshot.data?.docs ?? [];
            final List<Map<String, dynamic>> items = [];
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
            for (var doc in learners) {
              final d = doc.data();
              if (slot < timeSlots.length) {
                items.add({
                  'time': timeSlots[slot],
                  'name': d['fullName'] ?? 'N/A',
                  'role': 'LL',
                  'profileUrl': d['profileImageUrl'],
                  'type': 'learners',
                });
                slot++;
              }
            }
            for (var doc in driving) {
              final d = doc.data();
              if (slot < timeSlots.length) {
                items.add({
                  'time': timeSlots[slot],
                  'name': d['fullName'] ?? 'N/A',
                  'role': 'DL',
                  'profileUrl': d['profileImageUrl'],
                  'type': 'driving',
                });
                slot++;
              }
            }
            return _buildScheduleCard(context, isDark, textColor, items,
                learners.length, driving.length);
          },
        );
      },
    );
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

  Widget _buildRevenue(
      BuildContext context, bool isDark, Color textColor, String targetId) {
    final fs = FirebaseFirestore.instance;
    final now = DateTime.now();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: fs
          .collection('users')
          .doc(targetId)
          .collection('students')
          .snapshots(),
      builder: (context, s1) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: fs
              .collection('users')
              .doc(targetId)
              .collection('licenseonly')
              .snapshots(),
          builder: (context, s2) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: fs
                  .collection('users')
                  .doc(targetId)
                  .collection('endorsement')
                  .snapshots(),
              builder: (context, s3) {
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: fs
                      .collection('users')
                      .doc(targetId)
                      .collection('vehicleDetails')
                      .snapshots(),
                  builder: (context, s4) {
                    double totalRevenue = 0;
                    List<double> dailyRevenue = List.filled(8, 0.0);
                    double maxRevenue = 1.0;

                    if (s1.hasData && s2.hasData && s3.hasData && s4.hasData) {
                      final today = DateTime(now.year, now.month, now.day);

                      bool isSameMonth(DateTime a, DateTime b) {
                        return a.year == b.year && a.month == b.month;
                      }

                      for (var snapshot in [
                        s1.data,
                        s2.data,
                        s3.data,
                        s4.data
                      ]) {
                        if (snapshot == null) continue;
                        for (var doc in snapshot.docs) {
                          final data = doc.data();
                          double advance = double.tryParse(
                                  data['advanceAmount']?.toString() ?? '0') ??
                              0;
                          double second = double.tryParse(
                                  data['secondInstallment']?.toString() ??
                                      '0') ??
                              0;
                          double third = double.tryParse(
                                  data['thirdInstallment']?.toString() ??
                                      '0') ??
                              0;

                          DateTime reg = DateTime.tryParse(
                                  data['registrationDate'] ?? '') ??
                              DateTime(2000);
                          DateTime s2t = DateTime.tryParse(
                                  data['secondInstallmentTime'] ?? '') ??
                              DateTime(2000);
                          DateTime s3t = DateTime.tryParse(
                                  data['thirdInstallmentTime'] ?? '') ??
                              DateTime(2000);

                          // Revenue calculation (total for current month)
                          if (isSameMonth(reg, now)) totalRevenue += advance;
                          if (isSameMonth(s2t, now)) totalRevenue += second;
                          if (isSameMonth(s3t, now)) totalRevenue += third;

                          // Last 7 Days chart calculation
                          void updateChart(DateTime dt, double amount) {
                            if (amount <= 0) return;
                            final normalized =
                                DateTime(dt.year, dt.month, dt.day);
                            final diff = today.difference(normalized).inDays;
                            if (diff >= 0 && diff < 8) {
                              dailyRevenue[7 - diff] += amount;
                            }
                          }

                          updateChart(reg, advance);
                          updateChart(s2t, second);
                          updateChart(s3t, third);
                        }
                      }

                      double maxVal = dailyRevenue.reduce(math.max);
                      if (maxVal > 0) maxRevenue = maxVal;
                    }

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
                                '₹${NumberFormat('#,##0').format(totalRevenue)}',
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
                                final heightFactor =
                                    dailyRevenue[index] / maxRevenue;
                                final displayHeight =
                                    heightFactor == 0 ? 0.05 : heightFactor;

                                return Container(
                                  width: 14,
                                  height: 40 * displayHeight,
                                  decoration: BoxDecoration(
                                    color: kOrange.withOpacity(
                                        0.6 + (0.4 * displayHeight)),
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
              },
            );
          },
        );
      },
    );
  }

  Widget _buildRecentActivity(
      BuildContext context, bool isDark, Color textColor, String targetId) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(targetId)
          .collection('recentActivity')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        List<Map<String, dynamic>> activities = [];
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          activities = snapshot.data!.docs.map((doc) => doc.data()).toList();
        }
        return _buildActivityCard(context, isDark, textColor, activities);
      },
    );
  }

  Widget _buildActivityCard(
    BuildContext context,
    bool isDark,
    Color textColor,
    List<Map<String, dynamic>> activities,
  ) {
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
            ...activities.map((activity) {
              final name = _extractName(
                  activity['details'] ?? '', activity['title'] ?? 'Activity');
              final title = activity['title'] ?? 'Activity';
              return Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.blueGrey.shade700,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          title,
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
            }),
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
