import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class DocumentPreviewScreen extends StatefulWidget {
  final String docName;
  final String docUrl;

  const DocumentPreviewScreen({
    super.key,
    required this.docName,
    required this.docUrl,
  });

  @override
  State<DocumentPreviewScreen> createState() => _DocumentPreviewScreenState();
}

class _DocumentPreviewScreenState extends State<DocumentPreviewScreen> {
  bool _isProcessing = false;

  Future<File?> _downloadToTemp() async {
    try {
      setState(() {
        _isProcessing = true;
      });

      final uri = Uri.parse(widget.docUrl);
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to download document')),
          );
        }
        return null;
      }

      final dir = await getTemporaryDirectory();
      final fileName = widget.docName.isNotEmpty
          ? widget.docName.replaceAll(' ', '_')
          : 'document';
      final ext = uri.path.split('.').length > 1 ? '.${uri.path.split('.').last}' : '';
      final file = File('${dir.path}/$fileName$ext');
      await file.writeAsBytes(response.bodyBytes);
      return file;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error while processing document')),
        );
      }
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _handleDownload() async {
    final file = await _downloadToTemp();
    if (file == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Document saved to ${file.path}')),
    );
  }

  Future<void> _handleShare() async {
    final file = await _downloadToTemp();
    if (file == null || !mounted) return;
    await Share.shareXFiles(
      [XFile(file.path)],
      text: widget.docName.isNotEmpty ? widget.docName : 'Shared document',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.docName),
        actions: [
          IconButton(
            tooltip: 'Download',
            onPressed: _isProcessing ? null : _handleDownload,
            icon: const Icon(Icons.download),
          ),
          IconButton(
            tooltip: 'Share',
            onPressed: _isProcessing ? null : _handleShare,
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: widget.docUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.broken_image_outlined,
                  size: 64,
                ),
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: theme.colorScheme.surface.withOpacity(0.4),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}

