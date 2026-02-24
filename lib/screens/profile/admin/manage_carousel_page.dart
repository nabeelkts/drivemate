import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:get/get.dart';
import 'package:mds/controller/theme_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ManageCarouselPage extends StatefulWidget {
  const ManageCarouselPage({super.key});

  @override
  State<ManageCarouselPage> createState() => _ManageCarouselPageState();
}

class _ManageCarouselPageState extends State<ManageCarouselPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  final ThemeController themeController = Get.find<ThemeController>();
  bool _isUploading = false;

  Future<void> _uploadCarouselImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
      );

      if (image == null) return;

      setState(() => _isUploading = true);

      // Generate unique ID
      final String id = DateTime.now().millisecondsSinceEpoch.toString();

      // Upload to Firebase Storage
      final ref = _storage.ref().child('banners/$id.jpg');
      await ref.putFile(File(image.path));
      final String downloadUrl = await ref.getDownloadURL();

      // Save to Firestore
      await _firestore.collection('banners').doc(id).set({
        'title': id,
        'image': downloadUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Carousel image uploaded successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteCarouselImage(String id, String imageUrl) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Image'),
        content:
            const Text('Are you sure you want to delete this carousel image?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Delete from Storage
      try {
        final ref = _storage.refFromURL(imageUrl);
        await ref.delete();
      } catch (e) {
        // Image might not exist in storage, continue
      }

      // Delete from Firestore
      await _firestore.collection('banners').doc(id).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Carousel image deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey.shade200,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,
        title: Text(
          'Manage Carousel',
          style: TextStyle(
            color: textColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('banners').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final banners = snapshot.data?.docs ?? [];

          return Column(
            children: [
              // Upload Button
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isUploading ? null : _uploadCarouselImage,
                    icon: _isUploading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.add_photo_alternate),
                    label:
                        Text(_isUploading ? 'Uploading...' : 'Add New Image'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeController.themeColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),

              // Images Grid
              Expanded(
                child: banners.isEmpty
                    ? Center(
                        child: Text(
                          'No carousel images yet',
                          style: TextStyle(
                            color: textColor.withOpacity(0.5),
                            fontSize: 16,
                          ),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.5,
                        ),
                        itemCount: banners.length,
                        itemBuilder: (context, index) {
                          final doc = banners[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final imageUrl = data['image'] as String;
                          final id = doc.id;

                          return Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.1)
                                        : Colors.black.withOpacity(0.1),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    placeholder: (context, url) => Container(
                                      color: Colors.grey.shade300,
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                      color: Colors.grey.shade300,
                                      child: const Icon(Icons.error),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.white),
                                  style: IconButton.styleFrom(
                                    backgroundColor:
                                        Colors.red.withOpacity(0.8),
                                  ),
                                  onPressed: () =>
                                      _deleteCarouselImage(id, imageUrl),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
