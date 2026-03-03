import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Migration script to add isDeleted field to all existing documents
/// Run this ONCE to prepare your database for soft delete functionality
class SoftDeleteMigration {
  static Future<void> migrateAllDocuments() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('Error: No user logged in');
        return;
      }

      final userId = user.uid;
      final collections = [
        'students',
        'licenseonly',
        'endorsement',
        'vehicleDetails',
        'dl_services',
      ];

      print('Starting migration for user: $userId');

      for (String collection in collections) {
        await _migrateCollection(userId, collection);
      }

      print('✅ Migration completed successfully!');
    } catch (e) {
      print('❌ Migration error: $e');
    }
  }

  static Future<void> _migrateCollection(
    String userId,
    String collection,
  ) async {
    try {
      print('\nMigrating $collection...');

      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection(collection)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('  No documents found in $collection');
        return;
      }

      print('  Found ${querySnapshot.docs.length} documents');

      // Process in batches of 500 (Firestore batch limit)
      const batchSize = 500;
      var batch = FirebaseFirestore.instance.batch();
      var count = 0;
      var updatedCount = 0;

      for (var doc in querySnapshot.docs) {
        final data = doc.data();

        // Only update if isDeleted field doesn't exist
        if (!data.containsKey('isDeleted')) {
          batch.update(doc.reference, {
            'isDeleted': false,
          });
          updatedCount++;
        }

        count++;

        // Commit batch when it reaches the limit
        if (count % batchSize == 0) {
          await batch.commit();
          print('  Committed batch of $batchSize documents');
          batch = FirebaseFirestore.instance.batch();
        }
      }

      // Commit remaining documents
      if (count % batchSize != 0) {
        await batch.commit();
      }

      print('  ✅ Updated $updatedCount documents in $collection');
    } catch (e) {
      print('  ❌ Error migrating $collection: $e');
    }
  }

  /// Optional: Clean up test data after testing
  static Future<void> rollback() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userId = user.uid;
      final collections = [
        'students',
        'licenseonly',
        'endorsement',
        'vehicleDetails',
        'dl_services',
      ];

      for (String collection in collections) {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection(collection)
            .where('isDeleted', isEqualTo: false)
            .get();

        final batch = FirebaseFirestore.instance.batch();
        for (var doc in querySnapshot.docs) {
          batch.update(doc.reference, {
            'isDeleted': FieldValue.delete(),
          });
        }
        await batch.commit();
      }

      print('Rollback completed');
    } catch (e) {
      print('Rollback error: $e');
    }
  }
}
