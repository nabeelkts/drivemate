import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:mds/features/tracking/data/models/driver_location_model.dart';
import 'package:mds/features/tracking/data/repositories/tracking_repository.dart';
import 'package:mds/features/tracking/domain/entities/driver_location.dart';

class FirebaseTrackingRepository implements TrackingRepository {
  final FirebaseDatabase _database;
  final String _basePath = 'live_locations';

  FirebaseTrackingRepository(this._database);

  DatabaseReference _getRef(String driverId) =>
      _database.ref('$_basePath/$driverId');

  @override
  Future<void> startTracking(
    String driverId,
    String? lessonId, {
    String? driverName,
    String? schoolId,
    String? branchId,
  }) async {
    final ref = _getRef(driverId);

    await ref.onDisconnect().update({
      'isOnline': false,
      'updatedAt': ServerValue.timestamp,
    });

    await ref.set({
      'lat': 0.0,
      'lng': 0.0,
      'speed': 0.0,
      'heading': 0.0,
      'totalDistance': 0.0,
      'lessonDistance': 0.0,
      if (lessonId != null) 'lessonId': lessonId,
      if (driverName != null) 'driverName': driverName,
      if (schoolId != null) 'schoolId': schoolId,
      if (branchId != null) 'branchId': branchId,
      'isOnline': true,
      'updatedAt': ServerValue.timestamp,
    });

    // Re-confirm online — fixes onDisconnect race condition
    await Future.delayed(const Duration(milliseconds: 500));
    await ref.update({
      'isOnline': true,
      'updatedAt': ServerValue.timestamp,
    });
  }

  @override
  Future<void> stopTracking(String driverId) async {
    final ref = _getRef(driverId);
    await ref.onDisconnect().cancel();
    await ref.update({
      'isOnline': false,
      'updatedAt': ServerValue.timestamp,
    });
    Future.delayed(const Duration(minutes: 5), () => ref.remove());
  }

  @override
  Future<void> updateLocation(DriverLocation location) async {
    final ref = _getRef(location.driverId);
    final model = DriverLocationModel.fromEntity(location);
    await ref.update(model.toJson());
  }

  @override
  Stream<List<DriverLocation>> getOnlineDriverLocations() {
    return _database.ref(_basePath).onValue.map((event) {
      if (!event.snapshot.exists) return <DriverLocation>[];
      return _parseLocations(event.snapshot);
    });
  }

  @override
  Stream<List<DriverLocation>> getOnlineDriversForSchool(String schoolId) {
    return _database.ref(_basePath).onValue.map((event) {
      if (!event.snapshot.exists) return <DriverLocation>[];
      final all = _parseLocations(event.snapshot);
      print('DIAGNOSTIC: filtering by schoolId=$schoolId, '
          'drivers: ${all.map((l) => 'id=${l.driverId} school=${l.schoolId} branch=${l.branchId}').join(', ')}');
      return all
          .where((l) => l.schoolId == schoolId || l.branchId == schoolId)
          .toList();
    });
  }

  List<DriverLocation> _parseLocations(DataSnapshot snapshot) {
    return snapshot.children
        .map((child) {
          try {
            final driverId = child.key;
            if (driverId == null) return null;
            return DriverLocationModel.fromSnapshot(driverId, child).toEntity();
          } catch (e) {
            print('Error parsing driver location for ${child.key}: $e');
            return null;
          }
        })
        .whereType<DriverLocation>()
        .where((l) => l.isOnline)
        .toList();
  }

  @override
  Stream<DriverLocation?> getDriverLocation(String driverId) {
    return _getRef(driverId).onValue.map((event) {
      if (!event.snapshot.exists) return null;
      try {
        return DriverLocationModel.fromSnapshot(driverId, event.snapshot)
            .toEntity();
      } catch (e) {
        return null;
      }
    });
  }

  @override
  Future<bool> isTracking(String driverId) async {
    final snapshot = await _getRef(driverId).get();
    if (!snapshot.exists) return false;
    final data = snapshot.value as Map<dynamic, dynamic>?;
    return data?['isOnline'] as bool? ?? false;
  }

  @override
  Future<double> getDriverDistance(String driverId) async {
    final snapshot = await _getRef(driverId).get();
    if (!snapshot.exists) return 0.0;
    final data = snapshot.value as Map<dynamic, dynamic>?;
    return (data?['totalDistance'] as num?)?.toDouble() ?? 0.0;
  }

  /// ✅ Returns lesson-specific distance (meters) — use this for attendance
  @override
  Future<double> getDriverLessonDistance(String driverId) async {
    final snapshot = await _getRef(driverId).get();
    if (!snapshot.exists) return 0.0;
    final data = snapshot.value as Map<dynamic, dynamic>?;
    return (data?['lessonDistance'] as num?)?.toDouble() ?? 0.0;
  }
}
