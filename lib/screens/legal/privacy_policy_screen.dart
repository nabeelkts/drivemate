import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Policy',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Last updated: June 2025',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              '1. Information We Collect',
              'We collect information that you provide directly to us, including:\n\n'
                  '• Personal information (name, email address, phone number)\n'
                  '• Student information (course details, progress, payments)\n'
                  '• Device information (device type, operating system)\n'
                  '• Usage information (app interactions, features used)',
            ),
            _buildSection(
              '2. How We Use Your Information',
              'We use the collected information to:\n\n'
                  '• Provide and maintain our services\n'
                  '• Process your transactions\n'
                  '• Send you important updates\n'
                  '• Improve our services\n'
                  '• Comply with legal obligations',
            ),
            _buildSection(
              '3. Data Security',
              'We implement appropriate security measures to protect your personal information. However, no method of transmission over the internet is 100% secure.',
            ),
            _buildSection(
              '4. Data Sharing',
              'We do not sell your personal information. We may share your information with:\n\n'
                  '• Service providers\n'
                  '• Legal authorities when required\n'
                  '• Business partners with your consent',
            ),
            _buildSection(
              '5. Your Rights',
              'You have the right to:\n\n'
                  '• Access your personal information\n'
                  '• Correct inaccurate data\n'
                  '• Request deletion of your data\n'
                  '• Opt-out of communications',
            ),
            _buildSection(
              '6. Contact Us',
              'If you have any questions about this Privacy Policy, please contact us at:\n\n'
                  'Email: drivemate.mds@gmail.com\n',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
