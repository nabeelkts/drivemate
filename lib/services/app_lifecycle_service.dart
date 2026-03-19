import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:drivemate/services/security_service.dart';

class AppLifecycleService extends GetxService with WidgetsBindingObserver {
  final LocalAuthentication _auth = LocalAuthentication();
  final GetStorage _box = GetStorage();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  bool _isAuthenticated = false;
  bool _hasCheckedInitialAuth = false;
  int _retryCount = 0;
  static const int maxRetries = 2;
  DateTime? _pausedTime;
  SecurityService? _securityService;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    // Initialize SecurityService if available
    try {
      _securityService = Get.find<SecurityService>();
    } catch (e) {
      // SecurityService not yet available
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  /// Check biometric authentication when app first starts
  Future<void> checkBiometricOnAppStart() async {
    if (_hasCheckedInitialAuth) return;

    if (_firebaseAuth.currentUser != null &&
        (_box.read('biometricEnabled') ?? false)) {
      _hasCheckedInitialAuth = true;
      _retryCount = 0;
      await _authenticateWithBiometrics();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        // Record the time when app goes to background
        _pausedTime = DateTime.now();
        break;
      case AppLifecycleState.resumed:
        // SECURITY: Check session expiration when app resumes from background
        _checkSessionOnResume();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // Handle other states if needed
        break;
    }
  }

  /// SECURITY: Check session expiration when app resumes from background
  Future<void> _checkSessionOnResume() async {
    if (_pausedTime == null) return;

    // Initialize SecurityService if not already done
    if (_securityService == null) {
      try {
        _securityService = Get.find<SecurityService>();
      } catch (e) {
        return;
      }
    }

    // Check if session has expired
    if (_securityService!.isSessionExpired()) {
      // Session expired - sign out user
      await _firebaseAuth.signOut();

      // Clear security storage
      _securityService!.clearSecurityStorage();

      // Navigate to login
      Get.offAllNamed('/login');

      // Show session expired message
      Get.snackbar(
        'Session Expired',
        'Your session has expired. Please log in again.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    } else {
      // Session still valid - refresh session timer
      _securityService!.refreshSession();
    }

    _pausedTime = null;
  }

  Future<bool> _authenticateWithBiometrics() async {
    try {
      // Check if device supports biometrics or device credentials (PIN/pattern)
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();

      if (!canCheckBiometrics && !isDeviceSupported) {
        return false;
      }

      // Use biometricOnly: false to allow PIN/pattern as fallback
      final authenticated = await _auth.authenticate(
        localizedReason: 'Please authenticate to continue',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allow PIN/pattern as fallback
        ),
      );

      if (!authenticated) {
        // User cancelled or failed - retry
        _retryCount++;
        if (_retryCount <= maxRetries) {
          // Retry authentication after a short delay
          await Future.delayed(const Duration(milliseconds: 500));
          return await _authenticateWithBiometrics();
        } else {
          // Max retries reached - sign out and go to login page
          await _firebaseAuth.signOut();
          Get.offAllNamed('/login');
          return false;
        }
      }

      _isAuthenticated = authenticated;
      _retryCount = 0; // Reset retry count on success
      return authenticated;
    } catch (e) {
      print('Error during biometric authentication: $e');
      // On error, retry
      _retryCount++;
      if (_retryCount <= maxRetries) {
        await Future.delayed(const Duration(milliseconds: 500));
        return await _authenticateWithBiometrics();
      } else {
        // Max retries reached - sign out and go to login page
        await _firebaseAuth.signOut();
        Get.offAllNamed('/login');
        return false;
      }
    }
  }

  bool get isAuthenticated => _isAuthenticated;

  /// Reset authentication state (useful for testing or manual reset)
  void resetAuthentication() {
    _isAuthenticated = false;
    _hasCheckedInitialAuth = false;
    _retryCount = 0;
  }
}
