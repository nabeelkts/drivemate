import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class LocalNotificationService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription? _notificationSubscription;
  DateTime? _listenerStartTime;

  // Admin email - only show notifications to admin
  static const String _adminEmail = '3muhammednabeelkt@gmail.com';

  Future<LocalNotificationService> init() async {
    _startListeningForNotifications();
    return this;
  }

  void _startListeningForNotifications() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Only show notifications to admin user
    if (currentUser.email != _adminEmail) return;

    final userId = currentUser.uid;

    // Record when the listener starts to avoid showing existing notifications
    _listenerStartTime = DateTime.now();

    _notificationSubscription = _firestore
        .collection('notifications')
        .doc(userId)
        .collection('user_notifications')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data != null && data['isRead'] != true) {
            final notificationTime =
                (data['timestamp'] as Timestamp?)?.toDate();
            // Only show notifications created after the listener started
            // This prevents showing existing unread notifications on app launch
            if (notificationTime != null &&
                _listenerStartTime != null &&
                notificationTime.isAfter(_listenerStartTime!)) {
              _showLocalNotification(
                id: change.doc.id.hashCode,
                title: data['title'] ?? 'New Message',
                body: data['body'] ?? '',
                data: {
                  'type': data['type'] ?? 'chat_message',
                  'chatId': data['chatId'] ?? '',
                },
              );
            }
          }
        }
      }
    }, onError: (error) {
      debugPrint('Notification listener error: $error');
    });
  }

  void _showLocalNotification({
    required int id,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) {
    Get.snackbar(
      title,
      body,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(8),
      backgroundColor: Colors.black87,
      colorText: Colors.white,
      icon: const Icon(Icons.notifications_active, color: Colors.white),
      mainButton: TextButton(
        onPressed: () {
          Get.back();
          if (data['type'] == 'chat_message' && data['chatId'] != null) {
            _navigateToChat(data['chatId']);
          }
        },
        child: const Text('View', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _navigateToChat(String chatId) {
    Get.toNamed('/chat', arguments: {'chatId': chatId});
  }

  @override
  void onClose() {
    _notificationSubscription?.cancel();
    super.onClose();
  }
}
