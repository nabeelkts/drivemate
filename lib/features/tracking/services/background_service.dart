import 'dart:async';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mds/features/tracking/services/location_tracking_service.dart';
import 'package:mds/firebase_options.dart';

/// Background service for continuous location tracking
///
/// Runs in separate isolate with own Dart VM instance.
/// Independent of UI state - works when app is closed.
class BackgroundService {
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    await service.configure(
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
      androidConfiguration: AndroidConfiguration(
        autoStart: false,
        onStart: onStart,
        isForegroundMode: true,
        autoStartOnBoot: true,
        initialNotificationTitle: 'Drivemate',
        initialNotificationContent: 'Location tracking active',
        foregroundServiceNotificationId: 888,
      ),
    );
  }

  /// Entry point for background service
  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    // Required for background isolate
    DartPluginRegistrant.ensureInitialized();

    // Initialize Firebase in background isolate
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize GetX and GetStorage
    await GetStorage.init();

    // Get current user ID from storage
    final storage = GetStorage();
    final userId = storage.read('userId') as String?;

    if (userId == null) {
      print('No user ID found, stopping service');
      service.stopSelf();
      return;
    }

    // Initialize tracking service
    final trackingService = LocationTrackingService();
    await trackingService.observeLessonStatus(userId);

    // Listen for stop command
    service.on('stop').listen((event) {
      trackingService.stopTracking();
      service.stopSelf();
    });
  }

  /// iOS background handler
  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }

  /// Start the background service
  static Future<void> start() async {
    final service = FlutterBackgroundService();
    await service.startService();
  }

  /// Stop the background service
  static Future<void> stop() async {
    final service = FlutterBackgroundService();
    service.invoke('stop');
  }

  /// Check if service is running
  static Future<bool> isRunning() async {
    final service = FlutterBackgroundService();
    return service.isRunning();
  }
}
