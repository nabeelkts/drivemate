import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:mds/models/transaction_data.dart';
import '../screens/accounts/accounts_screen.dart';

class LedgerPdfService {
  static Future<File> generateLedgerStatement({
    required Map<String, dynamic> companyData,
    required List<TransactionData> transactions,
    required DateTime startDate,
    required DateTime endDate,
    Uint8List? companyLogoBytes,
  }) async {
    final pdf = pw.Document();
    final ttf = pw.Font.helvetica();
    final ttfBold = pw.Font.helveticaBold();

    double totalIncome = 0;
    double totalExpense = 0;
    for (var t in transactions) {
      if (t.isExpense) {
        totalExpense += t.amount;
      } else {
        totalIncome += t.amount;
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Company Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      companyData['companyName']?.toUpperCase() ??
                          'BUSINESS STATEMENT',
                      style: pw.TextStyle(
                        font: ttfBold,
                        fontSize: 20,
                        color: PdfColors.blueGrey800,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      companyData['companyAddress'] ?? '',
                      style: pw.TextStyle(font: ttf, fontSize: 10),
                    ),
                    pw.Text(
                      'Phone: ${companyData['companyPhone'] ?? ''}',
                      style: pw.TextStyle(font: ttf, fontSize: 10),
                    ),
                    if (companyData['companyEmail'] != null)
                      pw.Text(
                        'Email: ${companyData['companyEmail']}',
                        style: pw.TextStyle(font: ttf, fontSize: 10),
                      ),
                  ],
                ),
                if (companyLogoBytes != null)
                  pw.Image(
                    pw.MemoryImage(companyLogoBytes),
                    width: 60,
                    height: 60,
                    fit: pw.BoxFit.contain,
                  ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Divider(thickness: 1, color: PdfColors.grey300),
            pw.SizedBox(height: 10),

            // Statement Info
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'LEDGER STATEMENT',
                      style: pw.TextStyle(font: ttfBold, fontSize: 14),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Period: ${DateFormat('dd MMM yyyy').format(startDate)} - ${DateFormat('dd MMM yyyy').format(endDate)}',
                      style: pw.TextStyle(
                          font: ttf, fontSize: 10, color: PdfColors.grey700),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Generated on: ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}',
                      style: pw.TextStyle(
                          font: ttf, fontSize: 9, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Summary Cards
            pw.Row(
              children: [
                _buildSummaryBox(
                    'Total Income',
                    'Rs. ${totalIncome.toStringAsFixed(2)}',
                    PdfColors.green700,
                    ttf,
                    ttfBold),
                pw.SizedBox(width: 20),
                _buildSummaryBox(
                    'Total Expense',
                    'Rs. ${totalExpense.toStringAsFixed(2)}',
                    PdfColors.red700,
                    ttf,
                    ttfBold),
                pw.SizedBox(width: 20),
                _buildSummaryBox(
                    'Net Balance',
                    'Rs. ${(totalIncome - totalExpense).toStringAsFixed(2)}',
                    PdfColors.blueGrey800,
                    ttf,
                    ttfBold),
              ],
            ),
            pw.SizedBox(height: 30),

            // Transactions Table
            pw.Table(
              columnWidths: {
                0: const pw.FixedColumnWidth(80),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FixedColumnWidth(80),
                4: const pw.FixedColumnWidth(80),
              },
              border: pw.TableBorder(
                horizontalInside:
                    pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
              ),
              children: [
                // Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    _buildTableCell('Date', ttfBold, true),
                    _buildTableCell('Name / Description', ttfBold, true),
                    _buildTableCell('Type', ttfBold, true),
                    _buildTableCell('Income', ttfBold, true,
                        align: pw.TextAlign.right),
                    _buildTableCell('Expense', ttfBold, true,
                        align: pw.TextAlign.right),
                  ],
                ),
                // Data
                ...transactions.map((t) {
                  return pw.TableRow(
                    children: [
                      _buildTableCell(
                          DateFormat('dd/MM/yy').format(t.date), ttf, false),
                      _buildTableCell(
                          t.note != null && t.note!.trim().isNotEmpty
                              ? '${t.name}\n(${t.note})'
                              : t.name,
                          ttf,
                          false),
                      _buildTableCell(t.type, ttf, false),
                      _buildTableCell(
                        !t.isExpense
                            ? 'Rs. ${t.amount.toStringAsFixed(2)}'
                            : '-',
                        ttf,
                        false,
                        align: pw.TextAlign.right,
                        color: !t.isExpense ? PdfColors.green800 : null,
                      ),
                      _buildTableCell(
                        t.isExpense
                            ? 'Rs. ${t.amount.toStringAsFixed(2)}'
                            : '-',
                        ttf,
                        false,
                        align: pw.TextAlign.right,
                        color: t.isExpense ? PdfColors.red800 : null,
                      ),
                    ],
                  );
                }),
              ],
            ),
          ];
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: pw.TextStyle(
                  font: ttf, fontSize: 8, color: PdfColors.grey500),
            ),
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final fileName =
        "Ledger_Statement_${DateFormat('yyyyMMdd').format(startDate)}_to_${DateFormat('yyyyMMdd').format(endDate)}.pdf";
    final file = File("${output.path}/$fileName");
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _buildSummaryBox(String title, String value, PdfColor color,
      pw.Font font, pw.Font boldFont) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          border: pw.Border.all(color: PdfColors.grey200, width: 1),
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title,
                style: pw.TextStyle(
                    font: font, fontSize: 9, color: PdfColors.grey600)),
            pw.SizedBox(height: 5),
            pw.Text(value,
                style:
                    pw.TextStyle(font: boldFont, fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildTableCell(String text, pw.Font font, bool isHeader,
      {pw.TextAlign align = pw.TextAlign.left, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: pw.Text(
        text,
        maxLines: 2,
        style: pw.TextStyle(
          font: font,
          fontSize: isHeader ? 10 : 9,
          color: color ?? PdfColors.black,
        ),
        textAlign: align,
      ),
    );
  }
}
