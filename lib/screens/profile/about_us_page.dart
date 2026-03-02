import 'package:flutter/material.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/screens/widget/custom_back_button.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white38 : Colors.black38;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: const CustomBackButton(),
        title: Text('About Us',
            style: TextStyle(color: textColor, fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Section ────────────────────────────────────────
            Center(
              child: Column(
                children: [
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
                  const SizedBox(height: 16),
                  Text(
                    'Drivemate Management',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Smart Driving School Management Solution',
                    style: TextStyle(
                      color: subColor,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // ── About Content ───────────────────────────────────────────
            _buildContentCard(
              cardColor: cardColor,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About Drivemate',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Drivemate is a comprehensive driving school management solution designed to streamline operations and enhance the learning experience for Owner, Staff, Instructors, Students and other customers. Our platform combines modern technology with industry expertise to create an efficient, user-friendly system for driving education management.',
                        style: TextStyle(
                          color: textColor.withOpacity(0.8),
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Our Mission',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'To revolutionize driving education through innovative technology, making driving school management efficient, accessible, and student-focused. We strive to empower driving instructors with powerful tools while providing students with a seamless learning experience.',
                        style: TextStyle(
                          color: textColor.withOpacity(0.8),
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Key Features',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureItem(
                          '✓ Student Registration & Tracking', textColor),
                      _buildFeatureItem(
                          '✓ License & Endorsement Management', textColor),
                      _buildFeatureItem(
                          '✓ Vehicle Registration System', textColor),
                      _buildFeatureItem(
                          '✓ Payment & Fee Management', textColor),
                      _buildFeatureItem(
                          '✓ Test Scheduling & Updates', textColor),
                      _buildFeatureItem(
                          '✓ Multi-Branch Organization Support', textColor),
                      _buildFeatureItem(
                          '✓ Real-time Data Synchronization', textColor),
                      _buildFeatureItem(
                          '✓ Advanced Search Capabilities', textColor),
                      _buildFeatureItem(
                          '✓ Automated Notifications & Reminders', textColor),
                      _buildFeatureItem(
                          '✓ Detailed Reporting & Analytics', textColor),
                      const SizedBox(height: 20),
                      Text(
                        'Technology',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Built with Flutter for cross-platform compatibility, powered by Firebase for real-time data management, and designed with security and user experience as top priorities. Our cloud-based architecture ensures data is always synchronized and accessible from any device.',
                        style: TextStyle(
                          color: textColor.withOpacity(0.8),
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Security & Compliance',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'We prioritize the security and privacy of your data with end-to-end encryption, secure cloud storage, and compliance with industry standards. Regular security audits and updates ensure your information remains protected.',
                        style: TextStyle(
                          color: textColor.withOpacity(0.8),
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Contact Information ─────────────────────────────────────
            _buildContentCard(
              cardColor: cardColor,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Get In Touch',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.email_outlined,
                              color: kPrimaryColor, size: 18),
                          const SizedBox(width: 10),
                          Text(
                            'drivemate.mds@gmail.com',
                            style: TextStyle(
                              color: textColor.withOpacity(0.8),
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We\'re here to help! Reach out to us for support, feedback, or partnership opportunities.',
                        style: TextStyle(
                          color: textColor.withOpacity(0.6),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildContentCard({
    required Color cardColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
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

  Widget _buildFeatureItem(String text, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: textColor.withOpacity(0.8),
          fontSize: 15,
        ),
      ),
    );
  }
}
