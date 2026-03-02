import 'package:flutter/material.dart';
import 'package:mds/screens/widget/custom_back_button.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        elevation: 0,
        leading: const CustomBackButton(),
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
              'Last updated: December 2025',
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
                  '• Vehicle information (registration details, insurance)\n'
                  '• License and endorsement data\n'
                  '• Financial information (payment records, transactions)\n'
                  '• Device information (device type, operating system, app version)\n'
                  '• Usage information (app interactions, features used, session data)\n'
                  '• Technical data (IP address, browser type, crash reports)',
            ),
            _buildSection(
              '2. How We Use Your Information',
              'We use the collected information to:\n\n'
                  '• Provide and maintain our driving school management services\n'
                  '• Process your transactions and manage payments\n'
                  '• Send you important updates and notifications\n'
                  '• Improve our services and user experience\n'
                  '• Conduct analytics and performance monitoring\n'
                  '• Comply with legal obligations and regulations\n'
                  '• Prevent fraud and ensure security\n'
                  '• Provide customer support and respond to inquiries',
            ),
            _buildSection(
              '3. Data Processing and Storage',
              'Your data is processed and stored using secure cloud services:\n\n'
                  '• Firebase Firestore for real-time database operations\n'
                  '• Firebase Storage for file and document storage\n'
                  '• Firebase Authentication for secure user authentication\n'
                  '• Google Cloud services for data processing and analytics\n\n'
                  'Data is stored in encrypted format and processed in secure environments. We implement industry-standard security measures to protect your information.',
            ),
            _buildSection(
              '4. Data Security',
              'We implement appropriate security measures to protect your personal information:\n\n'
                  '• End-to-end encryption for data transmission\n'
                  '• Secure cloud storage with access controls\n'
                  '• Regular security audits and updates\n'
                  '• Employee training on data protection\n'
                  '• Incident response procedures\n\n'
                  'However, no method of transmission over the internet is 100% secure. While we strive to protect your personal information, we cannot guarantee absolute security.',
            ),
            _buildSection(
              '5. Data Sharing and Disclosure',
              'We do not sell your personal information. We may share your information with:\n\n'
                  '• Service providers who assist in operating our services\n'
                  '• Legal authorities when required by law\n'
                  '• Business partners with your explicit consent\n'
                  '• Third-party services for analytics and performance monitoring\n'
                  '• Payment processors for transaction handling\n\n'
                  'All third-party partners are contractually obligated to maintain the confidentiality and security of your data.',
            ),
            _buildSection(
              '6. International Data Transfers',
              'Your information may be transferred to and processed in countries other than your own. We ensure that appropriate safeguards are in place to protect your data in accordance with applicable data protection laws, including the use of standard contractual clauses and other legal mechanisms.',
            ),
            _buildSection(
              '7. Your Rights and Choices',
              'You have the following rights regarding your personal information:\n\n'
                  '• Access your personal information\n'
                  '• Correct inaccurate or incomplete data\n'
                  '• Request deletion of your data\n'
                  '• Object to processing of your data\n'
                  '• Data portability (receive your data in structured format)\n'
                  '• Opt-out of marketing communications\n'
                  '• Withdraw consent where processing is based on consent\n\n'
                  'To exercise these rights, please contact us using the information provided below.',
            ),
            _buildSection(
              '8. Data Retention',
              'We retain your personal information for as long as necessary to provide our services and comply with legal obligations:\n\n'
                  '• Active user data: While account is active\n'
                  '• Inactive account data: 24 months after last activity\n'
                  '• Financial records: 7 years for legal compliance\n'
                  '• Backup data: 90 days in encrypted backups\n\n'
                  'Data is securely deleted when retention periods expire.',
            ),
            _buildSection(
              '9. Children\'s Privacy',
              'Our services are not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. If we become aware that we have collected personal information from a child under 13, we will take steps to delete such information.',
            ),
            _buildSection(
              '10. Changes to This Policy',
              'We may update this Privacy Policy from time to time. We will notify you of any changes by:\n\n'
                  '• Posting the new Privacy Policy on this page\n'
                  '• Updating the "Last updated" date\n'
                  '• Sending you an email notification for significant changes\n\n'
                  'We encourage you to review this Privacy Policy periodically for any changes.',
            ),
            _buildSection(
              '11. Contact Us',
              'If you have any questions about this Privacy Policy or our data practices, please contact us at:\n\n'
                  '📧 Email: drivemate.mds@gmail.com\n'
                  '📱 Through the app: Contact Us section\n'
                  '🌐 Website: [if applicable]\n\n'
                  'We will respond to your inquiries within 48 hours during business days.',
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
