import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

/// Controller to handle all app permissions
class PermissionController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    // Start permission request flow after a short delay
    Future.delayed(const Duration(seconds: 1), () => requestAllPermissions());
  }

  /// Request all necessary permissions for the app
  Future<void> requestAllPermissions() async {
    // List of permissions to request
    final permissions = [
      Permission.location,
      Permission.locationWhenInUse,
      Permission.notification,
    ];

    // Request permissions one by one to avoid UI overlaps
    for (var permission in permissions) {
      final status = await permission.status;
      if (status.isDenied || status.isRestricted) {
        await permission.request();
      }
    }

    // Special check for Background Location (needed for tracking)
    // Only ask if WhenInUse is granted
    if (await Permission.locationWhenInUse.isGranted) {
      final backgroundStatus = await Permission.locationAlways.status;
      if (backgroundStatus.isDenied) {
        // We might want to show a custom rationale first
        // await Permission.locationAlways.request();
      }
    }
  }

  /// Helper to check if a permission is granted
  Future<bool> isGranted(Permission permission) async {
    return await permission.isGranted;
  }
}
