import 'dart:async';

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

class AppController extends GetxService {
  RxString oldVersion = "".obs;
  RxString currentVersion = "".obs;
  RxString newAppUrl = "".obs;
  RxString updateNotes = "".obs;
  RxBool isLatestVersion =
      false.obs;

  final _box = GetStorage();
  RxBool biometricEnabled = false.obs;
  RxBool notificationsEnabled = true.obs;

  StreamSubscription<RemoteMessage>? _messagingSubscription;

  @override
  void onInit() {
    super.onInit();
    _initAsync();
  }

  Future<void> _initAsync() async {
    biometricEnabled.value = _box.read('biometricEnabled') ?? false;
    notificationsEnabled.value = _box.read('notificationsEnabled') ?? true;

    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    currentVersion.value = packageInfo.version;
    if (kDebugMode) {
      print("Current version: ${currentVersion.value}");
    }
    if (!kIsWeb) {
      await _checkAndCompletePendingUpdate();
      await checkForUpdatesSilently();
      await _setupMessaging();
    }
  }

  @override
  void onClose() {
    _messagingSubscription?.cancel();
    super.onClose();
  }

  Future<void> _checkAndCompletePendingUpdate() async {
    if (!GetPlatform.isAndroid) return;

    final pendingUpdate = _box.read('pendingUpdate');
    if (pendingUpdate == true) {
      if (kDebugMode) {
        print('Found pending update - attempting to complete...');
      }
      try {
        await InAppUpdate.completeFlexibleUpdate();
        await _box.remove('pendingUpdate');
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
        await _box.remove('pendingUpdate');
        if (kDebugMode) {
          print('Could not complete pending update: $e');
        }
      }
    }
  }

  Future<void> checkForUpdatesSilently() async {
    if (!GetPlatform.isAndroid) return;

    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final currentVersionStr = packageInfo.version;
      final lastVersion = _box.read('lastAppVersion');

      if (kDebugMode) {
        print("Last version in storage: $lastVersion");
        print("Current app version: $currentVersionStr");
      }

      if (lastVersion != null && lastVersion != currentVersionStr) {
        await _box.write('lastAppVersion', currentVersionStr);
        await _box.remove('pendingUpdate');
        if (kDebugMode) {
          print('App was updated - skipping update check');
        }
        return;
      }

      if (lastVersion == null) {
        await _box.write('lastAppVersion', currentVersionStr);
      }

      final pendingUpdate = _box.read('pendingUpdate');
      if (pendingUpdate == true) {
        if (kDebugMode) {
          print('Found pending update - checking status...');
        }
      }

      final appUpdateInfo = await InAppUpdate.checkForUpdate();

      if (appUpdateInfo.updateAvailability ==
          UpdateAvailability.updateAvailable) {
        if (kDebugMode) {
          print('Update available from Play Store');
        }
        await Future.delayed(const Duration(seconds: 2));
        _showUpdateDialog(appUpdateInfo);
      } else if (appUpdateInfo.updateAvailability ==
          UpdateAvailability.updateNotAvailable) {
        if (lastVersion != currentVersionStr) {
          await _box.write('lastAppVersion', currentVersionStr);
        }
        if (kDebugMode) {
          print('No update available - app is up to date');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Silent update check failed: $e');
      }
    }
  }

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
          await _box.write('pendingUpdate', true);
          final result = await InAppUpdate.startFlexibleUpdate();

          if (kDebugMode) {
            print('Flexible update started: $result');
          }

          if (result == AppUpdateResult.success) {
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
                  if (kDebugMode) {
                    print('User deferred restart');
                  }
                }
              });
            }
          }
        } catch (e) {
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

  Future<void> checkForUpdate() async {
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
          await _box.remove('pendingUpdate');
        }
      }

      final appUpdateInfo = await InAppUpdate.checkForUpdate();

      if (appUpdateInfo.updateAvailability ==
          UpdateAvailability.updateAvailable) {
        try {
          await _box.write('pendingUpdate', true);
          final result = await InAppUpdate.startFlexibleUpdate();

          if (result == AppUpdateResult.success) {
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
                }
              });
            }
          }
        } catch (e) {
          await _box.remove('pendingUpdate');
          _openPlayStore();
        }
      } else if (appUpdateInfo.updateAvailability ==
          UpdateAvailability.updateNotAvailable) {
        PackageInfo packageInfo = await PackageInfo.fromPlatform();
        await _box.write('lastAppVersion', packageInfo.version);
        await _box.remove('pendingUpdate');
        _showUpToDateDialog();
      }
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('In-app update check failed: ${e.message}');
      }
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

  void _showUpToDateDialog() {
    showCustomInfoDialog(
      Get.context!,
      'Up to Date',
      'You are using the latest version of Drivemate.',
      buttonText: 'OK',
    );
  }

  Future<void> _openPlayStore() async {
    final playStoreUrl = 'market://details?id=com.drivemate.mds';
    final webUrl =
        'https://play.google.com/store/apps/details?id=com.drivemate.mds';

    try {
      final playStoreUri = Uri.parse(playStoreUrl);
      if (await canLaunchUrl(playStoreUri)) {
        await launchUrl(playStoreUri, mode: LaunchMode.externalApplication);
      } else {
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

  @Deprecated('Use Play Store In-App Updates instead')
  void checkUpdate({bool showUpToDate = false}) {}

  @Deprecated('Use Play Store In-App Updates instead')
  Future<void> checkLatestVersion({bool showUpToDate = false}) async {}

  Future<void> _setupMessaging() async {
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
    _messagingSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
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
