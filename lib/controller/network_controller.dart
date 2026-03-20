import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NetworkController extends GetxController {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void onInit() {
    super.onInit();
    _checkInitialConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
      if (results.isNotEmpty) {
        _updateConnectionStatus(results.first);
      }
    });
  }

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    super.onClose();
  }

  void _checkInitialConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      if (results.isNotEmpty) {
        _updateConnectionStatus(results.first);
      }
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
    }
  }

  void _updateConnectionStatus(ConnectivityResult connectivityResult) {
    if (connectivityResult == ConnectivityResult.none) {
      Get.rawSnackbar(
        messageText: const Text('No internet connection',
            style: TextStyle(color: Colors.white, fontSize: 14)),
        isDismissible: false,
        duration: const Duration(days: 1),
        backgroundColor: Colors.grey[900]!,
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
