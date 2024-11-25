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
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus as void Function(List<ConnectivityResult> event)?);
  }

  void _checkInitialConnectivity() async {
    ConnectivityResult connectivityResult =
        (await _connectivity.checkConnectivity()) as ConnectivityResult;
    _updateConnectionStatus(connectivityResult);
  }

  void _updateConnectionStatus(ConnectivityResult connectivityResult) {
    if (connectivityResult == ConnectivityResult.none) {
      Get.rawSnackbar(
        messageText: const Text('PLEASE CONNECT TO THE INTERNET',
            style: TextStyle(color: Colors.white, fontSize: 14)),
        isDismissible: false,
        duration: const Duration(seconds: 10),
        backgroundColor: Colors.red[400]!,
        icon: const Icon(
          Icons.wifi_off,
          color: Colors.white,
          size: 35,
        ),
        margin: EdgeInsets.zero,
        snackStyle: SnackStyle.GROUNDED,
      );
    } else {
      if (Get.isSnackbarOpen) {
        Get.closeCurrentSnackbar();
      }
    }
  }
}
