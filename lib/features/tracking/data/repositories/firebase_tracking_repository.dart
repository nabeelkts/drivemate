import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:mds/features/tracking/data/models/driver_location_model.dart';
import 'package:mds/features/tracking/data/repositories/tracking_repository.dart';
import 'package:mds/features/tracking/domain/entities/driver_location.dart';

/// Firebase Realtime Database implementation of TrackingRepository
///
/// Handles all Firebase-specific logic for live location tracking.
/// The UI layer has NO knowledge of Firebase through this abstraction.
class FirebaseTrackingRepository implements TrackingRepository {
  final FirebaseDatabase _database;
  final String _basePath = 'live_locations';

  FirebaseTrackingRepository(this._database);

  DatabaseReference _getRef(String driverId) {
    return _database.ref('$_basePath/$driverId');
  }

  @override
  Future<void> startTracking(String driverId, String? lessonId) async {
    final ref = _getRef(driverId);

    // Set up disconnect handler FIRST
    await ref.onDisconnect().update({
      'isOnline': false,
      'updatedAt': ServerValue.timestamp,
    });

    // Initialize tracking entry
    await ref.set({
      'lat': 0.0,
      'lng': 0.0,
      'speed': 0.0,
      'heading': 0.0,
      if (lessonId != null) 'lessonId': lessonId,
      'isOnline': true,
      'updatedAt': ServerValue.timestamp,
    });
  }

  @override
  Future<void> stopTracking(String driverId) async {
    final ref = _getRef(driverId);

    // Cancel disconnect handler
    await ref.onDisconnect().cancel();

    // Set offline
    await ref.update({
      'isOnline': false,
      'updatedAt': ServerValue.timestamp,
    });

    // Optionally remove the entry after a delay
    Future.delayed(const Duration(minutes: 5), () {
      ref.remove();
    });
  }

  @override
  Future<void> updateLocation(DriverLocation location) async {
    final ref = _getRef(location.driverId);
    final model = DriverLocationModel.fromEntity(location);
    await ref.update(model.toJson());
  }

  @override
  Stream<List<DriverLocation>> getOnlineDriverLocations() {
    return _database
        .ref(_basePath)
        .orderByChild('isOnline')
        .equalTo(true)
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return <DriverLocation>[];

      return data.entries
          .map((entry) {
            try {
              final driverId = entry.key as String;
              final snapshot = event.snapshot.child(driverId);
              return DriverLocationModel.fromSnapshot(driverId, snapshot)
                  .toEntity();
            } catch (e) {
              // Skip invalid entries
              return null;
            }
          })
          .whereType<DriverLocation>()
          .toList();
    });
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
}
