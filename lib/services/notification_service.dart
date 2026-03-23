import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
}

class NotificationService extends GetxService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<NotificationService> init() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    if (Platform.isAndroid) {
      await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    }

    _fcm.onTokenRefresh.listen(_saveTokenToFirestore);

    final token = await _fcm.getToken();
    await _saveTokenToFirestore(token);

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

    return this;
  }

  Future<void> _saveTokenToFirestore(String? token) async {
    if (token == null) return;
    
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore.collection('users').doc(userId).set({
        'fcmToken': token,
        'tokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message received: ${message.messageId}');
    _showNotification(message);
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Message opened app: ${message.messageId}');
    final data = message.data;
    
    if (data['type'] == 'chat_message') {
      final chatId = data['chatId'];
      if (chatId != null) {
        Get.toNamed('/chat', arguments: {'chatId': chatId});
      }
    }
  }

  void _showNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    Get.snackbar(
      notification.title ?? 'New Message',
      notification.body ?? '',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(8),
      backgroundColor: Colors.black87,
      colorText: Colors.white,
      icon: const Icon(Icons.notifications, color: Colors.white),
      mainButton: TextButton(
        onPressed: () {
          Get.back();
          final chatId = message.data['chatId'];
          if (chatId != null) {
            Get.toNamed('/chat', arguments: {'chatId': chatId});
          }
        },
        child: const Text('View', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Future<void> sendPushNotification({
    required String receiverId,
    required String title,
    required String body,
    required Map<String, String> data,
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(receiverId).get();
      final fcmToken = userDoc.data()?['fcmToken'];
      
      if (fcmToken == null) {
        debugPrint('No FCM token found for user: $receiverId');
        return;
      }

      await _firestore.collection('notifications').add({
        'fcmToken': fcmToken,
        'title': title,
        'body': body,
        'data': data,
        'receiverId': receiverId,
        'timestamp': FieldValue.serverTimestamp(),
        'sent': false,
      });
    } catch (e) {
      debugPrint('Error sending push notification: $e');
    }
  }
}
