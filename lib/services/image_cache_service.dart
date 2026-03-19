import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';

/// A singleton service to manage image caching as Uint8List.
/// This helps in making PDF generation instant, reducing network usage,
/// and ensuring images persist across app restarts using Hive.
class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  final Map<String, Uint8List> _memoryCache = {};
  Box<Uint8List>? _persistentCache;
  static const String _boxName = 'persistent_image_cache';

  /// Helper to generate a safe Hive key from a URL (hashes long URLs)
  String _generateKey(String url) {
    // Hive keys have a 255 character limit. URLs can be longer.
    // We use SHA-256 to create a fixed-length unique key for each URL.
    final bytes = utf8.encode(url);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Initializes the Hive box for persistent caching.
  /// Should be called during app initialization.
  Future<void> init() async {
    if (_persistentCache == null) {
      _persistentCache = await Hive.openBox<Uint8List>(_boxName);
      debugPrint('ImageCacheService: Persistent cache initialized.');
    }
  }

  /// Fetches an image from network and caches it.
  /// If already in cache (memory or disk), returns the cached bytes immediately.
  Future<Uint8List?> fetchAndCache(String? url) async {
    if (url == null) return null;
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty ||
        cleanUrl == 'null' ||
        cleanUrl == 'Null' ||
        cleanUrl == 'undefined') return null;

    // Handle local file paths
    if (!cleanUrl.startsWith('http')) {
      debugPrint(
          'ImageCacheService: Local path detected, not caching: $cleanUrl');
      return null;
    }

    // 1. Check Memory Cache
    if (_memoryCache.containsKey(cleanUrl)) {
      debugPrint('ImageCacheService: Memory hit for $cleanUrl');
      return _memoryCache[cleanUrl];
    }

    final key = _generateKey(cleanUrl);

    // 2. Check Persistent Cache (Hive)
    if (_persistentCache != null && _persistentCache!.containsKey(key)) {
      final bytes = _persistentCache!.get(key);
      if (bytes != null) {
        debugPrint('ImageCacheService: Persistent hit for $cleanUrl');
        _memoryCache[cleanUrl] =
            bytes; // Add to memory for faster subsequent access
        return bytes;
      }
    }

    // 3. Cache Miss - Fetch from Network
    try {
      debugPrint('ImageCacheService: Cache miss. Fetching $cleanUrl');
      final uri = Uri.tryParse(cleanUrl);
      if (uri == null) {
        debugPrint('ImageCacheService: Invalid URI: $cleanUrl');
        return null;
      }

      final response = await http.get(uri).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;

        if (bytes.isEmpty) {
          debugPrint('ImageCacheService: Received empty bytes for $cleanUrl');
          return null;
        }

        // Save to memory
        _memoryCache[cleanUrl] = bytes;

        // Save to disk (Hive)
        if (_persistentCache != null) {
          try {
            await _persistentCache!.put(key, bytes);
          } catch (e) {
            debugPrint('ImageCacheService: Hive put error: $e');
          }
        }

        debugPrint(
            'ImageCacheService: Successfully cached ${bytes.length} bytes for $cleanUrl');
        return bytes;
      } else {
        debugPrint(
            'ImageCacheService: Failed to fetch image (Status: ${response.statusCode}) for $cleanUrl');
        return null;
      }
    } catch (e) {
      debugPrint('ImageCacheService: Error fetching image $cleanUrl: $e');
      return null;
    }
  }

  /// Manually add bytes to cache
  Future<void> addToCache(String url, Uint8List bytes) async {
    final cleanUrl = url.trim();
    _memoryCache[cleanUrl] = bytes;
    if (_persistentCache != null) {
      final key = _generateKey(cleanUrl);
      await _persistentCache!.put(key, bytes);
    }
  }

  /// Clears both memory and persistent cache
  Future<void> clearCache() async {
    _memoryCache.clear();
    if (_persistentCache != null) {
      await _persistentCache!.clear();
    }
  }

  /// Helper to get cached bytes if they exist
  Uint8List? getFromCache(String url) {
    final cleanUrl = url.trim();
    // Check memory first
    if (_memoryCache.containsKey(cleanUrl)) return _memoryCache[cleanUrl];

    // Check disk
    if (_persistentCache != null) {
      final key = _generateKey(cleanUrl);

      // 1. Try with SHA-256 key (new logic)
      if (_persistentCache!.containsKey(key)) {
        return _persistentCache!.get(key);
      }

      // 2. Fallback: Try with raw URL as key (old logic)
      // This helps with transition after the key logic change.
      // Note: This only works for URLs < 255 characters.
      if (cleanUrl.length <= 255 && _persistentCache!.containsKey(cleanUrl)) {
        final bytes = _persistentCache!.get(cleanUrl);
        if (bytes != null) {
          // Migrating to new key logic for future hits
          _persistentCache!.put(key, bytes);
          _persistentCache!.delete(cleanUrl);
          return bytes;
        }
      }
    }

    return null;
  }
}
