import 'dart:async';
import 'package:async/async.dart' hide StreamGroup;
import 'package:get/get.dart';
import 'package:mds/controller/workspace_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/screens/dashboard/list/details/endorsement_details_page.dart';
import 'package:mds/screens/dashboard/list/details/license_only_details_page.dart';
import 'package:mds/screens/dashboard/list/details/rc_details_page.dart';
import 'package:mds/screens/dashboard/list/details/students_details_page.dart';
import 'package:mds/screens/accounts/daily_ledger_page.dart';
import 'package:mds/screens/dashboard/widgets/custom/custom_text.dart';
import 'package:mds/screens/statistics/receive_money.dart';
import 'package:mds/screens/accounts/add_expense_screen.dart';
import 'package:shimmer/shimmer.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

import 'package:mds/models/transaction_data.dart';
import 'package:mds/utils/stream_utils.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? user = FirebaseAuth.instance.currentUser;
  DateTime selectedDate = DateTime.now();
  DateTime? startDate;
  DateTime? endDate;
  String selectedFilter = 'All'; // Default to All
  String selectedPeriod = 'This Month'; // Default to This Month
  List<String> filterOptions = [
    'All',
    'Students',
    'License',
    'Endorsement',
    'Vehicle'
  ];
  List<String> periodOptions = [
    'Today',
    'This Month',
    'Last Month',
    'Last 6 Months',
    'This Year',
    'Custom Range'
  ];
  final ValueNotifier<List<TransactionData>> _filteredTransactionsNotifier =
      ValueNotifier<List<TransactionData>>([]);
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<TransactionData> _allTransactions = [];

  List<TransactionData> get filteredTransactions =>
      _filteredTransactionsNotifier.value;

  @override
  void initState() {
    super.initState();
    _setInitialPeriod();
  }

  void _setInitialPeriod() {
    final now = DateTime.now();
    startDate = DateTime(now.year, now.month, 1);
    endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  }

  void _showPeriodSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Period',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...periodOptions.map((period) => ListTile(
                    title: Text(period),
                    trailing: selectedPeriod == period
                        ? const Icon(Icons.check, color: Colors.blue)
                        : null,
                    onTap: () async {
                      setState(() {
                        selectedPeriod = period;
                      });

                      // Set date range based on selected period
                      final now = DateTime.now();
                      switch (period) {
                        case 'Today':
                          startDate = DateTime(now.year, now.month, now.day);
                          endDate = DateTime(
                              now.year, now.month, now.day, 23, 59, 59);
                          break;
                        case 'This Month':
                          startDate = DateTime(now.year, now.month, 1);
                          endDate =
                              DateTime(now.year, now.month + 1, 0, 23, 59, 59);
                          break;
                        case 'Last Month':
                          startDate = DateTime(now.year, now.month - 1, 1);
                          endDate =
                              DateTime(now.year, now.month, 0, 23, 59, 59);
                          break;
                        case 'Last 6 Months':
                          startDate = DateTime(now.year, now.month - 6, 1);
                          endDate =
                              DateTime(now.year, now.month + 1, 0, 23, 59, 59);
                          break;
                        case 'This Year':
                          startDate = DateTime(now.year, 1, 1);
                          endDate = DateTime(now.year, 12, 31, 23, 59, 59);
                          break;
                        case 'Custom Range':
                          final DateTimeRange? picked =
                              await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                            initialDateRange: DateTimeRange(
                              start: startDate ??
                                  DateTime.now()
                                      .subtract(const Duration(days: 7)),
                              end: endDate ?? DateTime.now(),
                            ),
                          );
                          if (picked != null) {
                            startDate = DateTime(picked.start.year,
                                picked.start.month, picked.start.day);
                            endDate = DateTime(picked.end.year,
                                picked.end.month, picked.end.day, 23, 59, 59);
                          }
                          break;
                      }
                      Navigator.pop(context);
                    },
                  )),
            ],
          ),
        );
      },
    );
  }

  void _updateFilteredTransactions(List<TransactionData> transactions) {
    // Filter transactions by date range
    if (startDate != null && endDate != null) {
      transactions = transactions.where((transaction) {
        // Skip transactions with invalid dates (1970 or future dates)
        if (transaction.date.year < 2000 ||
            transaction.date.year > DateTime.now().year) {
          return false;
        }

        // Convert dates to start of day for comparison
        final transactionDate = DateTime(
          transaction.date.year,
          transaction.date.month,
          transaction.date.day,
        );

        final startOfRange = DateTime(
          startDate!.year,
          startDate!.month,
          startDate!.day,
        );

        final endOfRange = DateTime(
          endDate!.year,
          endDate!.month,
          endDate!.day,
          23,
          59,
          59,
        );

        return transactionDate
                .isAfter(startOfRange.subtract(const Duration(days: 1))) &&
            transactionDate.isBefore(endOfRange.add(const Duration(days: 1)));
      }).toList();
    }

    // Filter by type if needed
    if (selectedFilter != 'All') {
      transactions = transactions.where((transaction) {
        switch (selectedFilter) {
          case 'Students':
            return transaction.collectionId == 'students';
          case 'License':
            return transaction.collectionId == 'licenseonly';
          case 'Endorsement':
            return transaction.collectionId == 'endorsement';
          case 'Vehicle':
            return transaction.collectionId == 'vehicleDetails';
          default:
            return true;
        }
      }).toList();
    }

    // Apply search filter
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      transactions = transactions.where((t) {
        final nameMatch = t.name.toLowerCase().contains(q);
        final typeMatch = t.type.toLowerCase().contains(q);
        final collectionMatch =
            getCollectionDisplayName(t.collectionId).toLowerCase().contains(q);
        final amountMatch = t.amount.toString().toLowerCase().contains(q);
        return nameMatch || typeMatch || collectionMatch || amountMatch;
      }).toList();
    }

    // Sort transactions by date in descending order (newest first)
    transactions.sort((a, b) => b.date.compareTo(a.date));

    _filteredTransactionsNotifier.value = transactions;
  }

  @override
  void dispose() {
    _filteredTransactionsNotifier.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Stream<List<QuerySnapshot<Map<String, dynamic>>>>
      _getCombinedTransactionsStream(String targetId) {
    final streams = [
      _firestore
          .collection('users')
          .doc(targetId)
          .collection('students')
          .snapshots(),
      _firestore
          .collection('users')
          .doc(targetId)
          .collection('licenseonly')
          .snapshots(),
      _firestore
          .collection('users')
          .doc(targetId)
          .collection('endorsement')
          .snapshots(),
      _firestore
          .collection('users')
          .doc(targetId)
          .collection('vehicleDetails')
          .snapshots(),
      _firestore
          .collection('users')
          .doc(targetId)
          .collection('expenses')
          .snapshots(),
      _firestore
          .collection('users')
          .doc(targetId)
          .collection('dl_services')
          .snapshots(),
      _firestore
          .collectionGroup('payments')
          .where('targetId', isEqualTo: targetId)
          .snapshots(),
    ];

    return StreamUtils.combineLatest(streams).asBroadcastStream();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final cardColor = isDark ? Colors.grey.shade900 : Colors.grey.shade100;
    final borderColor = isDark ? Colors.grey.shade600 : Colors.grey.shade400;
    return SafeArea(
      child: Scaffold(
        backgroundColor: isDark ? Colors.black : Colors.grey.shade200,
        appBar: AppBar(
          backgroundColor: isDark ? Colors.black : Colors.white,
          elevation: 0,
          title: Text(
            'Accounts',
            style: TextStyle(
                color: textColor, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: StreamBuilder<List<QuerySnapshot<Map<String, dynamic>>>>(
                  // Use combined stream to ensure real-time updates from ANY collection
                  stream: _getCombinedTransactionsStream(
                      Get.find<WorkspaceController>()
                              .currentSchoolId
                              .value
                              .isNotEmpty
                          ? Get.find<WorkspaceController>()
                              .currentSchoolId
                              .value
                          : (user?.uid ?? '')),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                          child: Text('Error loading transactions'));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return buildShimmerTransactions();
                    }

                    final dataList = snapshot.data ?? [];
                    List<TransactionData> transactions = [];

                    // 1. Process main collections (indices 0, 1, 2, 3, 5)
                    final mainIndices = [0, 1, 2, 3, 5];
                    for (var idx in mainIndices) {
                      if (dataList.length > idx) {
                        for (var doc in dataList[idx].docs) {
                          final data = doc.data();
                          final collectionId = doc.reference.parent.id;

                          double adv = double.tryParse(
                                  data['advanceAmount']?.toString() ?? '0') ??
                              0.0;
                          double sInst = double.tryParse(
                                  data['secondInstallment']?.toString() ??
                                      '0') ??
                              0.0;
                          double tInst = double.tryParse(
                                  data['thirdInstallment']?.toString() ??
                                      '0') ??
                              0.0;

                          String name = collectionId == 'vehicleDetails'
                              ? data['vehicleNumber'] ?? 'N/A'
                              : data['fullName'] ?? 'N/A';

                          String? img = (collectionId == 'vehicleDetails')
                              ? (data['rcImage'] ?? data['image'] ?? '')
                              : (data['photo'] ?? data['image'] ?? '');

                          DateTime regDate =
                              _safeParseGenericDate(data['registrationDate']);
                          DateTime sDate = _safeParseGenericDate(
                              data['secondInstallmentTime']);
                          DateTime tDate = _safeParseGenericDate(
                              data['thirdInstallmentTime']);

                          if (adv > 0 && regDate.year >= 2000) {
                            transactions.add(TransactionData(
                              date: regDate,
                              name: name,
                              amount: adv,
                              type: 'Advance',
                              collectionId: collectionId,
                              doc: doc,
                              imageUrl: img,
                              note: data['note'] ?? data['description'],
                            ));
                          }
                          if (sInst > 0 && sDate.year >= 2000) {
                            transactions.add(TransactionData(
                              date: sDate,
                              name: name,
                              amount: sInst,
                              type: 'Second Installment',
                              collectionId: collectionId,
                              doc: doc,
                              imageUrl: img,
                              note: data['note'] ?? data['description'],
                            ));
                          }
                          if (tInst > 0 && tDate.year >= 2000) {
                            transactions.add(TransactionData(
                              date: tDate,
                              name: name,
                              amount: tInst,
                              type: 'Third Installment',
                              collectionId: collectionId,
                              doc: doc,
                              imageUrl: img,
                              note: data['note'] ?? data['description'],
                            ));
                          }
                        }
                      }
                    }

                    // 2. Process Expenses (index 4)
                    if (dataList.length > 4) {
                      for (var doc in dataList[4].docs) {
                        final data = doc.data();
                        DateTime date = _safeParseGenericDate(
                            data['date'] ?? data['timestamp']);

                        transactions.add(TransactionData(
                          date: date,
                          name: data['categoryLabel'] ??
                              data['category'] ??
                              'Expense',
                          amount: double.tryParse(
                                  data['amount']?.toString() ?? '0') ??
                              0.0,
                          type: 'Expense',
                          collectionId: 'expenses',
                          doc: doc,
                          isExpense: true,
                          note: data['note'] ?? data['description'],
                        ));
                      }
                    }

                    // 3. Process Payments (index 6)
                    if (dataList.length > 6) {
                      for (var doc in dataList[6].docs) {
                        final data = doc.data();
                        DateTime date = _safeParseGenericDate(
                            data['date'] ?? data['createdAt']);
                        double amt = double.tryParse(
                                data['amountPaid']?.toString() ??
                                    data['amount']?.toString() ??
                                    '0') ??
                            0.0;

                        if (amt > 0) {
                          // Check for double counting
                          // A record is a duplicate if its date (day-wise), amount, and recordName match
                          // an existing registration (Advance/Installment) record.
                          bool duplicate = transactions.any((t) =>
                              t.name == (data['recordName'] ?? '') &&
                              (t.amount - amt).abs() < 0.01 &&
                              t.date.year == date.year &&
                              t.date.month == date.month &&
                              t.date.day == date.day);

                          if (!duplicate) {
                            transactions.add(TransactionData(
                              date: date,
                              name: data['recordName'] ?? 'Payment',
                              amount: amt,
                              type: data['description'] ?? 'Payment',
                              collectionId: data['category'] ?? 'payments',
                              doc: doc,
                              note: data['description'] ?? data['note'],
                            ));
                          }
                        }
                      }
                    }

                    // Store all for DailyLedger
                    _allTransactions = transactions;

                    // FILTERING LOGIC
                    List<TransactionData> filtered = List.from(transactions);

                    // Date Filter
                    if (startDate != null && endDate != null) {
                      filtered = filtered.where((t) {
                        final d =
                            DateTime(t.date.year, t.date.month, t.date.day);
                        final s = DateTime(
                            startDate!.year, startDate!.month, startDate!.day);
                        final e = DateTime(endDate!.year, endDate!.month,
                            endDate!.day, 23, 59, 59);
                        return d.isAfter(
                                s.subtract(const Duration(seconds: 1))) &&
                            d.isBefore(e.add(const Duration(seconds: 1)));
                      }).toList();
                    }

                    // Category Filter
                    if (selectedFilter != 'All') {
                      filtered = filtered.where((t) {
                        switch (selectedFilter) {
                          case 'Students':
                            return t.collectionId == 'students';
                          case 'License':
                            return t.collectionId == 'licenseonly';
                          case 'Endorsement':
                            return t.collectionId == 'endorsement';
                          case 'Vehicle':
                            return t.collectionId == 'vehicleDetails';
                          default:
                            return true;
                        }
                      }).toList();
                    }

                    // Search Filter
                    if (_searchQuery.trim().isNotEmpty) {
                      final q = _searchQuery.trim().toLowerCase();
                      filtered = filtered.where((t) {
                        return t.name.toLowerCase().contains(q) ||
                            t.type.toLowerCase().contains(q) ||
                            t.amount.toString().contains(q);
                      }).toList();
                    }

                    // Sort
                    filtered.sort((a, b) => b.date.compareTo(a.date));

                    // Period Totals (Dynamic based on filter)
                    double tIncome = filtered
                        .where((t) => !t.isExpense)
                        .fold(0.0, (sum, t) => sum + t.amount);
                    double tExpense = filtered
                        .where((t) => t.isExpense)
                        .fold(0.0, (sum, t) => sum + t.amount);
                    double tNet = tIncome - tExpense;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (c) => DailyLedgerPage(
                                        date: DateTime.now(),
                                        allTransactions: _allTransactions,
                                      ))),
                          child: _buildFinancialSummaryCard(
                              cardColor, borderColor, textColor, tNet),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                                child: _buildActionButton(
                                    'Add Income', Colors.green, () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (c) => ReceiveMoneyPage()));
                            })),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _buildActionButton(
                                    'Add Expense', Colors.red.shade700, () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (c) =>
                                          const AddExpenseScreen()));
                            })),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildSearchBar(cardColor, borderColor, textColor),
                        const SizedBox(height: 12),
                        Text('Transactions History',
                            style: TextStyle(
                                color: textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Expanded(
                          child: filtered.isEmpty
                              ? const Center(
                                  child: Text('No transactions found'))
                              : ListView.builder(
                                  itemCount: filtered.length,
                                  itemBuilder: (context, index) {
                                    final t = filtered[index];
                                    return buildTransactionRow(
                                      context,
                                      t,
                                      DateFormat('dd/MM/yyyy hh:mm a')
                                          .format(t.date),
                                      t.type,
                                      cardColor,
                                      borderColor,
                                      textColor,
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

  Widget _buildFinancialSummaryCard(
      Color cardColor, Color borderColor, Color textColor, double netBalance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Financial Overview',
                style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              Icon(Icons.arrow_forward_ios,
                  color: textColor.withOpacity(0.5), size: 14),
            ],
          ),
          const SizedBox(height: 8),
          Text('Net Balance:',
              style:
                  TextStyle(color: textColor.withOpacity(0.9), fontSize: 14)),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'Rs. ${NumberFormat('#,##0').format(netBalance)}',
                style: TextStyle(
                    color: netBalance >= 0 ? Colors.green : Colors.red,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Icon(
                netBalance >= 0 ? Icons.show_chart : Icons.trending_down,
                color: netBalance >= 0 ? Colors.green : Colors.red,
                size: 28,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _buildSearchBar(Color cardColor, Color borderColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: textColor.withOpacity(0.7), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                _searchQuery = value;
                _updateFilteredTransactions(_allTransactions);
              },
              style: TextStyle(color: textColor, fontSize: 16),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search',
                hintStyle:
                    TextStyle(color: textColor.withOpacity(0.5), fontSize: 16),
                border: InputBorder.none,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (ctx) => Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Filter',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor)),
                      const SizedBox(height: 16),
                      ...filterOptions.map((f) => ListTile(
                            title: Text(f),
                            trailing: selectedFilter == f
                                ? const Icon(Icons.check, color: Colors.green)
                                : null,
                            onTap: () {
                              setState(() => selectedFilter = f);
                              Navigator.pop(ctx);
                              _updateFilteredTransactions(_allTransactions);
                            },
                          )),
                    ],
                  ),
                ),
              );
            },
            child: Icon(Icons.filter_list,
                color: textColor.withOpacity(0.7), size: 22),
          ),
        ],
      ),
    );
  }

  Widget buildTransactionRow(
    BuildContext context,
    TransactionData transaction,
    String dateTime,
    String transactionType,
    Color cardColor,
    Color borderColor,
    Color textColor,
  ) {
    // Get initials based on collection type
    String getInitials() {
      if (transaction.collectionId == 'vehicleDetails') {
        // For vehicle details, show last 4 digits of vehicle number
        final vehicleNumber = transaction.name;
        if (vehicleNumber.length >= 4) {
          return vehicleNumber.substring(vehicleNumber.length - 4);
        }
        return vehicleNumber;
      }
      // For other collections, show first letter of name
      return transaction.name.isNotEmpty
          ? transaction.name[0].toUpperCase()
          : '?';
    }

    return GestureDetector(
      onTap: () {
        // Determine the collection and navigate to the appropriate details page
        if (transaction.collectionId == 'licenseonly') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LicenseOnlyDetailsPage(
                  licenseDetails: transaction.doc.data()!),
            ),
          );
        } else if (transaction.collectionId == 'endorsement') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EndorsementDetailsPage(
                  endorsementDetails: transaction.doc.data()!),
            ),
          );
        } else if (transaction.collectionId == 'vehicleDetails') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  RCDetailsPage(vehicleDetails: transaction.doc.data()!),
            ),
          );
        } else if (transaction.collectionId == 'students') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  StudentDetailsPage(studentDetails: transaction.doc.data()!),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              margin: const EdgeInsets.only(left: 0),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(12)),
              ),
            ),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green.withOpacity(0.2),
                      ),
                      child: (() {
                        final img = transaction.imageUrl;
                        final hasImg = img is String && img.trim().isNotEmpty;
                        if (hasImg) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: Image.network(
                              img,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Center(
                                child: Text(
                                  getInitials(),
                                  style: TextStyle(
                                    fontSize: transaction.collectionId ==
                                            'vehicleDetails'
                                        ? 14
                                        : 20,
                                    color: kPrimaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                        return Center(
                          child: Icon(
                            Icons.school_outlined,
                            color: Colors.green.shade700,
                            size: 24,
                          ),
                        );
                      })(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${transaction.name} - $transactionType',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Rs. ${transaction.amount.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DateTime _safeParseGenericDate(dynamic value) {
    if (value == null) return DateTime.fromMillisecondsSinceEpoch(0);
    if (value is Timestamp) return value.toDate();
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.fromMillisecondsSinceEpoch(0);
      }
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  Widget buildShimmerTransactions() {
    return ListView.separated(
      itemCount: 8,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }
}
