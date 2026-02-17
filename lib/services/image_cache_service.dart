import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// A singleton service to manage image caching as Uint8List.
/// This helps in making PDF generation instant and reducing network usage.
class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  final Map<String, Uint8List> _memoryCache = {};

  /// Fetches an image from network and caches it.
  /// If already in cache, returns the cached bytes immediately.
  Future<Uint8List?> fetchAndCache(String? url) async {
    if (url == null || url.isEmpty) return null;

    // Return from memory cache if available
    if (_memoryCache.containsKey(url)) {
      debugPrint('ImageCacheService: Cache hit for $url');
      return _memoryCache[url];
    }

    try {
      debugPrint('ImageCacheService: Cache miss. Fetching $url');
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        _memoryCache[url] = bytes;
        debugPrint(
            'ImageCacheService: Successfully cached ${bytes.length} bytes for $url');
        return bytes;
      } else {
        debugPrint(
            'ImageCacheService: Failed to fetch image (Status: ${response.statusCode})');
        return null;
      }
    } catch (e) {
      debugPrint('ImageCacheService: Error fetching image: $e');
      return null;
    }
  }

  /// Manually add bytes to cache
  void addToCache(String url, Uint8List bytes) {
    _memoryCache[url] = bytes;
  }

  /// Clears the memory cache
  void clearCache() {
    _memoryCache.clear();
  }

  /// Helper to get cached bytes if they exist
  Uint8List? getFromCache(String url) {
    return _memoryCache[url];
  }
}
