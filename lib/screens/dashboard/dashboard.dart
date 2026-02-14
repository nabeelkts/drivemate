import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mds/constants/constant.dart';
import 'package:mds/controller/app_controller.dart';
import 'package:mds/screens/dashboard/widgets/appbar.dart';
import 'package:mds/screens/dashboard/widgets/monthly_revenue_card.dart';
import 'package:mds/screens/dashboard/widgets/quick_register_card.dart';
import 'package:mds/screens/dashboard/widgets/recent_activity_card.dart';
import 'package:mds/screens/dashboard/widgets/school_news_card.dart';
import 'package:mds/screens/dashboard/widgets/today_schedule_card.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final AppController appController = Get.put(AppController());
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const DashAppBar(),
                kSizedBox,
                // Row 1: Today's Schedule (left) | Quick Register (right)
                // Row 1: Today's Schedule (left) | Quick Register (right)
                // Row 1: Today's Schedule (left) | Quick Register (right)
                // Row 1: Today's Schedule (left) | Quick Register (right)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      flex: 4,
                      child: TodayScheduleCard(),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      flex: 6,
                      child: QuickRegisterCard(),
                    ),
                  ],
                ),
                kSizedBox,
                // Row 2: Recent Activity (60%) | Monthly Revenue (40%)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      flex: 6,
                      child: RecentActivityCard(),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      flex: 4,
                      child: MonthlyRevenueCard(),
                    ),
                  ],
                ),
                kSizedBox,
                // School News & Tips (full width)
                const SchoolNewsCard(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
