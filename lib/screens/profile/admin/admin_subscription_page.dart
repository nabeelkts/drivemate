import 'package:flutter/material.dart';
import 'package:drivemate/constants/colors.dart';
import 'package:drivemate/screens/profile/admin/manage_carousel_page.dart';
import 'package:drivemate/screens/profile/admin/manage_codes_page.dart';
import 'package:drivemate/screens/profile/admin/manage_users_page.dart';
import 'package:drivemate/screens/profile/admin/manage_support_chats_page.dart';

class AdminSubscriptionPage extends StatefulWidget {
  const AdminSubscriptionPage({super.key});

  @override
  State<AdminSubscriptionPage> createState() => _AdminSubscriptionPageState();
}

class _AdminSubscriptionPageState extends State<AdminSubscriptionPage> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,
        title: Text(
          'Admin Panel',
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.photo_library, color: textColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageCarouselPage(),
                ),
              );
            },
            tooltip: 'Manage Carousel',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 130,
              child: _buildAdminCard(
                context: context,
                isDark: isDark,
                title: 'Subscription Codes',
                description: 'Generate and manage subscription codes for new users',
                icon: Icons.confirmation_number,
                color: Colors.blue,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ManageCodesPage()),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 130,
              child: _buildAdminCard(
                context: context,
                isDark: isDark,
                title: 'Manage Users',
                description: 'View and manage all registered users and their subscriptions',
                icon: Icons.people,
                color: Colors.purple,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ManageUsersPage()),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 130,
              child: _buildAdminCard(
                context: context,
                isDark: isDark,
                title: 'Support Chats',
                description: 'View and respond to user support requests',
                icon: Icons.support_agent,
                color: Colors.green,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ManageSupportChatsPage()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCard({
    required BuildContext context,
    required bool isDark,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.8),
              color.withOpacity(0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      size: 28,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white.withOpacity(0.7),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
