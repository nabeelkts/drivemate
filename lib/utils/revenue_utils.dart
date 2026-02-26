import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RevenueUtils {
  /// Calculates monthly revenue and returns a map of MM/yy -> amount.
  /// Uses a unified transaction extractor to ensure all pages show exactly the same data.
  static Map<String, dynamic> calculateMonthlyRevenue({
    required List<QuerySnapshot<Map<String, dynamic>>> snapshots,
    required DateTime selectedDate,
    required List<DateTime> months,
  }) {
    final Map<String, double> revenueByMonth = {};
    for (var month in months) {
      String key = DateFormat('MM/yy').format(month);
      revenueByMonth[key] = 0;
    }

    // Rely on the robust getTransactionsFromSnapshots to extract ALL transactions
    // with 'All' filter to get global transaction history for requested snapshots.
    final allTransactions = getTransactionsFromSnapshots(
      snapshots: snapshots,
      selectedDate: selectedDate,
      filter: 'All',
    );

    // Populate revenueByMonth
    for (var t in allTransactions) {
      final d = t['date'] as DateTime;
      for (var month in months) {
        if (d.year == month.year && d.month == month.month) {
          String key = DateFormat('MM/yy').format(month);
          revenueByMonth[key] =
              (revenueByMonth[key] ?? 0) + (t['amount'] as double);
        }
      }
    }

    final String selectedKey = DateFormat('MM/yy').format(selectedDate);
    final double currentMonthRevenue = revenueByMonth[selectedKey] ?? 0;

    return {
      'revenueByMonth': revenueByMonth,
      'currentMonthRevenue': currentMonthRevenue,
    };
  }

  /// Extracts transaction list for the Revenue Details sheet.
  /// Also serves as the unified engine for chart calculation.
  static List<Map<String, dynamic>> getTransactionsFromSnapshots({
    required List<QuerySnapshot<Map<String, dynamic>>> snapshots,
    required DateTime selectedDate,
    String filter = 'Month',
  }) {
    final List<Map<String, dynamic>> transactions = [];
    final Set<String> countedPayments = {};

    // 1. Process Main Records (Installments) FIRST
    final revIndices = [0, 1, 2, 3, 5];
    final collections = [
      'students',
      'licenseonly',
      'endorsement',
      'vehicleDetails',
      'expenses',
      'dl_services',
      'payments'
    ];

    for (var idx in revIndices) {
      if (snapshots.length > idx) {
        final source = collections[idx];
        for (var doc in snapshots[idx].docs) {
          final data = doc.data();
          final name = data['fullName'] ?? data['vehicleNumber'] ?? 'N/A';
          final id = doc.id;

          _addInstallment(transactions, data, id, name, source, 'advanceAmount',
              'registrationDate', 'Advance', countedPayments);
          _addInstallment(
              transactions,
              data,
              id,
              name,
              source,
              'secondInstallment',
              'secondInstallmentTime',
              'Installment 2',
              countedPayments);
          _addInstallment(
              transactions,
              data,
              id,
              name,
              source,
              'thirdInstallment',
              'thirdInstallmentTime',
              'Installment 3',
              countedPayments);

          // Numbered installments
          for (int i = 4; i <= 20; i++) {
            _addInstallment(
                transactions,
                data,
                id,
                name,
                source,
                'installment$i',
                'installment${i}Time',
                'Installment $i',
                countedPayments);
          }
        }
      }
    }

    // 2. Process Individual Payments Subcollections
    if (snapshots.length > 6) {
      for (var doc in snapshots[6].docs) {
        final data = doc.data();
        double amount = double.tryParse(data['amountPaid']?.toString() ??
                data['amount']?.toString() ??
                '0') ??
            0;

        if (amount <= 0) continue;

        DateTime? date = _parseDate(data['date'] ?? data['createdAt']);
        if (date == null) continue;

        String recordId = data['recordId'] ?? '';
        if (recordId.isEmpty) {
          final parentPath = doc.reference.parent.parent?.path ?? '';
          final parts = parentPath.split('/');
          if (parts.isNotEmpty) recordId = parts.last;
        }

        final dateStr = date.toIso8601String().substring(0, 10);
        String description = data['description']?.toString() ?? '';

        String dedupKey;
        if (description.isEmpty || description == 'Payment') {
          // Fallback for very old loose logic: use generic key
          // NOTE: this may still collide but guarantees safety for untagged legacy docs.
          dedupKey = '${recordId}_${amount.toStringAsFixed(2)}_$dateStr';
        } else if (description == 'Additional Fee') {
          // Extra fees MUST NOT be deduplicated against main records
          // Append document ID to guarantee uniqueness for multiple same-day extra fees
          dedupKey =
              'extra_${doc.id}_${recordId}_${amount.toStringAsFixed(2)}_$dateStr';
        } else {
          // For standard labeled installments ('Advance', 'Installment 2', etc.):
          // Match exactly against the label we used in _addInstallment
          dedupKey =
              '${recordId}_${amount.toStringAsFixed(2)}_${dateStr}_$description';
        }

        if (!countedPayments.contains(dedupKey)) {
          transactions.add({
            'name': data['recordName'] ?? 'N/A',
            'amount': amount,
            'date': date,
            'label': description.isNotEmpty ? description : 'Payment',
            'source': data['category'] ?? 'payments',
            'id': recordId,
            'data': data,
          });
          countedPayments.add(dedupKey);
        }
      }
    }

    transactions.sort(
        (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    // Filter by selectedDate and filter mode
    if (filter == 'All') return transactions;

    return transactions.where((t) {
      final d = t['date'] as DateTime;
      if (filter == 'Day') {
        return d.year == selectedDate.year &&
            d.month == selectedDate.month &&
            d.day == selectedDate.day;
      }
      if (filter == 'Month') {
        return d.year == selectedDate.year && d.month == selectedDate.month;
      }
      if (filter == 'Year') {
        return d.year == selectedDate.year;
      }
      return true;
    }).toList();
  }

  static void _addInstallment(
    List<Map<String, dynamic>> transactions,
    Map<String, dynamic> data,
    String id,
    String name,
    String source,
    String amountField,
    String timeField,
    String label,
    Set<String> countedPayments,
  ) {
    double amount = double.tryParse(data[amountField]?.toString() ?? '0') ?? 0;
    if (amount <= 0) return;

    DateTime? date = _parseDate(data[timeField]);
    if (date == null) return;

    final dateStr = date.toIso8601String().substring(0, 10);
    // Build an exact DedupKey inclusive of label to prevent multi-installment same-day collision
    String dedupKey = '${id}_${amount.toStringAsFixed(2)}_${dateStr}_$label';

    if (!countedPayments.contains(dedupKey)) {
      transactions.add({
        'name': name,
        'amount': amount,
        'date': date,
        'label': label,
        'source': source,
        'id': id,
        'data': data,
      });
      countedPayments.add(dedupKey);
    }
  }

  static DateTime? _parseDate(dynamic dateData) {
    if (dateData == null) return null;
    if (dateData is Timestamp) return dateData.toDate();
    if (dateData is String) return DateTime.tryParse(dateData);
    return null;
  }
}
