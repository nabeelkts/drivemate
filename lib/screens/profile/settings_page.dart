import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/controller/app_controller.dart';
import 'package:mds/controller/theme_controller.dart';
import 'package:mds/screens/profile/home_layout_selector.dart';
import 'package:mds/screens/profile/dialog_box.dart';
import 'package:mds/screens/authentication/google_sign_in.dart';
import 'package:mds/screens/widget/custom_back_button.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;
  final bool notificationsEnabled;
  final Function() toggleNotifications;
  final bool biometricEnabled;
  final Function() toggleBiometric;

  SettingsPage({
    super.key,
    required this.toggleTheme,
    required this.isDarkMode,
    required this.notificationsEnabled,
    required this.toggleNotifications,
    required this.biometricEnabled,
    required this.toggleBiometric,
  });

  final AppController appController = Get.find<AppController>();
  final ThemeController themeController = Get.find<ThemeController>();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? Colors.grey.shade900 : Colors.grey.shade100;
    final borderColor = isDark ? Colors.grey.shade600 : Colors.grey.shade400;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey.shade200,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,
        leading: const CustomBackButton(),
        title: Text(
          'Settings',
          style: TextStyle(
              color: textColor, fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Preferences',
                style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildSection(isDark, cardColor, [
              _buildSettingTile(
                  textColor: textColor,
                  icon: Icons.brightness_6,
                  title: 'Dark Mode',
                  subtitle: isDarkMode ? 'Enabled' : 'Disabled',
                  trailing: Switch(
                      value: isDarkMode,
                      onChanged: (v) => toggleTheme(),
                      activeColor: themeController.themeColor)),
              /* _buildSettingTile(
                  textColor: textColor,
                  icon: Icons.dashboard_customize,
                  title: 'Home layout',
                  subtitle: 'Choose your home screen design',
                  trailing: Icon(Icons.chevron_right,
                      color: textColor.withOpacity(0.5)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomeLayoutSelector(),
                      ),
                    );
                  }), */
              _buildSettingTile(
                  textColor: textColor,
                  icon: Icons.notifications,
                  title: 'Notifications',
                  subtitle: '',
                  trailing: Switch(
                      value: notificationsEnabled,
                      onChanged: (v) => toggleNotifications(),
                      activeColor: themeController.themeColor)),
              _buildSettingTile(
                  textColor: textColor,
                  icon: Icons.fingerprint,
                  title: 'Biometric login',
                  subtitle: 'Use fingerprint/face ID',
                  trailing: Switch(
                      value: biometricEnabled,
                      onChanged: (v) => toggleBiometric(),
                      activeColor: themeController.themeColor)),
            ]),
            const SizedBox(height: 24),
            Text('Account Actions',
                style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildAccountActionButton(
                    cardColor: cardColor,
                    borderColor: borderColor,
                    textColor: textColor,
                    label: 'Change password',
                    icon: Icons.lock,
                    onTap: () async {
                      final email = _auth.currentUser?.email;
                      if (email == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'No email associated with this account')));
                        return;
                      }
                      try {
                        await _auth.sendPasswordResetEmail(email: email);
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Password reset email sent')));
                      } on FirebaseAuthException catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content:
                                Text('Failed to send email. ${e.message}')));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildAccountActionButton(
                    cardColor: cardColor,
                    borderColor: borderColor,
                    textColor: textColor,
                    label: 'Logout',
                    icon: Icons.logout,
                    onTap: () => _showLogoutConfirmationDialog(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showCustomConfirmationDialog(
      context,
      'Logout',
      'Are you sure you want to logout?',
      () async {
        // Close confirmation dialog first
        Navigator.pop(context);
        final provider =
            Provider.of<GoogleSignInProvider>(context, listen: false);
        await provider.signOut(context);
      },
    );
  }

  Widget _buildSection(bool isDark, Color cardColor, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
          width: 1,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingTile({
    required Color textColor,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: textColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: kOrange, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: TextStyle(
                          color: textColor.withOpacity(0.5),
                          fontSize: 11,
                          fontWeight: FontWeight.w400),
                    ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildAccountActionButton({
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: kOrange, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                  color: textColor, fontSize: 13, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
