import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

pickImage(ImageSource source) async {
  final ImagePicker imagePicker = ImagePicker();
  XFile? file = await imagePicker.pickImage(source: source);
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
