import 'package:flutter/material.dart';
import 'package:mds/screens/widget/custom_back_button.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        elevation: 0,
        leading: const CustomBackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Terms of Service',
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
              '1. Acceptance of Terms',
              'By accessing and using DriveMate, you accept and agree to be bound by the terms and conditions of this agreement.',
            ),
            _buildSection(
              '2. Description of Service',
              'DriveMate is a driving school management system that provides:\n\n'
                  '• Student management\n'
                  '• Course tracking\n'
                  '• Payment processing\n'
                  '• License management\n'
                  '• Vehicle registration',
            ),
            _buildSection(
              '3. User Responsibilities',
              'As a user of DriveMate, you agree to:\n\n'
                  '• Provide accurate information\n'
                  '• Maintain the security of your account\n'
                  '• Use the service in compliance with laws\n'
                  '• Not misuse or abuse the service',
            ),
            _buildSection(
              '4. Payment Terms',
              '• All fees are non-refundable unless required by law\n'
                  '• We reserve the right to modify our fees\n'
                  '• Payment processing is handled securely',
            ),
            _buildSection(
              '5. Intellectual Property',
              'All content and materials available in DriveMate are protected by intellectual property rights. You may not use, copy, or distribute any content without permission.',
            ),
            _buildSection(
              '6. Limitation of Liability',
              'DriveMate is provided "as is" without warranties of any kind. We are not liable for any damages arising from the use of our service.',
            ),
            _buildSection(
              '7. Termination',
              'We reserve the right to terminate or suspend access to our service for any user who violates these terms.',
            ),
            _buildSection(
              '8. Changes to Terms',
              'We reserve the right to modify these terms at any time. Users will be notified of significant changes.',
            ),
            _buildSection(
              '9. Contact Information',
              'For questions about these Terms of Service, please contact us at:\n\n'
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
