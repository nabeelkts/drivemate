import 'package:async/async.dart'; // Import the async package
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/constants/constant.dart';
import 'package:mds/screens/dashboard/list/details/endorsement_details_page.dart';
import 'package:mds/screens/dashboard/list/details/license_only_details_page.dart';
import 'package:mds/screens/dashboard/list/details/rc_details_page.dart';
import 'package:mds/screens/dashboard/list/details/students_details_page.dart';
import 'package:mds/screens/dashboard/widgets/custom/custom_text.dart';
import 'package:mds/screens/statistics/receive_money.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart'; // Import the shimmer package

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? user = FirebaseAuth.instance.currentUser;
  DateTime selectedDate = DateTime.now();
  String selectedFilter = 'Month'; // Default to Month
  double totalRevenue = 0.0;
  double totalBalanceAmount = 0.0;

  // Define the filter options as a constant list
  static const List<String> filterOptions = ['Day', 'Month', 'Year'];

  @override
  void initState() {
    super.initState();
    _checkAndResetMonthlyData();
    // Set up a timer to update the date at midnight
    _setupDateUpdateTimer();
  }

  Future<void> _checkAndResetMonthlyData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String currentMonth = DateFormat('MM/yyyy').format(DateTime.now());
    String? lastUpdatedMonth = prefs.getString('lastUpdatedMonth');

    if (lastUpdatedMonth != currentMonth) {
      setState(() {
        totalRevenue = 0.0;
        totalBalanceAmount = 0.0;
        selectedDate = DateTime.now(); // Reset to current date
        selectedFilter = 'Month'; // Reset to Month filter
      });
      await prefs.setString('lastUpdatedMonth', currentMonth);
    }
  }

  void _setupDateUpdateTimer() {
    // Calculate time until next midnight
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = nextMidnight.difference(now);

    // Set up a timer that triggers at midnight
    Future.delayed(timeUntilMidnight, () {
      setState(() {
        selectedDate = DateTime.now();
      });
      // Set up the next timer
      _setupDateUpdateTimer();
    });
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
            'Statistics',
            style: TextStyle(
              color: textColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildFinancialOverviewCard(
                    cardColor, borderColor, textColor, isDark),
                kSizedBox,
                buildKeyMetricsGrid(cardColor, borderColor, textColor),
                kSizedBox,
                buildTransactionsSection(cardColor, borderColor, textColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildFinancialOverviewCard(
      Color cardColor, Color borderColor, Color textColor, bool isDark) {
    // Ensure colors are theme-aware
    final theme = Theme.of(context);
    final currentIsDark = theme.brightness == Brightness.dark;
    final displayTextColor = currentIsDark ? Colors.white : Colors.black;
    final chipBgColor =
        currentIsDark ? Colors.grey.shade800 : Colors.grey.shade300;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
                    fontSize: 18,
                    fontWeight: FontWeight.w700),
              ),
              GestureDetector(
                onTap: () => _showMonthFilterSheet(),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: chipBgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('MMM yyyy').format(selectedDate),
                        style: TextStyle(color: displayTextColor, fontSize: 14),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down,
                          color: displayTextColor, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
          kSizedBox,
          SizedBox(height: 200, child: buildChart()),
          const SizedBox(height: 8),
          Text(
            selectedFilter == 'Day'
                ? 'Is day of ${DateFormat('dd MMM yyyy').format(selectedDate)}'
                : selectedFilter == 'Year'
                    ? 'Is year of ${DateFormat('yyyy').format(selectedDate)}'
                    : 'Is month of ${DateFormat('MMM yyyy').format(selectedDate)}',
            style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _showMonthFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select period',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(3, (i) {
                  final opts = ['Day', 'Month', 'Year'];
                  final isSelected = selectedFilter == opts[i];
                  return ElevatedButton(
                    onPressed: () {
                      setState(() => selectedFilter = opts[i]);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected
                          ? kOrange
                          : (isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade300),
                      foregroundColor: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.black87),
                      elevation: isSelected ? 2 : 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Text(opts[i]),
                  );
                }),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => selectedDate = picked);
                    Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.calendar_today),
                label: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                  foregroundColor: isDark ? Colors.white : Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRevenueDetails(BuildContext context,
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String localFilter = 'Month';
        DateTime localDate = DateTime.now();
        return StatefulBuilder(builder: (ctx, setStateSB) {
          List<Map<String, dynamic>> transactions = [];
          for (var doc in docs) {
            final data = doc.data();
            final name = data['fullName'] ?? data['vehicleNumber'] ?? 'N/A';
            DateTime regDate =
                DateTime.tryParse(data['registrationDate'] ?? '') ??
                    DateTime(2000);
            double advance =
                double.tryParse(data['advanceAmount']?.toString() ?? '0') ?? 0;
            if (advance > 0)
              transactions.add({
                'name': name,
                'amount': advance,
                'date': regDate,
                'label': 'Advance'
              });
            DateTime t2 =
                DateTime.tryParse(data['secondInstallmentTime'] ?? '') ??
                    DateTime(2000);
            double s2 =
                double.tryParse(data['secondInstallment']?.toString() ?? '0') ??
                    0;
            if (s2 > 0)
              transactions.add({
                'name': name,
                'amount': s2,
                'date': t2,
                'label': '2nd Installment'
              });
            DateTime t3 =
                DateTime.tryParse(data['thirdInstallmentTime'] ?? '') ??
                    DateTime(2000);
            double s3 =
                double.tryParse(data['thirdInstallment']?.toString() ?? '0') ??
                    0;
            if (s3 > 0)
              transactions.add({
                'name': name,
                'amount': s3,
                'date': t3,
                'label': '3rd Installment'
              });
          }
          final filtered = transactions.where((t) {
            final d = t['date'] as DateTime;
            if (localFilter == 'Day') return isSameDate(d, localDate);
            if (localFilter == 'Month')
              return d.year == localDate.year && d.month == localDate.month;
            if (localFilter == 'Year') return d.year == localDate.year;
            return true;
          }).toList();
          double total =
              filtered.fold(0, (sum, item) => sum + (item['amount'] as double));
          return _buildFilterListSheet(
              context,
              'Revenue Details',
              total,
              localFilter,
              localDate,
              filtered,
              (v) => setStateSB(() => localFilter = v),
              (v) => setStateSB(() => localDate = v));
        });
      },
    );
  }

  void _showExpenseDetails(BuildContext context,
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String localFilter = 'Month';
        DateTime localDate = DateTime.now();
        return StatefulBuilder(builder: (ctx, setStateSB) {
          List<Map<String, dynamic>> expenses = docs.map((doc) {
            final e = doc.data();
            DateTime date;
            final dateStr = e['date']?.toString();
            if (dateStr != null && dateStr.isNotEmpty) {
              date = DateTime.tryParse(dateStr) ?? DateTime(2000);
            } else if (e['timestamp'] != null) {
              date = (e['timestamp'] as Timestamp).toDate();
            } else {
              date = DateTime(2000);
            }
            return {
              'name': e['categoryLabel'] ?? e['category'] ?? 'Expense',
              'amount': double.tryParse(e['amount']?.toString() ?? '0') ?? 0.0,
              'date': date,
              'label': e['note'] ?? '',
            };
          }).toList();
          final filtered = expenses.where((t) {
            final d = t['date'] as DateTime;
            if (localFilter == 'Day') return isSameDate(d, localDate);
            if (localFilter == 'Month')
              return d.year == localDate.year && d.month == localDate.month;
            if (localFilter == 'Year') return d.year == localDate.year;
            return true;
          }).toList();
          double total =
              filtered.fold(0, (sum, item) => sum + (item['amount'] as double));
          return _buildFilterListSheet(
              context,
              'Expense Details',
              total,
              localFilter,
              localDate,
              filtered,
              (v) => setStateSB(() => localFilter = v),
              (v) => setStateSB(() => localDate = v));
        });
      },
    );
  }

  Widget _buildFilterListSheet(
      BuildContext context,
      String title,
      double total,
      String currentFilter,
      DateTime currentDate,
      List<Map<String, dynamic>> items,
      Function(String) onFilterChanged,
      Function(DateTime) onDateChanged) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 8),
          Text('Total: Rs. ${total.toStringAsFixed(2)}',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: kOrange)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['Day', 'Month', 'Year']
                        .map((f) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(f),
                                selected: currentFilter == f,
                                onSelected: (v) => onFilterChanged(f),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                      context: context,
                      initialDate: currentDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now());
                  if (picked != null) onDateChanged(picked);
                },
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(currentFilter == 'Year'
                    ? DateFormat('yyyy').format(currentDate)
                    : currentFilter == 'Month'
                        ? DateFormat('MMM yyyy').format(currentDate)
                        : DateFormat('dd/MM/yyyy').format(currentDate)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('No transactions found'))
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (ctx, i) {
                      final item = items[i];
                      return ListTile(
                        title: Text(item['name']),
                        subtitle: Text(
                            '${DateFormat('dd/MM/yyyy').format(item['date'])} ${item['label'].isNotEmpty ? 'ΓÇó ${item['label']}' : ''}'),
                        trailing: Text(
                            'Rs. ${item['amount'].toStringAsFixed(0)}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget buildKeyMetricsGrid(
      Color cardColor, Color borderColor, Color textColor) {
    return StreamBuilder<List<QuerySnapshot<Map<String, dynamic>>>>(
      stream: StreamZip([
        _firestore
            .collection('users')
            .doc(user?.uid)
            .collection('students')
            .snapshots(),
        _firestore
            .collection('users')
            .doc(user?.uid)
            .collection('licenseonly')
            .snapshots(),
        _firestore
            .collection('users')
            .doc(user?.uid)
            .collection('endorsement')
            .snapshots(),
        _firestore
            .collection('users')
            .doc(user?.uid)
            .collection('vehicleDetails')
            .snapshots(),
        _firestore
            .collection('users')
            .doc(user?.uid)
            .collection('expenses')
            .snapshots(),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final dataList = snapshot.data!;
        final mainDocs = dataList.take(4).expand((s) => s.docs).toList();
        int totalLearners = 0;
        int monthLearners = 0;
        int prevMonthLearners = 0;
        double rev = 0, balance = 0;
        for (var doc in mainDocs) {
          final d = doc.data();
          final parent = doc.reference.parent.id;
          if (parent == 'students') {
            totalLearners++;
            final regDate = DateTime.tryParse(d['registrationDate'] ?? '') ??
                DateTime(2000);
            final prevMonthDate =
                DateTime(selectedDate.year, selectedDate.month - 1, 1);
            if (regDate.year == selectedDate.year &&
                regDate.month == selectedDate.month) {
              monthLearners++;
            }
            if (regDate.year == prevMonthDate.year &&
                regDate.month == prevMonthDate.month) {
              prevMonthLearners++;
            }
          }
          double advance =
              double.tryParse(d['advanceAmount']?.toString() ?? '0') ?? 0;
          double s2 =
              double.tryParse(d['secondInstallment']?.toString() ?? '0') ?? 0;
          double s3 =
              double.tryParse(d['thirdInstallment']?.toString() ?? '0') ?? 0;
          double bal =
              double.tryParse(d['balanceAmount']?.toString() ?? '0') ?? 0;
          DateTime reg =
              DateTime.tryParse(d['registrationDate'] ?? '') ?? DateTime(2000);
          DateTime t2 = DateTime.tryParse(d['secondInstallmentTime'] ?? '') ??
              DateTime(2000);
          DateTime t3 = DateTime.tryParse(d['thirdInstallmentTime'] ?? '') ??
              DateTime(2000);
          if (reg.year == selectedDate.year && reg.month == selectedDate.month)
            rev += advance;
          if (t2.year == selectedDate.year && t2.month == selectedDate.month)
            rev += s2;
          if (t3.year == selectedDate.year && t3.month == selectedDate.month)
            rev += s3;
          if (reg.year == selectedDate.year &&
              reg.month == selectedDate.month &&
              bal > 0) balance += bal;
        }
        double totalExpenses = 0.0;
        if (dataList.length >= 5) {
          for (var doc in dataList[4].docs) {
            final e = doc.data();
            final amount =
                double.tryParse(e['amount']?.toString() ?? '0') ?? 0.0;
            DateTime date;
            final dateStr = e['date']?.toString();
            if (dateStr != null && dateStr.isNotEmpty) {
              date = DateTime.tryParse(dateStr) ??
                  DateTime.fromMillisecondsSinceEpoch(0);
            } else if (e['timestamp'] != null) {
              date = (e['timestamp'] as Timestamp).toDate();
            } else {
              date = DateTime.fromMillisecondsSinceEpoch(0);
            }
            // Always calculate current month total for display card
            final now = DateTime.now();
            if (date.year == now.year && date.month == now.month) {
              totalExpenses += amount;
            }
          }
        }
        final avgRevenue = totalLearners > 0 ? rev / totalLearners : 0.0;
        final perc = prevMonthLearners > 0
            ? (((monthLearners - prevMonthLearners) / prevMonthLearners) * 100)
            : 0.0;
        final percStr = '${perc.abs().toStringAsFixed(0)}%';
        final percArrow = perc >= 0 ? 'Γåæ' : 'Γåô';
        final List<Widget> cards = [
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (ctx) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Totals',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            IconButton(
                                onPressed: () => Navigator.pop(ctx),
                                icon: const Icon(Icons.close)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text('Students: $totalLearners',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text('License Only: ${dataList[1].docs.length}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text('Endorsement: ${dataList[2].docs.length}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text('RC: ${dataList[3].docs.length}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                },
              );
            },
            child: _metricCard(cardColor, borderColor, textColor,
                'Total Learners', '$totalLearners ($percArrow$percStr)',
                isPositive: perc >= 0),
          ),
          _metricCard(cardColor, borderColor, textColor, 'Avg. Revenue/Learner',
              'Rs. ${avgRevenue.toStringAsFixed(0)}',
              isPositive: null),
          GestureDetector(
            onTap: () => _showRevenueDetails(context, mainDocs),
            child: _metricCard(cardColor, borderColor, textColor,
                'Revenue (Current Month)', 'Rs. ${rev.toStringAsFixed(2)}',
                isPositive: null),
          ),
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (ctx) {
                  String filterType = 'All';
                  // Build all outstanding list (not limited by period)
                  final List<Map<String, dynamic>> allOutstanding =
                      mainDocs.where((doc) {
                    final d = doc.data();
                    final bal = double.tryParse(
                            d['balanceAmount']?.toString() ?? '0') ??
                        0.0;
                    return bal > 0.0;
                  }).map((doc) {
                    final d = doc.data();
                    final parent = doc.reference.parent.id;
                    final name = d['fullName'] ?? d['vehicleNumber'] ?? 'N/A';
                    DateTime date =
                        DateTime.tryParse(d['registrationDate'] ?? '') ??
                            DateTime(2000);
                    final amount = double.tryParse(
                            d['balanceAmount']?.toString() ?? '0') ??
                        0.0;
                    return {
                      'doc': doc,
                      'name': name,
                      'amount': amount,
                      'date': date,
                      'type': parent,
                    };
                  }).toList();
                  return StatefulBuilder(
                    builder: (ctx, setSB) {
                      final filtered = allOutstanding.where((d) {
                        switch (filterType) {
                          case 'Students':
                            return d['type'] == 'students';
                          case 'License':
                            return d['type'] == 'licenseonly';
                          case 'Endorsement':
                            return d['type'] == 'endorsement';
                          case 'RC':
                            return d['type'] == 'vehicleDetails';
                          default:
                            return true;
                        }
                      }).toList();
                      return Container(
                        height: MediaQuery.of(context).size.height * 0.8,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Outstanding Details',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                IconButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    icon: const Icon(Icons.close)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  ChoiceChip(
                                      label: const Text('All'),
                                      selected: filterType == 'All',
                                      onSelected: (v) =>
                                          setSB(() => filterType = 'All')),
                                  const SizedBox(width: 8),
                                  ChoiceChip(
                                      label: const Text('Student'),
                                      selected: filterType == 'Students',
                                      onSelected: (v) =>
                                          setSB(() => filterType = 'Students')),
                                  const SizedBox(width: 8),
                                  ChoiceChip(
                                      label: const Text('License'),
                                      selected: filterType == 'License',
                                      onSelected: (v) =>
                                          setSB(() => filterType = 'License')),
                                  const SizedBox(width: 8),
                                  ChoiceChip(
                                      label: const Text('Endorse'),
                                      selected: filterType == 'Endorsement',
                                      onSelected: (v) => setSB(
                                          () => filterType = 'Endorsement')),
                                  const SizedBox(width: 8),
                                  ChoiceChip(
                                      label: const Text('RC'),
                                      selected: filterType == 'RC',
                                      onSelected: (v) =>
                                          setSB(() => filterType = 'RC')),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: filtered.isEmpty
                                  ? const Center(
                                      child: Text('No outstanding amounts'))
                                  : ListView.builder(
                                      itemCount: filtered.length,
                                      itemBuilder: (ctx, i) {
                                        final detail = filtered[i];
                                        return ListTile(
                                          title: Text(
                                              detail['name']?.toString() ?? ''),
                                          subtitle: Text(
                                              DateFormat('dd/MM/yyyy').format(
                                                  detail['date'] as DateTime)),
                                          trailing: Text(
                                              'Rs. ${(detail['amount'] as double).toStringAsFixed(0)}'),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
            child: _metricCard(cardColor, borderColor, textColor,
                'Outstanding Due', 'Rs. ${balance.toStringAsFixed(0)}',
                isPositive: null),
          ),
          GestureDetector(
            onTap: () => _showExpenseDetails(context, dataList[4].docs),
            child: _metricCard(
                cardColor,
                borderColor,
                textColor,
                'Expenses (Current Month)',
                'Rs. ${totalExpenses.toStringAsFixed(0)}',
                isPositive: null),
          ),
        ];
        return Column(
          children: [
            Row(
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 8),
                Expanded(child: cards[1]),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: cards[2]),
                const SizedBox(width: 8),
                Expanded(child: cards[3]),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: cards[4]),
                const SizedBox(width: 8),
                Expanded(child: buildReceiveMoneyButton()),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _metricCard(Color cardColor, Color borderColor, Color textColor,
      String title, String value,
      {bool? isPositive}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title,
              style: TextStyle(
                  color: textColor, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: isPositive == true ? Colors.green : textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildReceiveMoneyButton() {
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (context) => ReceiveMoneyPage())),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: kOrange,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade600, width: 1),
        ),
        child: const Center(
          child: Text('Receive money',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget buildTransactionsSection(
      Color cardColor, Color borderColor, Color textColor) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Transactions History',
                    style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Icon(Icons.chevron_right, color: textColor, size: 24),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 12),
            child: buildTransactions(),
          ),
        ],
      ),
    );
  }

  Widget buildChart() {
    return StreamBuilder<List<QuerySnapshot<Map<String, dynamic>>>>(
      stream: StreamZip([
        _firestore
            .collection('users')
            .doc(user?.uid)
            .collection('students')
            .snapshots(),
        _firestore
            .collection('users')
            .doc(user?.uid)
            .collection('licenseonly')
            .snapshots(),
        _firestore
            .collection('users')
            .doc(user?.uid)
            .collection('endorsement')
            .snapshots(),
        _firestore
            .collection('users')
            .doc(user?.uid)
            .collection('vehicleDetails')
            .snapshots(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Error loading chart data');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return buildShimmerChart();
        }

        final allDocuments =
            snapshot.data?.expand((snapshot) => snapshot.docs).toList() ?? [];
        Map<String, double> revenueData = {};

        switch (selectedFilter) {
          case 'Day':
            // Show last 6 days including current day
            List<DateTime> dateRange = List.generate(
                6, (index) => selectedDate.subtract(Duration(days: index)));
            dateRange.sort((a, b) => a.compareTo(b));

            for (var date in dateRange) {
              String key = DateFormat('dd/MM').format(date);
              revenueData[key] = 0.0;
            }

            for (var doc in allDocuments) {
              final data = doc.data();
              double advanceAmount =
                  double.tryParse(data['advanceAmount']?.toString() ?? '0') ??
                      0.0;
              double secondInstallment = double.tryParse(
                      data['secondInstallment']?.toString() ?? '0') ??
                  0.0;
              double thirdInstallment = double.tryParse(
                      data['thirdInstallment']?.toString() ?? '0') ??
                  0.0;

              DateTime transactionDate =
                  DateTime.tryParse(data['registrationDate'] ?? '') ??
                      DateTime.fromMillisecondsSinceEpoch(0);
              DateTime secondInstallmentTime =
                  DateTime.tryParse(data['secondInstallmentTime'] ?? '') ??
                      DateTime.fromMillisecondsSinceEpoch(0);
              DateTime thirdInstallmentTime =
                  DateTime.tryParse(data['thirdInstallmentTime'] ?? '') ??
                      DateTime.fromMillisecondsSinceEpoch(0);

              // Check each date and add to the corresponding day's revenue
              for (var date in dateRange) {
                String key = DateFormat('dd/MM').format(date);
                if (isSameDate(transactionDate, date)) {
                  revenueData[key] = (revenueData[key] ?? 0) + advanceAmount;
                }
                if (isSameDate(secondInstallmentTime, date)) {
                  revenueData[key] =
                      (revenueData[key] ?? 0) + secondInstallment;
                }
                if (isSameDate(thirdInstallmentTime, date)) {
                  revenueData[key] = (revenueData[key] ?? 0) + thirdInstallment;
                }
              }
            }
            break;

          case 'Month':
            // Show last 6 months including current month
            List<DateTime> monthRange = List.generate(6, (index) {
              DateTime date =
                  DateTime(selectedDate.year, selectedDate.month - index, 1);
              return DateTime(date.year, date.month, 1);
            });
            monthRange.sort((a, b) => a.compareTo(b));

            for (var date in monthRange) {
              String key = DateFormat('MM/yy').format(date);
              revenueData[key] = 0.0;
            }

            for (var doc in allDocuments) {
              final data = doc.data();
              double advanceAmount =
                  double.tryParse(data['advanceAmount']?.toString() ?? '0') ??
                      0.0;
              double secondInstallment = double.tryParse(
                      data['secondInstallment']?.toString() ?? '0') ??
                  0.0;
              double thirdInstallment = double.tryParse(
                      data['thirdInstallment']?.toString() ?? '0') ??
                  0.0;

              DateTime transactionDate =
                  DateTime.tryParse(data['registrationDate'] ?? '') ??
                      DateTime.fromMillisecondsSinceEpoch(0);
              DateTime secondInstallmentTime =
                  DateTime.tryParse(data['secondInstallmentTime'] ?? '') ??
                      DateTime.fromMillisecondsSinceEpoch(0);
              DateTime thirdInstallmentTime =
                  DateTime.tryParse(data['thirdInstallmentTime'] ?? '') ??
                      DateTime.fromMillisecondsSinceEpoch(0);

              // Check each month and add to the corresponding month's revenue
              for (var date in monthRange) {
                String key = DateFormat('MM/yy').format(date);
                if (transactionDate.year == date.year &&
                    transactionDate.month == date.month) {
                  revenueData[key] = (revenueData[key] ?? 0) + advanceAmount;
                }
                if (secondInstallmentTime.year == date.year &&
                    secondInstallmentTime.month == date.month) {
                  revenueData[key] =
                      (revenueData[key] ?? 0) + secondInstallment;
                }
                if (thirdInstallmentTime.year == date.year &&
                    thirdInstallmentTime.month == date.month) {
                  revenueData[key] = (revenueData[key] ?? 0) + thirdInstallment;
                }
              }
            }
            break;

          case 'Year':
            // Show last 6 years including current year
            List<DateTime> yearRange = List.generate(6, (index) {
              return DateTime(selectedDate.year - index, 1, 1);
            });
            yearRange.sort((a, b) => a.compareTo(b));

            for (var date in yearRange) {
              String key = DateFormat('yyyy').format(date);
              revenueData[key] = 0.0;
            }

            for (var doc in allDocuments) {
              final data = doc.data();
              double advanceAmount =
                  double.tryParse(data['advanceAmount']?.toString() ?? '0') ??
                      0.0;
              double secondInstallment = double.tryParse(
                      data['secondInstallment']?.toString() ?? '0') ??
                  0.0;
              double thirdInstallment = double.tryParse(
                      data['thirdInstallment']?.toString() ?? '0') ??
                  0.0;

              DateTime transactionDate =
                  DateTime.tryParse(data['registrationDate'] ?? '') ??
                      DateTime.fromMillisecondsSinceEpoch(0);
              DateTime secondInstallmentTime =
                  DateTime.tryParse(data['secondInstallmentTime'] ?? '') ??
                      DateTime.fromMillisecondsSinceEpoch(0);
              DateTime thirdInstallmentTime =
                  DateTime.tryParse(data['thirdInstallmentTime'] ?? '') ??
                      DateTime.fromMillisecondsSinceEpoch(0);

              // Check each year and add to the corresponding year's revenue
              for (var date in yearRange) {
                String key = DateFormat('yyyy').format(date);
                if (transactionDate.year == date.year) {
                  revenueData[key] = (revenueData[key] ?? 0) + advanceAmount;
                }
                if (secondInstallmentTime.year == date.year) {
                  revenueData[key] =
                      (revenueData[key] ?? 0) + secondInstallment;
                }
                if (thirdInstallmentTime.year == date.year) {
                  revenueData[key] = (revenueData[key] ?? 0) + thirdInstallment;
                }
              }
            }
            break;
        }

        return buildBarChart(revenueData);
      },
    );
  }

  Widget buildShimmerChart() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }

  Widget buildBarChart(Map<String, double> revenueData) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    if (revenueData.isEmpty) {
      return Center(
          child: Text('No data available for the selected period.',
              style: TextStyle(color: textColor)));
    }

    double maxValue = revenueData.values.reduce((a, b) => a > b ? a : b);
    double scaleFactor = 150 / (maxValue > 0 ? maxValue : 1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Container(
        height: 180,
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: revenueData.entries.map((entry) {
            String fullLabel = "";
            switch (selectedFilter) {
              case 'Day':
                fullLabel = "${entry.key} of ${selectedDate.year}";
                break;
              case 'Month':
                fullLabel =
                    "${DateFormat('MMMM').format(DateFormat('MM/yy').parse(entry.key))} ${DateFormat('yyyy').format(DateFormat('MM/yy').parse(entry.key))}";
                break;
              case 'Year':
                fullLabel = "Year ${entry.key}";
                break;
            }

            return Tooltip(
              message:
                  "$fullLabel\nRs. ${NumberFormat('#,##0').format(entry.value)}",
              triggerMode: TooltipTriggerMode.tap,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade800 : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color:
                        isDark ? Colors.grey.shade600 : Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              textStyle: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 12,
                    height: entry.value * scaleFactor,
                    decoration: BoxDecoration(
                      color: entry.value == maxValue ? Colors.green : kOrange,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    entry.key,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 10,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget buildCards() {
    return StreamBuilder<List<QuerySnapshot<Map<String, dynamic>>>>(
      stream: StreamZip([
        _firestore
            .collection('users')
            .doc(user?.uid)
            .collection('students')
            .snapshots(),
        _firestore
            .collection('users')
            .doc(user?.uid)
            .collection('licenseonly')
            .snapshots(),
        _firestore
            .collection('users')
            .doc(user?.uid)
            .collection('endorsement')
            .snapshots(),
        _firestore
            .collection('users')
            .doc(user?.uid)
            .collection('vehicleDetails')
            .snapshots(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Error loading data');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return buildShimmerCards();
        }

        final allDocuments =
            snapshot.data?.expand((snapshot) => snapshot.docs).toList() ?? [];
        totalRevenue = 0.0;
        totalBalanceAmount = 0.0;

        // Create a list to store outstanding details
        List<Map<String, dynamic>> outstandingDetails = [];

        for (var doc in allDocuments) {
          final data = doc.data();
          double advanceAmount =
              double.tryParse(data['advanceAmount']?.toString() ?? '0') ?? 0.0;
          double secondInstallment =
              double.tryParse(data['secondInstallment']?.toString() ?? '0') ??
                  0.0;
          double thirdInstallment =
              double.tryParse(data['thirdInstallment']?.toString() ?? '0') ??
                  0.0;
          double balanceAmount =
              double.tryParse(data['balanceAmount']?.toString() ?? '0') ?? 0.0;

          DateTime transactionDate =
              DateTime.tryParse(data['registrationDate'] ?? '') ??
                  DateTime.fromMillisecondsSinceEpoch(0);
          DateTime secondInstallmentTime =
              DateTime.tryParse(data['secondInstallmentTime'] ?? '') ??
                  DateTime.fromMillisecondsSinceEpoch(0);
          DateTime thirdInstallmentTime =
              DateTime.tryParse(data['thirdInstallmentTime'] ?? '') ??
                  DateTime.fromMillisecondsSinceEpoch(0);

          // Filter based on selected filter
          bool isInRange = false;
          switch (selectedFilter) {
            case 'Day':
              // For day filter, check if any installment was made on the selected date
              isInRange = isSameDate(transactionDate, selectedDate) ||
                  isSameDate(secondInstallmentTime, selectedDate) ||
                  isSameDate(thirdInstallmentTime, selectedDate);

              // Only add the amount for the specific day
              if (isInRange) {
                if (isSameDate(transactionDate, selectedDate)) {
                  totalRevenue += advanceAmount;
                }
                if (isSameDate(secondInstallmentTime, selectedDate)) {
                  totalRevenue += secondInstallment;
                }
                if (isSameDate(thirdInstallmentTime, selectedDate)) {
                  totalRevenue += thirdInstallment;
                }
                if (balanceAmount > 0 &&
                    isSameDate(transactionDate, selectedDate)) {
                  totalBalanceAmount += balanceAmount;
                  outstandingDetails.add({
                    'doc': doc,
                    'name': data['fullName'] ?? data['vehicleNumber'] ?? 'N/A',
                    'amount': balanceAmount,
                    'date': transactionDate,
                    'type': doc.reference.parent.id,
                  });
                }
              }
              break;

            case 'Month':
              // For month filter, check if any installment was made in the selected month
              bool isInMonth = (transactionDate.year == selectedDate.year &&
                      transactionDate.month == selectedDate.month) ||
                  (secondInstallmentTime.year == selectedDate.year &&
                      secondInstallmentTime.month == selectedDate.month) ||
                  (thirdInstallmentTime.year == selectedDate.year &&
                      thirdInstallmentTime.month == selectedDate.month);

              if (isInMonth) {
                // Add advance amount if it was in this month
                if (transactionDate.year == selectedDate.year &&
                    transactionDate.month == selectedDate.month) {
                  totalRevenue += advanceAmount;
                }
                // Add second installment if it was in this month
                if (secondInstallmentTime.year == selectedDate.year &&
                    secondInstallmentTime.month == selectedDate.month) {
                  totalRevenue += secondInstallment;
                }
                // Add third installment if it was in this month
                if (thirdInstallmentTime.year == selectedDate.year &&
                    thirdInstallmentTime.month == selectedDate.month) {
                  totalRevenue += thirdInstallment;
                }
                if (balanceAmount > 0 &&
                    transactionDate.year == selectedDate.year &&
                    transactionDate.month == selectedDate.month) {
                  totalBalanceAmount += balanceAmount;
                  outstandingDetails.add({
                    'doc': doc,
                    'name': data['fullName'] ?? data['vehicleNumber'] ?? 'N/A',
                    'amount': balanceAmount,
                    'date': transactionDate,
                    'type': doc.reference.parent.id,
                  });
                }
              }
              break;

            case 'Year':
              // For year filter, check if any installment was made in the selected year
              bool isInYear = (transactionDate.year == selectedDate.year) ||
                  (secondInstallmentTime.year == selectedDate.year) ||
                  (thirdInstallmentTime.year == selectedDate.year);

              if (isInYear) {
                // Add advance amount if it was in this year
                if (transactionDate.year == selectedDate.year) {
                  totalRevenue += advanceAmount;
                }
                // Add second installment if it was in this year
                if (secondInstallmentTime.year == selectedDate.year) {
                  totalRevenue += secondInstallment;
                }
                // Add third installment if it was in this year
                if (thirdInstallmentTime.year == selectedDate.year) {
                  totalRevenue += thirdInstallment;
                }
                if (balanceAmount > 0 &&
                    transactionDate.year == selectedDate.year) {
                  totalBalanceAmount += balanceAmount;
                  outstandingDetails.add({
                    'doc': doc,
                    'name': data['fullName'] ?? data['vehicleNumber'] ?? 'N/A',
                    'amount': balanceAmount,
                    'date': transactionDate,
                    'type': doc.reference.parent.id,
                  });
                }
              }
              break;
          }
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (BuildContext context) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Filter Revenue',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      ...filterOptions
                                          .map((filter) => ElevatedButton(
                                                onPressed: () {
                                                  setState(() {
                                                    selectedFilter = filter;
                                                  });
                                                  Navigator.pop(context);
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      selectedFilter == filter
                                                          ? Colors.blue
                                                          : Colors.grey[200],
                                                  foregroundColor:
                                                      selectedFilter == filter
                                                          ? Colors.white
                                                          : Colors.black,
                                                ),
                                                child: Text(filter),
                                              )),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      DateTime? pickedDate =
                                          await showDatePicker(
                                        context: context,
                                        initialDate: selectedDate,
                                        firstDate: DateTime(2000),
                                        lastDate: DateTime.now(),
                                      );
                                      if (pickedDate != null &&
                                          pickedDate != selectedDate) {
                                        setState(() {
                                          selectedDate = pickedDate;
                                        });
                                        Navigator.pop(context);
                                      }
                                    },
                                    icon: const Icon(Icons.calendar_today),
                                    label: Text(DateFormat('dd/MM/yyyy')
                                        .format(selectedDate)),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      child: buildCard(
                          'Revenue for\nthe ${selectedFilter.toLowerCase()}',
                          'Rs. ${totalRevenue.toStringAsFixed(2)}'),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (BuildContext context) {
                            String filterType = 'All';
                            // Build all outstanding list (not limited by period)
                            final List<Map<String, dynamic>> allOutstanding =
                                allDocuments.where((doc) {
                              final d = doc.data();
                              final bal = double.tryParse(
                                      d['balanceAmount']?.toString() ?? '0') ??
                                  0.0;
                              return bal > 0.0;
                            }).map((doc) {
                              final d = doc.data();
                              final parent = doc.reference.parent.id;
                              final name =
                                  d['fullName'] ?? d['vehicleNumber'] ?? 'N/A';
                              DateTime date = DateTime.tryParse(
                                      d['registrationDate'] ?? '') ??
                                  DateTime(2000);
                              final amount = double.tryParse(
                                      d['balanceAmount']?.toString() ?? '0') ??
                                  0.0;
                              return {
                                'doc': doc,
                                'name': name,
                                'amount': amount,
                                'date': date,
                                'type': parent,
                              };
                            }).toList();
                            return StatefulBuilder(
                              builder: (ctx, setSB) {
                                final filtered = allOutstanding.where((d) {
                                  switch (filterType) {
                                    case 'Students':
                                      return d['type'] == 'students';
                                    case 'License':
                                      return d['type'] == 'licenseonly';
                                    case 'Endorsement':
                                      return d['type'] == 'endorsement';
                                    case 'RC':
                                      return d['type'] == 'vehicleDetails';
                                    default:
                                      return true;
                                  }
                                }).toList();
                                return Container(
                                  height:
                                      MediaQuery.of(context).size.height * 0.8,
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Outstanding Details',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.close),
                                            onPressed: () =>
                                                Navigator.pop(context),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          ChoiceChip(
                                            label: const Text('All'),
                                            selected: filterType == 'All',
                                            onSelected: (v) =>
                                                setSB(() => filterType = 'All'),
                                          ),
                                          const SizedBox(width: 8),
                                          ChoiceChip(
                                            label: const Text('Student'),
                                            selected: filterType == 'Students',
                                            onSelected: (v) => setSB(
                                                () => filterType = 'Students'),
                                          ),
                                          const SizedBox(width: 8),
                                          ChoiceChip(
                                            label: const Text('License'),
                                            selected: filterType == 'License',
                                            onSelected: (v) => setSB(
                                                () => filterType = 'License'),
                                          ),
                                          const SizedBox(width: 8),
                                          ChoiceChip(
                                            label: const Text('Endorse'),
                                            selected:
                                                filterType == 'Endorsement',
                                            onSelected: (v) => setSB(() =>
                                                filterType = 'Endorsement'),
                                          ),
                                          const SizedBox(width: 8),
                                          ChoiceChip(
                                            label: const Text('RC'),
                                            selected: filterType == 'RC',
                                            onSelected: (v) =>
                                                setSB(() => filterType = 'RC'),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Expanded(
                                        child: filtered.isEmpty
                                            ? const Center(
                                                child: Text(
                                                  'No outstanding amounts',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              )
                                            : ListView.builder(
                                                itemCount: filtered.length,
                                                itemBuilder: (context, index) {
                                                  final detail =
                                                      filtered[index];
                                                  return GestureDetector(
                                                    onTap: () {
                                                      if (detail['type'] ==
                                                          'licenseonly') {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                LicenseOnlyDetailsPage(
                                                              licenseDetails:
                                                                  detail['doc']
                                                                      .data()!,
                                                            ),
                                                          ),
                                                        );
                                                      } else if (detail[
                                                              'type'] ==
                                                          'endorsement') {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                EndorsementDetailsPage(
                                                              endorsementDetails:
                                                                  detail['doc']
                                                                      .data()!,
                                                            ),
                                                          ),
                                                        );
                                                      } else if (detail[
                                                              'type'] ==
                                                          'vehicleDetails') {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                RCDetailsPage(
                                                              vehicleDetails:
                                                                  detail['doc']
                                                                      .data()!,
                                                            ),
                                                          ),
                                                        );
                                                      } else if (detail[
                                                              'type'] ==
                                                          'students') {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                StudentDetailsPage(
                                                              studentDetails:
                                                                  detail['doc']
                                                                      .data()!,
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                    },
                                                    child: Container(
                                                      margin:
                                                          const EdgeInsets.only(
                                                              bottom: 8),
                                                      padding:
                                                          const EdgeInsets.all(
                                                              12),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.grey
                                                                .withOpacity(
                                                                    0.1),
                                                            spreadRadius: 1,
                                                            blurRadius: 3,
                                                          ),
                                                        ],
                                                      ),
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  detail[
                                                                      'name'],
                                                                  style:
                                                                      const TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        16,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                    height: 4),
                                                                Text(
                                                                  DateFormat(
                                                                          'dd/MM/yyyy')
                                                                      .format(detail[
                                                                          'date']),
                                                                  style:
                                                                      TextStyle(
                                                                    color: Colors
                                                                            .grey[
                                                                        600],
                                                                    fontSize:
                                                                        14,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          Text(
                                                            'Rs. ${detail['amount'].toStringAsFixed(2)}',
                                                            style:
                                                                const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 16,
                                                              color: Colors.red,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                      child: buildCard('Outstanding\nDue',
                          'Rs. ${totalBalanceAmount.toStringAsFixed(2)}'),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget buildShimmerCards() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        buildShimmerCard(),
        const SizedBox(width: 10),
        buildShimmerCard(),
      ],
    );
  }

  Widget buildShimmerCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: 180,
        height: 155,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget buildCard(String title, String amount) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          constraints: BoxConstraints(
            minHeight: 120,
            maxHeight: 150,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBF7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: Text(
                    amount,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ReceiveMoneyPage()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            'Receive money',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              foreground: Paint()
                ..shader = const LinearGradient(
                  colors: <Color>[
                    Color(0xFFF46B45),
                    Color(0xFFEEA849),
                  ],
                ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTransactions() {
    return StreamBuilder<List<QuerySnapshot<Map<String, dynamic>>>>(
      stream: StreamZip([
        _firestore
            .collection('users')
            .doc(user?.uid)
            .collection('students')
            .snapshots(),
        _firestore
            .collection('users')
            .doc(user?.uid)
            .collection('licenseonly')
            .snapshots(),
        _firestore
            .collection('users')
            .doc(user?.uid)
            .collection('endorsement')
            .snapshots(),
        _firestore
            .collection('users')
            .doc(user?.uid)
            .collection('vehicleDetails')
            .snapshots(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Error loading transactions');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return buildShimmerTransactions();
        }

        final allDocuments =
            snapshot.data?.expand((snapshot) => snapshot.docs).toList() ?? [];

        // Create a list of transactions with their respective times
        List<Map<String, dynamic>> transactions = [];

        for (var doc in allDocuments) {
          final data = doc.data();
          double advanceAmount =
              double.tryParse(data['advanceAmount']?.toString() ?? '0') ?? 0.0;
          double secondInstallment =
              double.tryParse(data['secondInstallment']?.toString() ?? '0') ??
                  0.0;
          double thirdInstallment =
              double.tryParse(data['thirdInstallment']?.toString() ?? '0') ??
                  0.0;

          // Parse dates with proper error handling
          DateTime? registrationDate;
          DateTime? secondInstallmentTime;
          DateTime? thirdInstallmentTime;

          try {
            if (data['registrationDate'] != null &&
                data['registrationDate'].toString().isNotEmpty) {
              registrationDate = DateTime.parse(data['registrationDate']);
            }
          } catch (e) {
            print('Error parsing registration date: ${e.toString()}');
            registrationDate = DateTime.fromMillisecondsSinceEpoch(
                0); // Set to epoch if parsing fails
          }

          try {
            if (data['secondInstallmentTime'] != null &&
                data['secondInstallmentTime'].toString().isNotEmpty) {
              secondInstallmentTime =
                  DateTime.parse(data['secondInstallmentTime']);
            }
          } catch (e) {
            print('Error parsing second installment time: ${e.toString()}');
            secondInstallmentTime = DateTime.fromMillisecondsSinceEpoch(
                0); // Set to epoch if parsing fails
          }

          try {
            if (data['thirdInstallmentTime'] != null &&
                data['thirdInstallmentTime'].toString().isNotEmpty) {
              thirdInstallmentTime =
                  DateTime.parse(data['thirdInstallmentTime']);
            }
          } catch (e) {
            print('Error parsing third installment time: ${e.toString()}');
            thirdInstallmentTime = DateTime.fromMillisecondsSinceEpoch(
                0); // Set to epoch if parsing fails
          }

          // Determine the correct name field based on the collection
          String nameField;
          if (doc.reference.parent.id == 'vehicleDetails') {
            nameField = data['vehicleNumber'] ?? 'N/A';
          } else {
            nameField = data['fullName'] ?? 'N/A';
          }

          // Add transactions with their respective times only if they match the selected date and are valid dates
          if (registrationDate != null &&
              isSameDate(registrationDate, selectedDate) &&
              advanceAmount > 0) {
            transactions.add({
              'time': registrationDate,
              'description': 'Advance: Rs.${advanceAmount.toStringAsFixed(0)}',
              'name': nameField,
              'doc': doc,
              'amount': advanceAmount,
            });
          }
          if (secondInstallmentTime != null &&
              isSameDate(secondInstallmentTime, selectedDate) &&
              secondInstallment > 0) {
            transactions.add({
              'time': secondInstallmentTime,
              'description':
                  '2nd Installment: Rs.${secondInstallment.toStringAsFixed(0)}',
              'name': nameField,
              'doc': doc,
              'amount': secondInstallment,
            });
          }
          if (thirdInstallmentTime != null &&
              isSameDate(thirdInstallmentTime, selectedDate) &&
              thirdInstallment > 0) {
            transactions.add({
              'time': thirdInstallmentTime,
              'description':
                  '3rd Installment: Rs.${thirdInstallment.toStringAsFixed(0)}',
              'name': nameField,
              'doc': doc,
              'amount': thirdInstallment,
            });
          }
        }

        // Sort transactions by time in descending order (most recent first)
        transactions.sort((a, b) => b['time'].compareTo(a['time']));

        double totalTransactionAmount = transactions.fold(
            0.0, (sum, transaction) => sum + transaction['amount']);

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            buildTransactionHeader(totalTransactionAmount),
            if (transactions.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    'No transactions for ${DateFormat('dd/MM/yyyy').format(selectedDate)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ),
              )
            else
              ...transactions.map((transaction) {
                return buildTransactionRow(
                  transaction['doc'],
                  formatTime(transaction['time']),
                  transaction['name'],
                  transaction['description'],
                );
              }),
          ],
        );
      },
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

  DateTime getLatestInstallmentTime(Map<String, dynamic> data) {
    DateTime secondInstallmentTime =
        DateTime.tryParse(data['secondInstallmentTime'] ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
    DateTime thirdInstallmentTime =
        DateTime.tryParse(data['thirdInstallmentTime'] ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
    return secondInstallmentTime.isAfter(thirdInstallmentTime)
        ? secondInstallmentTime
        : thirdInstallmentTime;
  }

  String formatDate(String dateStr) {
    try {
      DateTime date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return 'Invalid Date';
    }
  }

  String formatTime(DateTime dateTime) {
    return DateFormat('hh:mm a').format(dateTime);
  }

  bool isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Widget buildTransactionHeader(double totalTransactionAmount) {
    final textColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          // LEFT SIDE (flexible)
          Expanded(
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.calendar_today, color: textColor),
                  onPressed: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null && pickedDate != selectedDate) {
                      setState(() {
                        selectedDate = pickedDate;
                      });
                    }
                  },
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(selectedDate),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // RIGHT SIDE (fixed)
          Text(
            'Total: Rs.${totalTransactionAmount.toStringAsFixed(0)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTransactionRow(
    DocumentSnapshot doc,
    String time,
    String name,
    String description,
  ) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    return GestureDetector(
      onTap: () {
        // Navigate to the appropriate details page based on the collection
        if (doc.reference.parent.id == 'licenseonly') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LicenseOnlyDetailsPage(
                licenseDetails: doc.data()! as Map<String, dynamic>,
              ),
            ),
          );
        } else if (doc.reference.parent.id == 'endorsement') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EndorsementDetailsPage(
                endorsementDetails: doc.data()! as Map<String, dynamic>,
              ),
            ),
          );
        } else if (doc.reference.parent.id == 'vehicleDetails') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RCDetailsPage(
                vehicleDetails: doc.data()! as Map<String, dynamic>,
              ),
            ),
          );
        } else if (doc.reference.parent.id == 'students') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudentDetailsPage(
                studentDetails: doc.data()! as Map<String, dynamic>,
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? Colors.grey[850]
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: theme.brightness == Brightness.dark
                  ? Colors.transparent
                  : Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              text: time,
              textColor: textColor,
              fontSize: 12.2,
              fontWeight: FontWeight.w400,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: name,
                    textColor: textColor,
                    fontSize: 14.2,
                    fontWeight: FontWeight.w700,
                  ),
                  const SizedBox(height: 4),
                  CustomText(
                    text: description,
                    textColor: textColor,
                    fontSize: 12.2,
                    fontWeight: FontWeight.w400,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
