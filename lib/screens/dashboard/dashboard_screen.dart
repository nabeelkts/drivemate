import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mds/constants/colors.dart';
import 'dart:async';
import 'package:get/get.dart';
import 'package:mds/controller/workspace_controller.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? user = FirebaseAuth.instance.currentUser;
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadNotifications();
  }

  Future<void> _loadUnreadNotifications() async {
    final notifications = await _firestore
        .collection('users')
        .doc(user?.uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .get();

    setState(() {
      _unreadNotifications = notifications.docs.length;
    });
  }

  Future<void> _markNotificationsAsRead() async {
    final notifications = await _firestore
        .collection('users')
        .doc(user?.uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .get();

    for (var doc in notifications.docs) {
      await doc.reference.update({'read': true});
    }

    setState(() {
      _unreadNotifications = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  _markNotificationsAsRead();
                  // Show notifications dialog or navigate to notifications page
                },
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_unreadNotifications',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  Widget buildRecentActivity() {
    if (user == null) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Please log in to view recent activity'),
      );
    }

    final WorkspaceController workspaceController =
        Get.find<WorkspaceController>();

    return Obx(() {
      final schoolId = workspaceController.currentSchoolId.value;
      final targetId = schoolId.isNotEmpty ? schoolId : user!.uid;

      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore
            .collection('users')
            .doc(targetId)
            .collection('recentActivity')
            .orderBy('timestamp', descending: true)
            .limit(10)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error loading recent activity: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            );
          }

          final documents = snapshot.data?.docs ?? [];

          if (documents.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No recent activity available',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            );
          }

          return SizedBox(
            width: double.infinity,
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: documents.length,
              itemBuilder: (context, index) {
                final doc = documents[index];
                final data = doc.data();
                final title = data['title'] as String? ?? 'Activity';
                final details = data['details'] as String? ?? '';
                final timestamp = data['timestamp'] as Timestamp?;
                final date = data['date'] as String?;

                // Format the date
                String formattedDate = 'Date not available';
                if (timestamp != null) {
                  try {
                    final dateTime = timestamp.toDate();
                    formattedDate =
                        '${dateTime.day}/${dateTime.month}/${dateTime.year}';
                  } catch (e) {
                    formattedDate = 'Invalid date';
                  }
                } else if (date != null && date.isNotEmpty) {
                  try {
                    final dateTime = DateTime.parse(date);
                    formattedDate =
                        '${dateTime.day}/${dateTime.month}/${dateTime.year}';
                  } catch (e) {
                    formattedDate = date;
                  }
                }

                // Extract name from details if available
                String displayName = title;
                if (details.isNotEmpty) {
                  final lines = details.split('\n');
                  if (lines.isNotEmpty) {
                    displayName = lines[0];
                  }
                }

                // Get activity type icon
                String activityIcon = title[0].toUpperCase();
                if (title.toLowerCase().contains('student')) {
                  activityIcon = 'S';
                } else if (title.toLowerCase().contains('vehicle')) {
                  activityIcon = 'V';
                } else if (title.toLowerCase().contains('license')) {
                  activityIcon = 'L';
                } else if (title.toLowerCase().contains('endorsement')) {
                  activityIcon = 'E';
                }

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: kPrimaryColor.withOpacity(0.1),
                      child: Text(
                        activityIcon,
                        style: TextStyle(
                          color: kPrimaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      displayName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (details.isNotEmpty && details != displayName) ...[
                          const SizedBox(height: 2),
                          Text(
                            details,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
          );
        },
      );
    });
  }
}
