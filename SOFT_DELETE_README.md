# Soft Delete / Recycle Bin Feature

## Overview
The soft delete feature allows users to "delete" records without permanently removing them from the database. Deleted items are moved to a Recycle Bin where they can be restored or permanently deleted within 90 days.

## Features
✅ **Soft Delete**: Move records to recycle bin instead of permanent deletion  
✅ **Restore**: Bring back deleted records anytime within 90 days  
✅ **Permanent Delete**: Manually delete records from recycle bin before 90 days  
✅ **Auto-Cleanup**: Records older than 90 days are automatically deleted  
✅ **Audit Trail**: All deletions are logged for tracking  

## File Structure
```
lib/
├── services/
│   └── soft_delete_service.dart      # Core service for soft delete operations
├── screens/
│   └── recycle_bin/
│       └── recycle_bin_screen.dart   # Recycle bin UI
├── widgets/
│   └── soft_delete_button.dart       # Reusable delete button widget
└── models/
    └── deleted_item.dart             # Model for deleted items (optional)
```

## Database Schema Changes

When a document is soft deleted, the following fields are added:
```javascript
{
  isDeleted: true,                    // Marks document as deleted
  deletedAt: Timestamp,               // When it was deleted
  deletedBy: string,                  // User ID who deleted it
  expiryDate: Timestamp,              // Auto-delete date (deletedAt + 90 days)
  originalCollection: string,         // Original collection name
  deletedFromBranch: string?,         // Branch ID (if using organization mode)
}
```

## Usage

### 1. Add Recycle Bin Screen to Routes

Add this to your routes configuration:
```dart
import 'package:mds/screens/recycle_bin/recycle_bin_screen.dart';

// In your routes
'/recycle-bin': (context) => const RecycleBinScreen(),
```

### 2. Add Recycle Bin Button to Settings/Menu

Add a navigation button to access the Recycle Bin:
```dart
ListTile(
  leading: const Icon(Icons.delete_outline),
  title: const Text('Recycle Bin'),
  onTap: () {
    Navigator.pushNamed(context, '/recycle-bin');
  },
)
```

### 3. Add Soft Delete Button to Detail Pages

Replace your existing delete buttons with `SoftDeleteButton`:

```dart
import 'package:mds/widgets/soft_delete_button.dart';

// In your detail page app bar
AppBar(
  actions: [
    SoftDeleteButton(
      docRef: FirebaseFirestore.instance.collection('students').doc(docId),
      documentName: studentData['fullName'],
      onDeleteSuccess: () {
        // Optional: Navigate back or refresh list
        Navigator.pop(context);
      },
    ),
  ],
)
```

### 4. Filter Out Deleted Items in Queries

Update your Firestore queries to exclude deleted items:

```dart
// Before
FirebaseFirestore.instance.collection('students')

// After
FirebaseFirestore.instance
  .collection('students')
  .where('isDeleted', isEqualTo: false)
```

### 5. Automatic Cleanup on App Startup

Add cleanup code to your main.dart or initialization:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase, etc.
  
  // Cleanup expired documents
  await SoftDeleteService.cleanupExpiredDocuments();
  
  runApp(MyApp());
}
```

## API Reference

### SoftDeleteService Methods

#### `softDelete()`
Move a document to recycle bin
```dart
await SoftDeleteService.softDelete(
  docRef: documentReference,
  userId: currentUserUid,
  branchId: currentBranchId, // Optional
);
```

#### `restoreDocument()`
Restore a deleted document
```dart
await SoftDeleteService.restoreDocument(
  docRef: documentReference,
  userId: currentUserUid,
);
```

#### `permanentDelete()`
Permanently delete from recycle bin
```dart
await SoftDeleteService.permanentDelete(
  docRef: documentReference,
  userId: currentUserUid,
);
```

#### `getDeletedItems()`
Stream of deleted items for recycle bin
```dart
SoftDeleteService.getDeletedItems(
  userId: currentUserUid,
  branchId: currentBranchId,
  isOrganization: isOrgMode,
);
```

#### `cleanupExpiredDocuments()`
Remove documents older than 90 days
```dart
final count = await SoftDeleteService.cleanupExpiredDocuments(
  userId: currentUserUid,
);
print('Cleaned up $count expired documents');
```

## Migration Guide

### Phase 1: Add Soft Delete Fields
Run this script to add `isDeleted` field to existing documents:

```dart
Future<void> migrateExistingDocuments() async {
  final collections = ['students', 'licenseonly', 'endorsement', 'vehicleDetails', 'dl_services'];
  
  for (String collection in collections) {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection(collection)
        .get();
    
    final batch = FirebaseFirestore.instance.batch();
    
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {
        'isDeleted': false,
      });
    }
    
    await batch.commit();
  }
}
```

### Phase 2: Update Existing Delete Operations
Replace all direct `.delete()` calls with `SoftDeleteService.softDelete()`.

### Phase 3: Test Thoroughly
- Test soft delete on all collection types
- Test restore functionality
- Test permanent delete
- Verify auto-cleanup works

## Best Practices

1. **Always filter deleted items**: Make sure all queries exclude `isDeleted: true` documents
2. **Show recycle bin indicator**: Add visual feedback when items are in recycle bin
3. **Confirm before delete**: Always show confirmation dialog before soft deleting
4. **Log activities**: Use the built-in activity logging for audit trails
5. **Regular cleanup**: Run cleanup periodically to remove expired documents
6. **Backup strategy**: Consider backing up data before permanent deletion

## Security Rules

Update your Firestore security rules to handle soft deletes:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Example for students collection
    match /users/{userId}/students/{studentId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
      // Prevent hard deletes - only allow updates (for soft delete)
      allow delete: if false;
    }
  }
}
```

## Troubleshooting

### Issue: Deleted items still appear in lists
**Solution**: Make sure your queries filter out `isDeleted: true`

### Issue: Can't restore items
**Solution**: Check that the user has write permissions on the collection

### Issue: Cleanup not working
**Solution**: Ensure you're calling `cleanupExpiredDocuments()` after Firebase initialization

### Issue: Activity logs not showing
**Solution**: Verify that the recentActivity subcollection exists and user has write access

## Future Enhancements

- [ ] Cloud Function for automatic cleanup (instead of client-side)
- [ ] Batch restore functionality
- [ ] Search/filter in recycle bin
- [ ] Export deleted items before permanent deletion
- [ ] Email notifications before auto-deletion
- [ ] Custom retention periods per collection type

## Support

For issues or questions about the soft delete feature, check the activity logs and ensure proper permissions are set in Firestore rules.

