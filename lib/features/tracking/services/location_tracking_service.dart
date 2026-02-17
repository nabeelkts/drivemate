import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:mds/features/tracking/data/repositories/tracking_repository.dart';
import 'package:mds/features/tracking/domain/entities/driver_location.dart';

/// Service for tracking driver location in real-time
///
/// Observes Firestore for active lessons and automatically starts/stops tracking.
/// Runs independently of UI state - works in background isolate.
class LocationTrackingService extends GetxService {
  final TrackingRepository _repository = Get.find<TrackingRepository>();

  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<QuerySnapshot>? _lessonStreamSubscription;

  String? _currentDriverId;
  String? _currentLessonId;
  bool _isTracking = false;

  /// Initialize service
  @override
  void onInit() {
    super.onInit();
    _checkLocationPermission();
  }

  /// Check and request location permissions
  Future<bool> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Observe lesson status from Firestore
  ///
  /// This runs independently - no WorkspaceController needed
  Future<void> observeLessonStatus(String driverId) async {
    _currentDriverId = driverId;

    // Cancel existing subscription
    await _lessonStreamSubscription?.cancel();

    // Query for active lessons assigned to this driver
    final query = FirebaseFirestore.instance
        .collectionGroup('students')
        .where('assignedDriver', isEqualTo: driverId)
        .where('lessonStatus', isEqualTo: 'started');

    _lessonStreamSubscription = query.snapshots().listen((snapshot) async {
      if (snapshot.docs.isNotEmpty) {
        // Active lesson found - start tracking
        final lessonId = snapshot.docs.first.id;
        if (_currentLessonId != lessonId) {
          _currentLessonId = lessonId;
          await startTracking(driverId, lessonId);
        }
      } else {
        // No active lessons - stop tracking
        if (_isTracking) {
          await stopTracking();
        }
      }
    });
  }

  /// Start location tracking
  Future<void> startTracking(String driverId, String lessonId) async {
    if (_isTracking) return;

    final hasPermission = await _checkLocationPermission();
    if (!hasPermission) {
      print('Location permission denied');
      return;
    }

    // Initialize tracking in repository
    await _repository.startTracking(driverId, lessonId);

    // Configure location settings
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    // Start streaming location
    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        _updateLocation(position);
      },
      onError: (error) {
        print('Location stream error: $error');
      },
    );

    _isTracking = true;
    _currentLessonId = lessonId;
    print('Started tracking for driver $driverId, lesson $lessonId');
  }

  /// Update location to Firebase
  void _updateLocation(Position position) {
    if (_currentDriverId == null) return;

    final location = DriverLocation(
      driverId: _currentDriverId!,
      latitude: position.latitude,
      longitude: position.longitude,
      speed: position.speed,
      heading: position.heading,
      lessonId: _currentLessonId,
      isOnline: true,
      updatedAt: DateTime.now(),
    );

    _repository.updateLocation(location);
  }

  /// Stop tracking
  Future<void> stopTracking() async {
    if (!_isTracking) return;

    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;

    if (_currentDriverId != null) {
      await _repository.stopTracking(_currentDriverId!);
    }

    _isTracking = false;
    _currentLessonId = null;
    print('Stopped tracking for driver $_currentDriverId');
  }

  /// Clean up
  @override
  void onClose() {
    _positionStreamSubscription?.cancel();
    _lessonStreamSubscription?.cancel();
    super.onClose();
  }

  /// Check if currently tracking
  bool get isTracking => _isTracking;

  /// Get current driver ID
  String? get currentDriverId => _currentDriverId;

  /// Get current lesson ID
  String? get currentLessonId => _currentLessonId;
}
