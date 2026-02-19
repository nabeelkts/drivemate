import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:mds/features/tracking/data/repositories/tracking_repository.dart';
import 'package:mds/features/tracking/domain/entities/driver_location.dart';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';

/// Service for tracking driver location in real-time
///
/// Observes Firestore for active lessons and automatically starts/stops tracking.
/// Runs independently of UI state - works in background isolate.
class LocationTrackingService extends GetxService {
  late final TrackingRepository _repository;
  final ServiceInstance? _serviceInstance;

  LocationTrackingService({
    TrackingRepository? repository,
    ServiceInstance? serviceInstance,
  }) : _serviceInstance = serviceInstance {
    _repository = repository ?? Get.find<TrackingRepository>();
  }

  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<QuerySnapshot>? _lessonStreamSubscription;

  String? _currentDriverId;
  String? _currentLessonId;
  bool _isTracking = false;

  // Distance tracking
  double _totalDistance = 0.0; // in meters
  Position? _lastPosition;

  /// Initialize service
  @override
  void onInit() {
    super.onInit();
    checkLocationPermission();
  }

  /// Check and request location permissions
  Future<bool> checkLocationPermission() async {
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

    // Start tracking immediately (Uber-style, always on when app is open/service started)
    await startTracking(driverId, null);

    // Cancel existing subscription
    await _lessonStreamSubscription?.cancel();

    // Query for active lessons assigned to this driver
    final query = FirebaseFirestore.instance
        .collectionGroup('students')
        .where('assignedDriver', isEqualTo: driverId)
        .where('lessonStatus', isEqualTo: 'started');

    _lessonStreamSubscription = query.snapshots().listen((snapshot) async {
      if (snapshot.docs.isNotEmpty) {
        // Active lesson found - update lessonId
        final lessonId = snapshot.docs.first.id;
        if (_currentLessonId != lessonId) {
          _currentLessonId = lessonId;
          print('Lesson started: $lessonId');
        }
      } else {
        // No active lessons - clear lessonId but keep tracking
        if (_currentLessonId != null) {
          _currentLessonId = null;
          print('Lesson ended');
        }
      }
    });
  }

  /// Start location tracking
  Future<void> startTracking(String driverId, String? lessonId) async {
    _currentDriverId = driverId;

    if (_isTracking) {
      // If already tracking, just update the lessonId if provided (or if it changed)
      if (lessonId != _currentLessonId) {
        _currentLessonId = lessonId;
      }
      return;
    }

    final hasPermission = await checkLocationPermission();
    if (!hasPermission) {
      print('Location permission denied');
      return;
    }

    // Initialize tracking in repository
    await _repository.startTracking(driverId, lessonId);

    // Reset distance tracking
    _totalDistance = 0.0;
    _lastPosition = null;

    // Configure location settings
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    // Start streaming location
    try {
      _positionStreamSubscription =
          Geolocator.getPositionStream(locationSettings: locationSettings)
              .listen(
        (Position position) {
          print('Location update: ${position.latitude}, ${position.longitude}');
          _calculateDistance(position);
          _updateLocation(position);
        },
        onError: (error) {
          print('Location stream error: $error');
          // Optional: Attempt to restart stream or notify user via local notification if possible
        },
      );

      _isTracking = true;
      _currentLessonId = lessonId;
      print('Started tracking for driver $driverId, lesson $lessonId');
    } catch (e) {
      print('Error starting location stream: $e');
      _isTracking = false;
    }
  }

  /// Update location to Firebase
  void _updateLocation(Position position) {
    if (_currentDriverId == null) {
      print('Cannot update location: driverId is null');
      return;
    }

    // print('Updating location for $_currentDriverId to Firebase');
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

    _repository.updateLocation(location).then((_) {
      // Success - maybe too verbose to print every time
    }).catchError((e) {
      print('Error updating location: $e');
    });

    // Update background service notification if available
    if (_serviceInstance is AndroidServiceInstance) {
      (_serviceInstance as AndroidServiceInstance)
          .setForegroundNotificationInfo(
        title: 'Drivemate: Active Lesson',
        content:
            'Speed: ${(location.speed * 3.6).toStringAsFixed(1)} km/h | Dist: ${(_totalDistance / 1000).toStringAsFixed(2)} km',
      );
    }
  }

  /// Calculate distance between positions
  void _calculateDistance(Position currentPosition) {
    if (_lastPosition != null) {
      double distance = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        currentPosition.latitude,
        currentPosition.longitude,
      );
      _totalDistance += distance;
    }
    _lastPosition = currentPosition;
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

  /// Get total distance covered in current session (in meters)
  double get totalDistance => _totalDistance;
}
