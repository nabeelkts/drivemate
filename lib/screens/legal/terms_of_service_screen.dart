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
              'Last updated: December 2025',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              '1. Acceptance of Terms',
              'By accessing and using DriveMate, you accept and agree to be bound by these Terms of Service and all applicable laws and regulations. If you do not agree to these terms, you may not use our services.',
            ),
            _buildSection(
              '2. Description of Service',
              'DriveMate is a comprehensive driving school management system that provides:\n\n'
                  '• Student registration and management\n'
                  '• Course tracking and progress monitoring\n'
                  '• License and endorsement application tracking\n'
                  '• Vehicle registration and documentation\n'
                  '• Payment processing and financial management\n'
                  '• Test scheduling and date management\n'
                  '• Reporting and analytics\n'
                  '• Multi-user organization support\n'
                  '• Real-time data synchronization\n'
                  '• Mobile and web application access',
            ),
            _buildSection(
              '3. User Account and Registration',
              'To use our services, you must:\n\n'
                  '• Provide accurate and complete registration information\n'
                  '• Maintain the security of your account credentials\n'
                  '• Be at least 18 years old or have parental consent\n'
                  '• Have authority to represent your driving school\n'
                  '• Not share your account with unauthorized users\n\n'
                  'You are responsible for all activities that occur under your account.',
            ),
            _buildSection(
              '4. User Responsibilities',
              'As a user of DriveMate, you agree to:\n\n'
                  '• Provide accurate and current information\n'
                  '• Maintain the security of your account and data\n'
                  '• Use the service in compliance with all applicable laws\n'
                  '• Not misuse or abuse the service\n'
                  '• Not attempt to reverse engineer or hack the system\n'
                  '• Not use the service for illegal activities\n'
                  '• Respect the rights and privacy of others\n'
                  '• Report any security vulnerabilities immediately',
            ),
            _buildSection(
              '5. Data Ownership and Usage',
              '• You retain ownership of all data you input into the system\n'
                  '• We may use anonymized, aggregated data for service improvement\n'
                  '• We will not sell or share your personal data without consent\n'
                  '• You grant us a license to process your data for service provision\n'
                  '• Data will be deleted upon account termination as per our Privacy Policy',
            ),
            _buildSection(
              '6. Payment Terms and Subscription',
              '• All fees are non-refundable unless required by law\n'
                  '• We reserve the right to modify our fees with 30 days notice\n'
                  '• Payment processing is handled through secure third-party providers\n'
                  '• Late payments may result in service suspension\n'
                  '• You are responsible for all taxes and fees associated with payments\n'
                  '• Subscription automatically renews unless cancelled\n'
                  '• Refund requests must be submitted within 14 days of payment',
            ),
            _buildSection(
              '7. Service Level and Availability',
              'We strive to provide reliable service:\n\n'
                  '• Target uptime: 99.5% excluding scheduled maintenance\n'
                  '• Support response time: Within 24 hours for standard inquiries\n'
                  '• Critical issue response: Within 4 hours for system emergencies\n'
                  '• Regular maintenance: Scheduled during off-peak hours\n'
                  '• Backup and recovery: Daily automated backups with 30-day retention\n\n'
                  'We are not liable for service interruptions due to circumstances beyond our control.',
            ),
            _buildSection(
              '8. Intellectual Property',
              'All content and materials available in DriveMate are protected by intellectual property rights:\n\n'
                  '• Our software, logos, and branding are our property\n'
                  '• You may not copy, modify, or distribute our content\n'
                  '• You retain rights to your own data and content\n'
                  '• Feedback and suggestions may be used to improve our services\n'
                  '• Third-party content is used under appropriate licenses',
            ),
            _buildSection(
              '9. Limitation of Liability',
              'DriveMate is provided "as is" without warranties of any kind:\n\n'
                  '• We are not liable for indirect, incidental, or consequential damages\n'
                  '• Our total liability is limited to the amount paid for services\n'
                  '• We are not responsible for data loss or business interruption\n'
                  '• Results and performance may vary based on usage and implementation\n'
                  '• Some jurisdictions do not allow limitation of liability',
            ),
            _buildSection(
              '10. Termination',
              'Either party may terminate these terms:\n\n'
                  '• Users may cancel their account at any time\n'
                  '• We may terminate accounts for violations of these terms\n'
                  '• Termination does not relieve you of payment obligations\n'
                  '• Data will be retained or deleted according to our Privacy Policy\n'
                  '• Termination does not affect accrued rights and obligations',
            ),
            _buildSection(
              '11. Updates and Modifications',
              'We reserve the right to modify these terms:\n\n'
                  '• Significant changes will be notified 30 days in advance\n'
                  '• Continued use constitutes acceptance of modified terms\n'
                  '• We may update features and functionality\n'
                  '• Legacy features may be deprecated with notice\n'
                  '• Users will be notified of major service changes',
            ),
            _buildSection(
              '12. Governing Law and Dispute Resolution',
              'These terms are governed by applicable laws:\n\n'
                  '• Disputes should first be resolved through negotiation\n'
                  '• Mediation may be required before legal proceedings\n'
                  '• Jurisdiction will be determined by your location\n'
                  '• Class action waivers may apply\n'
                  '• Any legal action must be filed within one year',
            ),
            _buildSection(
              '13. Contact Information',
              'For questions about these Terms of Service, please contact us at:\n\n'
                  '📧 Email: drivemate.mds@gmail.com\n'
                  '📱 Through the app: Contact Us section\n'
                  '🌐 Website: [if applicable]\n\n'
                  'Our support team is available to assist with any questions or concerns.',
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
