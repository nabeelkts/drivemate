import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mds/constants/colors.dart';

class ListSummaryHeader extends StatelessWidget {
  final String totalLabel;
  final int totalCount;
  final double pendingDues;
  final bool isDark;

  const ListSummaryHeader({
    super.key,
    required this.totalLabel,
    required this.totalCount,
    required this.pendingDues,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              context: context,
              label: totalLabel,
              value: totalCount.toString(),
              cardColor: cardColor,
              textColor: textColor,
              subTextColor: subTextColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              context: context,
              label: 'Pending Dues:',
              value: 'Rs. ${pendingDues.toStringAsFixed(0)}',
              showChart: true,
              cardColor: cardColor,
              textColor: textColor,
              subTextColor: subTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required BuildContext context,
    required String label,
    required String value,
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
    bool showChart = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: kPrimaryColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: subTextColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (showChart)
                SizedBox(
                  width: 50,
                  height: 30,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: 6,
                      minY: 0,
                      maxY: 6,
                      lineBarsData: [
                        LineChartBarData(
                          spots: const [
                            FlSpot(0, 2),
                            FlSpot(1, 1),
                            FlSpot(2, 4),
                            FlSpot(3, 3),
                            FlSpot(4, 5),
                            FlSpot(5, 4),
                            FlSpot(6, 6),
                          ],
                          isCurved: true,
                          color: kPrimaryColor,
                          barWidth: 2,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: kPrimaryColor.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
