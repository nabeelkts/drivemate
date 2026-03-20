import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppLifecycleService extends GetxService with WidgetsBindingObserver {
  final LocalAuthentication _auth = LocalAuthentication();
  final GetStorage _box = GetStorage();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  bool _isAuthenticated = false;
  bool _hasCheckedInitialAuth = false;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  /// Check biometric authentication when app first starts
  /// Only runs once per app launch - not on every resume
  Future<void> checkBiometricOnAppStart() async {
    // Skip if already checked or no user logged in
    if (_hasCheckedInitialAuth) return;

    // Check if biometric is actually enabled before attempting
    final biometricEnabled = _box.read('biometricEnabled') ?? false;
    if (_firebaseAuth.currentUser == null || !biometricEnabled) {
      _hasCheckedInitialAuth = true;
      return;
    }

    _hasCheckedInitialAuth = true;

    // Check if device supports biometrics before attempting
    final canCheckBiometrics = await _auth.canCheckBiometrics;
    final isDeviceSupported = await _auth.isDeviceSupported();

    if (!canCheckBiometrics && !isDeviceSupported) {
      // Device doesn't support biometrics - don't require it
      return;
    }

    await _authenticateWithBiometrics();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        // App went to background
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

  /// Check session when app resumes from background
  /// Session expiration is disabled - users stay logged in until they manually log out
  Future<void> _checkSessionOnResume() async {
    // Session expiry is disabled - no need to check
    // Users stay logged in until they manually log out
  }

  Future<bool> _authenticateWithBiometrics() async {
    try {
      // Use biometricOnly: false to allow PIN/pattern as fallback
      final authenticated = await _auth.authenticate(
        localizedReason: 'Please authenticate to continue',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allow PIN/pattern as fallback
        ),
      );

      if (!authenticated) {
        // User cancelled or failed - don't retry automatically, just return
        // This prevents accidental logouts when user doesn't want to authenticate
        return false;
      }

      _isAuthenticated = authenticated;
      return authenticated;
    } catch (e) {
      debugPrint('Error during biometric authentication: $e');
      // On error, don't sign out - just return false and let user continue
      // The session is still valid, user just couldn't authenticate with biometrics
      return false;
    }
  }

  bool get isAuthenticated => _isAuthenticated;

  /// Reset authentication state (useful for testing or manual reset)
  void resetAuthentication() {
    _isAuthenticated = false;
    _hasCheckedInitialAuth = false;
  }

  /// Allow re-checking biometric on app resume if needed
  void allowBiometricCheckAgain() {
    _hasCheckedInitialAuth = false;
  }
}
