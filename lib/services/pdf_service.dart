import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PdfService {
  static Future<Uint8List> generatePdf({
    required String title,
    required Map<String, dynamic> data,
    required bool includePayment,
    Uint8List? imageBytes,
    Map<String, dynamic>? companyData,
    Uint8List? companyLogoBytes,
  }) async {
    final pdf = pw.Document();

    final ttf = pw.Font.helvetica();
    final ttfBold = pw.Font.helveticaBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              // Company Header
              if (companyData != null) ...[
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          companyData['companyName'] ?? '',
                          style: pw.TextStyle(
                            font: ttfBold,
                            fontSize: 18,
                            color: PdfColors.red900,
                          ),
                        ),
                        pw.Text(
                          companyData['companyAddress'] ?? '',
                          style: pw.TextStyle(font: ttf, fontSize: 10),
                        ),
                        pw.Text(
                          'Ph: ${companyData['companyPhone'] ?? ''}',
                          style: pw.TextStyle(font: ttf, fontSize: 10),
                        ),
                      ],
                    ),
                    if (companyLogoBytes != null)
                      pw.Image(
                        pw.MemoryImage(companyLogoBytes),
                        width: 50,
                        height: 50,
                      ),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Divider(color: PdfColors.grey400),
                pw.SizedBox(height: 10),
              ],

              // Title
              pw.Text(
                title,
                style: pw.TextStyle(
                  font: ttfBold,
                  fontSize: 24,
                  color: PdfColors.black,
                ),
              ),
              pw.SizedBox(height: 20),

              // Profile Card (Name Card)
              _buildSectionCard(
                child: pw.Row(
                  children: [
                    if (imageBytes != null)
                      pw.Container(
                        width: 80,
                        height: 80,
                        decoration: pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          border: pw.Border.all(color: PdfColors.red, width: 2),
                          image: pw.DecorationImage(
                            image: pw.MemoryImage(imageBytes),
                            fit: pw.BoxFit.cover,
                          ),
                        ),
                      )
                    else
                      pw.Container(
                        width: 80,
                        height: 80,
                        decoration: pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          color: PdfColors.red,
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            data['fullName'] != null &&
                                    data['fullName'].isNotEmpty
                                ? data['fullName'][0].toUpperCase()
                                : '',
                            style: pw.TextStyle(
                                font: ttfBold,
                                fontSize: 30,
                                color: PdfColors.white),
                          ),
                        ),
                      ),
                    pw.SizedBox(width: 20),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            data['fullName'] ?? 'N/A',
                            style: pw.TextStyle(
                              font: ttfBold,
                              fontSize: 18,
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            'ID: ${data['studentId'] ?? 'N/A'}',
                            style: pw.TextStyle(
                              font: ttf,
                              fontSize: 14,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            'COV: ${data['cov'] ?? 'N/A'}',
                            style: pw.TextStyle(
                              font: ttfBold,
                              fontSize: 12,
                              color: PdfColors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 15),

              // Split Row: Personal Info & Address
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Personal Info
                  pw.Expanded(
                    flex: 3,
                    child: _buildSectionCard(
                      title: 'Personal Info',
                      titleFont: ttfBold,
                      child: pw.Column(
                        children: [
                          _buildPdfRow('Name', data['fullName'], ttf, ttfBold),
                          _buildPdfRow('Guardian',
                              data['guardianName'] ?? 'N/A', ttf, ttfBold),
                          _buildPdfRow('DOB', data['dob'], ttf, ttfBold),
                          _buildPdfRow(
                              'Mobile', data['mobileNumber'], ttf, ttfBold),
                          if (data['license'] != null)
                            _buildPdfRow(
                                'License No', data['license'], ttf, ttfBold),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 15),
                  // Address
                  pw.Expanded(
                    flex: 2,
                    child: _buildSectionCard(
                      title: 'Address',
                      titleFont: ttfBold,
                      child: pw.Column(
                        children: [
                          _buildPdfRow(
                              'House',
                              data['house'] ?? data['houseName'] ?? '',
                              ttf,
                              ttfBold),
                          _buildPdfRow('Place', data['place'], ttf, ttfBold),
                          _buildPdfRow('Post', data['post'], ttf, ttfBold),
                          _buildPdfRow(
                              'District', data['district'], ttf, ttfBold),
                          _buildPdfRow('PIN', data['pin'], ttf, ttfBold),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 15),

              // Payment Overview (Optional)
              if (includePayment)
                _buildSectionCard(
                  title: 'Payment Overview',
                  titleFont: ttfBold,
                  child: pw.Column(
                    children: [
                      _buildPdfRow(
                          'Total Fee', data['totalAmount'], ttf, ttfBold),
                      _buildPdfRow(
                          'Paid Amount',
                          (double.tryParse(
                                      data['totalAmount']?.toString() ?? '0') ??
                                  0) -
                              (double.tryParse(
                                      data['balanceAmount']?.toString() ??
                                          '0') ??
                                  0),
                          ttf,
                          ttfBold),
                      _buildPdfRow(
                          'Balance', data['balanceAmount'], ttf, ttfBold),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );

    return await pdf.save();
  }

  static Future<Uint8List> generateReceipt({
    required Map<String, dynamic> companyData,
    required Map<String, dynamic> studentDetails,
    required List<Map<String, dynamic>> transactions,
    Uint8List? companyLogoBytes,
  }) async {
    final pdf = pw.Document();
    final ttf = pw.Font.helvetica();
    final ttfBold = pw.Font.helveticaBold();

    // Construct Address String
    final List<String> addressParts = [];
    if (studentDetails['house'] != null &&
        studentDetails['house'].toString().isNotEmpty) {
      addressParts.add(studentDetails['house']);
    } else if (studentDetails['houseName'] != null &&
        studentDetails['houseName'].toString().isNotEmpty) {
      addressParts.add(studentDetails['houseName']);
    }

    if (studentDetails['place'] != null &&
        studentDetails['place'].toString().isNotEmpty) {
      addressParts.add(studentDetails['place']);
    }
    if (studentDetails['post'] != null &&
        studentDetails['post'].toString().isNotEmpty) {
      addressParts.add(studentDetails['post']);
    }
    if (studentDetails['district'] != null &&
        studentDetails['district'].toString().isNotEmpty) {
      addressParts.add(studentDetails['district']);
    }
    if (studentDetails['pin'] != null &&
        studentDetails['pin'].toString().isNotEmpty) {
      addressParts.add('PIN: ${studentDetails['pin']}');
    }

    final String fullAddress = addressParts.join('\n');
    final bool hasAddress = fullAddress.isNotEmpty;

    // Determine ID/Address Line to show
    // For students: Name, Address, Mob (User requested)
    // For vehicles: Name, Address (or ID if empty), Mob
    // We will use a consistent logic: Prefer Address, Fallback to ID if Address empty.

    final String secondLine = hasAddress
        ? fullAddress
        : 'ID: ${studentDetails['studentId'] ?? 'N/A'}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          double totalPaidInReceipt = 0;
          for (var tx in transactions) {
            totalPaidInReceipt +=
                double.tryParse(tx['amount']?.toString() ?? '0') ?? 0;
          }

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Company Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        companyData['companyName'] ?? '',
                        style: pw.TextStyle(
                          font: ttfBold,
                          fontSize: 20,
                          color: PdfColors.red900,
                        ),
                      ),
                      pw.Text(
                        companyData['companyAddress'] ?? '',
                        style: pw.TextStyle(font: ttf, fontSize: 10),
                      ),
                      pw.Text(
                        'Ph: ${companyData['companyPhone'] ?? ''}',
                        style: pw.TextStyle(font: ttf, fontSize: 10),
                      ),
                    ],
                  ),
                  if (companyLogoBytes != null)
                    pw.Image(
                      pw.MemoryImage(companyLogoBytes),
                      width: 60,
                      height: 60,
                    ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 20),

              // Receipt Title
              pw.Center(
                child: pw.Text(
                  'PAYMENT RECEIPT',
                  style: pw.TextStyle(
                    font: ttfBold,
                    fontSize: 22,
                    decoration: pw.TextDecoration.underline,
                  ),
                ),
              ),
              pw.SizedBox(height: 30),

              // Customer Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Bill To:',
                            style: pw.TextStyle(font: ttfBold, fontSize: 12)),
                        pw.Text(studentDetails['fullName'] ?? 'N/A',
                            style: pw.TextStyle(font: ttfBold, fontSize: 14)),
                        pw.Text(secondLine,
                            style: pw.TextStyle(font: ttf, fontSize: 12)),
                        pw.Text(
                            'Mob: ${studentDetails['mobileNumber'] ?? 'N/A'}',
                            style: pw.TextStyle(font: ttf, fontSize: 12)),
                      ],
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Date:',
                          style: pw.TextStyle(font: ttfBold, fontSize: 12)),
                      pw.Text(
                          DateFormat('dd/MM/yyyy')
                              .format(DateTime.now()), // current date
                          style: pw.TextStyle(font: ttf, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),

              // Transaction Table Header
              pw.Container(
                color: PdfColors.grey200,
                padding: const pw.EdgeInsets.all(8),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                        flex: 2,
                        child: pw.Text('Date',
                            style: pw.TextStyle(font: ttfBold, fontSize: 12))),
                    pw.Expanded(
                        flex: 4, // Increased flex for description
                        child: pw.Text('Description',
                            style: pw.TextStyle(font: ttfBold, fontSize: 12))),
                    pw.Expanded(
                        flex: 2,
                        child: pw.Text('Mode',
                            style: pw.TextStyle(font: ttfBold, fontSize: 12))),
                    pw.Expanded(
                        flex: 2,
                        child: pw.Text('Amount',
                            style: pw.TextStyle(font: ttfBold, fontSize: 12),
                            textAlign: pw.TextAlign.right)),
                  ],
                ),
              ),

              // Transaction rows
              ...transactions.map((tx) {
                final date = tx['date'] != null
                    ? (tx['date'] is Timestamp
                        ? (tx['date'] as Timestamp).toDate()
                        : DateTime.tryParse(tx['date'].toString()) ??
                            DateTime.now())
                    : DateTime.now();

                return pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                        bottom:
                            pw.BorderSide(color: PdfColors.grey300, width: .5)),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                          flex: 2,
                          child: pw.Text(DateFormat('dd/MM/yyyy').format(date),
                              style: const pw.TextStyle(fontSize: 10))),
                      pw.Expanded(
                          flex: 4,
                          child: pw.Text((() {
                            String desc = '';
                            // Determine Description
                            // Check if it's a vehicle payment (has vehicle number)
                            if (studentDetails['vehicleNumber'] != null &&
                                studentDetails['vehicleNumber']
                                    .toString()
                                    .isNotEmpty) {
                              String vNum =
                                  studentDetails['vehicleNumber'].toString();
                              String sType =
                                  studentDetails['cov']?.toString() ?? '';

                              // Fallback to serviceTypes array if cov string is empty
                              if (sType.isEmpty &&
                                  studentDetails['serviceTypes'] is List) {
                                sType = (studentDetails['serviceTypes'] as List)
                                    .join(', ');
                              }

                              if (sType.isNotEmpty) {
                                desc = '$vNum - $sType';
                              } else {
                                desc = vNum;
                              }
                            } else {
                              // Default for students/others
                              desc = studentDetails['cov'] ?? 'Course Payment';
                            }

                            if (tx['note'] != null &&
                                tx['note'].toString().trim().isNotEmpty) {
                              desc += '\nNote: ${tx['note']}';
                            } else if (tx['description'] != null &&
                                tx['description']
                                    .toString()
                                    .trim()
                                    .isNotEmpty) {
                              desc += '\n${tx['description']}';
                            }
                            return desc;
                          })(), style: const pw.TextStyle(fontSize: 10))),
                      pw.Expanded(
                          flex: 2,
                          child: pw.Text(tx['mode'] ?? 'N/A',
                              style: const pw.TextStyle(fontSize: 10))),
                      pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                              'Rs. ${tx['amount']?.toString() ?? '0'}',
                              style: pw.TextStyle(font: ttfBold, fontSize: 10),
                              textAlign: pw.TextAlign.right)),
                    ],
                  ),
                );
              }),

              pw.SizedBox(height: 20),

              // Summary
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Row(
                        children: [
                          pw.Text('Total Paid: ',
                              style: pw.TextStyle(font: ttfBold, fontSize: 14)),
                          pw.Text('Rs. $totalPaidInReceipt',
                              style: pw.TextStyle(
                                  font: ttfBold,
                                  fontSize: 14,
                                  color: PdfColors.green800)),
                        ],
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                          'Outstanding Balance: Rs. ${studentDetails['balanceAmount'] ?? '0'}',
                          style: pw.TextStyle(
                              font: ttf, fontSize: 10, color: PdfColors.red)),
                    ],
                  ),
                ],
              ),

              pw.Spacer(),

              // Footer
              pw.Divider(color: PdfColors.grey400),
              pw.Center(
                child: pw.Text(
                  'This is a computer generated receipt.',
                  style: pw.TextStyle(
                      font: ttf, fontSize: 8, color: PdfColors.grey600),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'Thank you for your business!',
                  style: pw.TextStyle(
                      font: ttfBold, fontSize: 10, color: PdfColors.red900),
                ),
              ),
            ],
          );
        },
      ),
    );

    return await pdf.save();
  }

  static pw.Widget _buildSectionCard(
      {required pw.Widget child, String? title, pw.Font? titleFont}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.red, width: 0.5),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            pw.Text(
              title,
              style: pw.TextStyle(font: titleFont, fontSize: 14),
            ),
            pw.SizedBox(height: 10),
          ],
          child,
        ],
      ),
    );
  }

  static pw.Widget _buildPdfRow(
      String label, dynamic value, pw.Font font, pw.Font boldFont) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('$label:',
              style: pw.TextStyle(
                  font: font, fontSize: 10, color: PdfColors.grey700)),
          pw.Flexible(
            child: pw.Text(
              '$value',
              style: pw.TextStyle(font: boldFont, fontSize: 10),
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
