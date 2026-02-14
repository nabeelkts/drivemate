import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionData {
  final DateTime date;
  final String name;
  final double amount;
  final String type;
  final String collectionId;
  final DocumentSnapshot<Map<String, dynamic>> doc;
  final String? imageUrl;
  final bool isExpense;
  final String? note;

  TransactionData({
    required this.date,
    required this.name,
    required this.amount,
    required this.type,
    required this.collectionId,
    required this.doc,
    this.imageUrl,
    this.isExpense = false,
    this.note,
  });
}
