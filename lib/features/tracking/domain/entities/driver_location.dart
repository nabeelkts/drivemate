import 'package:equatable/equatable.dart';

/// Domain entity representing a driver's real-time location
///
/// This is a pure domain model with no platform dependencies.
/// Can be used across all layers of the application.
class DriverLocation extends Equatable {
  final String driverId;
  final double latitude;
  final double longitude;
  final double speed;
  final double heading;
  final String? lessonId;
  final bool isOnline;
  final DateTime updatedAt;

  const DriverLocation({
    required this.driverId,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.heading,
    this.lessonId,
    required this.isOnline,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        driverId,
        latitude,
        longitude,
        speed,
        heading,
        lessonId,
        isOnline,
        updatedAt,
      ];

  /// Create a copy with updated fields
  DriverLocation copyWith({
    String? driverId,
    double? latitude,
    double? longitude,
    double? speed,
    double? heading,
    String? lessonId,
    bool? isOnline,
    DateTime? updatedAt,
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
    );
  }
}
