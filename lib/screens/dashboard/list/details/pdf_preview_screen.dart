import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:share_plus/share_plus.dart';

class PdfPreviewScreen extends StatelessWidget {
  final XFile pdfFile;

  const PdfPreviewScreen({required this.pdfFile, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Preview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              Share.shareXFiles([pdfFile], text: 'Student Details');
            },
          ),
        ],
      ),
      body: PDFView(
        filePath: pdfFile.path,
      ),
    );
  }
}
