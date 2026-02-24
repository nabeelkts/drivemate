import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mds/constants/colors.dart';
import 'package:get/get.dart';
import 'package:mds/controller/workspace_controller.dart';
import 'package:mds/screens/widget/custom_back_button.dart';

class RecentActivityScreen extends StatelessWidget {
  const RecentActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.white;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Recent Activity', style: TextStyle(color: textColor)),
          backgroundColor: theme.scaffoldBackgroundColor,
          iconTheme: IconThemeData(color: textColor),
          leading: const CustomBackButton(),
        ),
        body: Center(
          child: Text(
            'Please log in to view recent activity',
            style: TextStyle(color: textColor),
          ),
        ),
      );
    }

    final WorkspaceController workspaceController =
        Get.find<WorkspaceController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Recent Activity', style: TextStyle(color: textColor)),
        backgroundColor: theme.scaffoldBackgroundColor,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Obx(() {
        final schoolId = workspaceController.currentSchoolId.value;
        final targetId = schoolId.isNotEmpty ? schoolId : user.uid;

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(targetId)
              .collection('recentActivity')
              .orderBy('timestamp', descending: true)
              .limit(50)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(color: textColor),
                ),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return Center(
                child: Text(
                  'No recent activity',
                  style: TextStyle(color: textColor.withOpacity(0.7)),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data();
                final title = data['title'] as String? ?? 'Activity';
                final details = data['details'] as String? ?? '';
                final displayName = _extractName(details, title);
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: theme.brightness == Brightness.dark
                      ? Colors.grey.shade900
                      : Colors.grey.shade100,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: kPrimaryColor.withOpacity(0.2),
                      child: Text(
                        displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: kPrimaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      displayName,
                      style: TextStyle(
                          color: textColor, fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      }),
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
