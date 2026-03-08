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
    // Only request notification permission on startup
    // Location permission will be requested when a lesson/test starts
    final notificationStatus = await Permission.notification.status;
    if (notificationStatus.isDenied || notificationStatus.isRestricted) {
      await Permission.notification.request();
    }
  }

  /// Helper to check if a permission is granted
  Future<bool> isGranted(Permission permission) async {
    return await permission.isGranted;
  }
}
