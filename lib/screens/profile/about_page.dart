import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/controller/app_controller.dart';
import 'package:mds/screens/legal/privacy_policy_screen.dart';
import 'package:mds/screens/legal/terms_of_service_screen.dart';
import 'package:mds/screens/widget/custom_back_button.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appController = Get.find<AppController>();

    final bgColor = isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.06);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white38 : Colors.black38;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: const CustomBackButton(),
        title: Text('About', style: TextStyle(color: textColor, fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── App identity block ────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                          color: kPrimaryColor.withOpacity(0.2), width: 1.5),
                    ),
                    child: Icon(Icons.directions_car_rounded,
                        color: kPrimaryColor, size: 40),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'MDS Management',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Obx(() => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: kPrimaryColor.withOpacity(0.25)),
                        ),
                        child: Text(
                          'Version ${appController.currentVersion.value}',
                          style: TextStyle(
                            color: kPrimaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )),
                  const SizedBox(height: 6),
                  Text(
                    'Made with care for driving schools',
                    style: TextStyle(
                        color: subColor, fontSize: 12),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),

            // ── Legal & updates ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                'LEGAL & UPDATES',
                style: TextStyle(
                  color: subColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            _SectionCard(
              cardColor: cardColor,
              borderColor: borderColor,
              children: [
                _MenuRow(
                  icon: Icons.privacy_tip_outlined,
                  iconColor: Colors.blue,
                  label: 'Privacy Policy',
                  textColor: textColor,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
                ),
                _Divider(color: borderColor),
                _MenuRow(
                  icon: Icons.description_outlined,
                  iconColor: Colors.indigo,
                  label: 'Terms of Service',
                  textColor: textColor,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const TermsOfServiceScreen())),
                ),
                _Divider(color: borderColor),
                _MenuRow(
                  icon: Icons.system_update_outlined,
                  iconColor: Colors.green,
                  label: 'Check for Updates',
                  textColor: textColor,
                  onTap: () => appController.checkForUpdate(),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // ── Copyright ─────────────────────────────────────────────────
            Center(
              child: Text(
                '© ${DateTime.now().year} MDS Management. All rights reserved.',
                style: TextStyle(
                  color: subColor,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Shared components ─────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  final Color cardColor;
  final Color borderColor;

  const _SectionCard({
    required this.children,
    required this.cardColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String? subtitle;
  final Color textColor;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _MenuRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.textColor,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: TextStyle(
                            color: textColor.withOpacity(0.5), fontSize: 11.5)),
                  ],
                ],
              ),
            ),
            trailing ??
                Icon(Icons.chevron_right_rounded,
                    color: textColor.withOpacity(0.28), size: 20),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final Color color;
  const _Divider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 64),
      child: Divider(height: 1, thickness: 0.5, color: color),
    );
  }
}
