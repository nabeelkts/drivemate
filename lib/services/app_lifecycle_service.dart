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
  Future<void> checkBiometricOnAppStart() async {
    if (_hasCheckedInitialAuth) return;
    
    if (_firebaseAuth.currentUser != null && (_box.read('biometricEnabled') ?? false)) {
      _hasCheckedInitialAuth = true;
      await _authenticateWithBiometrics();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Biometric is only checked on app start (cold launch), not when resuming from background
  }

  Future<bool> _authenticateWithBiometrics() async {
    try {
      if (!await _auth.canCheckBiometrics) {
        return false;
      }

      final authenticated = await _auth.authenticate(
        localizedReason: 'Please authenticate to continue',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (!authenticated) {
        // If authentication fails, sign out the user
        await _firebaseAuth.signOut();
        Get.offAllNamed('/login');
      }

      _isAuthenticated = authenticated;
      return authenticated;
    } catch (e) {
      print('Error during biometric authentication: $e');
      return false;
    }
  }

  bool get isAuthenticated => _isAuthenticated;
  
  /// Reset authentication state (useful for testing or manual reset)
  void resetAuthentication() {
    _isAuthenticated = false;
    _hasCheckedInitialAuth = false;
  }
} 