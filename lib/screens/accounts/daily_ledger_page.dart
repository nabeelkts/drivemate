import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/controller/workspace_controller.dart';
import 'package:mds/services/ledger_pdf_service.dart';
import 'package:mds/utils/loading_utils.dart';
import 'package:mds/models/transaction_data.dart';
import 'accounts_screen.dart';
import 'package:flutter/foundation.dart';

class DailyLedgerPage extends StatefulWidget {
  final DateTime date;
  final List<TransactionData> allTransactions;

  const DailyLedgerPage({
    super.key,
    required this.date,
    required this.allTransactions,
  });

  @override
  State<DailyLedgerPage> createState() => _DailyLedgerPageState();
}

class _DailyLedgerPageState extends State<DailyLedgerPage> {
  late List<TransactionData> dayTransactions;
  late DateTime currentViewDate;
  String selectedFilter = 'All';
  final List<String> filterOptions = ['All', 'Income', 'Expense'];

  @override
  void initState() {
    super.initState();
    currentViewDate = widget.date;
    _filterTransactions();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: currentViewDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != currentViewDate) {
      setState(() {
        currentViewDate = picked;
        _filterTransactions();
      });
    }
  }

  void _filterTransactions() {
    final startOfDay = DateTime(
        currentViewDate.year, currentViewDate.month, currentViewDate.day);
    final endOfDay = DateTime(currentViewDate.year, currentViewDate.month,
        currentViewDate.day, 23, 59, 59);

    try {
      dayTransactions = widget.allTransactions.where((t) {
        final isSameDay = (t.date.isAtSameMomentAs(startOfDay) ||
                t.date.isAfter(startOfDay)) &&
            (t.date.isAtSameMomentAs(endOfDay) || t.date.isBefore(endOfDay));

        if (!isSameDay) return false;

        if (selectedFilter == 'Income') return !t.isExpense;
        if (selectedFilter == 'Expense') return t.isExpense;
        return true;
      }).toList();

      // Sort by date descending
      dayTransactions.sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      if (kDebugMode) {
        print("Error filtering transactions: $e");
      }
      dayTransactions = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final cardColor = isDark ? Colors.grey.shade900 : Colors.white;
    final borderColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;

    double totalIncome = dayTransactions
        .where((t) => !t.isExpense)
        .fold(0, (sum, t) => sum + t.amount);
    double totalExpense = dayTransactions
        .where((t) => t.isExpense)
        .fold(0, (sum, t) => sum + t.amount);
    double netBalance = totalIncome - totalExpense;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
            'Ledger: ${DateFormat('dd MMM yyyy').format(currentViewDate)}'),
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: TextStyle(
            color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: () => _showDownloadDialog(context),
            tooltip: 'Download Statement',
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            onPressed: () => _selectDate(context),
            tooltip: 'Change Date',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildNetBalanceCard(netBalance, textColor),
          _buildSummaryCards(totalIncome, totalExpense),
          _buildFilterChips(),
          Expanded(
            child: dayTransactions.isEmpty
                ? Center(
                    child: Text('No transactions for this day',
                        style: TextStyle(color: textColor.withOpacity(0.6))))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: dayTransactions.length,
                    itemBuilder: (context, index) {
                      final t = dayTransactions[index];
                      return _buildTransactionItem(
                          t, isDark, cardColor, borderColor, textColor);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetBalanceCard(double balance, Color textColor) {
    bool isProfit = balance >= 0;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isProfit ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isProfit ? Colors.green : Colors.red).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Net Balance of the Day',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(
                isProfit ? Icons.show_chart : Icons.trending_down,
                color: Colors.white.withOpacity(0.8),
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Rs. ${NumberFormat('#,##0').format(balance)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(double income, double expense) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: _summaryCard('Income', income, Colors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _summaryCard('Expense', expense, Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            'Rs. ${NumberFormat('#,##0').format(amount)}',
            style: TextStyle(
                color: color, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: filterOptions.map((filter) {
          final isSelected = selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    selectedFilter = filter;
                    _filterTransactions();
                  });
                }
              },
              selectedColor: kPrimaryColor,
              backgroundColor:
                  isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              labelStyle: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white : Colors.black),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTransactionItem(TransactionData t, bool isDark, Color cardColor,
      Color borderColor, Color textColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: t.isExpense
                  ? Colors.red.withOpacity(0.1)
                  : Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              t.isExpense ? Icons.arrow_upward : Icons.arrow_downward,
              color: t.isExpense ? Colors.red : Colors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.name,
                  style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
                Text(
                  t.type,
                  style: TextStyle(
                      color: textColor.withOpacity(0.6), fontSize: 12),
                ),
                if (t.note != null && t.note!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      t.note!,
                      style: TextStyle(
                        fontSize: 11,
                        color: textColor.withOpacity(0.5),
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${t.isExpense ? "-" : "+"} Rs. ${NumberFormat('#,##0').format(t.amount)}',
                style: TextStyle(
                  color: t.isExpense ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Text(
                DateFormat('hh:mm a').format(t.date),
                style:
                    TextStyle(color: textColor.withOpacity(0.5), fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDownloadDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Download Statement',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildRangeOption('Last 30 Days', 30),
              _buildRangeOption('Last 90 Days', 90),
              _buildRangeOption('Last 180 Days', 180),
              _buildRangeOption('Last 365 Days', 365),
              ListTile(
                leading: const Icon(Icons.date_range, color: kPrimaryColor),
                title: const Text('Select Date Range'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showCustomRangePicker(context);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRangeOption(String label, int days) {
    return ListTile(
      leading: const Icon(Icons.history, color: kPrimaryColor),
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        final end = DateTime.now();
        final start = DateTime(end.year, end.month, end.day, 0, 0, 0)
            .subtract(Duration(days: days));
        _generateAndShareStatement(start, end);
      },
    );
  }

  Future<void> _showCustomRangePicker(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 7)),
        end: DateTime.now(),
      ),
    );

    if (picked != null) {
      final start =
          DateTime(picked.start.year, picked.start.month, picked.start.day);
      final end = DateTime(
          picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
      _generateAndShareStatement(start, end);
    }
  }

  Future<void> _generateAndShareStatement(DateTime start, DateTime end) async {
    final filtered = widget.allTransactions.where((t) {
      final tDate = DateTime(t.date.year, t.date.month, t.date.day);
      final sDate = DateTime(start.year, start.month, start.day);
      final eDate = DateTime(end.year, end.month, end.day);

      return (tDate.isAtSameMomentAs(sDate) || tDate.isAfter(sDate)) &&
          (tDate.isAtSameMomentAs(eDate) || tDate.isBefore(eDate));
    }).toList();

    if (filtered.isEmpty) {
      Get.snackbar(
        'No Data',
        'No transactions found for the selected range.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
      return;
    }

    filtered.sort((a, b) => b.date.compareTo(a.date));

    try {
      await LoadingUtils.wrapWithLoading(
        context,
        () async {
          final workspace = Get.find<WorkspaceController>();
          final file = await LedgerPdfService.generateLedgerStatement(
            companyData: workspace.companyData,
            transactions: filtered,
            startDate: start,
            endDate: end,
          );

          await Share.shareXFiles([XFile(file.path)], text: 'Ledger Statement');
        },
        message: 'Generating Statement...',
      );
    } catch (e) {
      print('Error generating PDF: $e');
      Get.snackbar('Error', 'Failed to generate PDF statement.');
    }
  }
}
