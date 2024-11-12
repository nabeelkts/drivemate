import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AppController extends GetxController {
  RxString oldVersion = "".obs;
  RxString currentVersion = "".obs;
  RxString newAppUrl = "".obs;

  @override
  void onInit() async {
    super.onInit();
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    currentVersion.value = packageInfo.version;
    print("Current version: ${currentVersion.value}");
    checkLatestVersion();
  }

  // Show update prompt if there's a new version
  void checkUpdate() {
    Get.rawSnackbar(
      message: "New Update Available",
      mainButton: TextButton(
        onPressed: () {
          if (newAppUrl.value.isNotEmpty) {
            launchUrl(
              Uri.parse(newAppUrl.value),
              mode: LaunchMode.externalApplication,
            );
            Get.back();
          } else {
            Get.snackbar("Error", "Update URL is not available");
          }
        },
        child: Text("Update"),
      ),
      duration: Duration(days: 1),
      icon: Icon(Icons.update_sharp),
      snackStyle: SnackStyle.FLOATING,
      barBlur: 20,
      leftBarIndicatorColor: Colors.blue,
    );
  }

  // Fetch the latest release from GitHub API
  Future<void> checkLatestVersion() async {
    const repositoryOwner = 'nabeelkts';
    const repositoryName = 'drivemate';
    
    final response = await http.get(
      Uri.parse('https://api.github.com/repos/$repositoryOwner/$repositoryName/releases/latest'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final tagName = data['tag_name'];  // version tag, e.g., v1.2.3
      oldVersion.value = tagName;

      final assets = data['assets'] as List<dynamic>;
      for (final asset in assets) {
        final assetName = asset['name'];
        final assetDownloadUrl = asset['browser_download_url'];
        newAppUrl.value = assetDownloadUrl;
      }

      print("Latest version: ${oldVersion.value}");
      print("Download URL: ${newAppUrl.value}");

      // Compare versions and show update prompt if versions differ
      if (currentVersion.value != oldVersion.value) {
        checkUpdate();
      }
    } else {
      print('Failed to fetch GitHub release info. Status code: ${response.statusCode}');
    }
  }
}
