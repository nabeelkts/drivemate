import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class OCRService {
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  Future<Map<String, String>> parseDocument(XFile image) async {
  final inputImage = InputImage.fromFilePath(image.path);
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  final RecognizedText recognizedText =
      await textRecognizer.processImage(inputImage);

  final text = recognizedText.text.toLowerCase();

  Map<String, String> data = {};

  // ---------- Detect Document Type ----------
  bool isAadhaar = text.contains('government of india') ||
      text.contains('aadhaar');
  bool isPassport = text.contains('passport') ||
      text.contains('republic of india');
  bool isSSLC = text.contains('secondary school') ||
      text.contains('sslc');

  // ---------- COMMON DOB ----------
  final dobMatch =
      RegExp(r'(\d{2}/\d{2}/\d{4}|\d{2}-\d{2}-\d{4})').firstMatch(text);
  if (dobMatch != null) {
    data['dob'] = dobMatch.group(0)!;
  }

  // ============================================================
  // 🟠 AADHAAR PARSER
  // ============================================================
  if (isAadhaar) {
    final lines = recognizedText.blocks
        .expand((b) => b.lines)
        .map((l) => l.text.trim())
        .toList();

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toLowerCase();

      // Name usually before DOB
      if (line.contains('dob') && i > 0) {
        data['fullName'] = lines[i - 1];
      }

      // Father/Guardian
      if (line.contains('s/o') ||
          line.contains('d/o') ||
          line.contains('c/o')) {
        data['guardianName'] =
            lines[i].replaceAll(RegExp(r'(s/o|d/o|c/o)'), '').trim();
      }

      // Address starts after "Address"
      if (line.contains('address')) {
        final addressLines = lines.sublist(i + 1, i + 6);

        if (addressLines.length >= 4) {
          data['house'] = addressLines[0];
          data['place'] = addressLines[1];
          data['post'] = addressLines[2];
          data['district'] = addressLines[3];

          final pinMatch =
              RegExp(r'\b\d{6}\b').firstMatch(addressLines.join(' '));
          if (pinMatch != null) data['pin'] = pinMatch.group(0)!;
        }
        break;
      }
    }
  }

  // ============================================================
  // 🔵 PASSPORT PARSER
  // ============================================================
  if (isPassport) {
    final lines = recognizedText.blocks
        .expand((b) => b.lines)
        .map((l) => l.text.trim())
        .toList();

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toLowerCase();

      if (line.contains('name')) {
        data['fullName'] = lines[i + 1];
      }

      if (line.contains('father')) {
        data['guardianName'] = lines[i + 1];
      }

      if (line.contains('address')) {
        final addr = lines.sublist(i + 1, i + 6);

        if (addr.length >= 4) {
          data['house'] = addr[0];
          data['place'] = addr[1];
          data['post'] = addr[2];
          data['district'] = addr[3];

          final pinMatch =
              RegExp(r'\b\d{6}\b').firstMatch(addr.join(' '));
          if (pinMatch != null) data['pin'] = pinMatch.group(0)!;
        }
        break;
      }
    }
  }

  // ============================================================
  // 🟢 SSLC PARSER
  // ============================================================
  if (isSSLC) {
    final lines = recognizedText.blocks
        .expand((b) => b.lines)
        .map((l) => l.text.trim())
        .toList();

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toLowerCase();

      if (line.contains('name')) {
        data['fullName'] = lines[i + 1];
      }

      if (line.contains('father')) {
        data['guardianName'] = lines[i + 1];
      }

      if (line.contains('address')) {
        final addr = lines.sublist(i + 1, i + 6);

        if (addr.length >= 4) {
          data['house'] = addr[0];
          data['place'] = addr[1];
          data['post'] = addr[2];
          data['district'] = addr[3];

          final pinMatch =
              RegExp(r'\b\d{6}\b').firstMatch(addr.join(' '));
          if (pinMatch != null) data['pin'] = pinMatch.group(0)!;
        }
        break;
      }
    }
  }

  textRecognizer.close();
  return data;
}

  void dispose() {
    _textRecognizer.close();
  }
}