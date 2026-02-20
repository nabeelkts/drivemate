import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Generates a professional attendance log PDF for a student
class AttendancePdfService {
  static Future<Uint8List> generate({
    required String studentName,
    required String studentId,
    required String cov,
    required List<Map<String, dynamic>> records,
    Map<String, dynamic>? companyData,
    Uint8List? companyLogoBytes,
  }) async {
    final pdf = pw.Document();

    // ── Colours ──────────────────────────────────────────────────────────────
    const primary = PdfColor.fromInt(0xFFD32F2F);   // accent red matching app
    const headerBg = PdfColor.fromInt(0xFFD32F2F);
    const rowAlt = PdfColor.fromInt(0xFFFFF8F8);
    const border = PdfColor.fromInt(0xFFEEEEEE);
    const textDark = PdfColor.fromInt(0xFF212121);
    const textMed = PdfColor.fromInt(0xFF616161);
    const white = PdfColors.white;

    // ── Fonts ─────────────────────────────────────────────────────────────────
    final boldFont = pw.Font.helveticaBold();
    final regularFont = pw.Font.helvetica();

    // ── Summary stats ─────────────────────────────────────────────────────────
    Duration totalDuration = Duration.zero;
    double totalDistanceKm = 0.0;
    int totalLessons = records.length;

    for (final r in records) {
      final dur = _parseDuration(r['duration']?.toString() ?? '');
      totalDuration += dur;
      final distStr = (r['distance'] ?? '0 KM')
          .toString()
          .replaceAll(RegExp(r'[^0-9.]'), '');
      totalDistanceKm += double.tryParse(distStr) ?? 0.0;
    }

    final totalHours = totalDuration.inHours;
    final totalMins = totalDuration.inMinutes.remainder(60);
    final totalDurStr = totalHours > 0
        ? '${totalHours}h ${totalMins}m'
        : '${totalMins}m';

    // ── Table columns ─────────────────────────────────────────────────────────
    const colWidths = [
      0.04, // #
      0.14, // Date
      0.18, // Time
      0.20, // Instructor
      0.12, // Duration
      0.12, // Distance
      0.20, // Status
    ];

    final headers = [
      '#', 'Date', 'Time Range', 'Instructor', 'Duration', 'Distance', 'Status'
    ];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 36),
        header: (ctx) => _buildHeader(
          ctx,
          studentName: studentName,
          studentId: studentId,
          cov: cov,
          companyData: companyData,
          companyLogoBytes: companyLogoBytes,
          boldFont: boldFont,
          regularFont: regularFont,
          primary: primary,
          white: white,
          textDark: textDark,
          textMed: textMed,
        ),
        footer: (ctx) => _buildFooter(ctx, regularFont, textMed),
        build: (ctx) => [
          pw.SizedBox(height: 14),

          // ── Summary stats row ──────────────────────────────────────────────
          pw.Container(
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFFCE4EC),
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(
                  color: const PdfColor.fromInt(0xFFFFCDD2), width: 0.5),
            ),
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _statCell('Total Lessons', '$totalLessons',
                    boldFont, regularFont, primary),
                _vertDivider(),
                _statCell('Total Hours', totalDurStr,
                    boldFont, regularFont, primary),
                _vertDivider(),
                _statCell('Total Distance',
                    '${totalDistanceKm.toStringAsFixed(2)} km',
                    boldFont, regularFont, primary),
                _vertDivider(),
                _statCell('Generated',
                    DateFormat('dd MMM yyyy').format(DateTime.now()),
                    boldFont, regularFont, textMed),
              ],
            ),
          ),

          pw.SizedBox(height: 16),

          // ── Table ──────────────────────────────────────────────────────────
          pw.Table(
            columnWidths: {
              for (int i = 0; i < colWidths.length; i++)
                i: pw.FlexColumnWidth(colWidths[i] * 100),
            },
            border: pw.TableBorder.all(
                color: border, width: 0.5),
            children: [
              // Header row
              pw.TableRow(
                decoration: pw.BoxDecoration(color: headerBg),
                children: headers
                    .map((h) => _headerCell(h, boldFont, white))
                    .toList(),
              ),

              // Data rows
              ...records.asMap().entries.map((entry) {
                final i = entry.key;
                final r = entry.value;

                final date = (r['date'] as Timestamp?)?.toDate();
                final startTime =
                    (r['startTime'] as Timestamp?)?.toDate();
                final endTime = (r['endTime'] as Timestamp?)?.toDate();

                final dateStr = date != null
                    ? DateFormat('dd MMM yyyy').format(date)
                    : 'N/A';
                String timeStr = 'N/A';
                if (startTime != null && endTime != null) {
                  timeStr =
                      '${DateFormat('hh:mm a').format(startTime)}\n– ${DateFormat('hh:mm a').format(endTime)}';
                }

                final instructor = r['instructorName']?.toString() ?? 'N/A';
                final duration = r['duration']?.toString() ?? 'N/A';
                final distance = r['distance']?.toString() ?? '0 KM';

                final bg = i.isOdd ? rowAlt : white;

                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: bg),
                  children: [
                    _cell('${i + 1}', regularFont, textMed,
                        align: pw.TextAlign.center),
                    _cell(dateStr, regularFont, textDark),
                    _cell(timeStr, regularFont, textMed, fontSize: 7.5),
                    _cell(instructor, regularFont, textDark),
                    _cell(duration, boldFont, primary,
                        align: pw.TextAlign.center),
                    _cell(distance, regularFont, textDark,
                        align: pw.TextAlign.center),
                    _statusCell(boldFont, regularFont),
                  ],
                );
              }),
            ],
          ),

          pw.SizedBox(height: 20),

          // ── Footer note ────────────────────────────────────────────────────
          pw.Container(
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFF5F5F5),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            padding: const pw.EdgeInsets.all(10),
            child: pw.Text(
              'This attendance report is system-generated and reflects all recorded lesson sessions for the above student. '
              'Duration and distance are tracked via the MDS Management app.',
              style: pw.TextStyle(
                font: regularFont,
                fontSize: 7.5,
                color: textMed,
              ),
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  static pw.Widget _buildHeader(
    pw.Context ctx, {
    required String studentName,
    required String studentId,
    required String cov,
    required Map<String, dynamic>? companyData,
    required Uint8List? companyLogoBytes,
    required pw.Font boldFont,
    required pw.Font regularFont,
    required PdfColor primary,
    required PdfColor white,
    required PdfColor textDark,
    required PdfColor textMed,
  }) {
    final companyName = companyData?['companyName'] ?? 'MDS Management';
    final companyAddress = companyData?['address'] ?? '';
    final companyPhone = companyData?['phone'] ?? '';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Top banner
        pw.Container(
          width: double.infinity,
          padding:
              const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: pw.BoxDecoration(
            color: primary,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Logo
              if (companyLogoBytes != null)
                pw.Container(
                  width: 42,
                  height: 42,
                  margin: const pw.EdgeInsets.only(right: 12),
                  decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    color: white,
                  ),
                  child: pw.ClipOval(
                    child: pw.Image(
                      pw.MemoryImage(companyLogoBytes),
                      fit: pw.BoxFit.cover,
                    ),
                  ),
                ),
              // Company info
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      companyName,
                      style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 15,
                          color: white),
                    ),
                    if (companyAddress.isNotEmpty)
                      pw.Text(companyAddress,
                          style: pw.TextStyle(
                              font: regularFont,
                              fontSize: 8,
                              color: white.flatten())),
                    if (companyPhone.isNotEmpty)
                      pw.Text('Tel: $companyPhone',
                          style: pw.TextStyle(
                              font: regularFont,
                              fontSize: 8,
                              color: white.flatten())),
                  ],
                ),
              ),
              // Report title
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'ATTENDANCE REPORT',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 13,
                      color: white,
                      letterSpacing: 1.0,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    DateFormat('dd MMMM yyyy').format(DateTime.now()),
                    style: pw.TextStyle(
                        font: regularFont, fontSize: 8, color: white.flatten()),
                  ),
                ],
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 10),

        // Student info strip
        pw.Container(
          width: double.infinity,
          padding:
              const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(
                color: const PdfColor.fromInt(0xFFFFCDD2), width: 0.8),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Row(
            children: [
              _infoChip('Student', studentName, boldFont, regularFont,
                  textDark, textMed),
              pw.SizedBox(width: 24),
              _infoChip('Student ID', studentId, boldFont, regularFont,
                  textDark, textMed),
              pw.SizedBox(width: 24),
              _infoChip('COV', cov, boldFont, regularFont, textDark, textMed),
            ],
          ),
        ),

        pw.SizedBox(height: 4),
      ],
    );
  }

  static pw.Widget _buildFooter(
      pw.Context ctx, pw.Font regularFont, PdfColor textMed) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'Confidential — MDS Management',
          style: pw.TextStyle(
              font: regularFont, fontSize: 7.5, color: textMed),
        ),
        pw.Text(
          'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
          style: pw.TextStyle(
              font: regularFont, fontSize: 7.5, color: textMed),
        ),
      ],
    );
  }

  // ── Cell helpers ─────────────────────────────────────────────────────────────

  static pw.Widget _headerCell(
      String text, pw.Font font, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font, fontSize: 8, color: color),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _cell(
    String text,
    pw.Font font,
    PdfColor color, {
    pw.TextAlign align = pw.TextAlign.left,
    double fontSize = 8.0,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font, fontSize: fontSize, color: color),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _statusCell(pw.Font boldFont, pw.Font regularFont) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Container(
        padding:
            const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: pw.BoxDecoration(
          color: const PdfColor.fromInt(0xFFE8F5E9),
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Text(
          'COMPLETED',
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 7,
            color: const PdfColor.fromInt(0xFF2E7D32),
          ),
          textAlign: pw.TextAlign.center,
        ),
      ),
    );
  }

  static pw.Widget _statCell(String label, String value, pw.Font boldFont,
      pw.Font regularFont, PdfColor valueColor) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(value,
            style:
                pw.TextStyle(font: boldFont, fontSize: 13, color: valueColor)),
        pw.SizedBox(height: 2),
        pw.Text(label,
            style: pw.TextStyle(
                font: regularFont,
                fontSize: 7.5,
                color: const PdfColor.fromInt(0xFF616161))),
      ],
    );
  }

  static pw.Widget _vertDivider() {
    return pw.Container(
      width: 0.5,
      height: 28,
      color: const PdfColor.fromInt(0xFFFFCDD2),
    );
  }

  static pw.Widget _infoChip(
    String label,
    String value,
    pw.Font boldFont,
    pw.Font regularFont,
    PdfColor textDark,
    PdfColor textMed,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text('$label: ',
            style: pw.TextStyle(
                font: regularFont,
                fontSize: 8,
                color: textMed)),
        pw.Text(value,
            style: pw.TextStyle(
                font: boldFont, fontSize: 8.5, color: textDark)),
      ],
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  static Duration _parseDuration(String s) {
    int hours = 0, minutes = 0;
    final hMatch = RegExp(r'(\d+)h').firstMatch(s);
    final mMatch = RegExp(r'(\d+)m').firstMatch(s);
    if (hMatch != null) hours = int.tryParse(hMatch.group(1)!) ?? 0;
    if (mMatch != null) minutes = int.tryParse(mMatch.group(1)!) ?? 0;
    return Duration(hours: hours, minutes: minutes);
  }
}
