import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mds/constants/colors.dart';

class PaymentUtils {
  static Future<void> showReceiveMoneyDialog({
    required BuildContext context,
    required DocumentSnapshot<Map<String, dynamic>> doc,
    required String targetId,
    required String category,
  }) async {
    final data = doc.data()!;
    final name = data['fullName'] ?? data['vehicleNumber'] ?? 'N/A';
    final balance =
        double.tryParse((data['balanceAmount'] ?? 0).toString()) ?? 0;

    final amountController = TextEditingController();
    String installmentType = 'second';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Receive Money'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Record: $name',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('Balance due: Rs. $balance'),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: installmentType,
                  decoration:
                      const InputDecoration(labelText: 'Installment type'),
                  items: const [
                    DropdownMenuItem(
                        value: 'second', child: Text('Second Installment')),
                    DropdownMenuItem(
                        value: 'third', child: Text('Third Installment')),
                  ],
                  onChanged: (v) =>
                      setDialogState(() => installmentType = v ?? 'second'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Amount (Rs.)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text.trim());
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enter valid amount')));
                  return;
                }

                final now = DateTime.now();
                final dateStr =
                    '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

                try {
                  final firestore = FirebaseFirestore.instance;
                  final batch = firestore.batch();

                  final updateData = <String, dynamic>{
                    'balanceAmount':
                        (balance - amount).clamp(0.0, double.infinity),
                  };

                  if (installmentType == 'second') {
                    updateData['secondInstallment'] = amount;
                    updateData['secondInstallmentTime'] = dateStr;
                  } else {
                    updateData['thirdInstallment'] = amount;
                    updateData['thirdInstallmentTime'] = dateStr;
                  }

                  // Add timestamp to trigger real-time updates
                  updateData['lastPaymentUpdate'] =
                      FieldValue.serverTimestamp();

                  batch.update(doc.reference, updateData);

                  // Add to payments subcollection with metadata for collection group query
                  final paymentRef = doc.reference.collection('payments').doc();
                  batch.set(paymentRef, {
                    'amount': amount,
                    'mode': 'Cash',
                    'date': Timestamp.now(),
                    'description': installmentType == 'second'
                        ? 'Second Installment'
                        : 'Third Installment',
                    'createdAt': FieldValue.serverTimestamp(),
                    'targetId': targetId,
                    'recordId': doc.id,
                    'recordName': name,
                    'category': category,
                  });

                  // Add to recent activity
                  final activityRef = firestore
                      .collection('users')
                      .doc(targetId)
                      .collection('recentActivity')
                      .doc();
                  batch.set(activityRef, {
                    'title': installmentType == 'second'
                        ? 'Second Installment Received'
                        : 'Third Installment Received',
                    'details': '$name\nRs. ${amount.toStringAsFixed(0)}',
                    'timestamp': FieldValue.serverTimestamp(),
                    'type': category,
                    'recordId': doc.id,
                  });

                  await batch.commit();
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Payment recorded')));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // Generic add payment for Advance (or any custom amount)
  static Future<void> showAddPaymentDialog({
    required BuildContext context,
    required DocumentSnapshot<Map<String, dynamic>> doc,
    required String targetId,
    required String category,
    String description = 'Payment Received',
  }) async {
    final data = doc.data()!;
    final name = data['fullName'] ?? data['vehicleNumber'] ?? 'N/A';
    final balance =
        double.tryParse((data['balanceAmount'] ?? 0).toString()) ?? 0;

    final amountController = TextEditingController();
    String selectedMode = 'Cash';
    final modes = [
      'Cash',
      'GPay',
      'PhonePe',
      'Paytm',
      'Bank Transfer',
      'Other'
    ];

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Record: $name',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('Balance due: Rs. $balance'),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Amount (Rs.)', prefixText: 'Rs. '),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedMode,
              decoration: const InputDecoration(labelText: 'Payment Mode'),
              items: modes
                  .map((mode) =>
                      DropdownMenuItem(value: mode, child: Text(mode)))
                  .toList(),
              onChanged: (val) => selectedMode = val!,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text.trim());
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enter valid amount')));
                return;
              }

              try {
                final firestore = FirebaseFirestore.instance;
                final batch = firestore.batch();

                final currentAdvance =
                    double.tryParse(data['advanceAmount']?.toString() ?? '0') ??
                        0.0;
                final newAdvance = currentAdvance + amount;
                final newBalance =
                    (balance - amount).clamp(0.0, double.infinity);

                batch.update(doc.reference, {
                  'advanceAmount': newAdvance,
                  'balanceAmount': newBalance,
                  // Add timestamp to trigger real-time updates
                  'lastPaymentUpdate': FieldValue.serverTimestamp(),
                });

                final paymentRef = doc.reference.collection('payments').doc();
                batch.set(paymentRef, {
                  'amount': amount,
                  'mode': selectedMode,
                  'date': Timestamp.now(),
                  'description': description,
                  'createdAt': FieldValue.serverTimestamp(),
                  'targetId': targetId,
                  'recordId': doc.id,
                  'recordName': name,
                  'category': category,
                });

                await batch.commit();
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Payment added successfully')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
