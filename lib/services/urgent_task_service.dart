import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mds/models/urgent_task_model.dart';
import 'package:intl/intl.dart';

/// Service for fetching and managing urgent tasks (expiring items)
class UrgentTaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get the base path for collections
  String _getBasePath(String userId, String schoolId) {
    if (schoolId.isNotEmpty) {
      return 'users/$schoolId';
    }
    final uid = FirebaseAuth.instance.currentUser?.uid ?? userId;
    return 'users/$uid';
  }

  /// Parse date string in DD-MM-YYYY format to DateTime
  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      final parts = dateStr.split('-');
      if (parts.length != 3) return null;
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      return DateTime(year, month, day);
    } catch (e) {
      return null;
    }
  }

  /// Calculate days remaining until expiry
  int _calculateDaysRemaining(DateTime expiryDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return expiry.difference(today).inDays;
  }

  /// Check if date is within 30 days or already expired
  bool _isUrgent(DateTime? expiryDate) {
    if (expiryDate == null) return false;
    final daysRemaining = _calculateDaysRemaining(expiryDate);
    return daysRemaining <= 30;
  }

  /// Fetch urgent tasks from a single collection
  Future<List<UrgentTaskModel>> _fetchFromCollection({
    required String collection,
    required String userId,
    required String schoolId,
    required String branchId,
  }) async {
    final tasks = <UrgentTaskModel>[];

    try {
      final basePath = _getBasePath(userId, schoolId);

      // Fetch from both active and deactivated collections
      final collectionsToCheck = [collection, 'deactivated_$collection'];

      for (final col in collectionsToCheck) {
        Query query = _firestore.collection('$basePath/$col');

        // Apply workspace filters
        if (schoolId.isEmpty && branchId.isNotEmpty) {
          query = query.where('branchId', isEqualTo: branchId);
        }

        final snapshot = await query.get();

        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final additionalInfo =
              data['additionalInfo'] as Map<String, dynamic>?;
          print(
              'URGENT TASK DEBUG: Doc ${doc.id}, collection: $col, additionalInfo: $additionalInfo');
          if (additionalInfo == null) continue;

          // Check if student has passed (course completed) or is deactivated
          final status = data['status'] as String?;
          final deactivated = data['deactivated'] as bool?;
          final isPassed = status == 'passed' || deactivated == true;

          final docId = doc.id;
          final name = data['fullName'] ?? data['name'] ?? 'Unknown';
          final photoUrl =
              data['image'] as String? ?? data['photoUrl'] as String?;

          // Check collection type and extract relevant expiry fields
          if (collection == 'students' ||
              collection == 'licenseonly' ||
              collection == 'endorsement') {
            // For active students (in non-deactivated collections): show ALL expiries
            if (!col.startsWith('deactivated_')) {
              // Show learners license expiry for active students
              final learnersExpiry =
                  _parseDate(additionalInfo['learnersLicenseExpiry']);
              if (_isUrgent(learnersExpiry)) {
                tasks.add(UrgentTaskModel(
                  id: '${docId}_learners',
                  name: name,
                  photoUrl: photoUrl,
                  expiryType: ExpiryTypes.learnersLicense,
                  expiryDate: additionalInfo['learnersLicenseExpiry'] ?? '',
                  expiryDateTime: learnersExpiry!,
                  collection:
                      col, // Use the actual collection where the doc was found
                  documentId: docId,
                  daysRemaining: _calculateDaysRemaining(learnersExpiry),
                ));
              }

              // Show driving license expiry for active students
              final drivingExpiry =
                  _parseDate(additionalInfo['drivingLicenseExpiry']);
              if (_isUrgent(drivingExpiry)) {
                tasks.add(UrgentTaskModel(
                  id: '${docId}_driving',
                  name: name,
                  photoUrl: photoUrl,
                  expiryType: ExpiryTypes.drivingLicense,
                  expiryDate: additionalInfo['drivingLicenseExpiry'] ?? '',
                  expiryDateTime: drivingExpiry!,
                  collection:
                      col, // Use the actual collection where the doc was found
                  documentId: docId,
                  daysRemaining: _calculateDaysRemaining(drivingExpiry),
                ));
              }
            }
            // For deactivated students (in deactivated collections): show only driving license expiry
            else {
              // DO NOT show learners license expiry for deactivated students

              // Show driving license expiry for deactivated students
              final drivingExpiry =
                  _parseDate(additionalInfo['drivingLicenseExpiry']);
              if (_isUrgent(drivingExpiry)) {
                tasks.add(UrgentTaskModel(
                  id: '${docId}_driving',
                  name: name,
                  photoUrl: photoUrl,
                  expiryType: ExpiryTypes.drivingLicense,
                  expiryDate: additionalInfo['drivingLicenseExpiry'] ?? '',
                  expiryDateTime: drivingExpiry!,
                  collection:
                      col, // Use the actual collection where the doc was found
                  documentId: docId,
                  daysRemaining: _calculateDaysRemaining(drivingExpiry),
                ));
              }
            }
          } else if (collection == 'dl_services') {
            // Check license expiry
            final licenseExpiry = _parseDate(additionalInfo['licenseExpiry']);
            if (_isUrgent(licenseExpiry)) {
              tasks.add(UrgentTaskModel(
                id: '${docId}_license',
                name: name,
                photoUrl: photoUrl,
                expiryType: ExpiryTypes.license,
                expiryDate: additionalInfo['licenseExpiry'] ?? '',
                expiryDateTime: licenseExpiry!,
                collection:
                    col, // Use the actual collection where the doc was found
                documentId: docId,
                daysRemaining: _calculateDaysRemaining(licenseExpiry),
              ));
            }
          } else if (collection == 'vehicleDetails') {
            // Check all RC service expiries
            final expiries = [
              {
                'field': 'registrationRenewalOrFitnessExpiry',
                'type': ExpiryTypes.registrationFitness
              },
              {'field': 'insuranceExpiry', 'type': ExpiryTypes.insurance},
              {'field': 'taxExpiry', 'type': ExpiryTypes.tax},
              {'field': 'pollutionExpiry', 'type': ExpiryTypes.pollution},
              {'field': 'permitExpiry', 'type': ExpiryTypes.permit},
            ];

            for (var expiry in expiries) {
              final date = _parseDate(additionalInfo[expiry['field']]);
              if (_isUrgent(date)) {
                tasks.add(UrgentTaskModel(
                  id: '${docId}_${expiry['field']}',
                  name: name,
                  photoUrl: photoUrl,
                  expiryType: expiry['type']!,
                  expiryDate: additionalInfo[expiry['field']] ?? '',
                  expiryDateTime: date!,
                  collection:
                      col, // Use the actual collection where the doc was found
                  documentId: docId,
                  daysRemaining: _calculateDaysRemaining(date),
                ));
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error fetching from $collection: $e');
    }

    return tasks;
  }

  /// Fetch all urgent tasks across all collections
  Future<List<UrgentTaskModel>> fetchAllUrgentTasks({
    required String userId,
    required String schoolId,
    required String branchId,
  }) async {
    final allTasks = <UrgentTaskModel>[];

    final collections = [
      'students',
      'licenseonly',
      'endorsement',
      'dl_services',
      'vehicleDetails',
    ];

    for (var collection in collections) {
      final tasks = await _fetchFromCollection(
        collection: collection,
        userId: userId,
        schoolId: schoolId,
        branchId: branchId,
      );
      allTasks.addAll(tasks);
    }

    // Sort by days remaining (earliest first)
    allTasks.sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));

    return allTasks;
  }

  /// Get urgent task count
  Future<int> getUrgentTaskCount({
    required String userId,
    required String schoolId,
    required String branchId,
  }) async {
    final tasks = await fetchAllUrgentTasks(
      userId: userId,
      schoolId: schoolId,
      branchId: branchId,
    );
    return tasks.length;
  }
}
