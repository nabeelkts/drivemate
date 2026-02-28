import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing an urgent task (expiring item)
class UrgentTaskModel {
  final String id;
  final String name;
  final String? photoUrl;
  final String expiryType;
  final String expiryDate;
  final DateTime expiryDateTime;
  final String collection;
  final String documentId;
  final int daysRemaining;

  UrgentTaskModel({
    required this.id,
    required this.name,
    this.photoUrl,
    required this.expiryType,
    required this.expiryDate,
    required this.expiryDateTime,
    required this.collection,
    required this.documentId,
    required this.daysRemaining,
  });

  factory UrgentTaskModel.fromMap(Map<String, dynamic> map) {
    return UrgentTaskModel(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Unknown',
      photoUrl: map['photoUrl'],
      expiryType: map['expiryType'] ?? 'Expiry',
      expiryDate: map['expiryDate'] ?? '',
      expiryDateTime: map['expiryDateTime']?.toDate() ?? DateTime.now(),
      collection: map['collection'] ?? '',
      documentId: map['documentId'] ?? '',
      daysRemaining: map['daysRemaining'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'photoUrl': photoUrl,
      'expiryType': expiryType,
      'expiryDate': expiryDate,
      'expiryDateTime': Timestamp.fromDate(expiryDateTime),
      'collection': collection,
      'documentId': documentId,
      'daysRemaining': daysRemaining,
    };
  }

  /// Get color based on urgency
  String get urgencyLevel {
    if (daysRemaining < 0) return 'expired';
    if (daysRemaining <= 7) return 'critical';
    if (daysRemaining <= 15) return 'warning';
    return 'normal';
  }
}

/// Types of expiry that can be tracked
class ExpiryTypes {
  static const String learnersLicense = 'Learners License';
  static const String drivingLicense = 'Driving License';
  static const String license = 'License';
  static const String registrationFitness = 'Registration/Fitness';
  static const String insurance = 'Insurance';
  static const String tax = 'Tax';
  static const String pollution = 'Pollution';
  static const String permit = 'Permit';
}

/// Collections that can have urgent tasks
class UrgentTaskCollections {
  static const String students = 'students';
  static const String licenseOnly = 'licenseonly';
  static const String endorsement = 'endorsement';
  static const String dlServices = 'dl_services';
  static const String rcServices = 'vehicleDetails';
}
