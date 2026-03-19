import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:drivemate/services/image_cache_service.dart';
import 'package:shimmer/shimmer.dart';

/// A widget that uses [ImageCacheService] to provide persistent caching
/// via Hive. This prevents repeated image decoding and network fetches
/// across app restarts.
class PersistentCachedImage extends StatefulWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final BorderRadius? borderRadius;

  const PersistentCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.memCacheWidth,
    this.memCacheHeight,
    this.borderRadius,
  });

  @override
  State<PersistentCachedImage> createState() => _PersistentCachedImageState();
}

class _PersistentCachedImageState extends State<PersistentCachedImage> {
  Future<Uint8List?>? _fetchFuture;

  @override
  void initState() {
    super.initState();
    _initFuture();
  }

  @override
  void didUpdateWidget(PersistentCachedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _initFuture();
    }
  }

  void _initFuture() {
    final String? url = widget.imageUrl?.toString().trim();
    if (url != null &&
        url.isNotEmpty &&
        url != 'null' &&
        url != 'Null' &&
        url.startsWith('http')) {
      _fetchFuture = ImageCacheService().fetchAndCache(url);
    } else {
      _fetchFuture = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? url = widget.imageUrl?.toString().trim();
    if (url == null ||
        url.isEmpty ||
        url == 'null' ||
        url == 'Null' ||
        url == 'undefined') {
      return widget.errorWidget ?? _buildDefaultError();
    }

    // Check for local file path first
    if (!url.startsWith('http')) {
      return ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.zero,
        child: Image.file(
          File(url),
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          cacheWidth: widget.memCacheWidth,
          cacheHeight: widget.memCacheHeight,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('PersistentCachedImage: File error for $url: $error');
            return widget.errorWidget ?? _buildDefaultError();
          },
        ),
      );
    }

    // If it's a URL, we must have a future. If not, create it.
    if (_fetchFuture == null) {
      _initFuture();
    }

    // Attempt to return from memory/disk synchronously to avoid flicker
    final cachedBytes = ImageCacheService().getFromCache(url);
    if (cachedBytes != null) {
      return _buildImage(cachedBytes);
    }

    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.zero,
      child: FutureBuilder<Uint8List?>(
        future: _fetchFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return widget.placeholder ?? _buildDefaultPlaceholder(context);
          }

          if (snapshot.hasError) {
            debugPrint(
                'PersistentCachedImage: Future error for $url: ${snapshot.error}');
            return widget.errorWidget ?? _buildDefaultError();
          }

          if (!snapshot.hasData || snapshot.data == null) {
            // If the future completed but returned null, try one last synchronous check
            // (in case it was cached by another instance in the meantime)
            final lastCheck = ImageCacheService().getFromCache(url);
            if (lastCheck != null) {
              return _buildImage(lastCheck);
            }
            return widget.errorWidget ?? _buildDefaultError();
          }

          return _buildImage(snapshot.data!);
        },
      ),
    );
  }

  Widget _buildImage(Uint8List bytes) {
    return Image.memory(
      bytes,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      cacheWidth: widget.memCacheWidth,
      cacheHeight: widget.memCacheHeight,
      gaplessPlayback: true,
    );
  }

  Widget _buildDefaultPlaceholder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Container(
        width: widget.width,
        height: widget.height,
        color: Colors.white,
      ),
    );
  }

  Widget _buildDefaultError() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[200],
      child: const Icon(Icons.error_outline, color: Colors.grey),
    );
  }
}
