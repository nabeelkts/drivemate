import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:drivemate/controller/workspace_controller.dart';
import 'package:drivemate/screens/widget/custom_back_button.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:drivemate/utils/loading_utils.dart';
import 'package:drivemate/screens/dashboard/list/widgets/shimmer_loading_list.dart';
import 'package:drivemate/screens/dashboard/list/details/students_details_page.dart';
import 'package:drivemate/screens/dashboard/list/details/license_only_details_page.dart';
import 'package:drivemate/screens/dashboard/list/details/endorsement_details_page.dart';

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
      // Run all 6 queries in parallel for faster loading (3x speedup)
      final futures = <Future>[];
      final results =
          Map<String, Map<String, QuerySnapshot<Map<String, dynamic>>>>();

      for (var col in collections) {
        final colRef = FirebaseFirestore.instance
            .collection('users')
            .doc(_workspaceController.currentSchoolId.value)
            .collection(col);

        // Create both queries and store results
        final learnerFuture =
            colRef.where('learnersTestDate', isEqualTo: dateStr).get();
        final drivingFuture =
            colRef.where('drivingTestDate', isEqualTo: dateStr).get();

        futures.add(learnerFuture.then((snapshot) {
          results[col] ??= {};
          results[col]!['learners'] = snapshot;
        }));

        futures.add(drivingFuture.then((snapshot) {
          results[col] ??= {};
          results[col]!['driving'] = snapshot;
        }));
      }

      // Wait for ALL queries to complete simultaneously
      await Future.wait(futures);

      // Process all results
      for (var col in collections) {
        final colResults = results[col];
        if (colResults != null) {
          if (colResults['learners'] != null) {
            final lSnap = colResults['learners']!;
            allLearners.addAll(lSnap.docs.map((d) {
              final data = Map<String, dynamic>.from(d.data());
              // Inject document ID for navigation
              data['studentId'] = d.id;
              data['id'] = d.id;
              data['recordId'] = d.id;
              return {...data, '_collection': col};
            }).toList());
          }

          if (colResults['driving'] != null) {
            final dSnap = colResults['driving']!;
            allDriving.addAll(dSnap.docs.map((d) {
              final data = Map<String, dynamic>.from(d.data());
              // Inject document ID for navigation
              data['studentId'] = d.id;
              data['id'] = d.id;
              data['recordId'] = d.id;
              return {...data, '_collection': col};
            }).toList());
          }
        }
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
    final typeLabel = isLL ? 'LL TEST' : 'DL TEST';

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
      return const ShimmerLoadingList();
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
            isThreeLine: true,
            title: Text(s['fullName'] ?? ''),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(colType.toUpperCase()),
                Text('COV: ${s['cov'] ?? ''}'),
                Text('Mobile: ${s['mobileNumber'] ?? ''}'),
              ],
            ),
            trailing: Text(balance.isNotEmpty ? '₹ $balance' : ''),
            onTap: () {
              // Navigate to the respective student details page based on collection type
              String collection = s['_collection'] ?? 'students';

              if (collection == 'students') {
                // Navigate to StudentDetailsPage
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      final enriched = Map<String, dynamic>.from(s);
                      if (!enriched.containsKey('id') &&
                          enriched['id']?.toString().isEmpty != false) {
                        // Try to pass through recordId if present
                        if (enriched['id'] == null &&
                            enriched['recordId'] != null) {
                          enriched['id'] = enriched['recordId'];
                        }
                      }
                      return StudentDetailsPage(studentDetails: enriched);
                    },
                  ),
                );
              } else if (collection == 'licenseonly') {
                // Navigate to LicenseOnlyDetailsPage
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        LicenseOnlyDetailsPage(licenseDetails: s),
                  ),
                );
              } else if (collection == 'endorsement') {
                // Navigate to EndorsementDetailsPage
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EndorsementDetailsPage(endorsementDetails: s),
                  ),
                );
              }
            },
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
        title: Text('Schedule for ($dateLabel)'),
        leading: const CustomBackButton(),
        actions: [
          IconButton(
              onPressed: _pickDate, icon: const Icon(Icons.calendar_today)),
          IconButton(
              onPressed: _exportPdf, icon: const Icon(Icons.picture_as_pdf)),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'LL TEST (${learners.length})'),
            Tab(text: 'DL TEST (${driving.length})'),
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
