import 'package:mds/features/tracking/domain/entities/driver_location.dart';

/// Abstract repository interface for driver location tracking
///
/// This abstraction allows the UI layer to be independent of the data source.
/// Can be implemented with Firebase, Supabase, or any other backend.
abstract class TrackingRepository {
  /// Start tracking a driver's location
  ///
  /// Sets up Firebase .onDisconnect() handler and initializes location entry
  Future<void> startTracking(String driverId, String? lessonId);

  /// Stop tracking a driver's location
  ///
  /// Sets isOnline to false and optionally removes the location entry
  Future<void> stopTracking(String driverId);

  /// Update driver's current location
  ///
  /// Called periodically by the location service
  Future<void> updateLocation(DriverLocation location);

  /// Stream of all online driver locations
  ///
  /// Filters for isOnline == true
  Stream<List<DriverLocation>> getOnlineDriverLocations();

  /// Stream of a specific driver's location
  ///
  /// Returns null if driver is offline or not tracking
  Stream<DriverLocation?> getDriverLocation(String driverId);

  /// Check if a driver is currently being tracked
  Future<bool> isTracking(String driverId);
}
