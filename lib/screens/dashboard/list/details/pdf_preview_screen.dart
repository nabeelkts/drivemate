import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class PdfPreviewScreen extends StatelessWidget {
  final Uint8List pdfBytes;
  final String fileName;
  final String? studentName;
  final String? studentPhone; // must include country code, e.g., 91XXXXXXXXXX

  const PdfPreviewScreen({
    required this.pdfBytes,
    this.studentName,
    this.studentPhone,
    this.fileName = 'document.pdf',
    super.key,
  });

  /// Opens WhatsApp chat for the student with PDF + text ready
  Future<void> sendPdfWithTextToWhatsApp() async {
    if (studentName == null || studentPhone == null) return;

    try {
      // Save PDF to temporary file
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/receipt_$studentName.pdf');
      await file.writeAsBytes(pdfBytes);

      // Pre-fill message
      final message =
          'Hello $studentName, here is your fee receipt. Please check the attachment.';

      // Open WhatsApp chat for specific number
      final whatsappUrl = Uri.parse(
        'whatsapp://send?phone=${studentPhone!.replaceAll(RegExp(r'\D'), '')}&text=${Uri.encodeComponent(message)}',
      );

      if (await canLaunchUrl(whatsappUrl)) {
        // Open WhatsApp chat first
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);

        // Then open share sheet to attach PDF
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'application/pdf')],
          text: message,
        );
      } else {
        print('WhatsApp not installed or number invalid');
      }
    } catch (e) {
      print('Error sharing PDF to WhatsApp: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PDF Preview')),
      body: PdfPreview(
        build: (format) => pdfBytes,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        pdfFileName: fileName,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF25D366),
        icon: const Icon(Icons.send_rounded, color: Colors.white),
        label: const Text(
          'Send to WhatsApp',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        onPressed: sendPdfWithTextToWhatsApp,
      ),
    );
  }
}