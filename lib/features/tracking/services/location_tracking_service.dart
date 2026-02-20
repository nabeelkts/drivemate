import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mds/features/tracking/data/repositories/tracking_repository.dart';
import 'package:mds/features/tracking/domain/entities/driver_location.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

/// Service for tracking driver location in real-time
///
/// Writes GPS path to Firestore under lesson_paths/{lessonId}/points
/// so the owner map can replay the full route even after reconnecting.
class LocationTrackingService extends GetxService {
  late final TrackingRepository _repository;
  final ServiceInstance? _serviceInstance;

  final String? _driverName;
  final String? _schoolId;
  final String? _branchId;

  LocationTrackingService({
    TrackingRepository? repository,
    ServiceInstance? serviceInstance,
    String? driverName,
    String? schoolId,
    String? branchId,
  })  : _serviceInstance = serviceInstance,
        _driverName = driverName ?? GetStorage().read('driverName'),
        _schoolId = schoolId ?? GetStorage().read('schoolId'),
        _branchId = branchId ?? GetStorage().read('branchId') {
    _repository = repository ?? Get.find<TrackingRepository>();
  }

  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<QuerySnapshot>? _lessonStreamSubscription;

  String? _currentDriverId;
  String? _currentLessonId;
  bool _isTracking = false;
  Timer? _heartbeatTimer;

  double _totalDistance = 0.0;
  double _lessonDistance = 0.0;
  Position? _lastPosition;

  // Path persistence — throttle Firestore writes
  // Write a path point every _pathWriteIntervalMeters OR _pathWriteIntervalSeconds
  static const double _pathWriteIntervalMeters = 20.0; // every 20m
  static const int _pathWriteIntervalSeconds = 15;    // or every 15s
  double _distanceSinceLastPathWrite = 0.0;
  DateTime? _lastPathWriteTime;

  @override
  void onInit() {
    super.onInit();
    checkLocationPermission();
  }

  Future<bool> checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  Future<void> observeLessonStatus(String driverId) async {
    _currentDriverId = driverId;
    await startTracking(driverId, null);
    await _lessonStreamSubscription?.cancel();

    final query = FirebaseFirestore.instance
        .collectionGroup('students')
        .where('assignedDriver', isEqualTo: driverId)
        .where('lessonStatus', isEqualTo: 'started');

    _lessonStreamSubscription = query.snapshots().listen((snapshot) async {
      if (snapshot.docs.isNotEmpty) {
        final lessonId = snapshot.docs.first.id;
        if (_currentLessonId != lessonId) {
          _currentLessonId = lessonId;
          _lessonDistance = 0.0;
          _lastPosition = null;
          _distanceSinceLastPathWrite = 0.0;
          _lastPathWriteTime = null;
          print('Lesson started: $lessonId');

          // Create lesson path document with metadata
          await _initLessonPath(lessonId, driverId);
        }
      } else {
        if (_currentLessonId != null) {
          final completedLessonId = _currentLessonId!;
          final distanceKm = _lessonDistance / 1000;
          print('Lesson ended: $completedLessonId — ${distanceKm.toStringAsFixed(2)} km');
          await _saveLessonDistance(completedLessonId, _lessonDistance);
          await _finalizeLessonPath(completedLessonId, _lessonDistance);
          _currentLessonId = null;
          _lessonDistance = 0.0;
        }
      }
    }, onError: (e) {
      print('Lesson status observer error: $e');
    });
  }

  /// Create the lesson_paths document when lesson starts
  Future<void> _initLessonPath(String lessonId, String driverId) async {
    try {
      final schoolId = _schoolId ?? GetStorage().read('schoolId') ?? '';
      await FirebaseFirestore.instance
          .collection('lesson_paths')
          .doc(lessonId)
          .set({
        'lessonId': lessonId,
        'driverId': driverId,
        'driverName': _driverName ?? GetStorage().read('driverName'),
        'schoolId': schoolId,
        'startedAt': FieldValue.serverTimestamp(),
        'finalDistanceKm': 0.0,
        'isComplete': false,
      });
    } catch (e) {
      print('Error initializing lesson path: $e');
    }
  }

  /// Mark path as complete and write final distance
  Future<void> _finalizeLessonPath(String lessonId, double distanceMeters) async {
    try {
      await FirebaseFirestore.instance
          .collection('lesson_paths')
          .doc(lessonId)
          .update({
        'finalDistanceKm': distanceMeters / 1000,
        'completedAt': FieldValue.serverTimestamp(),
        'isComplete': true,
      });
    } catch (e) {
      print('Error finalizing lesson path: $e');
    }
  }

  /// Write a single GPS point to Firestore (throttled)
  Future<void> _writePathPoint(Position position) async {
    if (_currentLessonId == null) return;

    final now = DateTime.now();
    final secondsSinceLast = _lastPathWriteTime == null
        ? _pathWriteIntervalSeconds + 1
        : now.difference(_lastPathWriteTime!).inSeconds;

    final shouldWrite =
        _distanceSinceLastPathWrite >= _pathWriteIntervalMeters ||
        secondsSinceLast >= _pathWriteIntervalSeconds;

    if (!shouldWrite) return;

    try {
      await FirebaseFirestore.instance
          .collection('lesson_paths')
          .doc(_currentLessonId)
          .collection('points')
          .add({
        'lat': position.latitude,
        'lng': position.longitude,
        'speed': position.speed,
        'heading': position.heading,
        'distanceFromStart': _lessonDistance,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _distanceSinceLastPathWrite = 0.0;
      _lastPathWriteTime = now;
    } catch (e) {
      print('Error writing path point: $e');
    }
  }

  /// Save lesson distance to the student's Firestore doc
  Future<void> _saveLessonDistance(
      String lessonId, double distanceMeters) async {
    try {
      final schoolId = _schoolId ?? GetStorage().read('schoolId');
      final driverId = _currentDriverId;
      if (schoolId == null || driverId == null) return;

      final query = await FirebaseFirestore.instance
          .collectionGroup('students')
          .where('assignedDriver', isEqualTo: driverId)
          .get();

      for (final doc in query.docs) {
        if (doc.id == lessonId ||
            doc.data()['currentLessonId'] == lessonId) {
          await doc.reference.update({
            'lessonDistanceKm': distanceMeters / 1000,
            'lessonCompletedAt': FieldValue.serverTimestamp(),
          });
          print(
              'Saved ${(distanceMeters / 1000).toStringAsFixed(2)} km to Firestore');
          break;
        }
      }
    } catch (e) {
      print('Error saving lesson distance: $e');
    }
  }

  Future<void> startTracking(String driverId, String? lessonId) async {
    _currentDriverId = driverId;
    if (_isTracking) {
      if (lessonId != _currentLessonId) _currentLessonId = lessonId;
      return;
    }

    final hasPermission = await checkLocationPermission();
    if (!hasPermission) {
      print('Location permission denied');
      return;
    }

    final effectiveDriverName = _driverName ?? GetStorage().read('driverName');
    final effectiveSchoolId = _schoolId ?? GetStorage().read('schoolId');
    final effectiveBranchId = _branchId ?? GetStorage().read('branchId');

    print('DIAGNOSTIC: startTracking driverId=$driverId '
        'driverName=$effectiveDriverName schoolId=$effectiveSchoolId '
        'branchId=$effectiveBranchId');

    await _repository.startTracking(
      driverId,
      lessonId,
      driverName: effectiveDriverName,
      schoolId: effectiveSchoolId,
      branchId: effectiveBranchId,
    );

    _totalDistance = 0.0;
    _lessonDistance = 0.0;
    _lastPosition = null;
    _distanceSinceLastPathWrite = 0.0;
    _lastPathWriteTime = null;

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    try {
      Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      ).then((position) {
        _lastPosition = position;
        _updateLocation(position);
      }).catchError((e) => print('Initial position error: $e'));

      _positionStreamSubscription =
          Geolocator.getPositionStream(locationSettings: locationSettings)
              .listen(
        (Position position) {
          _calculateDistance(position);
          _updateLocation(position);
          _writePathPoint(position); // ✅ persist to Firestore
        },
        onError: (e) => print('Location stream error: $e'),
      );

      _isTracking = true;
      _currentLessonId = lessonId;
      print('Started tracking for driver $driverId');

      _heartbeatTimer?.cancel();
      _heartbeatTimer =
          Timer.periodic(const Duration(seconds: 30), (_) => _sendHeartbeat());
    } catch (e) {
      print('Error starting location stream: $e');
      _isTracking = false;
    }
  }

  void _updateLocation(Position position) {
    if (_currentDriverId == null) return;

    final effectiveDriverName = _driverName ?? GetStorage().read('driverName');
    final effectiveSchoolId = _schoolId ?? GetStorage().read('schoolId');
    final effectiveBranchId = _branchId ?? GetStorage().read('branchId');

    final location = DriverLocation(
      driverId: _currentDriverId!,
      latitude: position.latitude,
      longitude: position.longitude,
      speed: position.speed,
      heading: position.heading,
      lessonId: _currentLessonId,
      isOnline: true,
      updatedAt: DateTime.now(),
      driverName: effectiveDriverName,
      schoolId: effectiveSchoolId,
      branchId: effectiveBranchId,
      totalDistance: _totalDistance,
      lessonDistance: _lessonDistance,
    );

    _repository.updateLocation(location).catchError((e) {
      print('Error updating location: $e');
    });

    if (_serviceInstance is AndroidServiceInstance) {
      (_serviceInstance as AndroidServiceInstance)
          .setForegroundNotificationInfo(
        title: 'Drivemate: Active',
        content:
            'Speed: ${(location.speed * 3.6).toStringAsFixed(1)} km/h | '
            'Trip: ${(_lessonDistance / 1000).toStringAsFixed(2)} km',
      );
    }
  }

  void _sendHeartbeat() {
    if (_currentDriverId == null || !_isTracking) return;
    if (_lastPosition != null) {
      _updateLocation(_lastPosition!);
    } else {
      _repository.startTracking(
        _currentDriverId!,
        _currentLessonId,
        driverName: _driverName ?? GetStorage().read('driverName'),
        schoolId: _schoolId ?? GetStorage().read('schoolId'),
        branchId: _branchId ?? GetStorage().read('branchId'),
      );
    }
  }

  void _calculateDistance(Position currentPosition) {
    if (_lastPosition != null) {
      final distance = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        currentPosition.latitude,
        currentPosition.longitude,
      );
      if (distance > 2.0) {
        _totalDistance += distance;
        if (_currentLessonId != null) {
          _lessonDistance += distance;
          _distanceSinceLastPathWrite += distance;
        }
      }
    }
    _lastPosition = currentPosition;
  }

  Future<void> stopTracking() async {
    if (!_isTracking) return;

    if (_currentLessonId != null && _lessonDistance > 0) {
      await _saveLessonDistance(_currentLessonId!, _lessonDistance);
      await _finalizeLessonPath(_currentLessonId!, _lessonDistance);
    }

    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    if (_currentDriverId != null) {
      await _repository.stopTracking(_currentDriverId!);
    }

    _isTracking = false;
    _currentLessonId = null;
    _lessonDistance = 0.0;
    print('Stopped tracking for driver $_currentDriverId');
  }

  @override
  void onClose() {
    _positionStreamSubscription?.cancel();
    _lessonStreamSubscription?.cancel();
    super.onClose();
  }

  bool get isTracking => _isTracking;
  String? get currentDriverId => _currentDriverId;
  String? get currentLessonId => _currentLessonId;
  double get totalDistance => _totalDistance;
  double get lessonDistance => _lessonDistance;
}
