import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:drivemate/widgets/persistent_cached_image.dart';
import 'package:flutter/material.dart';
import 'package:drivemate/constants/colors.dart';
import 'package:get/get.dart';
import 'package:drivemate/controller/workspace_controller.dart';
import 'package:drivemate/screens/widget/custom_back_button.dart';
import 'package:drivemate/screens/dashboard/list/widgets/shimmer_loading_list.dart';

class RecentActivityScreen extends StatefulWidget {
  const RecentActivityScreen({super.key});

  @override
  State<RecentActivityScreen> createState() => _RecentActivityScreenState();
}

class _RecentActivityScreenState extends State<RecentActivityScreen> {
  late final StreamController<QuerySnapshot<Map<String, dynamic>>>
      _streamController;
  late final StreamSubscription<QuerySnapshot<Map<String, dynamic>>>
      _subscription;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _cachedDocs = [];

  @override
  void initState() {
    super.initState();
    _setupStream();
  }

  void _setupStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final workspaceController = Get.find<WorkspaceController>();
    final schoolId = workspaceController.currentSchoolId.value;
    final targetId = schoolId.isNotEmpty ? schoolId : user.uid;

    _streamController =
        StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();

    _subscription = FirebaseFirestore.instance
        .collection('users')
        .doc(targetId)
        .collection('recentActivity')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
      // Cache the documents
      setState(() {
        _cachedDocs = snapshot.docs;
      });
      _streamController.add(snapshot);
    }, onError: (error) {
      _streamController.addError(error);
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    _streamController.close();
    super.dispose();
  }

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

    return Scaffold(
      appBar: AppBar(
        title: Text('Recent Activity', style: TextStyle(color: textColor)),
        backgroundColor: theme.scaffoldBackgroundColor,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _streamController.stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(color: textColor),
              ),
            );
          }

          // Use cached data first to avoid showing shimmer when returning from back navigation
          if (_cachedDocs.isNotEmpty) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _cachedDocs.length,
              itemBuilder: (context, index) {
                final doc = _cachedDocs[index];
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
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: (data['imageUrl'] != null &&
                                data['imageUrl'].toString().isNotEmpty)
                            ? PersistentCachedImage(
                                imageUrl: data['imageUrl'],
                                fit: BoxFit.cover,
                                memCacheWidth: 120,
                                memCacheHeight: 120,
                                placeholder: const CircularProgressIndicator(
                                    strokeWidth: 2),
                                errorWidget: Center(
                                  child: Text(
                                    displayName.isNotEmpty
                                        ? displayName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: kPrimaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  displayName.isNotEmpty
                                      ? displayName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: kPrimaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
          }

          // Only show shimmer on initial load if no cached data
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ShimmerLoadingList();
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
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: (data['imageUrl'] != null &&
                              data['imageUrl'].toString().isNotEmpty)
                          ? PersistentCachedImage(
                              imageUrl: data['imageUrl'],
                              fit: BoxFit.cover,
                              memCacheWidth: 100,
                              memCacheHeight: 100,
                              placeholder: const CircularProgressIndicator(
                                  strokeWidth: 2),
                              errorWidget: Center(
                                child: Text(
                                  displayName.isNotEmpty
                                      ? displayName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: kPrimaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                displayName.isNotEmpty
                                    ? displayName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: kPrimaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
