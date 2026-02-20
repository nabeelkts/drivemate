import 'package:firebase_database/firebase_database.dart';
import 'package:mds/features/tracking/domain/entities/driver_location.dart';

/// Data model for serializing/deserializing driver location to/from Firebase
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
    super.driverName,
    super.schoolId,
    super.branchId,
    super.totalDistance,
    super.lessonDistance,
  });

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
      driverName: entity.driverName,
      schoolId: entity.schoolId,
      branchId: entity.branchId,
      totalDistance: entity.totalDistance,
      lessonDistance: entity.lessonDistance,
    );
  }

  factory DriverLocationModel.fromSnapshot(
    String driverId,
    DataSnapshot snapshot,
  ) {
    final value = snapshot.value;
    if (value == null) throw Exception('Snapshot data is null');

    final Map<dynamic, dynamic> data =
        Map<dynamic, dynamic>.from(value as Map);

    return DriverLocationModel(
      driverId: driverId,
      latitude: (data['lat'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['lng'] as num?)?.toDouble() ?? 0.0,
      speed: (data['speed'] as num?)?.toDouble() ?? 0.0,
      heading: (data['heading'] as num?)?.toDouble() ?? 0.0,
      lessonId: data['lessonId'] as String?,
      isOnline: data['isOnline'] as bool? ?? false,
      updatedAt: data['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (data['updatedAt'] as num).toInt())
          : DateTime.now(),
      driverName: data['driverName'] as String?,
      schoolId: data['schoolId'] as String?,
      branchId: data['branchId'] as String?,
      totalDistance: (data['totalDistance'] as num?)?.toDouble() ?? 0.0,
      // ✅ lessonDistance stored separately so it's readable on lesson end
      lessonDistance: (data['lessonDistance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': latitude,
      'lng': longitude,
      'speed': speed,
      'heading': heading,
      if (lessonId != null) 'lessonId': lessonId,
      'isOnline': isOnline,
      'updatedAt': ServerValue.timestamp,
      if (driverName != null) 'driverName': driverName,
      if (schoolId != null) 'schoolId': schoolId,
      if (branchId != null) 'branchId': branchId,
      'totalDistance': totalDistance,
      'lessonDistance': lessonDistance, // ✅ always write lesson distance
    };
  }

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
      driverName: driverName,
      schoolId: schoolId,
      branchId: branchId,
      totalDistance: totalDistance,
      lessonDistance: lessonDistance,
    );
  }
}
