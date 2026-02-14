import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/controller/workspace_controller.dart';

class SubscriptionCard extends StatelessWidget {
  final Color cardColor;
  final Color textColor;
  final VoidCallback onSubscribeDialog;

  const SubscriptionCard({
    super.key,
    required this.cardColor,
    required this.textColor,
    required this.onSubscribeDialog,
  });

  @override
  Widget build(BuildContext context) {
    final WorkspaceController workspaceController =
        Get.find<WorkspaceController>();

    return Obx(() {
      final subData = workspaceController.subscriptionData;
      if (workspaceController.isAppDataLoading.value && subData.isEmpty) {
        return const Center(child: LinearProgressIndicator());
      }

      final isDark = Theme.of(context).brightness == Brightness.dark;
      final status = subData['status'] ?? 'Trial';
      final isPremium = status == 'Premium';
      final daysLeft = subData['daysLeft'] ?? 0;
      final isExpired = subData['isExpired'] ?? false;
      final isInGracePeriod = subData['isInGracePeriod'] ?? false;
      final isGracePeriodExpired = subData['isGracePeriodExpired'] ?? false;
      final shouldWarn = subData['shouldWarn'] ?? false;

      Color badgeColor = Colors.green;
      if (isGracePeriodExpired) {
        badgeColor = Colors.grey;
      } else if (isInGracePeriod) {
        badgeColor = Colors.blue;
      } else if (shouldWarn) {
        badgeColor = Colors.red;
      }

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
            width: 1.5,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
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
                Text(
                  'Subscription',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (isExpired ? Colors.red : kOrange).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isExpired ? Icons.warning : Icons.hourglass_empty,
                    color: isExpired ? Colors.red : kOrange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isGracePeriodExpired
                            ? 'Subscription Expired'
                            : isInGracePeriod
                                ? 'Grace Period Active'
                                : '$daysLeft Days Remaining',
                        style: TextStyle(
                          color: isGracePeriodExpired
                              ? Colors.red
                              : isInGracePeriod
                                  ? Colors.blue
                                  : textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Support: drivemate.mds@gmail.com',
                        style: TextStyle(
                          color: textColor.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!isPremium || isExpired) ...[
              const SizedBox(height: 16),
              Text(
                'To get a Premium code, contact support at drivemate.mds@gmail.com',
                style: TextStyle(
                  color: textColor.withOpacity(0.6),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onSubscribeDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Upgrade to Premium',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}
