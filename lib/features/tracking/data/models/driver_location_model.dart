import 'package:firebase_database/firebase_database.dart';
import 'package:mds/features/tracking/domain/entities/driver_location.dart';

/// Data model for serializing/deserializing driver location to/from Firebase
///
/// Handles conversion between domain entity and Firebase JSON format.
class DriverLocationModel extends DriverLocation {
  const DriverLocationModel({
    required super.driverId,
    required super.latitude,
    required super.longitude,
    required super.speed,
    required super.heading,
    super.lessonId,
    required super.isOnline,
    required super.updatedAt,
  });

  /// Create from domain entity
  factory DriverLocationModel.fromEntity(DriverLocation entity) {
    return DriverLocationModel(
      driverId: entity.driverId,
      latitude: entity.latitude,
      longitude: entity.longitude,
      speed: entity.speed,
      heading: entity.heading,
      lessonId: entity.lessonId,
      isOnline: entity.isOnline,
      updatedAt: entity.updatedAt,
    );
  }

  /// Create from Firebase DataSnapshot
  factory DriverLocationModel.fromSnapshot(
    String driverId,
    DataSnapshot snapshot,
  ) {
    final data = snapshot.value as Map<dynamic, dynamic>?;

    if (data == null) {
      throw Exception('Snapshot data is null');
    }

    return DriverLocationModel(
      driverId: driverId,
      latitude: (data['lat'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['lng'] as num?)?.toDouble() ?? 0.0,
      speed: (data['speed'] as num?)?.toDouble() ?? 0.0,
      heading: (data['heading'] as num?)?.toDouble() ?? 0.0,
      lessonId: data['lessonId'] as String?,
      isOnline: data['isOnline'] as bool? ?? false,
      updatedAt: data['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['updatedAt'] as int)
          : DateTime.now(),
    );
  }

  /// Convert to JSON map for Firebase
  Map<String, dynamic> toJson() {
    return {
      'lat': latitude,
      'lng': longitude,
      'speed': speed,
      'heading': heading,
      if (lessonId != null) 'lessonId': lessonId,
      'isOnline': isOnline,
      'updatedAt': ServerValue.timestamp,
    };
  }

  /// Convert to domain entity
  DriverLocation toEntity() {
    return DriverLocation(
      driverId: driverId,
      latitude: latitude,
      longitude: longitude,
      speed: speed,
      heading: heading,
      lessonId: lessonId,
      isOnline: isOnline,
      updatedAt: updatedAt,
    );
  }
}
