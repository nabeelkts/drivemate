import 'package:async/async.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mds/screens/dashboard/list/details/endorsement_details_page.dart';
import 'package:mds/screens/dashboard/list/details/license_only_details_page.dart';
import 'package:mds/screens/dashboard/list/details/rc_details_page.dart';
import 'package:mds/screens/dashboard/list/details/students_details_page.dart';
import 'package:shimmer/shimmer.dart'; // Import the shimmer package

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    User? user = FirebaseAuth.instance.currentUser;

    return SafeArea(
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: StreamBuilder<List<QuerySnapshot<Map<String, dynamic>>>>(
                  stream: StreamZip([
                    _firestore.collection('users').doc(user?.uid).collection('students').snapshots(),
                    _firestore.collection('users').doc(user?.uid).collection('licenseonly').snapshots(),
                    _firestore.collection('users').doc(user?.uid).collection('endorsement').snapshots(),
                    _firestore.collection('users').doc(user?.uid).collection('vehicleDetails').snapshots(),
                  ]),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Text('Error loading transactions');
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return buildShimmerTransactions();
                    }

                    final allDocuments = snapshot.data?.expand((snapshot) => snapshot.docs).toList() ?? [];
                    List<TransactionData> transactions = [];
                    double totalTransactionAmount = 0.0;

                    for (var doc in allDocuments) {
                      final data = doc.data();
                      final collectionId = doc.reference.parent.id;

                      double advanceAmount = double.tryParse(data['advanceAmount']?.toString() ?? '0') ?? 0.0;
                      double secondInstallment = double.tryParse(data['secondInstallment']?.toString() ?? '0') ?? 0.0;
                      double thirdInstallment = double.tryParse(data['thirdInstallment']?.toString() ?? '0') ?? 0.0;

                      String nameField = collectionId == 'vehicleDetails'
                          ? data['vehicleNumber'] ?? 'N/A'
                          : data['fullName'] ?? 'N/A';

                      DateTime registrationDate = DateTime.tryParse(data['registrationDate'] ?? '') ?? DateTime.now();
                      DateTime secondInstallmentTime = DateTime.tryParse(data['secondInstallmentTime'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
                      DateTime thirdInstallmentTime = DateTime.tryParse(data['thirdInstallmentTime'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);

                      // Add advance amount transaction
                      if (advanceAmount > 0) {
                        transactions.add(TransactionData(
                          date: registrationDate,
                          name: nameField,
                          amount: advanceAmount,
                          type: 'Advance',
                          collectionId: collectionId,
                          doc: doc,
                        ));
                      }

                      // Add second installment transaction
                      if (secondInstallment > 0) {
                        transactions.add(TransactionData(
                          date: secondInstallmentTime,
                          name: nameField,
                          amount: secondInstallment,
                          type: '2nd Installment',
                          collectionId: collectionId,
                          doc: doc,
                        ));
                      }

                      // Add third installment transaction
                      if (thirdInstallment > 0) {
                        transactions.add(TransactionData(
                          date: thirdInstallmentTime,
                          name: nameField,
                          amount: thirdInstallment,
                          type: '3rd Installment',
                          collectionId: collectionId,
                          doc: doc,
                        ));
                      }

                      totalTransactionAmount += advanceAmount + secondInstallment + thirdInstallment;
                    }

                    // Sort transactions by date in descending order
                    transactions.sort((a, b) => b.date.compareTo(a.date));

                    return Column(
                      children: [
                        buildTransactionHeader(totalTransactionAmount),
                        Expanded(
                          child: ListView.builder(
                            itemCount: transactions.length,
                            itemBuilder: (context, index) {
                              final transaction = transactions[index];
                              return buildTransactionRow(
                                context, // Pass context here
                                transaction,
                                formatDateTime(transaction.date),
                                '${transaction.name} (${getCollectionDisplayName(transaction.collectionId)})',
                                '${transaction.type}: Rs.${transaction.amount.toStringAsFixed(0)}',
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String getCollectionDisplayName(String collectionId) {
    switch (collectionId) {
      case 'students':
        return 'Student';
      case 'licenseonly':
        return 'License';
      case 'endorsement':
        return 'Endorsement';
      case 'vehicleDetails':
        return 'Vehicle';
      default:
        return collectionId;
    }
  }

  Widget buildTransactionHeader(double totalTransactionAmount) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: const [
              Icon(Icons.calendar_today),
              SizedBox(width: 8),
              Text(
                'Transactions History',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          Text(
            'Total: Rs.${totalTransactionAmount.toStringAsFixed(0)}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTransactionRow(BuildContext context, TransactionData transaction, String dateTime, String name, String amountDescription) {
    return GestureDetector(
      onTap: () {
        // Determine the collection and navigate to the appropriate details page
        if (transaction.collectionId == 'licenseonly') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LicenseOnlyDetailsPage(licenseDetails: transaction.doc.data()!),
            ),
          );
        } else if (transaction.collectionId == 'endorsement') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EndorsementDetailsPage(endorsementDetails: transaction.doc.data()!),
            ),
          );
        } else if (transaction.collectionId == 'vehicleDetails') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RCDetailsPage(vehicleDetails: transaction.doc.data()!),
            ),
          );
        } else if (transaction.collectionId == 'students') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudentDetailsPage(studentDetails: transaction.doc.data()!),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              dateTime,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF1E1E1E),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Color(0xFF1E1E1E),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              amountDescription,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF1E1E1E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildShimmerTransactions() {
    return Column(
      children: List.generate(5, (index) => buildShimmerTransactionRow()),
    );
  }

  Widget buildShimmerTransactionRow() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  String formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yy\nhh:mm a').format(dateTime);
  }
}

class TransactionData {
  final DateTime date;
  final String name;
  final double amount;
  final String type;
  final String collectionId;
  final DocumentSnapshot<Map<String, dynamic>> doc;

  TransactionData({
    required this.date,
    required this.name,
    required this.amount,
    required this.type,
    required this.collectionId,
    required this.doc,
  });
}
