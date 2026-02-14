import 'package:async/async.dart'; // Import the async package
import 'package:mds/utils/stream_utils.dart';
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
import 'package:mds/screens/dashboard/list/details/vehicle_details_page.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mds/screens/dashboard/widgets/custom/custom_text.dart';
import 'package:mds/screens/statistics/receive_money.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'package:mds/controller/workspace_controller.dart';
import 'package:shimmer/shimmer.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? user = FirebaseAuth.instance.currentUser;
  final WorkspaceController _workspaceController =
      Get.find<WorkspaceController>();
  DateTime selectedDate = DateTime.now();
  String selectedFilter = 'Month'; // Default to Month
  double totalRevenue = 0.0;
  double totalBalanceAmount = 0.0;

  // Define the filter options as a constant list

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
    final backgroundColor =
        isDark ? const Color(0xFF121212) : Colors.grey.shade100;

    return SafeArea(
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(textColor, isDark),
                const SizedBox(height: 20),
                _buildBusinessPerformanceCard(isDark),
                const SizedBox(height: 20),
                _buildMetricsGrid(isDark),
                const SizedBox(height: 12),
                _buildExpensesCard(isDark),
                const SizedBox(height: 12),
                _buildActionsRow(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color textColor, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Business Performance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            _buildPeriodSelector(isDark),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Revenue vs Expenses',
          style: TextStyle(
            fontSize: 16,
            color: textColor.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector(bool isDark) {
    return GestureDetector(
      onTap: () => _showMonthFilterSheet(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black12,
          ),
        ),
        child: Row(
          children: [
            Text(
              DateFormat('MMM yyyy').format(selectedDate),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessPerformanceCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              // Responsive height: 150-200px based on available width
              final chartHeight = constraints.maxWidth > 400 ? 200.0 : 150.0;
              return SizedBox(
                height: chartHeight,
                child: _buildRedesignedChart(isDark),
              );
            },
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              'Showing last 6 months',
              style: TextStyle(
                fontSize: 13,
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRedesignedChart(bool isDark) {
    final schoolId = _workspaceController.currentSchoolId.value;
    final targetId = schoolId.isNotEmpty ? schoolId : (user?.uid ?? '');

    return StreamBuilder<List<QuerySnapshot<Map<String, dynamic>>>>(
      stream: _getCombinedStatsStream(targetId),
      builder: (context, snapshot) {
        if (!snapshot.hasData ||
            snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerLoader(200, isDark);
        }

        final dataList = snapshot.data!;
        Map<String, double> revenueByMonth = {};
        Map<String, double> expensesByMonth = {};
        List<DateTime> months = List.generate(6, (i) {
          return DateTime(selectedDate.year, selectedDate.month - (5 - i), 1);
        });

        for (var month in months) {
          String key = DateFormat('MM/yy').format(month);
          revenueByMonth[key] = 0;
          expensesByMonth[key] = 0;
        }

        // 1. Process Revenue from main collections (indices 0, 1, 2, 3, 5)
        final revIndices = [0, 1, 2, 3, 5];
        for (var idx in revIndices) {
          if (dataList.length > idx) {
            for (var doc in dataList[idx].docs) {
              _processRevenue(doc.data(), months, revenueByMonth);
            }
          }
        }

        // 2. Process Expenses (index 4)
        if (dataList.length > 4) {
          for (var doc in dataList[4].docs) {
            _processExpenses(doc.data(), months, expensesByMonth);
          }
        }

        // 3. Process Payments (index 6)
        if (dataList.length > 6) {
          for (var doc in dataList[6].docs) {
            final data = doc.data();
            double amount = double.tryParse(data['amountPaid']?.toString() ??
                    data['amount']?.toString() ??
                    '0') ??
                0;
            DateTime? date;
            if (data['date'] is Timestamp) {
              date = (data['date'] as Timestamp).toDate();
            } else {
              date = DateTime.tryParse(data['date']?.toString() ?? '');
            }

            if (date != null) {
              for (var month in months) {
                String key = DateFormat('MM/yy').format(month);
                if (date.year == month.year && date.month == month.month) {
                  revenueByMonth[key] = (revenueByMonth[key] ?? 0) + amount;
                }
              }
            }
          }
        }

        double maxY = _getMaxY(revenueByMonth, expensesByMonth);

        return BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                tooltipBgColor: isDark ? Colors.grey.shade800 : Colors.white,
                tooltipBorder:
                    BorderSide(color: isDark ? Colors.white10 : Colors.black12),
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  String key = DateFormat('MM/yy').format(months[groupIndex]);
                  double rev = revenueByMonth[key] ?? 0;
                  double exp = expensesByMonth[key] ?? 0;
                  return BarTooltipItem(
                    '${DateFormat('MMM yy').format(months[groupIndex])}\n',
                    const TextStyle(fontWeight: FontWeight.bold),
                    children: [
                      TextSpan(
                        text: 'Rev: Rs. ${rev.toStringAsFixed(0)}\n',
                        style: const TextStyle(
                            color: Colors.green, fontWeight: FontWeight.normal),
                      ),
                      TextSpan(
                        text: 'Exp: Rs. ${exp.toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.normal),
                      ),
                    ],
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value < 0 || value >= months.length)
                      return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        DateFormat('MMM').format(months[value.toInt()]),
                        style: TextStyle(
                          color: (isDark ? Colors.white : Colors.black)
                              .withOpacity(0.5),
                          fontSize: 10,
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(months.length, (i) {
              String key = DateFormat('MM/yy').format(months[i]);
              double rev = revenueByMonth[key] ?? 0;
              double exp = expensesByMonth[key] ?? 0;
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: rev,
                    color: Colors.green,
                    width: 12,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                  BarChartRodData(
                    toY: exp,
                    color: Colors.redAccent.withOpacity(0.7),
                    width: 12,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ],
              );
            }),
          ),
        );
      },
    );
  }

  void _processRevenue(Map<String, dynamic> data, List<DateTime> months,
      Map<String, double> revenueByMonth) {
    double advance =
        double.tryParse(data['advanceAmount']?.toString() ?? '0') ?? 0;
    double second =
        double.tryParse(data['secondInstallment']?.toString() ?? '0') ?? 0;
    double third =
        double.tryParse(data['thirdInstallment']?.toString() ?? '0') ?? 0;

    DateTime? t1 = DateTime.tryParse(data['registrationDate'] ?? '');
    DateTime? t2 = DateTime.tryParse(data['secondInstallmentTime'] ?? '');
    DateTime? t3 = DateTime.tryParse(data['thirdInstallmentTime'] ?? '');

    for (var month in months) {
      String key = DateFormat('MM/yy').format(month);
      if (t1 != null && t1.year == month.year && t1.month == month.month)
        revenueByMonth[key] = (revenueByMonth[key] ?? 0) + advance;
      if (t2 != null && t2.year == month.year && t2.month == month.month)
        revenueByMonth[key] = (revenueByMonth[key] ?? 0) + second;
      if (t3 != null && t3.year == month.year && t3.month == month.month)
        revenueByMonth[key] = (revenueByMonth[key] ?? 0) + third;
    }
  }

  void _processExpenses(Map<String, dynamic> data, List<DateTime> months,
      Map<String, double> expensesByMonth) {
    double amount = double.tryParse(data['amount']?.toString() ?? '0') ?? 0;
    DateTime? date = DateTime.tryParse(data['date'] ?? '');
    if (date == null) return;

    for (var month in months) {
      String key = DateFormat('MM/yy').format(month);
      if (date.year == month.year && date.month == month.month) {
        expensesByMonth[key] = (expensesByMonth[key] ?? 0) + amount;
      }
    }
  }

  double _getMaxY(Map<String, double> r, Map<String, double> e) {
    double max = 0;
    r.values.forEach((v) => max = v > max ? v : max);
    e.values.forEach((v) => max = v > max ? v : max);
    return max == 0 ? 100 : max * 1.2;
  }

  Stream<List<QuerySnapshot<Map<String, dynamic>>>> _getCombinedStatsStream(
      String targetId) {
    return StreamUtils.combineLatest([
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
    ]);
  }

  Widget _buildMetricsGrid(bool isDark) {
    final schoolId = _workspaceController.currentSchoolId.value;
    final targetId = schoolId.isNotEmpty ? schoolId : (user?.uid ?? '');

    return StreamBuilder<List<QuerySnapshot<Map<String, dynamic>>>>(
      stream: _getCombinedStatsStream(targetId),
      builder: (context, snapshot) {
        if (!snapshot.hasData ||
            snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerLoader(100, isDark);
        }

        final List<Map<String, dynamic>> allItems = [];
        final collections = [
          'students',
          'licenseonly',
          'endorsement',
          'vehicleDetails',
          'expenses',
          'dl_services',
          'payments'
        ];

        for (int i = 0; i < snapshot.data!.length; i++) {
          final docs = snapshot.data![i].docs;
          final source = collections[i];
          // We only aggregate main record collections for "Total Learners" and "Outstanding"
          // expenses (4) and payments (6) are handled separately for revenue calculations
          if (i == 4 || i == 6) continue;

          for (var doc in docs) {
            allItems.add({
              'data': doc.data(),
              'id': doc.id,
              'source': source,
            });
          }
        }

        int totalLearners = allItems.length;
        double currentMonthRevenue = 0;
        double totalBalance = 0;

        final startOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
        final endOfMonth =
            DateTime(selectedDate.year, selectedDate.month + 1, 0, 23, 59, 59);

        // Revenue from main collections
        for (var item in allItems) {
          final data = item['data'] as Map<String, dynamic>;
          double advance =
              double.tryParse(data['advanceAmount']?.toString() ?? '0') ?? 0;
          double second =
              double.tryParse(data['secondInstallment']?.toString() ?? '0') ??
                  0;
          double third =
              double.tryParse(data['thirdInstallment']?.toString() ?? '0') ?? 0;
          double balance =
              double.tryParse(data['balanceAmount']?.toString() ?? '0') ?? 0;

          totalBalance += balance;

          DateTime? t1 = DateTime.tryParse(data['registrationDate'] ?? '');
          DateTime? t2 = DateTime.tryParse(data['secondInstallmentTime'] ?? '');
          DateTime? t3 = DateTime.tryParse(data['thirdInstallmentTime'] ?? '');

          if (t1 != null &&
              t1.isAfter(startOfMonth.subtract(const Duration(seconds: 1))) &&
              t1.isBefore(endOfMonth.add(const Duration(seconds: 1)))) {
            currentMonthRevenue += advance;
          }
          if (t2 != null &&
              t2.isAfter(startOfMonth.subtract(const Duration(seconds: 1))) &&
              t2.isBefore(endOfMonth.add(const Duration(seconds: 1)))) {
            currentMonthRevenue += second;
          }
          if (t3 != null &&
              t3.isAfter(startOfMonth.subtract(const Duration(seconds: 1))) &&
              t3.isBefore(endOfMonth.add(const Duration(seconds: 1)))) {
            currentMonthRevenue += third;
          }
        }

        // Revenue from Payments collectionGroup (index 6)
        if (snapshot.data!.length > 6) {
          for (var doc in snapshot.data![6].docs) {
            final data = doc.data();
            double amount = double.tryParse(data['amountPaid']?.toString() ??
                    data['amount']?.toString() ??
                    '0') ??
                0;
            DateTime? pDate;
            if (data['date'] is Timestamp) {
              pDate = (data['date'] as Timestamp).toDate();
            } else {
              pDate = DateTime.tryParse(data['date']?.toString() ?? '');
            }

            if (pDate != null &&
                pDate.isAfter(
                    startOfMonth.subtract(const Duration(seconds: 1))) &&
                pDate.isBefore(endOfMonth.add(const Duration(seconds: 1)))) {
              // Special case: if this payment is also an advance, we might double count
              // But usually 'payments' subcollection is for installments, while 'advance' is in root.
              // However, PaymentUtils adds advances to 'payments' too.
              // To avoid double counting, we'd need to check if the main record registrationDate matches.
              // For simplicity now, we assume root record advance is the primary source if it exists.
              // Actually, many root records DON'T have sub-payments yet.
              currentMonthRevenue += amount;
            }
          }
        }

        // Calculate Total Learners Growth
        final endOfLastMonth =
            DateTime(selectedDate.year, selectedDate.month, 0);

        int learnersLastMonthEnd = 0;
        int learnersCurrentTotal = totalLearners;

        for (var item in allItems) {
          final data = item['data'] as Map<String, dynamic>;
          DateTime? regDate = DateTime.tryParse(data['registrationDate'] ?? '');
          if (regDate != null &&
              regDate
                  .isBefore(endOfLastMonth.add(const Duration(seconds: 1)))) {
            learnersLastMonthEnd++;
          }
        }

        double growthPercentage = 0;
        if (learnersLastMonthEnd > 0) {
          growthPercentage = ((learnersCurrentTotal - learnersLastMonthEnd) /
                  learnersLastMonthEnd) *
              100;
        } else if (learnersCurrentTotal > 0) {
          growthPercentage = 100; // From 0 to something is 100% (or infinite)
        }

        String growthString = '${growthPercentage.abs().toStringAsFixed(1)}%';
        String growthLabel = growthPercentage >= 0
            ? '+$growthString from last month'
            : '-$growthString from last month';
        Color growthColor = growthPercentage >= 0 ? Colors.green : Colors.red;

        return Column(
          children: [
            GestureDetector(
              onTap: () => _showLearnersSummary(context, snapshot.data!),
              child: _buildMetricCard(
                'Total Learners',
                totalLearners.toString(),
                growthLabel,
                growthColor, // Pass color
                isDark,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showRevenueDetails(context, allItems),
                    child: _buildMetricCard(
                      'Revenue (${DateFormat('MMM').format(selectedDate)})',
                      'Rs. ${currentMonthRevenue.toStringAsFixed(0)}',
                      null,
                      kOrange,
                      isDark,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showOutstandingDetails(context, allItems),
                    child: _buildMetricCard(
                      'Outstanding Due',
                      'Rs. ${totalBalance.toStringAsFixed(0)}',
                      null,
                      Colors.redAccent,
                      isDark,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildExpensesCard(bool isDark) {
    final schoolId = _workspaceController.currentSchoolId.value;
    final targetId = schoolId.isNotEmpty ? schoolId : user?.uid;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('users')
          .doc(targetId)
          .collection('expenses')
          .snapshots(),
      builder: (context, snapshot) {
        double totalExpenses = 0;
        List<String> categories = [];

        if (snapshot.hasData) {
          final startOfMonth =
              DateTime(selectedDate.year, selectedDate.month, 1);
          final endOfMonth =
              DateTime(selectedDate.year, selectedDate.month + 1, 0);

          for (var doc in snapshot.data!.docs) {
            final data = doc.data();
            double amount =
                double.tryParse(data['amount']?.toString() ?? '0') ?? 0;
            DateTime? date = DateTime.tryParse(data['date'] ?? '');

            if (date != null &&
                date.isAfter(
                    startOfMonth.subtract(const Duration(seconds: 1))) &&
                date.isBefore(endOfMonth.add(const Duration(seconds: 1)))) {
              totalExpenses += amount;
              String cat = data['categoryLabel'] ?? data['category'] ?? 'Other';
              if (!categories.contains(cat)) categories.add(cat);
            }
          }
        }

        return GestureDetector(
          onTap: () => _showExpenseDetails(context, snapshot.data!.docs),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Expenses (${DateFormat('MMM').format(selectedDate)})',
                          style: TextStyle(
                            fontSize: 13,
                            color: (isDark ? Colors.white : Colors.black)
                                .withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Rs. ${totalExpenses.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_upward,
                          color: Colors.redAccent, size: 20),
                    ),
                  ],
                ),
                if (categories.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories
                        .take(3)
                        .map((c) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white10
                                    : Colors.black.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                c,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: (isDark ? Colors.white : Colors.black)
                                      .withOpacity(0.6),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(
      String title, String value, String? subValue, Color? color, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (subValue != null) ...[
            const SizedBox(height: 4),
            Text(
              subValue,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionsRow(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Outstanding Due',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        (isDark ? Colors.white : Colors.black).withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Summary of all pending payments',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const ReceiveMoneyPage())),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: kOrange,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: kOrange.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              children: [
                Text(
                  'Receive Payment',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, color: Colors.white, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showLearnersSummary(BuildContext context,
      List<QuerySnapshot<Map<String, dynamic>>> snapshots) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final labels = ['Students', 'License Only', 'Endorsement', 'Vehicles'];
        final colors = [kOrange, Colors.blue, Colors.green, Colors.purple];
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Learners Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ...List.generate(snapshots.length, (i) {
                final count = snapshots[i].docs.length;
                return ListTile(
                  leading: CircleAvatar(backgroundColor: colors[i], radius: 6),
                  title: Text(labels[i]),
                  trailing: Text(count.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showRevenueDetails(
      BuildContext context, List<Map<String, dynamic>> items) {
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
          for (var item in items) {
            final data = item['data'] as Map<String, dynamic>;
            final name = data['fullName'] ?? data['vehicleNumber'] ?? 'N/A';
            final source = item['source'];
            final id = item['id'];

            DateTime? t1 = DateTime.tryParse(data['registrationDate'] ?? '');
            DateTime? t2 =
                DateTime.tryParse(data['secondInstallmentTime'] ?? '');
            DateTime? t3 =
                DateTime.tryParse(data['thirdInstallmentTime'] ?? '');

            if (t1 != null) {
              transactions.add({
                'name': name,
                'amount':
                    double.tryParse(data['advanceAmount']?.toString() ?? '0') ??
                        0,
                'date': t1,
                'label': 'Advance',
                'source': source,
                'id': id,
                'data': data,
              });
            }
            if (t2 != null) {
              transactions.add({
                'name': name,
                'amount': double.tryParse(
                        data['secondInstallment']?.toString() ?? '0') ??
                    0,
                'date': t2,
                'label': '2nd Installment',
                'source': source,
                'id': id,
                'data': data,
              });
            }
            if (t3 != null) {
              transactions.add({
                'name': name,
                'amount': double.tryParse(
                        data['thirdInstallment']?.toString() ?? '0') ??
                    0,
                'date': t3,
                'label': '3rd Installment',
                'source': source,
                'id': id,
                'data': data,
              });
            }
          }
          transactions.sort((a, b) => b['date'].compareTo(a['date']));
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
            (v) => setStateSB(() => localDate = v),
            (item) => _navigateToDetails(context, item),
          );
        });
      },
    );
  }

  void _showOutstandingDetails(
      BuildContext context, List<Map<String, dynamic>> items) {
    // First, process all items to get waiting dues
    List<Map<String, dynamic>> allOutstandingItems = items.where((item) {
      final data = item['data'] as Map<String, dynamic>;
      return (double.tryParse(data['balanceAmount']?.toString() ?? '0') ?? 0) >
          0;
    }).map((item) {
      final data = item['data'] as Map<String, dynamic>;
      return {
        'name': data['fullName'] ?? data['vehicleNumber'] ?? 'N/A',
        'amount':
            double.tryParse(data['balanceAmount']?.toString() ?? '0') ?? 0.0,
        'date':
            DateTime.tryParse(data['registrationDate'] ?? '') ?? DateTime(2000),
        'label': data['mobileNumber'] ?? '',
        'source': item['source'],
        'id': item['id'],
        'data': data,
      };
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String localFilter = 'All';
        DateTime localDate = DateTime.now();

        return StatefulBuilder(
          builder: (ctx, setStateSB) {
            // Apply Date/Type Filter
            final sortedItems =
                List<Map<String, dynamic>>.from(allOutstandingItems);
            sortedItems.sort((a, b) =>
                (b['date'] as DateTime).compareTo(a['date'] as DateTime));

            final filtered = sortedItems.where((t) {
              if (localFilter == 'All') return true;
              final d = t['date'] as DateTime;
              if (localFilter == 'Day') return isSameDate(d, localDate);
              if (localFilter == 'Month')
                return d.year == localDate.year && d.month == localDate.month;
              if (localFilter == 'Year') return d.year == localDate.year;
              return true;
            }).toList();

            double total = filtered.fold(
                0, (sum, item) => sum + (item['amount'] as double));

            return _buildFilterListSheet(
              context,
              'Outstanding Due',
              total,
              localFilter,
              localDate,
              filtered,
              (v) => setStateSB(() => localFilter = v),
              (v) => setStateSB(() => localDate = v),
              (item) => _navigateToDetails(context, item),
            );
          },
        );
      },
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
          expenses.sort((a, b) =>
              (b['date'] as DateTime).compareTo(a['date'] as DateTime));
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
              (v) => setStateSB(() => localDate = v),
              null);
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
      Function(DateTime) onDateChanged,
      Function(Map<String, dynamic>)? onItemTap) {
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
                        onTap: onItemTap != null ? () => onItemTap(item) : null,
                        title: Text(item['name']),
                        subtitle: Text(
                            '${DateFormat('dd/MM/yyyy').format(item['date'])} ${item['label'].isNotEmpty ? '• ${item['label']}' : ''}'),
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

  void _navigateToDetails(BuildContext context, Map<String, dynamic> item) {
    if (item['source'] == null) return;
    final source = item['source'];
    final data = item['data'] as Map<String, dynamic>;
    final id = item['id'];

    final detailsData = Map<String, dynamic>.from(data);
    if (!detailsData.containsKey('studentId')) {
      detailsData['studentId'] = id;
    }
    if (!detailsData.containsKey('id')) {
      detailsData['id'] = id;
    }

    if (source == 'students') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StudentDetailsPage(
            studentDetails: detailsData,
          ),
        ),
      );
    } else if (source == 'licenseonly') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LicenseOnlyDetailsPage(
            licenseDetails: detailsData,
          ),
        ),
      );
    } else if (source == 'endorsement') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EndorsementDetailsPage(
            endorsementDetails: detailsData,
          ),
        ),
      );
    } else if (source == 'vehicleDetails') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VehicleDetailsPage(
            vehicleDetails: detailsData,
          ),
        ),
      );
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

  Widget _buildShimmerLoader(double height, bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.white10 : Colors.grey.shade300,
      highlightColor: isDark ? Colors.white24 : Colors.grey.shade100,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
