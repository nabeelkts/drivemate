import 'package:cloud_firestore/cloud_firestore.dart';

/// Utility functions for soft delete filtering
class SoftDeleteUtils {
  /// Filter out soft-deleted documents from a query snapshot
  static List<QueryDocumentSnapshot<Map<String, dynamic>>>
      filterDeletedDocuments(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return docs.where((doc) {
      final data = doc.data();
      // Exclude documents where isDeleted is true
      return data['isDeleted'] != true;
    }).toList();
  }

  /// Check if a document is soft-deleted
  static bool isDeleted(Map<String, dynamic> data) {
    return data['isDeleted'] == true;
  }
}
