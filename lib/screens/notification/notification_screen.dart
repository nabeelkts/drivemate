import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:drivemate/controller/workspace_controller.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> notifications = [];
  User? user = FirebaseAuth.instance.currentUser;
  final WorkspaceController _workspaceController =
      Get.find<WorkspaceController>();
  StreamSubscription<QuerySnapshot>? _notificationsSubscription;

  @override
  void initState() {
    super.initState();
    _listenToNotifications();
  }

  void _listenToNotifications() {
    _notificationsSubscription = _firestore
        .collection('users')
        .doc(_workspaceController.currentSchoolId.value)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          notifications = snapshot.docs;
        });
      }
    }, onError: (error) {
      debugPrint('Notifications stream error: $error');
    });
  }

  String _formatDate(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);
      return DateFormat('dd-MM-yy hh:mm a').format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }

  void _deleteNotification(String docId) async {
    try {
      await _firestore
          .collection('users')
          .doc(_workspaceController.currentSchoolId.value)
          .collection('notifications')
          .doc(docId)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete notification: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _notificationsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index].data();
          final docId = notifications[index].id;
          return Dismissible(
            key: Key(docId),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) {
              _deleteNotification(docId);
            },
            background: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Icon(
                  Icons.delete,
                  color: Colors.white,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: ListTile(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification['title'] ?? 'No Title',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _formatDate(notification['date'] ?? ''),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(notification['details'] ?? 'No Details'),
                  onTap: () {
                    // Handle tap if needed, e.g., navigate to details
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
