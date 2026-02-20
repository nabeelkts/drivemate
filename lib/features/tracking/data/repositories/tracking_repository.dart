import 'package:mds/features/tracking/domain/entities/driver_location.dart';

abstract class TrackingRepository {
  Future<void> startTracking(
    String driverId,
    String? lessonId, {
    String? driverName,
    String? schoolId,
    String? branchId,
  });

  Future<void> stopTracking(String driverId);
  Future<void> updateLocation(DriverLocation location);
  Stream<List<DriverLocation>> getOnlineDriverLocations();
  Stream<List<DriverLocation>> getOnlineDriversForSchool(String schoolId);
  Stream<DriverLocation?> getDriverLocation(String driverId);
  Future<bool> isTracking(String driverId);

  /// Total distance since tracking started (meters)
  Future<double> getDriverDistance(String driverId);

  /// ✅ Lesson-specific distance only (meters) — accurate for attendance
  Future<double> getDriverLessonDistance(String driverId);
}
