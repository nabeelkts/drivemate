import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoadingUtils {
  static void showLoadingDialog(BuildContext context,
      {String message = 'Loading...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Future<T> wrapWithLoading<T>(
    BuildContext context,
    Future<T> Function() action, {
    String message = 'Generating PDF...',
  }) async {
    showLoadingDialog(context, message: message);
    try {
      final result = await action();
      Get.back(); // Use Get.back() for more reliable dismissal in reactive flows
      return result;
    } catch (e) {
      Get.back();
      rethrow;
    }
  }
}
