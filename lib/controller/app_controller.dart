import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mds/firebase_options.dart';
import 'package:flutter/services.dart';

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
  bool _updateDialogOpen = false;

  @override
  void onInit() async {
    super.onInit();
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    currentVersion.value = packageInfo.version;
    if (kDebugMode) {
      print("Current version: ${currentVersion.value}");
    }
    if (!kIsWeb) {
      await checkLatestVersion();
      await _initMessaging();
    }
  }

  // Trigger the version check manually when user clicks the "Update" icon
  void checkForUpdate() async {
    await checkLatestVersion(showUpToDate: true);
  }

  // Show update prompt if there's a new version
  void checkUpdate({bool showUpToDate = false}) {
    // Show update prompt only if the app is not on the latest version
    if (!isLatestVersion.value) {
      if (_updateDialogOpen) return;
      _writeUpdateNotification();
      final titleStyle = Get.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            decoration: TextDecoration.none,
          ) ??
          const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            decoration: TextDecoration.none,
          );
      final versionStyle = Get.textTheme.bodySmall?.copyWith(
            color: Colors.white70,
            fontWeight: FontWeight.w500,
            decoration: TextDecoration.none,
          ) ??
          const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            decoration: TextDecoration.none,
          );
      final notesStyle = Get.textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            height: 1.35,
            decoration: TextDecoration.none,
          ) ??
          const TextStyle(
            color: Colors.white,
            fontSize: 13,
            height: 1.35,
            decoration: TextDecoration.none,
          );
      final theme = Get.theme;
      final isDark = theme.brightness == Brightness.dark;
      final cardColor = isDark ? Colors.black : Colors.white;
      final textPrimary = isDark ? Colors.white : Colors.black87;
      final accent = const Color(0xFFF46B45);
      _updateDialogOpen = true;
      Get.dialog(
        WillPopScope(
          onWillPop: () async {
            return false;
          },
          child: Stack(
            children: [
              Container(color: Colors.black.withOpacity(0.6)),
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.system_update, size: 48, color: textPrimary),
                      const SizedBox(height: 12),
                      Text('Update Required', style: titleStyle),
                      const SizedBox(height: 8),
                      Text(
                        'Available: v${oldVersion.value} • Current: v${currentVersion.value}',
                        style: versionStyle,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 160),
                        child: SingleChildScrollView(
                          child: Text(
                            updateNotes.value.isNotEmpty
                                ? updateNotes.value
                                : 'A new version is available with improvements and fixes.',
                            style: notesStyle,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () async {
                                if (newAppUrl.value.isNotEmpty) {
                                  // Launch the URL
                                  await launchUrl(
                                    Uri.parse(newAppUrl.value),
                                    mode: LaunchMode.externalApplication,
                                  );

                                  // Close the dialog and reset flag
                                  _updateDialogOpen = false;
                                  if (Get.isDialogOpen ?? false) {
                                    Get.back();
                                  }
                                }
                              },
                              child: const Text('Update'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                _updateDialogOpen = false;
                                if (Get.isDialogOpen ?? false) {
                                  Get.back();
                                }
                              },
                              child: const Text('Later'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        barrierDismissible: false,
        useSafeArea: true,
      ).then((_) {
        _updateDialogOpen = false;
      });
    } else if (showUpToDate) {
      final theme = Get.theme;
      final isDark = theme.brightness == Brightness.dark;
      final cardColor = isDark ? Colors.black : Colors.white;
      final textPrimary = isDark ? Colors.white : Colors.black87;
      Get.dialog(
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 48, color: textPrimary),
                const SizedBox(height: 12),
                Text('Up to Date',
                    style: TextStyle(
                        color: textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.none)),
                const SizedBox(height: 8),
                Text(
                  'You are using the latest version (v${currentVersion.value}).',
                  style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontSize: 13,
                      decoration: TextDecoration.none),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (Get.isDialogOpen ?? false) Get.back();
                    },
                    child: const Text('OK'),
                  ),
                ),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
        useSafeArea: true,
      );
    }
  }

  // Fetch the latest release from GitHub API
  Future<void> checkLatestVersion({bool showUpToDate = false}) async {
    const repositoryOwner = 'nabeelkts';
    const repositoryName = 'drivemate';

    final response = await http.get(
      Uri.parse(
          'https://api.github.com/repos/$repositoryOwner/$repositoryName/releases/latest'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final tagName = data['tag_name'];
      final normalizedLatest = _extractVersion(tagName?.toString() ?? '');
      final normalizedCurrent = _extractVersion(currentVersion.value);
      oldVersion.value = normalizedLatest;
      updateNotes.value = (data['body'] ?? data['name'] ?? '').toString();
      final assets = data['assets'] as List<dynamic>;
      for (final asset in assets) {
        final assetDownloadUrl = asset['browser_download_url'];
        newAppUrl.value = assetDownloadUrl;
      }

      // Compare versions and update isLatestVersion flag
      if (normalizedCurrent != normalizedLatest) {
        isLatestVersion.value = false;
        checkUpdate(); // Show update prompt if versions don't match
      } else {
        isLatestVersion.value = true;
        if (showUpToDate) {
          checkUpdate(
              showUpToDate:
                  true); // Show "Up to Date" feedback only on manual action
        }
      }
    } else {
      if (kDebugMode) {
        print(
            'Failed to fetch GitHub release info. Status code: ${response.statusCode}');
      }
      Get.snackbar(
        "Update Check Failed",
        "Could not check for updates. Please try again later.",
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }

  String _extractVersion(String input) {
    final match = RegExp(r'(\\d+\\.\\d+\\.\\d+)').firstMatch(input);
    if (match != null) {
      return match.group(1)!;
    }
    return input.replaceAll(RegExp(r'^[vV]'), '');
  }

  Future<void> _writeUpdateNotification() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final now = DateTime.now().toIso8601String();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .add({
        'title': 'App Update Available',
        'date': now,
        'timestamp': FieldValue.serverTimestamp(),
        'details':
            'Version ${oldVersion.value} is available. Tap Update to install.',
      });
    } catch (e) {
      if (kDebugMode) {
        print('Failed to write update notification: $e');
      }
    }
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
}
