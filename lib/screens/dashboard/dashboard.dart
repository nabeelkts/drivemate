import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:drivemate/constants/constant.dart';
import 'package:drivemate/controller/app_controller.dart';
import 'package:drivemate/screens/dashboard/widgets/appbar.dart';
import 'package:drivemate/screens/dashboard/widgets/monthly_revenue_card.dart';
import 'package:drivemate/screens/dashboard/widgets/quick_register_card.dart';
import 'package:drivemate/screens/dashboard/widgets/recent_activity_card.dart';
import 'package:drivemate/screens/dashboard/widgets/school_news_card.dart';
import 'package:drivemate/screens/dashboard/widgets/today_schedule_card.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final AppController appController = Get.put(AppController());
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              Theme.of(context).brightness == Brightness.dark
                  ? Brightness.light
                  : Brightness.dark,
          statusBarBrightness: Theme.of(context).brightness == Brightness.dark
              ? Brightness.dark
              : Brightness.light,
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, top: 0, bottom: 8),
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
