import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:drivemate/controller/workspace_controller.dart';

class EmailService {
  // We will configure Vercel domain later, using a placeholder loopback or production URL for now.
  // The newly deployed Vercel endpoint:
  static const String _baseUrl = 'https://email-backend-ofctngsyl-drivematemds-1128s-projects.vercel.app/api/send';
  // Must match API_SECRET_KEY in functions/.env (and in Vercel Environment Variables)
  static const String _apiSecretKey = 'VercelBackendSecretKey123!';

  static String _getSchoolName() {
    try {
      if (Get.isRegistered<WorkspaceController>()) {
        final ctrl = Get.find<WorkspaceController>();
        final name = ctrl.companyData['companyName']?.toString();
        if (name != null && name.isNotEmpty && name != 'N/A') return name;
      }
    } catch (_) {}
    return 'Our Driving School';
  }

  static Future<bool> _sendEmail({
    required String to,
    required String subject,
    required String htmlContent,
    List<Map<String, dynamic>>? attachments,
  }) async {
    if (kDebugMode) {
      print('Sending email to $to...');
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiSecretKey',
        },
        body: jsonEncode({
          'to': to,
          'subject': subject,
          'htmlContent': htmlContent,
          if (attachments != null) 'attachments': attachments,
        }),
      );

      if (response.statusCode == 200) {
        if (kDebugMode) print('Email sent successfully');
        return true;
      } else {
        if (kDebugMode) print('Failed to send email: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      if (kDebugMode) print('Error sending email via API: $e');
      return false;
    }
  }

  static Future<void> sendWelcomeEmail(String email, String displayName) async {
    if (email.isEmpty) return;
    final subject = 'Welcome to Drivemate.';
    final content = '''
      <h2>Welcome to ${_getSchoolName()}!</h2>
      <p>Hi ${displayName.isNotEmpty ? displayName : 'there'},</p>
      <p>Your account has been successfully created. We are excited to have you on board.</p>
      <p>Best regards,<br>The ${_getSchoolName()} Team</p>
    ''';
    await _sendEmail(to: email, subject: subject, htmlContent: content);
  }

  static Future<void> sendStudentWelcomeEmail(String email, String fullName, String studentId) async {
    if (email.isEmpty) return;
    final subject = 'Welcome to ${_getSchoolName()}.';
    final content = '''
      <h2>Welcome, ${fullName.isNotEmpty ? fullName : 'Student'}!</h2>
      <p>Your registration is complete.</p>
      <p><strong>Your Student ID:</strong> $studentId</p>
      <p>We look forward to helping you learn how to drive safely.</p>
      <p>Best regards,<br>The ${_getSchoolName()} Team</p>
    ''';
    await _sendEmail(to: email, subject: subject, htmlContent: content);
  }

  static Future<void> sendPaymentReceipt(
      String email, String fullName, double amount, String dateStr,
      {Uint8List? pdfBytes, String? paymentMode}) async {
    if (email.isEmpty) return;
    final subject = 'Payment Receipt - ${_getSchoolName()}.';
    final content = '''
      <h2>Payment Receipt</h2>
      <p>Hi ${fullName.isNotEmpty ? fullName : 'Student'},</p>
      <p>We have successfully received your payment.</p>
      <table style="border-collapse: collapse; width: 100%; max-width: 400px; margin-top: 10px;">
        <tr>
          <td style="padding: 8px; border: 1px solid #ddd;"><strong>Amount:</strong></td>
          <td style="padding: 8px; border: 1px solid #ddd;">₹$amount</td>
        </tr>
        <tr>
          <td style="padding: 8px; border: 1px solid #ddd;"><strong>Date:</strong></td>
          <td style="padding: 8px; border: 1px solid #ddd;">$dateStr</td>
        </tr>
        ${paymentMode != null && paymentMode.isNotEmpty ? '''
        <tr>
          <td style="padding: 8px; border: 1px solid #ddd;"><strong>Mode:</strong></td>
          <td style="padding: 8px; border: 1px solid #ddd;">$paymentMode</td>
        </tr>''' : ''}
      </table>
      <p>Thank you for your payment!</p>
    ''';

    List<Map<String, dynamic>>? attachments;
    if (pdfBytes != null) {
      attachments = [
        {
          'filename': 'Payment_Receipt_$dateStr.pdf',
          'content': base64Encode(pdfBytes),
          'encoding': 'base64',
        }
      ];
    }

    await _sendEmail(to: email, subject: subject, htmlContent: content, attachments: attachments);
  }

  static Future<void> sendTestScheduledEmail(String email, String fullName, String dateStr) async {
    if (email.isEmpty) return;
    final subject = 'Your Driving Test has been Scheduled';
    final content = '''
      <h2>Hi ${fullName.isNotEmpty ? fullName : 'Student'},</h2>
      <p>Your upcoming driving test is scheduled for: <strong>$dateStr</strong>.</p>
      <p>Please remember to bring all necessary documents and arrive on time.</p>
      <p>Best regards,<br>The ${_getSchoolName()} Team</p>
    ''';
    await _sendEmail(to: email, subject: subject, htmlContent: content);
  }

  static Future<void> sendTestResultEmail(String email, String fullName, String result) async {
    if (email.isEmpty) return;
    final resultString = result.toLowerCase();
    final isPass = resultString.contains('pass') || resultString == 'p';
    
    final subject = isPass ? 'Congratulations! You Passed Your Driving Test' : 'Your Driving Test Result Update';
    
    final message = '''
      <p>Your driving test result has just been updated in our system.</p>
      <p>Result: <strong>$result</strong></p>
      ${isPass 
        ? '<p>Congratulations on passing! We wish you safe travels on the road.</p>' 
        : "<p>Don't be discouraged! You can review your mistakes and schedule another test when you're ready.</p>"}
    ''';
    
    final content = '''
      <h2>Hi ${fullName.isNotEmpty ? fullName : 'Student'},</h2>
      $message
      <p>Best regards,<br>The ${_getSchoolName()} Team</p>
    ''';
    
    await _sendEmail(to: email, subject: subject, htmlContent: content);
  }
}
