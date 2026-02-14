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
  final dateLabel = DateFormat('ddMMyyyy').format(DateTime.now());
  final countersDoc = FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('counters')
      .doc('daily_$dateLabel');

  return FirebaseFirestore.instance.runTransaction<String>((transaction) async {
    final snapshot = await transaction.get(countersDoc);
    int nextSeq = 1;
    if (snapshot.exists) {
      final current = (snapshot.data()?['seq'] ?? 0) as int;
      nextSeq = current + 1;
      transaction.update(countersDoc, {
        'seq': nextSeq,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      transaction.set(countersDoc, {
        'seq': nextSeq,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    final padded = nextSeq.toString().padLeft(4, '0');
    return '$dateLabel$padded';
  });
}
