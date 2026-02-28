import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Formats date string from yyyy-MM-dd to dd/MM/yyyy
/// If input is already in dd/MM/yyyy format, returns as-is
/// Returns 'N/A' if input is null or empty
String formatDisplayDate(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty || dateStr == 'N/A') {
    return 'N/A';
  }

  // If already in dd/MM/yyyy format, return as-is
  if (RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(dateStr)) {
    return dateStr;
  }

  // Try to parse yyyy-MM-dd format
  try {
    final date = DateTime.parse(dateStr);
    return DateFormat('dd/MM/yyyy').format(date);
  } catch (e) {
    // If parsing fails, return original
    return dateStr;
  }
}

pickImage(ImageSource source) async {
  final ImagePicker imagePicker = ImagePicker();
  XFile? file = await imagePicker.pickImage(source: source, imageQuality: 50);
  if (file != null) {
    return await file.readAsBytes();
  }
  if (kDebugMode) {
    print('No Images Selected');
  }
}

Future<String> generateStudentId(String userId) async {
  // Use a deterministic ID based on local time to allow offline support.
  // Format: ddMMyyyyHHmmss (total 14 digits)
  final now = DateTime.now();
  final dateLabel = DateFormat('ddMMyyyy').format(now);
  final timeLabel = DateFormat('HHmmss').format(now);

  return '$dateLabel$timeLabel';
}
