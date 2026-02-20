import 'dart:async';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:mds/features/tracking/data/repositories/firebase_tracking_repository.dart';
import 'package:mds/features/tracking/data/repositories/tracking_repository.dart';
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
    print('BackgroundService: onStart called');

    try {
      // Initialize Firebase in background isolate
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('BackgroundService: Firebase initialized');

      // Initialize GetX and GetStorage
      await GetStorage.init();
      print('BackgroundService: GetStorage initialized');

      // Get current user info from storage
      final storage = GetStorage();
      String? userId = storage.read('userId') as String?;
      print('BackgroundService: userId from storage: $userId');

      // Retry logic for userId if null (sometimes storage isn't immediately ready)
      if (userId == null) {
        print('BackgroundService: userId is null, retrying in 1 second...');
        await Future.delayed(const Duration(seconds: 1));
        userId = storage.read('userId') as String?;
        print('BackgroundService: userId after retry: $userId');
      }

      if (userId == null) {
        print(
            'BackgroundService: No user ID found after retry, stopping service');
        service.stopSelf();
        return;
      }

      // Read driver metadata from storage (written by WorkspaceController)
      final driverName = storage.read('driverName') as String?;
      final schoolId = storage.read('schoolId') as String?;
      final branchId = storage.read('branchId') as String?;
      print(
          'DIAGNOSTIC: BackgroundService storage read - userId=$userId, driverName=$driverName, schoolId=$schoolId, branchId=$branchId');

      // Initialize TrackingRepository for this isolate with explicit URL
      // This ensures background isolate always connects to the correct database
      const databaseUrl = 'https://smds-c1713-default-rtdb.firebaseio.com';
      final database = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: databaseUrl,
      );
      final trackingRepo = FirebaseTrackingRepository(database);

      // Initialize tracking service with dependencies and metadata
      final trackingService = LocationTrackingService(
        repository: trackingRepo,
        serviceInstance: service,
        driverName: driverName,
        schoolId: schoolId,
        branchId: branchId,
      );

      // Manually initialize the service since we aren't using Get.put
      trackingService.onInit();

      await trackingService.observeLessonStatus(userId);

      // Listen for stop command
      service.on('stop').listen((event) {
        trackingService.stopTracking();
        service.stopSelf();
        print('BackgroundService: Service stopped via event');
      });

      print('BackgroundService: Service started successfully for user $userId');
    } catch (e, stackTrace) {
      print('BackgroundService: Error starting service: $e');
      print('BackgroundService: Stack trace: $stackTrace');
      service.stopSelf();
    }
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
