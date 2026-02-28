import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class SmartDocumentScanner {
  /// ===============================
  /// IMAGE PREPROCESSING
  /// ===============================

  Future<File> preprocessImage(File file) async {
    try {
      final bytes = await file.readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) return file;

      // Auto rotate based on EXIF
      image = img.bakeOrientation(image);

      // Convert to grayscale
      image = img.grayscale(image);

      // Increase contrast
      image = img.adjustColor(image, contrast: 1.7);

      // Light sharpen
      image = img.convolution(image, filter: [
        0, -1, 0,
        -1, 5, -1,
        0, -1, 0
      ]);

      final processedFile =
          File(file.path.replaceAll(".jpg", "_processed.jpg"));

      await processedFile.writeAsBytes(
        img.encodeJpg(image, quality: 95),
      );

      return processedFile;
    } catch (e) {
      return file;
    }
  }

  /// ===============================
  /// OCR
  /// ===============================

  Future<String> performOCR(File file) async {
    final inputImage = InputImage.fromFile(file);
    final textRecognizer = TextRecognizer(
      script: TextRecognitionScript.latin,
    );

    final RecognizedText recognizedText =
        await textRecognizer.processImage(inputImage);

    await textRecognizer.close();

    return recognizedText.text;
  }

  /// ===============================
  /// DOCUMENT TYPE DETECTION
  /// ===============================

  String detectDocumentType(String text) {
    final lower = text.toLowerCase();

    if (lower.contains("government of india") ||
        lower.contains("aadhaar") ||
        lower.contains("uidai")) {
      return "aadhaar";
    }

    if (lower.contains("passport") ||
        lower.contains("republic of india")) {
      return "passport";
    }

    if (lower.contains("secondary school") ||
        lower.contains("sslc") ||
        lower.contains("kerala")) {
      return "sslc";
    }

    return "unknown";
  }

  /// ===============================
  /// FIELD EXTRACTION
  /// ===============================

  Map<String, String> extractFields(String text, String type) {
    text = text.replaceAll('\n', ' ');
    text = text.replaceAll(RegExp(r'\s+'), ' ');

    Map<String, String> data = {
      "name": "",
      "guardian": "",
      "dob": "",
      "house": "",
      "place": "",
      "post": "",
      "district": "",
      "pin": "",
    };

    // DOB
    final dobMatch =
        RegExp(r'(\d{2}[/-]\d{2}[/-]\d{4})').firstMatch(text);
    if (dobMatch != null) {
      data["dob"] =
          dobMatch.group(1)!.replaceAll("/", "-");
    }

    // PIN
    final pinMatch = RegExp(r'\b\d{6}\b').firstMatch(text);
    if (pinMatch != null) {
      data["pin"] = pinMatch.group(0)!;
    }

    if (type == "aadhaar") {
      final nameMatch =
          RegExp(r'([A-Z][a-z]+(?:\s[A-Z][a-z]+)+)')
              .firstMatch(text);
      if (nameMatch != null) {
        data["name"] = nameMatch.group(1)!;
      }

      final guardianMatch =
          RegExp(r'(S/O|D/O|C/O)\s*([A-Z][a-z]+\s?[A-Za-z]*)')
              .firstMatch(text);
      if (guardianMatch != null) {
        data["guardian"] = guardianMatch.group(2)!;
      }

      extractKeralaDistrict(text, data);
    }

    if (type == "passport") {
  final RegExp fatherRegex =
      RegExp(r"Father'?s?\s*Name\s*[:\-]?\s*([A-Z\s]+)");

  final Match? fatherMatch = fatherRegex.firstMatch(text);

  if (fatherMatch != null && fatherMatch.groupCount >= 1) {
    final String? guardianName = fatherMatch.group(1);
    if (guardianName != null) {
      data["guardian"] = guardianName.trim();
    }
  }
}

    if (type == "sslc") {
      final nameMatch =
          RegExp(r'Name\s*[:\-]?\s*([A-Z\s]+)')
              .firstMatch(text);
      if (nameMatch != null) {
        data["name"] = nameMatch.group(1)!.trim();
      }

      final parentMatch =
          RegExp(r'(Father|Mother)\s*[:\-]?\s*([A-Z\s]+)')
              .firstMatch(text);
      if (parentMatch != null) {
        data["guardian"] = parentMatch.group(2)!.trim();
      }
    }

    return data;
  }

  /// ===============================
  /// Kerala District Detection
  /// ===============================

  void extractKeralaDistrict(
      String text, Map<String, String> data) {
    const districts = [
      "Thiruvananthapuram",
      "Kollam",
      "Pathanamthitta",
      "Alappuzha",
      "Kottayam",
      "Idukki",
      "Ernakulam",
      "Thrissur",
      "Palakkad",
      "Malappuram",
      "Kozhikode",
      "Wayanad",
      "Kannur",
      "Kasaragod"
    ];

    for (final district in districts) {
      if (text.contains(district)) {
        data["district"] = district;
        break;
      }
    }
  }

  /// ===============================
  /// MAIN FUNCTION
  /// ===============================

  Future<Map<String, String>> scan(File file) async {
    File processed = await preprocessImage(file);
    String text = await performOCR(processed);
    String type = detectDocumentType(text);

    return extractFields(text, type);
  }
}