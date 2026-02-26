import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mds/constants/colors.dart';
import 'package:get/get.dart';
import 'package:mds/controller/workspace_controller.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mds/utils/revenue_utils.dart';
import 'package:mds/utils/stream_utils.dart';
import 'package:animate_do/animate_do.dart';

class MonthlyRevenueCard extends StatelessWidget {
  const MonthlyRevenueCard({super.key});

  static bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.white;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _buildCard(context, textColor, 0.0, const []);
    }

    final fs = FirebaseFirestore.instance;
    final WorkspaceController workspaceController =
        Get.find<WorkspaceController>();

    return Obx(() {
      final schoolId = workspaceController.currentSchoolId.value;
      final targetId = schoolId.isNotEmpty ? schoolId : user.uid;
      final isOrg = workspaceController.isOrganizationMode.value;
      final branchId = workspaceController.currentBranchId.value;

      Query<Map<String, dynamic>> paymentsQuery =
          fs.collectionGroup('payments').where('targetId', isEqualTo: targetId);
      if (!isOrg && branchId.isNotEmpty && branchId != targetId) {
        paymentsQuery = paymentsQuery.where('branchId', isEqualTo: branchId);
      }

      return StreamBuilder<List<QuerySnapshot<Map<String, dynamic>>>>(
        stream: StreamUtils.combineLatest([
          workspaceController.getFilteredCollection('students').snapshots(),
          workspaceController.getFilteredCollection('licenseonly').snapshots(),
          workspaceController.getFilteredCollection('endorsement').snapshots(),
          workspaceController
              .getFilteredCollection('vehicleDetails')
              .snapshots(),
          workspaceController.getFilteredCollection('expenses').snapshots(),
          workspaceController.getFilteredCollection('dl_services').snapshots(),
          paymentsQuery.snapshots(),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState(context);
          }

          final now = DateTime.now();
          final todayDate = DateTime(now.year, now.month, now.day);
          double monthlyRevenue = 0.0;
          final List<double> weekValues = List.filled(7, 0.0);

          if (snapshot.hasData) {
            final dataList = snapshot.data!;
            final revenueStats = RevenueUtils.calculateMonthlyRevenue(
              snapshots: dataList,
              selectedDate: now,
              months: [now],
            );
            monthlyRevenue = revenueStats['currentMonthRevenue'] ?? 0;

            // Chart calculation
            void updateChart(DateTime dt, double amount) {
              if (amount <= 0) return;
              final normalized = DateTime(dt.year, dt.month, dt.day);
              final diff = todayDate.difference(normalized).inDays;
              if (diff >= 0 && diff < 7) {
                weekValues[6 - diff] += amount;
              }
            }

            // Process snapshots for chart specifically
            final revIndices = [0, 1, 2, 3, 5];
            for (var idx in revIndices) {
              for (var doc in dataList[idx].docs) {
                final data = doc.data();
                final reg = DateTime.tryParse(data['registrationDate'] ?? '');
                final s2t =
                    DateTime.tryParse(data['secondInstallmentTime'] ?? '');
                final s3t =
                    DateTime.tryParse(data['thirdInstallmentTime'] ?? '');
                final adv =
                    double.tryParse(data['advanceAmount']?.toString() ?? '0') ??
                        0;
                final s2a = double.tryParse(
                        data['secondInstallment']?.toString() ?? '0') ??
                    0;
                final s3a = double.tryParse(
                        data['thirdInstallment']?.toString() ?? '0') ??
                    0;

                if (reg != null) updateChart(reg, adv);
                if (s2t != null) updateChart(s2t, s2a);
                if (s3t != null) updateChart(s3t, s3a);

                for (int i = 4; i <= 20; i++) {
                  final it =
                      DateTime.tryParse(data['installment${i}Time'] ?? '');
                  final ia = double.tryParse(
                          data['installment$i']?.toString() ?? '0') ??
                      0;
                  if (it != null) updateChart(it, ia);
                }
              }
            }

            // Payments for chart
            for (var doc in dataList[6].docs) {
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
              if (pDate != null) updateChart(pDate, amount);
            }
          }

          // Convert to cumulative values for increasing bars
          final List<double> cumulativeValues = List.filled(7, 0.0);
          double runningTotal = 0.0;
          for (int i = 0; i < 7; i++) {
            runningTotal += weekValues[i];
            cumulativeValues[i] = runningTotal;
          }

          return _buildCard(
              context, textColor, monthlyRevenue, cumulativeValues);
        },
      );
    });
  }

  Widget _buildLoadingState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[850]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[800]! : Colors.grey[100]!;

    return _buildCard(
      context,
      Colors.transparent,
      0.0,
      [],
      isLoading: true,
      shimmerBase: baseColor,
      shimmerHighlight: highlightColor,
    );
  }

  Widget _buildCard(
    BuildContext context,
    Color textColor,
    double revenue,
    List<double> barValues, {
    bool isLoading = false,
    Color? shimmerBase,
    Color? shimmerHighlight,
  }) {
    final maxVal = barValues.isEmpty
        ? 1.0
        : (barValues.reduce((a, b) => a > b ? a : b) * 1.2)
            .clamp(1.0, double.infinity);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF252525),
                  const Color(0xFF1A1A1A),
                ]
              : [
                  Colors.white,
                  const Color(0xFFF8F9FA),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.05),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: -2,
          ),
        ],
      ),
      child: FadeInUp(
        duration: const Duration(milliseconds: 500),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.account_balance_wallet,
                        color: Colors.green, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Monthly Revenue',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Collected',
                          style: TextStyle(
                            color: textColor.withOpacity(0.5),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          softWrap: false,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (isLoading)
                          Shimmer.fromColors(
                            baseColor: shimmerBase!,
                            highlightColor: shimmerHighlight!,
                            child: Container(
                              height: 24,
                              width: 100,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          )
                        else
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Rs. ${NumberFormat('#,##0').format(revenue)}',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: isLoading
                          ? Shimmer.fromColors(
                              baseColor: shimmerBase!,
                              highlightColor: shimmerHighlight!,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: List.generate(
                                    7,
                                    (i) => Container(
                                          width: 4,
                                          height: 20 + (i * 2.0),
                                          color: Colors.white,
                                        )),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: List.generate(7, (i) {
                                final h = maxVal > 0
                                    ? (barValues[i] / maxVal * 36)
                                        .clamp(4.0, 36.0)
                                    : 4.0;
                                return Container(
                                  width: 4, // Narrower bars
                                  height: h,
                                  decoration: BoxDecoration(
                                    color: kOrange.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                );
                              }),
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up, color: Colors.blue, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'Active Month',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
