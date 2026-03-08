import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:drivemate/firebase_options.dart';
import 'package:flutter/services.dart';
import 'package:in_app_update/in_app_update.dart';

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class AppController extends GetxController {
  RxString oldVersion = "".obs;
  RxString currentVersion = "".obs;
  RxString newAppUrl = "".obs;
  RxString updateNotes = "".obs;
  RxBool isLatestVersion =
      false.obs; // Track whether we are using the latest version

  // Reactive settings
  final _box = GetStorage();
  RxBool biometricEnabled = false.obs;
  RxBool notificationsEnabled = true.obs;

  @override
  void onInit() async {
    super.onInit();
    // Initialize settings from storage
    biometricEnabled.value = _box.read('biometricEnabled') ?? false;
    notificationsEnabled.value = _box.read('notificationsEnabled') ?? true;

    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    currentVersion.value = packageInfo.version;
    if (kDebugMode) {
      print("Current version: ${currentVersion.value}");
    }
    if (!kIsWeb) {
      // Check for updates from Play Store silently on app startup
      await checkForUpdatesSilently();
      await _initMessaging();

      // Setup Firebase messaging for update notifications
      await _setupUpdateNotifications();
    }
  }

  // Silent update check on app startup (shows custom dialog when update available)
  Future<void> checkForUpdatesSilently() async {
    // Only check for updates on Android
    if (!GetPlatform.isAndroid) return;

    try {
      final appUpdateInfo = await InAppUpdate.checkForUpdate();

      if (appUpdateInfo.updateAvailability ==
          UpdateAvailability.updateAvailable) {
        // Update available - show custom dialog after a short delay
        if (kDebugMode) {
          print('Update available from Play Store');
        }

        // Wait a bit for app to fully load before showing dialog
        await Future.delayed(const Duration(seconds: 2));

        // Show update dialog
        _showUpdateDialog(appUpdateInfo);
      }
    } catch (e) {
      // Silently fail on startup check - don't bother user
      if (kDebugMode) {
        print('Silent update check failed: $e');
      }
    }
  }

  // Show custom update dialog with flexible update
  void _showUpdateDialog(AppUpdateInfo appUpdateInfo) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.system_update, color: Colors.blue, size: 28),
            SizedBox(width: 12),
            Text('Update Available'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A new version of Drivemate is available!',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Update now to get the latest features and improvements.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Update will download in the background',
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Later'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Get.back();
              try {
                // Start flexible update (downloads in background)
                await InAppUpdate.startFlexibleUpdate();
              } catch (e) {
                if (kDebugMode) {
                  print('Flexible update failed: $e');
                }
                // Fallback to immediate update
                try {
                  await InAppUpdate.performImmediateUpdate();
                } catch (e2) {
                  // Final fallback - open Play Store
                  _openPlayStore();
                }
              }
            },
            icon: const Icon(Icons.system_update_alt),
            label: const Text('Update Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
      barrierDismissible: false, // User must choose Later or Update
    );
  }

  // Trigger the version check manually when user clicks the "Update" icon
  Future<void> checkForUpdate() async {
    // Only check for updates on Android
    if (!GetPlatform.isAndroid) {
      Get.snackbar(
        'Not Available',
        'In-app updates are only available on Android.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    try {
      // Check if update is available from Play Store
      final appUpdateInfo = await InAppUpdate.checkForUpdate();

      if (appUpdateInfo.updateAvailability ==
          UpdateAvailability.updateAvailable) {
        // Update is available - start the update flow
        await InAppUpdate.startFlexibleUpdate();
      } else {
        // No update available - show up-to-date message
        _showUpToDateDialog();
      }
    } on PlatformException catch (e) {
      // Handle cases where Play Store is not available
      if (kDebugMode) {
        print('In-app update check failed: ${e.message}');
      }
      // Fallback: Open Play Store directly
      _openPlayStore();
    } catch (e) {
      if (kDebugMode) {
        print('Error checking for updates: $e');
      }
      Get.snackbar(
        'Update Check Failed',
        'Unable to check for updates. Please try again later.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }

  // Show "Up to Date" dialog
  void _showUpToDateDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('Up to Date'),
          ],
        ),
        content: Text(
          'You are using the latest version of Drivemate.',
          style: Get.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Open Play Store as fallback
  Future<void> _openPlayStore() async {
    final playStoreUrl = 'market://details?id=com.drivemate.mds';
    final webUrl =
        'https://play.google.com/store/apps/details?id=com.drivemate.mds';

    try {
      // Try opening Play Store app first
      final playStoreUri = Uri.parse(playStoreUrl);
      if (await canLaunchUrl(playStoreUri)) {
        await launchUrl(playStoreUri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to web browser
        final webUri = Uri.parse(webUrl);
        if (await canLaunchUrl(webUri)) {
          await launchUrl(webUri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error opening Play Store: $e');
      }
      Get.snackbar(
        'Play Store',
        'Please open Play Store and search for Drivemate to update.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }

  // Show update prompt if there's a new version (DEPRECATED - using Play Store now)
  // This method is kept for backward compatibility but not used
  @Deprecated('Use Play Store In-App Updates instead')
  void checkUpdate({bool showUpToDate = false}) {
    // Deprecated - using Play Store In-App Updates
  }

  // Fetch the latest release from GitHub API (DEPRECATED)
  @Deprecated('Use Play Store In-App Updates instead')
  Future<void> checkLatestVersion({bool showUpToDate = false}) async {
    // Deprecated - using Play Store In-App Updates
  }

  String _extractVersion(String input) {
    // Deprecated - not needed for Play Store updates
    return input;
  }

  Future<void> _writeUpdateNotification() async {
    // Deprecated - not needed for Play Store updates
  }

  Future<void> _initMessaging() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    final token = await messaging.getToken();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && token != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('device_tokens')
          .doc(token)
          .set({
        'token': token,
        'platform':
            kIsWeb ? 'web' : (GetPlatform.isAndroid ? 'android' : 'ios'),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final title = message.notification?.title ?? 'Notification';
      final body = message.notification?.body ?? '';
      Get.rawSnackbar(
        message: '$title\n$body',
        duration: const Duration(seconds: 5),
        snackStyle: SnackStyle.FLOATING,
      );
    });
  }

  Future<void> _setupUpdateNotifications() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    final token = await messaging.getToken();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && token != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('device_tokens')
          .doc(token)
          .set({
        'token': token,
        'platform':
            kIsWeb ? 'web' : (GetPlatform.isAndroid ? 'android' : 'ios'),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final title = message.notification?.title ?? 'Notification';
      final body = message.notification?.body ?? '';
      Get.rawSnackbar(
        message: '$title\n$body',
        duration: const Duration(seconds: 5),
        snackStyle: SnackStyle.FLOATING,
      );
    });
  }
}
