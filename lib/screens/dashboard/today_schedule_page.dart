import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:mds/controller/workspace_controller.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:mds/utils/loading_utils.dart';

class TodaySchedulePage extends StatefulWidget {
  const TodaySchedulePage({super.key});

  @override
  State<TodaySchedulePage> createState() => _TodaySchedulePageState();
}

class _TodaySchedulePageState extends State<TodaySchedulePage>
    with SingleTickerProviderStateMixin {
  DateTime selectedDate = DateTime.now();
  final DateFormat storageFormat = DateFormat('yyyy-MM-dd');
  List<Map<String, dynamic>> learners = [];
  final DateFormat displayFormat = DateFormat('dd-MM-yyyy');
  List<Map<String, dynamic>> driving = [];
  bool isLoading = true;
  late TabController _tabController;
  final WorkspaceController _workspaceController =
      Get.find<WorkspaceController>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => isLoading = false);
      return;
    }
    final dateStr = storageFormat.format(selectedDate);
    final collections = ['students', 'licenseonly', 'endorsement'];

    List<Map<String, dynamic>> allLearners = [];
    List<Map<String, dynamic>> allDriving = [];

    try {
      for (var col in collections) {
        final colRef = FirebaseFirestore.instance
            .collection('users')
            .doc(_workspaceController.currentSchoolId.value)
            .collection(col);

        final lSnap =
            await colRef.where('learnersTestDate', isEqualTo: dateStr).get();
        final dSnap =
            await colRef.where('drivingTestDate', isEqualTo: dateStr).get();

        allLearners.addAll(lSnap.docs.map((d) {
          final data = d.data();
          return {...data, '_collection': col};
        }).toList());

        allDriving.addAll(dSnap.docs.map((d) {
          final data = d.data();
          return {...data, '_collection': col};
        }).toList());
      }

      setState(() {
        learners = allLearners;
        driving = allDriving;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading schedule: $e')));
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
      _fetchData();
    }
  }

  Future<void> _exportPdf() async {
    final isLL = _tabController.index == 0;
    final data = isLL ? learners : driving;
    final typeLabel = isLL ? 'LL' : 'DL';

    if (data.isEmpty) {
      Get.snackbar(
        'No Data',
        'No $typeLabel test schedule found for ${displayFormat.format(selectedDate)}.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    Uint8List? bytes;
    try {
      bytes = await LoadingUtils.wrapWithLoading(context, () async {
        final doc = pw.Document();
        final all = data.map((s) => {...s, '_type': typeLabel}).toList();

        doc.addPage(
          pw.Page(
            build: (pw.Context ctx) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                      '$typeLabel Test Schedule - ${displayFormat.format(selectedDate)}',
                      style: pw.TextStyle(
                          fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 12),
                  pw.Table(
                    border: pw.TableBorder.all(),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(2),
                      1: const pw.FlexColumnWidth(2),
                      2: const pw.FlexColumnWidth(2),
                      3: const pw.FlexColumnWidth(1),
                      4: const pw.FlexColumnWidth(2),
                    },
                    children: [
                      pw.TableRow(
                        decoration:
                            const pw.BoxDecoration(color: PdfColors.grey300),
                        children: [
                          pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text('Name',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold))),
                          pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text('Class of Vehicle',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold))),
                          pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text('Mobile',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold))),
                          pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text('Type',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold))),
                          pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text('Balance',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold))),
                        ],
                      ),
                      ...all.map((s) {
                        final balance = s['balanceAmount']?.toString() ?? '';
                        return pw.TableRow(
                          children: [
                            pw.Padding(
                                padding: const pw.EdgeInsets.all(6),
                                child:
                                    pw.Text(s['fullName']?.toString() ?? '')),
                            pw.Padding(
                                padding: const pw.EdgeInsets.all(6),
                                child: pw.Text(s['cov']?.toString() ?? '')),
                            pw.Padding(
                                padding: const pw.EdgeInsets.all(6),
                                child: pw.Text(
                                    s['mobileNumber']?.toString() ?? '')),
                            pw.Padding(
                                padding: const pw.EdgeInsets.all(6),
                                child: pw.Text(s['_type']?.toString() ?? '')),
                            pw.Padding(
                                padding: const pw.EdgeInsets.all(6),
                                child: pw.Text(balance)),
                          ],
                        );
                      }),
                    ],
                  ),
                ],
              );
            },
          ),
        );
        return await doc.save();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    }

    if (bytes != null && mounted) {
      await Printing.sharePdf(
          bytes: bytes,
          filename:
              '${typeLabel}_test_schedule_${storageFormat.format(selectedDate)}.pdf');
    }
  }

  Widget _buildList(List<Map<String, dynamic>> data) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (data.isEmpty) {
      return Center(
          child: Text('No tests for ${displayFormat.format(selectedDate)}'));
    }
    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (context, index) {
        final s = data[index];
        final balance = s['balanceAmount']?.toString() ?? '';
        final colType = s['_collection']?.toString() ?? 'STUDENTS';
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            title: Text(s['fullName'] ?? ''),
            subtitle: Text(
                '${colType.toUpperCase()} • COV: ${s['cov'] ?? ''} • Mobile: ${s['mobileNumber'] ?? ''}'),
            trailing: Text(balance.isNotEmpty ? '₹ $balance' : ''),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = displayFormat.format(selectedDate);
    return Scaffold(
      appBar: AppBar(
        title: Text('Today\'s Schedule ($dateLabel)'),
        actions: [
          IconButton(
              onPressed: _pickDate, icon: const Icon(Icons.calendar_today)),
          IconButton(
              onPressed: _exportPdf, icon: const Icon(Icons.picture_as_pdf)),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'LL (${learners.length})'),
            Tab(text: 'DL (${driving.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(learners),
          _buildList(driving),
        ],
      ),
    );
  }
}
