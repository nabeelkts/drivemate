import 'package:get_storage/get_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mds/services/app_lifecycle_service.dart';

class AuthService {
  final LocalAuthentication _auth = LocalAuthentication();
  final GetStorage _box = GetStorage();
  late final AppLifecycleService _lifecycleService;

  AuthService() {
    _lifecycleService = Get.find<AppLifecycleService>();
  }

  Future<bool> isBiometricAvailable() async {
    try {
      return await _auth.canCheckBiometrics;
    } on PlatformException catch (e) {
      print('Error checking biometric availability: $e');
      return false;
    }
  }

  Future<bool> isBiometricEnabled() async {
    return _box.read('biometricEnabled') ?? false;
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      if (!await isBiometricAvailable()) {
        return false;
      }

      // Check what biometrics are available
      final availableBiometrics = await _auth.getAvailableBiometrics();
      print('Available biometrics: $availableBiometrics');

      // Use biometricOnly: false to allow device credentials as fallback
      // This helps on devices where fingerprint/face might not work properly
      return await _auth.authenticate(
        localizedReason: 'Please authenticate to login',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Changed to false to allow device credentials
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (e) {
      print('Error authenticating with biometrics: $e');
      return false;
    }
  }

  Future<void> enableBiometric() async {
    await _box.write('biometricEnabled', true);
  }

  Future<void> disableBiometric() async {
    await _box.write('biometricEnabled', false);
  }

  bool get isAuthenticated => _lifecycleService.isAuthenticated;
}
