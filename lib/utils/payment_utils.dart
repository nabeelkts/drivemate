import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/services/pdf_service.dart';
import 'package:mds/screens/dashboard/list/details/pdf_preview_screen.dart';

class PaymentUtils {
  static Future<void> showReceiveMoneyDialog({
    required BuildContext context,
    required DocumentSnapshot<Map<String, dynamic>> doc,
    required String targetId,
    required String category,
    String? branchId,
  }) async {
    final data = doc.data()!;
    final name = data['fullName'] ?? data['vehicleNumber'] ?? 'N/A';
    final balance =
        double.tryParse((data['balanceAmount'] ?? 0).toString()) ?? 0;

    if (balance <= 0) {
      _showPaymentCompletedDialog(context, doc, targetId, branchId, category);
      return;
    }

    final amountController = TextEditingController();
    final noteController = TextEditingController();
    String selectedMode = 'Cash';
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

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
                TextField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Amount (Rs.)'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedMode,
                  decoration: const InputDecoration(labelText: 'Payment Mode'),
                  items: modes
                      .map((mode) =>
                          DropdownMenuItem(value: mode, child: Text(mode)))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => selectedMode = v ?? 'Cash'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(
                            DateFormat('dd MMM yyyy').format(selectedDate)),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setDialogState(() => selectedDate = date);
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.access_time, size: 18),
                        label: Text(selectedTime.format(context)),
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                          );
                          if (time != null) {
                            setDialogState(() => selectedTime = time);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                      labelText: 'Note / Remarks (Optional)'),
                  maxLines: 2,
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

                if (balance <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text(
                          'Student has already paid in full. To accept more, add as "Additional Fee".')));
                  return;
                }

                if (amount > balance) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          'Payment cannot exceed balance. Max: Rs. $balance')));
                  return;
                }

                // Combine date and time
                final combinedDateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );

                final dateStr =
                    '${combinedDateTime.year}-${combinedDateTime.month.toString().padLeft(2, '0')}-${combinedDateTime.day.toString().padLeft(2, '0')}';

                try {
                  final firestore = FirebaseFirestore.instance;
                  final batch = firestore.batch();

                  final updateData = <String, dynamic>{
                    'balanceAmount':
                        (balance - amount).clamp(0.0, double.infinity),
                  };

                  // Determine which installment number to use (supports unlimited installments)
                  // Get all existing installment fields dynamically
                  final existingInstallments = <int, double>{};

                  // Check for numbered installments (installment1, installment2, etc.)
                  for (int i = 1; i <= 20; i++) {
                    final key = 'installment$i';
                    final value =
                        double.tryParse(data[key]?.toString() ?? '0') ?? 0;
                    if (value > 0) {
                      existingInstallments[i] = value;
                    }
                  }

                  // Also check legacy secondInstallment and thirdInstallment fields
                  final secondInstallment = double.tryParse(
                          data['secondInstallment']?.toString() ?? '0') ??
                      0;
                  final thirdInstallment = double.tryParse(
                          data['thirdInstallment']?.toString() ?? '0') ??
                      0;

                  // Map legacy fields to numbered installments
                  if (secondInstallment > 0 &&
                      !existingInstallments.containsKey(2)) {
                    existingInstallments[2] = secondInstallment;
                  }
                  if (thirdInstallment > 0 &&
                      !existingInstallments.containsKey(3)) {
                    existingInstallments[3] = thirdInstallment;
                  }

                  // Find the next available installment number
                  int nextInstallmentNumber = 1;
                  while (
                      existingInstallments.containsKey(nextInstallmentNumber) &&
                          existingInstallments[nextInstallmentNumber]! > 0) {
                    nextInstallmentNumber++;
                  }

                  // If we've reached the limit, use the last one
                  if (nextInstallmentNumber > 20) {
                    nextInstallmentNumber = 20;
                  }

                  // Get current value for this installment (if any)
                  final currentValue =
                      existingInstallments[nextInstallmentNumber] ?? 0;
                  final newValue = currentValue + amount;

                  // Update the appropriate field
                  if (nextInstallmentNumber == 2) {
                    // Use legacy field for backward compatibility
                    updateData['secondInstallment'] = newValue;
                    updateData['secondInstallmentTime'] = dateStr;
                  } else if (nextInstallmentNumber == 3) {
                    // Use legacy field for backward compatibility
                    updateData['thirdInstallment'] = newValue;
                    updateData['thirdInstallmentTime'] = dateStr;
                  } else {
                    // Use numbered installment field
                    updateData['installment$nextInstallmentNumber'] = newValue;
                    updateData['installment${nextInstallmentNumber}Time'] =
                        dateStr;
                  }

                  final installmentType = nextInstallmentNumber.toString();
                  final description = 'Installment $nextInstallmentNumber';

                  // Add timestamp to trigger real-time updates
                  updateData['lastPaymentUpdate'] =
                      FieldValue.serverTimestamp();

                  batch.update(doc.reference, updateData);

                  // Add to payments subcollection with metadata for collection group query
                  final paymentRef = doc.reference.collection('payments').doc();
                  batch.set(paymentRef, {
                    'amount': amount,
                    'mode': selectedMode,
                    'date': Timestamp.fromDate(combinedDateTime),
                    'description': description,
                    'createdAt': FieldValue.serverTimestamp(),
                    'targetId': targetId,
                    'recordId': doc.id,
                    'recordName': name,
                    'category': category,
                    'branchId': branchId ?? targetId,
                    'note': noteController.text.trim(),
                  });

                  // Add to recent activity
                  final activityRef = firestore
                      .collection('users')
                      .doc(targetId)
                      .collection('recentActivity')
                      .doc();
                  batch.set(activityRef, {
                    'title': '$description Received',
                    'details': '$name\nRs. ${amount.toStringAsFixed(0)}',
                    'timestamp': FieldValue.serverTimestamp(),
                    'type': category,
                    'recordId': doc.id,
                    'imageUrl': doc['image'],
                    'branchId': branchId ?? targetId,
                  });

                  await batch.commit();

                  // Sync extra fee statuses based on new balance
                  final finalBatch = firestore.batch();
                  await _syncExtraFeeStatuses(
                    docRef: doc.reference,
                    batch: finalBatch,
                  );
                  await finalBatch.commit();

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
    String? branchId,
  }) async {
    final data = doc.data()!;
    final name = data['fullName'] ?? data['vehicleNumber'] ?? 'N/A';
    final balance =
        double.tryParse((data['balanceAmount'] ?? 0).toString()) ?? 0;

    if (balance <= 0) {
      _showPaymentCompletedDialog(context, doc, targetId, branchId, category);
      return;
    }

    final amountController = TextEditingController();
    final noteController = TextEditingController();
    String selectedMode = 'Cash';
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

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
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Payment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  onChanged: (val) => setDialogState(() => selectedMode = val!),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(
                            DateFormat('dd MMM yyyy').format(selectedDate)),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setDialogState(() => selectedDate = date);
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.access_time, size: 18),
                        label: Text(selectedTime.format(context)),
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                          );
                          if (time != null) {
                            setDialogState(() => selectedTime = time);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                      labelText: 'Note / Remarks (Optional)'),
                  maxLines: 2,
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

                if (balance <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text(
                          'Student has already paid in full. To accept more, add as "Additional Fee".')));
                  return;
                }

                if (amount > balance) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          'Payment cannot exceed balance. Max: Rs. $balance')));
                  return;
                }

                final combinedDateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );

                try {
                  final firestore = FirebaseFirestore.instance;
                  final batch = firestore.batch();

                  final currentAdvance = double.tryParse(
                          data['advanceAmount']?.toString() ?? '0') ??
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
                    'date': Timestamp.fromDate(combinedDateTime),
                    'description': description,
                    'createdAt': FieldValue.serverTimestamp(),
                    'targetId': targetId,
                    'recordId': doc.id,
                    'recordName': name,
                    'category': category,
                    'branchId': branchId ?? targetId,
                    'note': noteController.text.trim(),
                  });

                  // Add to recent activity
                  final activityRef = firestore
                      .collection('users')
                      .doc(targetId)
                      .collection('recentActivity')
                      .doc();
                  batch.set(activityRef, {
                    'title': description,
                    'details': '$name\nRs. ${amount.toStringAsFixed(0)}',
                    'timestamp': FieldValue.serverTimestamp(),
                    'type': category,
                    'recordId': doc.id,
                    'imageUrl': data['image'],
                    'branchId': branchId ?? targetId,
                  });

                  await batch.commit();

                  // Sync extra fee statuses based on new balance
                  final finalBatch = firestore.batch();
                  await _syncExtraFeeStatuses(
                    docRef: doc.reference,
                    batch: finalBatch,
                  );
                  await finalBatch.commit();
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
      ),
    );
  }

  static Future<void> showEditPaymentDialog({
    required BuildContext context,
    required DocumentReference docRef,
    required DocumentSnapshot paymentDoc,
    required String targetId,
    required String category,
    String? branchId,
  }) async {
    final paymentData = paymentDoc.data() as Map<String, dynamic>;
    final oldAmount =
        double.tryParse(paymentData['amount']?.toString() ?? '0') ?? 0;
    final oldNote = paymentData['note']?.toString() ?? '';
    final oldMode = paymentData['mode']?.toString() ?? 'Cash';
    final oldDate =
        (paymentData['date'] as Timestamp?)?.toDate() ?? DateTime.now();

    final amountController =
        TextEditingController(text: oldAmount.toStringAsFixed(0));
    final noteController = TextEditingController(text: oldNote);
    String selectedMode = oldMode;
    DateTime selectedDate = oldDate;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(oldDate);

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
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Payment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Update payment details:',
                    style: TextStyle(fontWeight: FontWeight.w600)),
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
                  onChanged: (val) => setDialogState(() => selectedMode = val!),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(
                            DateFormat('dd MMM yyyy').format(selectedDate)),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setDialogState(() => selectedDate = date);
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.access_time, size: 18),
                        label: Text(selectedTime.format(context)),
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                          );
                          if (time != null) {
                            setDialogState(() => selectedTime = time);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                      labelText: 'Note / Remarks (Optional)'),
                  maxLines: 2,
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
                final newAmount =
                    double.tryParse(amountController.text.trim()) ?? 0;
                if (newAmount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enter valid amount')));
                  return;
                }

                final combinedDateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );

                try {
                  final firestore = FirebaseFirestore.instance;
                  final batch = firestore.batch();

                  // Get parent document to update balance
                  final parentDoc = await docRef.get();
                  if (!parentDoc.exists) throw 'Parent record not found';
                  final parentData = parentDoc.data() as Map<String, dynamic>;

                  final currentBalance = double.tryParse(
                          parentData['balanceAmount']?.toString() ?? '0') ??
                      0.0;
                  // Adjust balance: newBalance = currentBalance + (oldAmount - newAmount)
                  final newBalance = (currentBalance + oldAmount - newAmount)
                      .clamp(0.0, double.infinity);

                  final updateData = <String, dynamic>{
                    'balanceAmount': newBalance,
                    'lastPaymentUpdate': FieldValue.serverTimestamp(),
                  };

                  final description = paymentData['description'] ?? '';
                  if (description == 'Second Installment') {
                    updateData['secondInstallment'] = newAmount;
                  } else if (description == 'Third Installment') {
                    updateData['thirdInstallment'] = newAmount;
                  } else if (description
                      .toString()
                      .startsWith('Installment ')) {
                    final match =
                        RegExp(r'Installment (\d+)').firstMatch(description);
                    if (match != null) {
                      final n = match.group(1);
                      updateData['installment$n'] = newAmount;
                    }
                  } else {
                    final currentAdvance = double.tryParse(
                            parentData['advanceAmount']?.toString() ?? '0') ??
                        0.0;
                    updateData['advanceAmount'] =
                        (currentAdvance - oldAmount + newAmount)
                            .clamp(0.0, double.infinity);
                  }

                  batch.update(docRef, updateData);

                  // Update payment document
                  batch.update(paymentDoc.reference, {
                    'amount': newAmount,
                    'mode': selectedMode,
                    'date': Timestamp.fromDate(combinedDateTime),
                    'note': noteController.text.trim(),
                    'updatedAt': FieldValue.serverTimestamp(),
                  });

                  // Add activity
                  final activityRef = firestore
                      .collection('users')
                      .doc(targetId)
                      .collection('recentActivity')
                      .doc();
                  batch.set(activityRef, {
                    'title': 'Payment Updated',
                    'details':
                        '${parentData['fullName'] ?? parentData['vehicleNumber'] ?? 'N/A'}\nRs. ${newAmount.toStringAsFixed(0)}',
                    'timestamp': FieldValue.serverTimestamp(),
                    'type': 'editing',
                    'recordId': parentDoc.id,
                    'imageUrl': parentData['image'],
                    'branchId': branchId ?? targetId,
                  });

                  await batch.commit();
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Payment updated successfully')));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
              child:
                  const Text('Update', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> deletePayment({
    required BuildContext context,
    required DocumentReference studentRef,
    required DocumentSnapshot paymentDoc,
    required String targetId,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Payment'),
        content: const Text(
            'Are you sure you want to delete this payment? This will update the student\'s balance.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      final paymentData = paymentDoc.data() as Map<String, dynamic>;
      final amount =
          double.tryParse(paymentData['amount']?.toString() ?? '0') ?? 0.0;
      final description = paymentData['description'] ?? '';

      final studentDoc = await studentRef.get();
      if (!studentDoc.exists) throw 'Student record not found';
      final studentData = studentDoc.data() as Map<String, dynamic>;

      final currentBalance =
          double.tryParse(studentData['balanceAmount']?.toString() ?? '0') ??
              0.0;
      final newBalance = currentBalance + amount;

      final updateData = <String, dynamic>{
        'balanceAmount': newBalance,
        'lastPaymentUpdate': FieldValue.serverTimestamp(),
      };

      if (description == 'Second Installment') {
        updateData['secondInstallment'] = 0;
        updateData['secondInstallmentTime'] = '';
      } else if (description == 'Third Installment') {
        updateData['thirdInstallment'] = 0;
        updateData['thirdInstallmentTime'] = '';
      } else {
        // Assume it's an Advance or generic payment
        final currentAdvance =
            double.tryParse(studentData['advanceAmount']?.toString() ?? '0') ??
                0.0;
        updateData['advanceAmount'] =
            (currentAdvance - amount).clamp(0.0, double.infinity);
      }

      batch.update(studentRef, updateData);
      batch.delete(paymentDoc.reference);

      // Add to recent activity
      final activityRef = firestore
          .collection('users')
          .doc(targetId)
          .collection('recentActivity')
          .doc();
      batch.set(activityRef, {
        'title': 'Payment Deleted',
        'details':
            '${studentData['fullName'] ?? studentData['vehicleNumber'] ?? 'N/A'}\nAmount: Rs. ${amount.toStringAsFixed(0)}',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'deletion',
        'recordId': studentDoc.id,
        'imageUrl': studentData['image'],
        'branchId': targetId,
      });

      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment deleted successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting payment: $e')),
        );
      }
    }
  }

  static Future<void> showEditLegacyPaymentDialog({
    required BuildContext context,
    required DocumentReference docRef,
    required String legacyId,
    required Map<String, dynamic> parentData,
    required String targetId,
    required String category,
    String? branchId,
  }) async {
    double oldAmount = 0;
    String oldMode = 'Cash';
    DateTime oldDate = DateTime.now();
    String fieldName = '';
    String dateFieldName = '';
    String label = '';

    if (legacyId == 'legacy_adv') {
      oldAmount =
          double.tryParse(parentData['advanceAmount']?.toString() ?? '0') ?? 0;
      oldMode = parentData['paymentMode'] ?? 'Cash';
      oldDate = DateTime.tryParse(parentData['registrationDate']?.toString() ??
              parentData['date']?.toString() ??
              '') ??
          DateTime.now();
      fieldName = 'advanceAmount';
      dateFieldName = 'registrationDate';
      label = 'Advance Payment';
    } else if (legacyId.startsWith('legacy_inst')) {
      int index = int.tryParse(legacyId.replaceFirst('legacy_inst', '')) ?? 0;
      oldAmount =
          double.tryParse(parentData['installment$index']?.toString() ?? '0') ??
              0;
      oldMode = 'Cash';
      oldDate = DateTime.tryParse(
              parentData['installment${index}Time']?.toString() ?? '') ??
          DateTime.now();
      fieldName = 'installment$index';
      dateFieldName = 'installment${index}Time';
      label = 'Installment $index';
    }

    final amountController =
        TextEditingController(text: oldAmount.toStringAsFixed(0));
    String selectedMode = oldMode;
    DateTime selectedDate = oldDate;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(oldDate);

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
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Edit $label'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                  onChanged: (val) => setDialogState(() => selectedMode = val!),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(DateFormat('dd MMM').format(selectedDate)),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setDialogState(() => selectedDate = date);
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.access_time, size: 18),
                        label: Text(selectedTime.format(context)),
                        onPressed: () async {
                          final time = await showTimePicker(
                              context: context, initialTime: selectedTime);
                          if (time != null) {
                            setDialogState(() => selectedTime = time);
                          }
                        },
                      ),
                    ),
                  ],
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
                final newAmount =
                    double.tryParse(amountController.text.trim()) ?? 0;
                final combinedDateTime = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    selectedTime.hour,
                    selectedTime.minute);

                try {
                  final firestore = FirebaseFirestore.instance;
                  final batch = firestore.batch();

                  final currentBalance = double.tryParse(
                          parentData['balanceAmount']?.toString() ?? '0') ??
                      0.0;
                  final newBalance = (currentBalance + oldAmount - newAmount)
                      .clamp(0.0, double.infinity);

                  final Map<String, dynamic> updateData = {
                    'balanceAmount': newBalance,
                    fieldName: newAmount,
                    dateFieldName: combinedDateTime.toIso8601String(),
                    'lastPaymentUpdate': FieldValue.serverTimestamp(),
                  };
                  if (legacyId == 'legacy_adv') {
                    updateData['paymentMode'] = selectedMode;
                  }

                  batch.update(docRef, updateData);

                  final activityRef = firestore
                      .collection('users')
                      .doc(targetId)
                      .collection('recentActivity')
                      .doc();
                  batch.set(activityRef, {
                    'title': 'Legacy Payment Updated',
                    'details':
                        '${parentData['fullName'] ?? parentData['vehicleNumber'] ?? 'N/A'}\n$label updated to Rs. ${newAmount.toStringAsFixed(0)}',
                    'timestamp': FieldValue.serverTimestamp(),
                    'type': 'editing',
                    'recordId': docRef.id,
                    'imageUrl': parentData['image'],
                    'branchId': branchId ?? targetId,
                  });

                  await batch.commit();
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Payment updated successfully')));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> deleteLegacyPayment({
    required BuildContext context,
    required DocumentReference docRef,
    required String legacyId,
    required Map<String, dynamic> parentData,
    required String targetId,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Payment'),
        content: const Text(
            'Are you sure you want to delete this legacy payment? This will update the balance.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      double amount = 0;
      String fieldName = '';
      String dateFieldName = '';

      if (legacyId == 'legacy_adv') {
        amount =
            double.tryParse(parentData['advanceAmount']?.toString() ?? '0') ??
                0;
        fieldName = 'advanceAmount';
        dateFieldName = 'registrationDate';
      } else if (legacyId.startsWith('legacy_inst')) {
        int index = int.tryParse(legacyId.replaceFirst('legacy_inst', '')) ?? 0;
        amount = double.tryParse(
                parentData['installment$index']?.toString() ?? '0') ??
            0;
        fieldName = 'installment$index';
        dateFieldName = 'installment${index}Time';
      }

      final currentBalance =
          double.tryParse(parentData['balanceAmount']?.toString() ?? '0') ?? 0;
      final newBalance = currentBalance + amount;

      final Map<String, dynamic> updateData = {
        'balanceAmount': newBalance,
        fieldName: 0,
        dateFieldName: '',
        'lastPaymentUpdate': FieldValue.serverTimestamp(),
      };

      batch.update(docRef, updateData);

      final activityRef = firestore
          .collection('users')
          .doc(targetId)
          .collection('recentActivity')
          .doc();
      batch.set(activityRef, {
        'title': 'Legacy Payment Deleted',
        'details':
            '${parentData['fullName'] ?? parentData['vehicleNumber'] ?? 'N/A'}\nDeleted Rs. ${amount.toStringAsFixed(0)} ($legacyId)',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'deletion',
        'recordId': docRef.id,
        'imageUrl': parentData['image'],
        'branchId': targetId,
      });

      await batch.commit();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment deleted successfully')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  static Future<void> showAddExtraFeeDialog({
    required BuildContext context,
    required DocumentSnapshot<Map<String, dynamic>> doc,
    required String targetId,
    required String category,
    String? branchId,
  }) async {
    final data = doc.data()!;
    final name = data['fullName'] ?? data['vehicleNumber'] ?? 'N/A';

    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    final noteController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Extra Fee'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Record: $name',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Fee Type',
                    hintText:
                        'Faild fees, Additional Class, Learners Renewal ect.',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Amount (Rs.)'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(
                            DateFormat('dd MMM yyyy').format(selectedDate)),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setDialogState(() => selectedDate = date);
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.access_time, size: 18),
                        label: Text(selectedTime.format(context)),
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                          );
                          if (time != null) {
                            setDialogState(() => selectedTime = time);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                      labelText: 'Note / Remarks (Optional)'),
                  maxLines: 2,
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

                final combinedDateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );

                try {
                  final firestore = FirebaseFirestore.instance;
                  final batch = firestore.batch();

                  // Increase totalAmount and balanceAmount
                  final currentTotal =
                      double.tryParse(data['totalAmount']?.toString() ?? '0') ??
                          0.0;
                  final currentBalance = double.tryParse(
                          data['balanceAmount']?.toString() ?? '0') ??
                      0.0;

                  batch.update(doc.reference, {
                    'totalAmount': currentTotal + amount,
                    'balanceAmount': currentBalance + amount,
                  });

                  // Add extra fee document
                  final feeRef = doc.reference.collection('extra_fees').doc();
                  batch.set(feeRef, {
                    'amount': amount,
                    'description': descriptionController.text.trim(),
                    'date': Timestamp.fromDate(combinedDateTime),
                    'note': noteController.text.trim(),
                    'createdAt': FieldValue.serverTimestamp(),
                    'targetId': targetId,
                    'recordId': doc.id,
                    'recordName': name,
                    'category': category,
                    'branchId': branchId ?? targetId,
                    'status': 'unpaid',
                  });

                  // Log activity
                  final activityRef = firestore
                      .collection('users')
                      .doc(targetId)
                      .collection('recentActivity')
                      .doc();
                  batch.set(activityRef, {
                    'title': 'Extra Fee Added',
                    'details':
                        '$name\n${descriptionController.text.trim()}: Rs. ${amount.toStringAsFixed(0)}',
                    'timestamp': FieldValue.serverTimestamp(),
                    'type': 'addition',
                    'recordId': doc.id,
                    'imageUrl': data['image'],
                    'branchId': branchId ?? targetId,
                  });

                  await batch.commit();

                  // Sync extra fee statuses based on new balance
                  final finalBatch = firestore.batch();
                  await _syncExtraFeeStatuses(
                    docRef: doc.reference,
                    batch: finalBatch,
                  );
                  await finalBatch.commit();
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Extra fee added successfully')));
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
      ),
    );
  }

  static Future<void> showEditExtraFeeDialog({
    required BuildContext context,
    required DocumentReference docRef,
    required DocumentSnapshot feeDoc,
    required String targetId,
    required String category,
    String? branchId,
  }) async {
    final feeData = feeDoc.data() as Map<String, dynamic>;
    final oldAmount =
        double.tryParse(feeData['amount']?.toString() ?? '0') ?? 0;
    final oldNote = feeData['note']?.toString() ?? '';
    final oldDescription = feeData['description']?.toString() ?? 'Exam Failed';
    final oldDate = (feeData['date'] as Timestamp?)?.toDate() ?? DateTime.now();

    final amountController =
        TextEditingController(text: oldAmount.toStringAsFixed(0));
    final descriptionController = TextEditingController(text: oldDescription);
    final noteController = TextEditingController(text: oldNote);
    DateTime selectedDate = oldDate;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(oldDate);

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Extra Fee'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Fee Type'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Amount (Rs.)'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(
                            DateFormat('dd MMM yyyy').format(selectedDate)),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setDialogState(() => selectedDate = date);
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.access_time, size: 18),
                        label: Text(selectedTime.format(context)),
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                          );
                          if (time != null) {
                            setDialogState(() => selectedTime = time);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                      labelText: 'Note / Remarks (Optional)'),
                  maxLines: 2,
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
                final newAmount = double.tryParse(amountController.text.trim());
                if (newAmount == null || newAmount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enter valid amount')));
                  return;
                }

                final combinedDateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );

                try {
                  final firestore = FirebaseFirestore.instance;
                  final batch = firestore.batch();

                  final parentDoc = await docRef.get();
                  if (!parentDoc.exists) throw 'Parent record not found';

                  final parentData = parentDoc.data() as Map<String, dynamic>;
                  final currentTotal = double.tryParse(
                          parentData['totalAmount']?.toString() ?? '0') ??
                      0.0;
                  final currentBalance = double.tryParse(
                          parentData['balanceAmount']?.toString() ?? '0') ??
                      0.0;

                  // Adjust totalAmount and balanceAmount by the diff
                  final amountDiff = newAmount - oldAmount;

                  batch.update(docRef, {
                    'totalAmount': currentTotal + amountDiff,
                    'balanceAmount': currentBalance + amountDiff,
                  });

                  batch.update(feeDoc.reference, {
                    'amount': newAmount,
                    'description': descriptionController.text.trim(),
                    'date': Timestamp.fromDate(combinedDateTime),
                    'note': noteController.text.trim(),
                    'lastUpdated': FieldValue.serverTimestamp(),
                  });

                  // Log activity
                  final activityRef = firestore
                      .collection('users')
                      .doc(targetId)
                      .collection('recentActivity')
                      .doc();
                  batch.set(activityRef, {
                    'title': 'Extra Fee Edited',
                    'details':
                        '${parentData['fullName'] ?? parentData['vehicleNumber'] ?? 'N/A'}\nUpdated to Rs. ${newAmount.toStringAsFixed(0)}',
                    'timestamp': FieldValue.serverTimestamp(),
                    'type': 'edit',
                    'recordId': parentDoc.id,
                    'imageUrl': parentData['image'],
                    'branchId': branchId ?? targetId,
                  });

                  await batch.commit();

                  // Sync extra fee statuses based on new balance
                  final finalBatch = firestore.batch();
                  await _syncExtraFeeStatuses(
                    docRef: docRef,
                    batch: finalBatch,
                  );
                  await finalBatch.commit();

                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Extra fee updated successfully')));
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

  static Future<void> showCollectExtraFeeDialog({
    required BuildContext context,
    required DocumentReference docRef,
    required DocumentSnapshot feeDoc,
    required String targetId,
    String? branchId,
  }) async {
    final feeData = feeDoc.data() as Map<String, dynamic>;
    final feeAmount =
        double.tryParse(feeData['amount']?.toString() ?? '0') ?? 0.0;
    final feeDescription = feeData['description']?.toString() ?? '';

    final paymentModes = [
      'Cash',
      'GPay',
      'PhonePe',
      'Paytm',
      'Bank Transfer',
      'Other'
    ];
    String selectedMode = 'Cash';
    final noteController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    bool generateReceipt = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Collect: $feeDescription'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Amount: Rs. ${feeAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedMode,
                  decoration: const InputDecoration(labelText: 'Payment Mode'),
                  items: paymentModes
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (val) => setDialogState(() => selectedMode = val!),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(
                            DateFormat('dd MMM yyyy').format(selectedDate)),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setDialogState(() => selectedDate = date);
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.access_time, size: 18),
                        label: Text(selectedTime.format(ctx)),
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                          );
                          if (time != null) {
                            setDialogState(() => selectedTime = time);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  decoration:
                      const InputDecoration(labelText: 'Note (Optional)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text('Generate Receipt',
                      style: TextStyle(fontSize: 14)),
                  value: generateReceipt,
                  dense: true,
                  onChanged: (val) =>
                      setDialogState(() => generateReceipt = val!),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
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
                final combinedDateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );

                try {
                  final firestore = FirebaseFirestore.instance;
                  final batch = firestore.batch();

                  final parentDoc = await docRef.get();
                  if (!parentDoc.exists) throw 'Parent record not found';
                  final parentData = parentDoc.data() as Map<String, dynamic>;

                  final currentBalance = double.tryParse(
                          parentData['balanceAmount']?.toString() ?? '0') ??
                      0.0;

                  // Reduce balance
                  batch.update(docRef, {
                    'balanceAmount': currentBalance - feeAmount,
                    'lastPaymentUpdate': FieldValue.serverTimestamp(),
                  });

                  // Mark fee as paid
                  batch.update(feeDoc.reference, {
                    'status': 'paid',
                    'collectedAt': FieldValue.serverTimestamp(),
                    'paymentMode': selectedMode,
                    'paymentDate': Timestamp.fromDate(combinedDateTime),
                    'paymentNote': noteController.text.trim(),
                  });

                  // Log activity
                  final activityRef = firestore
                      .collection('users')
                      .doc(targetId)
                      .collection('recentActivity')
                      .doc();
                  batch.set(activityRef, {
                    'title': 'Extra Fee Collected',
                    'details':
                        '${parentData['fullName'] ?? parentData['vehicleNumber'] ?? 'N/A'}\n$feeDescription: Rs. ${feeAmount.toStringAsFixed(0)}',
                    'timestamp': FieldValue.serverTimestamp(),
                    'type': 'payment',
                    'recordId': parentDoc.id,
                    'imageUrl': parentData['image'],
                    'branchId': branchId ?? targetId,
                  });

                  await batch.commit();

                  if (generateReceipt && context.mounted) {
                    try {
                      final companySnap = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(targetId)
                          .get();
                      final companyData = companySnap.data() ?? {};

                      final txData = {
                        'amount': feeAmount,
                        'description': feeDescription,
                        'mode': selectedMode,
                        'date': combinedDateTime,
                        'note': noteController.text.trim(),
                      };

                      final Uint8List pdfBytes =
                          await PdfService.generateReceipt(
                        companyData: companyData,
                        studentDetails: parentData,
                        transactions: [txData],
                      );

                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PdfPreviewScreen(
                              pdfBytes: pdfBytes,
                              fileName:
                                  'Receipt_${parentData['fullName'] ?? 'User'}.pdf',
                            ),
                          ),
                        );
                      }
                    } catch (pdfError) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Error generating PDF: $pdfError')),
                        );
                      }
                    }
                  }

                  if (context.mounted) {
                    if (!generateReceipt) {
                      Navigator.pop(ctx);
                    }
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Fee collected successfully')));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
              child:
                  const Text('Collect', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> deleteExtraFee({
    required BuildContext context,
    required DocumentReference docRef,
    required DocumentSnapshot feeDoc,
    required String targetId,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Extra Fee'),
        content: const Text(
            'Are you sure you want to delete this extra fee? The total amount and balance will be reduced.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      final feeData = feeDoc.data() as Map<String, dynamic>;
      final amount =
          double.tryParse(feeData['amount']?.toString() ?? '0') ?? 0.0;

      final parentDoc = await docRef.get();
      if (!parentDoc.exists) throw 'Parent record not found';
      final parentData = parentDoc.data() as Map<String, dynamic>;

      final currentTotal =
          double.tryParse(parentData['totalAmount']?.toString() ?? '0') ?? 0.0;
      final currentBalance =
          double.tryParse(parentData['balanceAmount']?.toString() ?? '0') ??
              0.0;
      final currentAdvance =
          double.tryParse(parentData['advanceAmount']?.toString() ?? '0') ??
              0.0;

      final isPaid = feeData['status'] == 'paid';
      final newTotal = currentTotal - amount;
      final updateData = <String, dynamic>{
        'totalAmount': newTotal,
      };

      if (isPaid) {
        // If fee was paid, reduce the advance amount and recalculate balance
        final newAdvance = currentAdvance - amount;
        updateData['advanceAmount'] = newAdvance;
        updateData['balanceAmount'] = newTotal - newAdvance;
      } else {
        // If fee was unpaid, reduce the balance
        updateData['balanceAmount'] = currentBalance - amount;
      }

      batch.update(docRef, updateData);

      batch.delete(feeDoc.reference);

      // Add to recent activity
      final activityRef = firestore
          .collection('users')
          .doc(targetId)
          .collection('recentActivity')
          .doc();
      batch.set(activityRef, {
        'title': 'Extra Fee Deleted',
        'details':
            '${parentData['fullName'] ?? parentData['vehicleNumber'] ?? 'N/A'}\nAmount: Rs. ${amount.toStringAsFixed(0)}',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'deletion',
        'recordId': parentDoc.id,
        'imageUrl': parentData['image'],
        'branchId': targetId,
      });

      await batch.commit();

      // Sync extra fee statuses based on new balance
      final finalBatch = firestore.batch();
      await _syncExtraFeeStatuses(
        docRef: docRef,
        batch: finalBatch,
      );
      await finalBatch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Extra fee deleted successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting extra fee: $e')),
        );
      }
    }
  }

  static Future<void> _syncExtraFeeStatuses({
    required DocumentReference docRef,
    required WriteBatch batch,
  }) async {
    final parentDoc = await docRef.get();
    if (!parentDoc.exists) return;

    final parentData = parentDoc.data() as Map<String, dynamic>;
    final totalAmount =
        double.tryParse(parentData['totalAmount']?.toString() ?? '0') ?? 0.0;
    final balanceAmount =
        double.tryParse(parentData['balanceAmount']?.toString() ?? '0') ?? 0.0;
    final totalPaid = (totalAmount - balanceAmount).clamp(0.0, double.infinity);

    final feesSnapshot = await docRef
        .collection('extra_fees')
        .orderBy('date', descending: false)
        .get();

    double totalExtraFees = 0;
    for (var doc in feesSnapshot.docs) {
      totalExtraFees +=
          double.tryParse(doc.data()['amount']?.toString() ?? '0') ?? 0.0;
    }

    final baseFee = totalAmount - totalExtraFees;
    double availableForExtra =
        (totalPaid - baseFee).clamp(0.0, double.infinity);

    for (var doc in feesSnapshot.docs) {
      final feeAmount =
          double.tryParse(doc.data()['amount']?.toString() ?? '0') ?? 0.0;
      final currentStatus = doc.data()['status']?.toString() ?? 'unpaid';

      if (availableForExtra >= feeAmount) {
        if (currentStatus != 'paid') {
          batch.update(doc.reference, {'status': 'paid'});
        }
        availableForExtra -= feeAmount;
      } else {
        if (currentStatus != 'unpaid') {
          batch.update(doc.reference, {'status': 'unpaid'});
        }
      }
    }
  }

  static void _showPaymentCompletedDialog(
    BuildContext context,
    DocumentSnapshot doc,
    String targetId,
    String? branchId,
    String category,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Payment Completed'),
        content: const Text(
            'This student has no outstanding balance. To accept more money, please add an "Additional Fee".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              showAddExtraFeeDialog(
                context: context,
                doc: doc as DocumentSnapshot<Map<String, dynamic>>,
                targetId: targetId,
                category: category,
                branchId: branchId,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
            child: const Text('Add Extra Fee',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
} // End of PaymentUtils class
