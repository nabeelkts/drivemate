import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NetworkController extends GetxController {
  final Connectivity _connectivity = Connectivity();

  @override
  void onInit() {
    super.onInit();

    // Check the initial connectivity status
    _checkInitialConnectivity();

    // Listen for connectivity changes
    _connectivity.onConnectivityChanged.listen((results) {
      if (results.isNotEmpty) {
        _updateConnectionStatus(results.first);
      }
    });
  }

  void _checkInitialConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results.first);
    } catch (e) {
      print('Error checking connectivity: $e');
    }
  }

  void _updateConnectionStatus(ConnectivityResult connectivityResult) {
    if (connectivityResult == ConnectivityResult.none) {
      Get.rawSnackbar(
        messageText: const Text('No internet connection',
            style: TextStyle(color: Colors.white, fontSize: 14)),
        isDismissible: false,
        duration: const Duration(days: 1), // Keep visible until reconnected
        backgroundColor: Colors.grey[900]!, // More professional dark theme
        icon: const Icon(
          Icons.wifi_off_rounded,
          color: Colors.white,
          size: 28,
        ),
        mainButton: TextButton(
          onPressed: () {
            if (Get.isSnackbarOpen) {
              Get.closeCurrentSnackbar();
            }
          },
          child: const Text(
            'HIDE',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        margin: EdgeInsets.zero,
        snackStyle: SnackStyle.GROUNDED,
      );
    } else {
      if (Get.isSnackbarOpen) {
        Get.closeCurrentSnackbar();
        // Show a brief success message when reconnected
        Get.rawSnackbar(
          messageText: const Text('Back online',
              style: TextStyle(color: Colors.white, fontSize: 14)),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.green[600]!,
          icon: const Icon(
            Icons.wifi_rounded,
            color: Colors.white,
            size: 28,
          ),
          margin: EdgeInsets.zero,
          snackStyle: SnackStyle.GROUNDED,
        );
      }
    }
  }
}
