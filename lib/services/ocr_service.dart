import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class OCRService {
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  /// Processes an image and extracts document details.
  Future<Map<String, String>> parseDocument(XFile image) async {
    try {
      final inputImage = InputImage.fromFilePath(image.path);
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      String fullText = recognizedText.text;
      final lines = fullText.split('\n');

      Map<String, String> results = {};

      for (var line in lines) {
        final lower = line.toLowerCase();

        if (lower.contains('name') && !lower.contains('guardian')) {
          results['fullName'] = _extractValue(line, 'name');
        } else if (lower.contains('guardian') || lower.contains('father')) {
          results['guardianName'] = _extractValue(
              line, lower.contains('guardian') ? 'guardian' : 'father');
        } else if (lower.contains('dob') || lower.contains('birth')) {
          final dob = _extractDate(line);
          if (dob.isNotEmpty) results['dob'] = dob;
        } else if (lower.contains('pin')) {
          final pin = RegExp(r'\d{6}').stringMatch(line);
          if (pin != null) results['pin'] = pin;
        } else if (lower.contains('house') || lower.contains('no:')) {
          results['house'] = _extractValue(line, 'house');
        } else if (lower.contains('place') || lower.contains('at:')) {
          results['place'] = _extractValue(line, 'place');
        } else if (lower.contains('post')) {
          results['post'] = _extractValue(line, 'post');
        } else if (lower.contains('district')) {
          results['district'] = _extractValue(line, 'district');
        }
      }

      return results;
    } catch (e) {
      throw Exception('OCR Parsing failed: $e');
    }
  }

  String _extractValue(String line, String key) {
    final parts = line.split(RegExp(r'[:\-]'));
    if (parts.length > 1) {
      return parts.sublist(1).join(' ').trim();
    }
    return line.replaceAll(RegExp(key, caseSensitive: false), '').trim();
  }

  String _extractDate(String line) {
    final match = RegExp(r'\d{2}[\-/]\d{2}[\-/]\d{4}').stringMatch(line);
    if (match != null) return match.replaceAll('/', '-');
    return '';
  }

  void dispose() {
    _textRecognizer.close();
  }
}
