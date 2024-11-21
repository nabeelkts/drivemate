import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/screens/authentication/widgets/my_button.dart';
import 'package:mds/screens/dashboard/form/edit_forms/edit_student_details_form.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class StudentDetailsPage extends StatelessWidget {
  final Map<String, dynamic> studentDetails;

  const StudentDetailsPage({required this.studentDetails, super.key});

  final TextStyle labelStyle = const TextStyle(
    fontFamily: 'Inter',
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: Color(0xFF000000),
    height: 15.73 / 13,
  );
  final TextStyle valueStyle = const TextStyle(
    fontFamily: 'Inter',
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: Color(0xFF747474),
    height: 15.73 / 13,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Details'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareStudentDetails(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: studentDetails['image'] != null &&
                          studentDetails['image'].isNotEmpty
                      ? CachedNetworkImageProvider(studentDetails['image'])
                      : const AssetImage('assets/icons/user.png') as ImageProvider,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  buildTableRow('Name of Student', studentDetails['fullName']),
                  const Divider(color: kDivider),
                  buildTableRow('Student ID', studentDetails['studentId']),
                  const Divider(color: kDivider),
                  buildAddressRow(),
                  const Divider(color: kDivider),
                  buildTableRow('Date of Birth', studentDetails['dob']),
                  const Divider(color: kDivider),
                  buildTableRow('Phone Number', studentDetails['mobileNumber']),
                  const Divider(color: kDivider),
                  buildTableRow('Blood Group', studentDetails['bloodGroup']),
                  const Divider(),
                  buildTableRow('Fees', studentDetails['totalAmount']),
                  const Divider(color: kDivider),
                  buildTableRow('Advance Received', studentDetails['advanceAmount']),
                  const Divider(color: kDivider),
                  buildTableRow('Balance', studentDetails['balanceAmount']),
                  const Divider(color: kDivider),
                  buildTableRow('Course Selected', studentDetails['cov']),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
              child: MyButton(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditStudentDetailsForm(
                        initialValues: studentDetails,
                        items: const [
                          'M/C Study',
                          'LMV Study',
                          'LMV Study + M/C Study',
                          'LMV Study + M/C License'
                        ],
                      ),
                    ),
                  );
                },
                text: 'Update Student',
                isLoading: false,
                isEnabled: true,
                width: double.infinity, // Adjust width as needed
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget buildTableRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: labelStyle,
          ),
          Flexible(
            child: Text(
              '$value',
              style: valueStyle,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildAddressRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Address:',
            style: labelStyle,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    studentDetails['houseName'] ?? '',
                    style: valueStyle,
                  ),
                  Text(
                    studentDetails['post'] ?? '',
                    style: valueStyle,
                  ),
                  Text(
                    studentDetails['district'] ?? '',
                    style: valueStyle,
                  ),
                  Text(
                    studentDetails['pin'] ?? '',
                    style: valueStyle,
                  ),
                ].where((element) => element.data!.isNotEmpty).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

 Future<void> _shareStudentDetails(BuildContext context) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Text(
                'Student Details',
                style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Divider(),
            _buildPdfRow('Name of Student', studentDetails['fullName']),
            _buildPdfRow('Student ID', studentDetails['studentId']),
            _buildPdfRow('Address', _formatAddress()),
            _buildPdfRow('Date of Birth', studentDetails['dob']),
            _buildPdfRow('Phone Number', studentDetails['mobileNumber']),
            _buildPdfRow('Blood Group', studentDetails['bloodGroup']),
            _buildPdfRow('Fees', studentDetails['totalAmount']),
            _buildPdfRow('Advance Received', studentDetails['advanceAmount']),
            _buildPdfRow('Balance', studentDetails['balanceAmount']),
            _buildPdfRow('Course Selected', studentDetails['cov']),
            pw.Divider(),
            pw.SizedBox(height: 20),
            pw.Text(
              'Additional Notes:',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              studentDetails['notes'] ?? 'No additional notes provided.',
              style: const pw.TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/student_details.pdf");
    await file.writeAsBytes(await pdf.save());

    // ignore: deprecated_member_use
    Share.shareFiles([file.path], text: 'Student Details');
  }

  pw.Widget _buildPdfRow(String label, dynamic value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8.0),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            '$label:',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            '$value',
            style: const pw.TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  String _formatAddress() {
    return [
      studentDetails['houseName'],
      studentDetails['post'],
      studentDetails['district'],
      studentDetails['pin']
    ].where((element) => element != null && element.isNotEmpty).join(', ');
  }

  // Existing code...
}
