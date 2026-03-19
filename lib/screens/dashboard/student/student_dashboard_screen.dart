import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:drivemate/constants/colors.dart';
import 'package:drivemate/controller/workspace_controller.dart';
import 'package:drivemate/screens/dashboard/list/widgets/shimmer_loading_list.dart';
import 'package:drivemate/screens/dashboard/list/details/pdf_preview_screen.dart';
import 'package:drivemate/screens/widget/custom_back_button.dart';
import 'package:drivemate/utils/date_utils.dart';
import 'package:drivemate/utils/payment_utils.dart';
import 'package:iconly/iconly.dart';
import 'package:intl/intl.dart';
import 'package:drivemate/widgets/additional_info_sheet.dart';
import 'package:drivemate/services/additional_info_service.dart';
import 'package:drivemate/screens/dashboard/list/details/document_preview_screen.dart';
import 'package:drivemate/widgets/persistent_cached_image.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final WorkspaceController _workspaceController =
      Get.find<WorkspaceController>();

  Map<String, dynamic> _studentData = {};
  List<Map<String, dynamic>> _payments = [];
  List<Map<String, dynamic>> _attendance = [];
  List<Map<String, dynamic>> _documents = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final schoolId = _workspaceController.currentSchoolId.value;
      final studentDocId = _workspaceController.studentDocId.value;

      if (schoolId.isEmpty || studentDocId.isEmpty) {
        setState(() {
          _error = 'Unable to load student data';
          _isLoading = false;
        });
        return;
      }

      // Load student data
      final studentDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(schoolId)
          .collection('students')
          .doc(studentDocId)
          .get();

      if (studentDoc.exists) {
        _studentData = studentDoc.data() ?? {};
        _studentData['id'] = studentDoc.id;
      }

      // Load payments
      final paymentsSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(schoolId)
          .collection('students')
          .doc(studentDocId)
          .collection('payments')
          .orderBy('date', descending: true)
          .get();
      _payments = paymentsSnap.docs.map((d) => d.data()).toList();

      // Load attendance
      final attendanceSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(schoolId)
          .collection('students')
          .doc(studentDocId)
          .collection('attendance')
          .orderBy('date', descending: true)
          .get();
      _attendance = attendanceSnap.docs.map((d) => d.data()).toList();

      // Load documents
      final documentsSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(schoolId)
          .collection('students')
          .doc(studentDocId)
          .collection('documents')
          .orderBy('timestamp', descending: true)
          .get();
      _documents = documentsSnap.docs.map((d) => d.data()).toList();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading student data: $e');
      setState(() {
        _error = 'Error loading data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.grey : Colors.grey[700]!;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: false,
          titleSpacing: 16,
          title: const Text('My Dashboard'),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: false,
          titleSpacing: 16,
          title: const Text('My Dashboard'),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, style: TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Text('My Dashboard', style: TextStyle(color: textColor)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: subTextColor),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Profile Header
          _buildProfileHeader(context),

          // Tab Bar - scrollable for smaller screens
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: TabBar(
              controller: _tabController,
              isScrollable: true, // Allow scrolling on smaller screens
              labelColor: kPrimaryColor,
              unselectedLabelColor: subTextColor,
              indicatorColor: kPrimaryColor,
              labelStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              tabs: const [
                Tab(icon: Icon(IconlyBold.wallet, size: 18), text: 'Payments'),
                Tab(
                    icon: Icon(IconlyBold.calendar, size: 18),
                    text: 'Attendance'),
                Tab(icon: Icon(IconlyBold.document, size: 18), text: 'Test'),
                Tab(icon: Icon(IconlyBold.paper, size: 18), text: 'Docs'),
                Tab(icon: Icon(IconlyBold.info_circle, size: 18), text: 'Info'),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPaymentsTab(context),
                _buildAttendanceTab(context),
                _buildTestTab(context),
                _buildDocumentsTab(context),
                _buildAdditionalInfoTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final cardColor = Theme.of(context).cardColor;

    final name = _studentData['fullName'] ?? _studentData['name'] ?? 'Student';
    final studentId = _studentData['studentId'] ?? '';
    final imageUrl = _studentData['image'] ?? _studentData['photoUrl'] ?? '';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimaryColor.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          // Student photo or initials
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kPrimaryColor,
            ),
            child: ClipOval(
              child: imageUrl.isNotEmpty
                  ? PersistentCachedImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      memCacheWidth: 150,
                      memCacheHeight: 150,
                      errorWidget: Center(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'S',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'S',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: $studentId',
                  style: TextStyle(
                    color: textColor.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.grey : Colors.grey[700]!;

    if (_payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(IconlyBold.wallet, size: 64, color: subTextColor),
            const SizedBox(height: 16),
            Text(
              'No payments yet',
              style: TextStyle(color: subTextColor, fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Calculate totals - handle multiple status field names
    double totalPaid = 0;
    double totalPending = 0;
    double totalAmount = 0;
    for (var payment in _payments) {
      final amount = (payment['amount'] ?? 0).toDouble();
      final status = (payment['status'] ?? payment['paymentStatus'] ?? '')
          .toString()
          .toLowerCase();

      totalAmount += amount;

      // Paid statuses
      if (status == 'paid' || status == 'completed' || status == 'success') {
        totalPaid += amount;
      } else {
        // Pending/failed/other statuses
        totalPending += amount;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards - Total Amount, Paid, Pending
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  context,
                  'Total',
                  '${totalAmount.toStringAsFixed(2)}',
                  Icons.account_balance_wallet,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryCard(
                  context,
                  'Paid',
                  '${totalPaid.toStringAsFixed(2)}',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryCard(
                  context,
                  'Pending',
                  '${totalPending.toStringAsFixed(2)}',
                  Icons.pending,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Payment History
          Text(
            'Payment History',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          ...List.generate(_payments.length, (index) {
            final payment = _payments[index];
            final amount = (payment['amount'] ?? 0).toDouble();
            final description =
                payment['description'] ?? payment['note'] ?? 'Payment';

            // Handle date field - could be String, Timestamp, or null
            final dateValue = payment['date'];
            String dateString = '';
            if (dateValue != null) {
              if (dateValue is String) {
                dateString = dateValue;
              } else if (dateValue is Timestamp) {
                dateString = dateValue.toDate().toIso8601String();
              }
            }
            final status = payment['status'] ?? '';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Icon(
                  status.toLowerCase() == 'paid' ||
                          status.toLowerCase() == 'completed'
                      ? Icons.check_circle
                      : Icons.pending,
                  color: status.toLowerCase() == 'paid' ||
                          status.toLowerCase() == 'completed'
                      ? Colors.green
                      : Colors.orange,
                ),
                title: Text(description),
                subtitle: Text(
                  dateString.isNotEmpty
                      ? DateFormat('dd MMM yyyy')
                          .format(DateTime.parse(dateString))
                      : '',
                  style: TextStyle(color: subTextColor),
                ),
                trailing: Text(
                  '\$${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () => _generateReceipt(context, payment),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: isDark ? Colors.grey : Colors.grey[700],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateReceipt(
      BuildContext context, Map<String, dynamic> payment) async {
    // Show a dialog or navigate to receipt generation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Receipt'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount: \$${(payment['amount'] ?? 0).toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            Text(
                'Description: ${payment['description'] ?? payment['note'] ?? 'Payment'}'),
            const SizedBox(height: 8),
            Text('Date: ${payment['date'] ?? ''}'),
            const SizedBox(height: 8),
            Text('Status: ${payment['status'] ?? ''}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subTextColor = isDark ? Colors.grey : Colors.grey[700]!;

    if (_attendance.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(IconlyBold.calendar, size: 64, color: subTextColor),
            const SizedBox(height: 16),
            Text(
              'No attendance records yet',
              style: TextStyle(color: subTextColor, fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Calculate attendance stats
    int present = 0;
    int absent = 0;
    for (var record in _attendance) {
      final status = record['status'] ?? '';
      if (status.toLowerCase() == 'present' ||
          status.toLowerCase() == 'completed') {
        present++;
      } else if (status.toLowerCase() == 'absent' ||
          status.toLowerCase() == 'missed') {
        absent++;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  context,
                  'Present',
                  present.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  context,
                  'Absent',
                  absent.toString(),
                  Icons.cancel,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Text(
            'Attendance History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          ...List.generate(_attendance.length, (index) {
            final record = _attendance[index];
            final status = record['status'] ?? '';

            // Handle date field - could be String, Timestamp, or null
            final dateValue = record['date'];
            String dateString = '';
            if (dateValue != null) {
              if (dateValue is String) {
                dateString = dateValue;
              } else if (dateValue is Timestamp) {
                dateString = dateValue.toDate().toIso8601String();
              }
            }
            final lesson = record['lesson'] ?? record['package'] ?? '';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Icon(
                  status.toLowerCase() == 'present' ||
                          status.toLowerCase() == 'completed'
                      ? Icons.check_circle
                      : Icons.cancel,
                  color: status.toLowerCase() == 'present' ||
                          status.toLowerCase() == 'completed'
                      ? Colors.green
                      : Colors.red,
                ),
                title: Text(lesson.toString()),
                subtitle: Text(
                  dateString.isNotEmpty
                      ? DateFormat('dd MMM yyyy')
                          .format(DateTime.parse(dateString))
                      : '',
                  style: TextStyle(color: subTextColor),
                ),
                trailing: Text(
                  status.toString(),
                  style: TextStyle(
                    color: status.toLowerCase() == 'present' ||
                            status.toLowerCase() == 'completed'
                        ? Colors.green
                        : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTestTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.grey : Colors.grey[700]!;

    // Get test date from student data
    final testDate = _studentData['testDate'] ?? _studentData['test_date'];
    final testType =
        _studentData['testType'] ?? _studentData['test_type'] ?? '';
    final testStatus = _studentData['testStatus'] ??
        _studentData['test_status'] ??
        'Not Scheduled';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Test Info Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kPrimaryColor.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(IconlyBold.calendar, color: kPrimaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'Test Information',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildInfoRow('Test Type', testType.toString()),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Test Date',
                  testDate != null && testDate.toString().isNotEmpty
                      ? DateFormat('dd MMM yyyy')
                          .format(DateTime.parse(testDate.toString()))
                      : 'Not Scheduled',
                ),
                const SizedBox(height: 12),
                _buildInfoRow('Status', testStatus.toString()),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Request Test Date Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _requestTestDate(context),
              icon: const Icon(Icons.calendar_today),
              label: const Text('Request Test Date'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your driving school will review your request and schedule the test date.',
                    style: TextStyle(color: Colors.blue.shade700, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.grey : Colors.grey[700]!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: subTextColor, fontSize: 14),
        ),
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Future<void> _requestTestDate(BuildContext context) async {
    final schoolId = _workspaceController.currentSchoolId.value;
    final studentDocId = _workspaceController.studentDocId.value;

    if (schoolId.isEmpty || studentDocId.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Test Date'),
        content: const Text(
          'Would you like to request your driving school to schedule your test date?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Add a test date request to the student document
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(schoolId)
                    .collection('students')
                    .doc(studentDocId)
                    .update({
                  'testDateRequest': true,
                  'testDateRequestAt': DateTime.now().toIso8601String(),
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Test date request submitted!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Request'),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.grey : Colors.grey[700]!;

    if (_documents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(IconlyBold.document, size: 64, color: subTextColor),
            const SizedBox(height: 16),
            Text(
              'No documents uploaded yet',
              style: TextStyle(color: subTextColor, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Documents',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'View your uploaded documents. Request updates if needed.',
            style: TextStyle(color: subTextColor, fontSize: 14),
          ),
          const SizedBox(height: 16),

          ...List.generate(_documents.length, (index) {
            final doc = _documents[index];
            final docName = doc['name'] ?? doc['documentName'] ?? 'Document';
            final docType = doc['type'] ?? doc['documentType'] ?? '';
            final url = doc['url'] ?? doc['downloadUrl'] ?? '';
            final uploadDate = doc['timestamp'] ?? doc['uploadDate'] ?? '';
            final status = doc['status'] ?? 'approved';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Icon(
                  _getDocumentIcon(docType.toString()),
                  color: kPrimaryColor,
                ),
                title: Text(docName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      docType.toString(),
                      style: TextStyle(color: subTextColor),
                    ),
                    if (uploadDate.toString().isNotEmpty)
                      Text(
                        'Uploaded: ${DateFormat('dd MMM yyyy').format(DateTime.parse(uploadDate.toString()))}',
                        style: TextStyle(color: subTextColor, fontSize: 12),
                      ),
                    if (status == 'pending_update')
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Update Pending Approval',
                          style: TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                      ),
                  ],
                ),
                trailing: url.toString().isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.visibility),
                        onPressed: () {
                          // View document
                        },
                      )
                    : null,
              ),
            );
          }),

          const SizedBox(height: 24),

          // Request Document Update Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _requestDocumentUpdate(context),
              icon: const Icon(Icons.update),
              label: const Text('Request Document Update'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: kPrimaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getDocumentIcon(String docType) {
    final type = docType.toLowerCase();
    if (type.contains('photo') ||
        type.contains('image') ||
        type.contains('selfie')) {
      return Icons.photo;
    } else if (type.contains('license') || type.contains('id')) {
      return Icons.badge;
    } else if (type.contains('medical')) {
      return Icons.medical_services;
    } else if (type.contains('address') || type.contains('proof')) {
      return Icons.location_on;
    } else {
      return Icons.description;
    }
  }

  Future<void> _requestDocumentUpdate(BuildContext context) async {
    // Show a dialog to select which document to update
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Document Update'),
        content: const Text(
          'This will notify your driving school that you need to update one or more documents. '
          'They will review and approve your request.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final schoolId = _workspaceController.currentSchoolId.value;
              final studentDocId = _workspaceController.studentDocId.value;

              if (schoolId.isEmpty || studentDocId.isEmpty) return;

              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(schoolId)
                    .collection('students')
                    .doc(studentDocId)
                    .update({
                  'documentUpdateRequest': true,
                  'documentUpdateRequestAt': DateTime.now().toIso8601String(),
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Document update request submitted!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Request'),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.grey : Colors.grey[700]!;

    // Get additional info from student data
    final package =
        _studentData['package'] ?? _studentData['selectedPackage'] ?? '';
    final cov = _studentData['cov'] ?? _studentData['classOfVehicle'] ?? '';
    final status = _studentData['status'] ?? '';
    final enrolledDate =
        _studentData['enrolledDate'] ?? _studentData['registrationDate'] ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Additional Information',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildInfoRow('Package', package.toString()),
                const Divider(),
                _buildInfoRow('Class of Vehicle (COV)',
                    cov.toString().isNotEmpty ? cov.toString() : 'N/A'),
                const Divider(),
                _buildInfoRow('Status', status.toString()),
                const Divider(),
                _buildInfoRow(
                  'Enrolled Date',
                  enrolledDate.toString().isNotEmpty
                      ? DateFormat('dd MMM yyyy')
                          .format(DateTime.parse(enrolledDate.toString()))
                      : 'N/A',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Note about view-only
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This information is managed by your driving school. Contact them for any changes.',
                    style: TextStyle(color: Colors.blue.shade700, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
