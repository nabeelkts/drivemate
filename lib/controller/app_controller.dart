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
import 'package:drivemate/screens/profile/dialog_box.dart';

@pragma('vm:entry-point')
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
      // Check for pending update that needs to be completed
      await _checkAndCompletePendingUpdate();

      // Check for updates from Play Store silently on app startup
      await checkForUpdatesSilently();
      await _initMessaging();

      // Setup Firebase messaging for update notifications
      await _setupUpdateNotifications();
    }
  }

  // Check and complete any pending update that was downloaded but not installed
  Future<void> _checkAndCompletePendingUpdate() async {
    if (!GetPlatform.isAndroid) return;

    final pendingUpdate = _box.read('pendingUpdate');
    if (pendingUpdate == true) {
      if (kDebugMode) {
        print('Found pending update - attempting to complete...');
      }
      try {
        // Try to complete the flexible update
        await InAppUpdate.completeFlexibleUpdate();
        // Clear pending state after successful completion
        await _box.remove('pendingUpdate');
        // Update the version tracking
        PackageInfo packageInfo = await PackageInfo.fromPlatform();
        await _box.write('lastAppVersion', packageInfo.version);
        if (kDebugMode) {
          print('Pending update completed successfully!');
        }
        Get.snackbar(
          'Update Complete',
          'App has been updated to the latest version.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      } catch (e) {
        // If completion fails, clear the pending state
        // The app might already be up to date or there's another issue
        await _box.remove('pendingUpdate');
        if (kDebugMode) {
          print('Could not complete pending update: $e');
        }
      }
    }
  }

  // Silent update check on app startup (shows custom dialog when update available)
  Future<void> checkForUpdatesSilently() async {
    // Only check for updates on Android
    if (!GetPlatform.isAndroid) return;

    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final currentVersionStr = packageInfo.version;

      // Check if we just updated - skip check if app was updated recently
      final lastVersion = _box.read('lastAppVersion');

      // Debug: print versions
      if (kDebugMode) {
        print("Last version in storage: $lastVersion");
        print("Current app version: $currentVersionStr");
      }

      // If this is a new version (app was just updated), don't show update dialog
      if (lastVersion != null && lastVersion != currentVersionStr) {
        // App was updated - save new version and skip update check
        await _box.write('lastAppVersion', currentVersionStr);
        // Also clear any pending update state
        await _box.remove('pendingUpdate');
        if (kDebugMode) {
          print(
              'App was updated from $lastVersion to $currentVersionStr - skipping update check');
        }
        return;
      }

      // First time or same version - check for updates
      if (lastVersion == null) {
        await _box.write('lastAppVersion', currentVersionStr);
      }

      // Check if there's a pending update that needs to be completed
      final pendingUpdate = _box.read('pendingUpdate');
      if (pendingUpdate == true) {
        // We have a pending update - check if it's still available
        if (kDebugMode) {
          print('Found pending update - checking status...');
        }
      }

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
      } else if (appUpdateInfo.updateAvailability ==
          UpdateAvailability.updateNotAvailable) {
        // No update available - ensure version is saved
        if (lastVersion != currentVersionStr) {
          await _box.write('lastAppVersion', currentVersionStr);
        }
        if (kDebugMode) {
          print('No update available - app is up to date');
        }
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
    showCustomConfirmBoolDialog(
      Get.context!,
      'Update Available',
      'A new version of Drivemate is available!\n\nUpdate will download in the background.',
      confirmText: 'Update Now',
      cancelText: 'Later',
    ).then((confirmed) async {
      if (confirmed == true) {
        try {
          // Mark that we have a pending update
          await _box.write('pendingUpdate', true);

          final result = await InAppUpdate.startFlexibleUpdate();

          if (kDebugMode) {
            print('Flexible update started: $result');
          }

          // If flexible update was successful, we need to restart the app
          if (result == AppUpdateResult.success) {
            // The update is downloaded but not installed yet
            // Show dialog to restart
            if (Get.context != null) {
              showCustomConfirmBoolDialog(
                Get.context!,
                'Update Ready',
                'The update has been downloaded. Restart now to apply the update?',
                confirmText: 'Restart Now',
                cancelText: 'Later',
              ).then((restartConfirmed) async {
                if (restartConfirmed == true) {
                  await InAppUpdate.completeFlexibleUpdate();
                  // App will restart automatically
                } else {
                  // Keep pending update state for next app launch
                  if (kDebugMode) {
                    print(
                        'User deferred restart - update will apply on next launch');
                  }
                }
              });
            }
          }
        } catch (e) {
          // Clear pending update state on failure
          await _box.remove('pendingUpdate');
          if (kDebugMode) {
            print('Flexible update failed: $e');
          }
          try {
            await InAppUpdate.performImmediateUpdate();
          } catch (e2) {
            _openPlayStore();
          }
        }
      }
    });
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
      // First, check if there's a pending update that needs to be completed
      final pendingUpdate = _box.read('pendingUpdate');
      if (pendingUpdate == true) {
        try {
          await InAppUpdate.completeFlexibleUpdate();
          await _box.remove('pendingUpdate');
          PackageInfo packageInfo = await PackageInfo.fromPlatform();
          await _box.write('lastAppVersion', packageInfo.version);
          Get.snackbar(
            'Update Complete',
            'App has been updated to the latest version.',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 3),
          );
          return;
        } catch (e) {
          // Continue to check for updates
          await _box.remove('pendingUpdate');
        }
      }

      // Check if update is available from Play Store
      final appUpdateInfo = await InAppUpdate.checkForUpdate();

      if (appUpdateInfo.updateAvailability ==
          UpdateAvailability.updateAvailable) {
        // Update is available - start flexible update
        try {
          await _box.write('pendingUpdate', true);
          final result = await InAppUpdate.startFlexibleUpdate();

          if (result == AppUpdateResult.success) {
            // Show dialog to restart
            if (Get.context != null) {
              showCustomConfirmBoolDialog(
                Get.context!,
                'Update Ready',
                'The update has been downloaded. Restart now to apply the update?',
                confirmText: 'Restart Now',
                cancelText: 'Later',
              ).then((restartConfirmed) async {
                if (restartConfirmed == true) {
                  await InAppUpdate.completeFlexibleUpdate();
                } else {
                  // Keep pending state for next launch
                }
              });
            }
          }
        } catch (e) {
          // Fallback to Play Store
          await _box.remove('pendingUpdate');
          _openPlayStore();
        }
      } else if (appUpdateInfo.updateAvailability ==
          UpdateAvailability.updateNotAvailable) {
        // No update available - update local version tracking
        PackageInfo packageInfo = await PackageInfo.fromPlatform();
        await _box.write('lastAppVersion', packageInfo.version);
        await _box.remove('pendingUpdate');
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
    showCustomInfoDialog(
      Get.context!,
      'Up to Date',
      'You are using the latest version of Drivemate.',
      buttonText: 'OK',
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
