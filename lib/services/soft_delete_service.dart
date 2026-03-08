import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

/// SoftDeleteService handles soft deletion of documents with automatic cleanup after 3 months
class SoftDeleteService {
  static const int retentionDays = 90; // 3 months

  /// Soft delete a document - moves it to recycle bin state
  static Future<void> softDelete({
    required DocumentReference docRef,
    required String userId,
    String? branchId,
    String? documentName, // Optional: Name of the document for activity logging
  }) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      // Update the document with soft delete metadata
      batch.update(docRef, {
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': userId,
        'expiryDate': Timestamp.fromDate(
          DateTime.now().add(Duration(days: retentionDays)),
        ),
        'originalCollection': docRef.parent.path.split('/').last,
        if (branchId != null) 'deletedFromBranch': branchId,
      });

      await batch.commit();

      // Log the deletion activity with document name
      await _logDeletionActivity(
        userId: userId,
        docRef: docRef,
        branchId: branchId,
        documentName: documentName,
      );
    } catch (e) {
      throw Exception('Failed to soft delete document: $e');
    }
  }

  /// Restore a soft-deleted document
  static Future<void> restoreDocument({
    required DocumentReference docRef,
    required String userId,
  }) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      // Remove soft delete metadata
      batch.update(docRef, {
        'isDeleted': false,
        'deletedAt': FieldValue.delete(),
        'deletedBy': FieldValue.delete(),
        'expiryDate': FieldValue.delete(),
        'restoredAt': FieldValue.serverTimestamp(),
        'restoredBy': userId,
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to restore document: $e');
    }
  }

  /// Permanently delete a document (from recycle bin)
  static Future<void> permanentDelete({
    required DocumentReference docRef,
    required String userId,
    String? documentName, // Optional: Name for activity logging
  }) async {
    try {
      await docRef.delete();

      // Log permanent deletion with document name
      await _logPermanentDeletion(
        userId: userId,
        docRef: docRef,
        documentName: documentName,
      );
    } catch (e) {
      throw Exception('Failed to permanently delete document: $e');
    }
  }

  /// Get all soft-deleted documents for a user
  static Stream<List<DeletedItem>> getDeletedItems({
    required String userId,
    String? branchId,
    bool isOrganization = false,
  }) {
    // List of all collections to query
    final collections = [
      'students',
      'licenseonly',
      'endorsement',
      'vehicleDetails',
      'dl_services',
    ];

    final streamController = StreamController<List<DeletedItem>>();
    final Map<String, List<DeletedItem>> collectionData = {};

    // Emit initial empty list immediately
    streamController.add([]);

    for (String collectionName in collections) {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collectionGroup(collectionName)
          .where('isDeleted', isEqualTo: true)
          .where('deletedBy', isEqualTo: userId);

      // For organization mode, filter by branch
      if (isOrganization && branchId != null) {
        query = query.where('deletedFromBranch', isEqualTo: branchId);
      }

      // Listen to each collection
      query.snapshots().listen(
        (snapshot) {
          try {
            collectionData[collectionName] = snapshot.docs.map((doc) {
              final data = doc.data();
              return DeletedItem(
                id: doc.id,
                reference: doc.reference,
                name: _extractDocumentName(data, collectionName),
                collectionType: data['originalCollection'] ?? collectionName,
                deletedAt: (data['deletedAt'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
                expiryDate: (data['expiryDate'] as Timestamp?)?.toDate(),
                imageUrl: _extractImageUrl(data, collectionName),
                canRestore: true,
                daysRemaining: _calculateDaysRemaining(data['expiryDate']),
              );
            }).toList();

            // Emit combined results
            final allItems =
                collectionData.values.expand((items) => items).toList();
            if (!streamController.isClosed) {
              streamController.add(allItems);
            }
          } catch (e) {
            print('Error processing $collectionName: $e');
            if (!streamController.isClosed) {
              // Still emit current data even if one collection fails
              final allItems =
                  collectionData.values.expand((items) => items).toList();
              streamController.add(allItems);
            }
          }
        },
        onError: (error) {
          print('Error listening to $collectionName: $error');
          // Don't send error to stream, just continue with other collections
          // Emit current data
          if (!streamController.isClosed) {
            final allItems =
                collectionData.values.expand((items) => items).toList();
            streamController.add(allItems);
          }
        },
      );
    }

    return streamController.stream;
  }

  /// Extract document name based on collection type
  static String _extractDocumentName(
      Map<String, dynamic> data, String collection) {
    switch (collection) {
      case 'vehicleDetails':
        return data['vehicleNumber'] ?? 'Unknown';
      default:
        return data['fullName'] ?? 'Unknown';
    }
  }

  /// Extract image URL based on collection type
  static String? _extractImageUrl(
      Map<String, dynamic> data, String collection) {
    // Try common image field names
    return data['image'] ??
        data['imageUrl'] ??
        data['photoUrl'] ??
        data['profileImage'];
  }

  /// Cleanup expired documents automatically
  /// This should be called periodically (e.g., on app startup or via Cloud Functions)
  static Future<int> cleanupExpiredDocuments({
    String? userId,
  }) async {
    try {
      final now = Timestamp.now();
      int deletedCount = 0;

      // List of collections to check
      final collections = [
        'students',
        'licenseonly',
        'endorsement',
        'vehicleDetails',
        'dl_services',
      ];

      for (String collection in collections) {
        final query = FirebaseFirestore.instance
            .collectionGroup(collection)
            .where('isDeleted', isEqualTo: true)
            .where('expiryDate', isLessThan: now)
            .limit(100); // Process in batches

        final snapshot = await query.get();

        for (var doc in snapshot.docs) {
          try {
            await doc.reference.delete();
            deletedCount++;
          } catch (e) {
            print('Error deleting expired document ${doc.id}: $e');
          }
        }
      }

      if (deletedCount > 0) {
        print('Cleaned up $deletedCount expired documents');
      }

      return deletedCount;
    } catch (e) {
      print('Error during cleanup: $e');
      return 0;
    }
  }

  /// Calculate days remaining until permanent deletion
  static int _calculateDaysRemaining(Timestamp? expiryDate) {
    if (expiryDate == null) return 0;

    final now = DateTime.now();
    final expiry = expiryDate.toDate();
    final difference = expiry.difference(now);

    return difference.inDays.clamp(0, retentionDays);
  }

  /// Log deletion activity for audit trail
  static Future<void> _logDeletionActivity({
    required String userId,
    required DocumentReference docRef,
    String? branchId,
    String? documentName,
  }) async {
    try {
      final activityRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('recentActivity')
          .doc();

      await activityRef.set({
        'title': 'Document Moved to Recycle Bin',
        'details': documentName != null
            ? '"$documentName" moved to recycle bin'
            : 'Document ID: ${docRef.id}',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'soft_delete',
        'documentPath': docRef.path,
        'branchId': branchId,
        if (documentName != null) 'documentName': documentName,
      });
    } catch (e) {
      print('Error logging deletion activity: $e');
    }
  }

  /// Log permanent deletion
  static Future<void> _logPermanentDeletion({
    required String userId,
    required DocumentReference docRef,
    String? documentName,
  }) async {
    try {
      final activityRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('recentActivity')
          .doc();

      await activityRef.set({
        'title': 'Document Permanently Deleted',
        'details': documentName != null
            ? '"$documentName" permanently deleted'
            : 'Document ID: ${docRef.id} removed from recycle bin',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'permanent_delete',
        'documentPath': docRef.path,
      });
    } catch (e) {
      print('Error logging permanent deletion: $e');
    }
  }
}

/// Model representing a deleted item in recycle bin
class DeletedItem {
  final String id;
  final DocumentReference reference;
  final String name;
  final String collectionType;
  final DateTime deletedAt;
  final DateTime? expiryDate;
  final String? imageUrl;
  final bool canRestore;
  final int daysRemaining;

  DeletedItem({
    required this.id,
    required this.reference,
    required this.name,
    required this.collectionType,
    required this.deletedAt,
    this.expiryDate,
    this.imageUrl,
    required this.canRestore,
    required this.daysRemaining,
  });
}
