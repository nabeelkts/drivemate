import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads a file to Firebase Storage and returns the download URL.
  Future<String> uploadFile({
    required XFile file,
    required String path,
    String? fileName,
  }) async {
    try {
      final String effectiveFileName =
          fileName ?? '${DateTime.now().millisecondsSinceEpoch}.jpg';

      final Reference ref = _storage.ref().child('$path/$effectiveFileName');

      // Use putData for cross-platform support (web/mobile)
      final bytes = await file.readAsBytes();

      // Upload task using putData which works on web
      final UploadTask uploadTask = ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Wait for completion and get URL with timeout
      final TaskSnapshot snapshot =
          await uploadTask.timeout(const Duration(seconds: 30));
      return await snapshot.ref
          .getDownloadURL()
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      throw Exception('Failed to upload image to Firebase Storage: $e');
    }
  }

  /// Specialized upload for student images
  Future<String> uploadStudentImage(XFile file) async {
    return uploadFile(
      file: file,
      path: 'student_images',
    );
  }

  /// Specialized upload for profile pictures
  Future<String> uploadProfilePicture(String userId, XFile file) async {
    return uploadFile(
      file: file,
      path: 'profile_pictures',
      fileName: '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
  }

  /// Specialized upload for company logos
  Future<String> uploadCompanyLogo(String userId, XFile file) async {
    return uploadFile(
      file: file,
      path: 'company_logos',
      fileName: '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
  }
}
