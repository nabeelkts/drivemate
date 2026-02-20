import 'package:equatable/equatable.dart';

/// Domain entity representing a driver's real-time location
class DriverLocation extends Equatable {
  final String driverId;
  final double latitude;
  final double longitude;
  final double speed;
  final double heading;
  final String? lessonId;
  final bool isOnline;
  final DateTime updatedAt;

  final String? driverName;
  final String? schoolId;
  final String? branchId;
  final double totalDistance;   // total since tracking started (meters)
  final double lessonDistance;  // distance for current lesson only (meters)

  const DriverLocation({
    required this.driverId,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.heading,
    this.lessonId,
    required this.isOnline,
    required this.updatedAt,
    this.driverName,
    this.schoolId,
    this.branchId,
    this.totalDistance = 0.0,
    this.lessonDistance = 0.0,
  });

  @override
  List<Object?> get props => [
        driverId, latitude, longitude, speed, heading,
        lessonId, isOnline, updatedAt, driverName, schoolId,
        branchId, totalDistance, lessonDistance,
      ];

  DriverLocation copyWith({
    String? driverId,
    double? latitude,
    double? longitude,
    double? speed,
    double? heading,
    String? lessonId,
    bool? isOnline,
    DateTime? updatedAt,
    String? driverName,
    String? schoolId,
    String? branchId,
    double? totalDistance,
    double? lessonDistance,
  }) {
    return DriverLocation(
      driverId: driverId ?? this.driverId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      lessonId: lessonId ?? this.lessonId,
      isOnline: isOnline ?? this.isOnline,
      updatedAt: updatedAt ?? this.updatedAt,
      driverName: driverName ?? this.driverName,
      schoolId: schoolId ?? this.schoolId,
      branchId: branchId ?? this.branchId,
      totalDistance: totalDistance ?? this.totalDistance,
      lessonDistance: lessonDistance ?? this.lessonDistance,
    );
  }
}
