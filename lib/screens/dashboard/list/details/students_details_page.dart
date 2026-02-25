import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/screens/widget/custom_back_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mds/screens/authentication/widgets/my_button.dart';
import 'package:mds/screens/dashboard/form/edit_forms/edit_student_details_form.dart';
import 'package:mds/screens/dashboard/list/details/pdf_preview_screen.dart';
import 'package:mds/service/attendance_pdf_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:mds/services/pdf_service.dart';
import 'package:mds/services/image_cache_service.dart';
import 'package:mds/services/attendance_pdf_service.dart';
import 'package:mds/screens/profile/action_button.dart';
import 'package:mds/utils/loading_utils.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:mds/controller/workspace_controller.dart';
import 'package:mds/utils/payment_utils.dart';
import 'package:mds/utils/date_utils.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mds/features/tracking/services/background_service.dart';
import 'package:mds/features/tracking/data/repositories/tracking_repository.dart';
import 'package:mds/features/tracking/services/location_tracking_service.dart';

class StudentDetailsPage extends StatefulWidget {
  final Map<String, dynamic> studentDetails;

  const StudentDetailsPage({required this.studentDetails, super.key});

  @override
  State<StudentDetailsPage> createState() => _StudentDetailsPageState();
}

class _StudentDetailsPageState extends State<StudentDetailsPage> {
  static const Color kAccentRed = Color.fromRGBO(241, 135, 71, 1);
  late Map<String, dynamic> studentDetails;
  final List<String> _selectedTransactionIds = [];
  final WorkspaceController _workspaceController =
      Get.find<WorkspaceController>();

  @override
  void initState() {
    super.initState();
    studentDetails = Map.from(widget.studentDetails);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark ? Colors.grey : Colors.grey[700]!;

    final targetId = _workspaceController.currentSchoolId.value.isNotEmpty
        ? _workspaceController.currentSchoolId.value
        : (FirebaseAuth.instance.currentUser?.uid ?? '');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text('Student Details', style: TextStyle(color: textColor)),
        elevation: 0,
        leading: const CustomBackButton(),
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf, color: subTextColor),
            onPressed: () => _shareStudentDetails(context),
          ),
          IconButton(
            icon: Icon(Icons.edit, color: subTextColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditStudentDetailsForm(
                    initialValues: studentDetails,
                    items: const [
                      'MC Study',
                      'MCWOG Study',
                      'LMV Study',
                      'LMV Study + MC Study',
                      'LMV Study + MCWOG Study',
                      'LMV Study + MC License',
                      'LMV Study + MCWOG License',
                      'LMV License + MC Study',
                      'LMV License + MCWOG Study',
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(targetId)
            .collection('students')
            .doc(studentDetails['studentId'].toString())
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.exists) {
            studentDetails = snapshot.data!.data() as Map<String, dynamic>;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildProfileHeader(context),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 1, child: _buildPersonalInfoCard(context)),
                    const SizedBox(width: 16),
                    Expanded(flex: 1, child: _buildAddressCard(context)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildPaymentOverviewCard(context),
                const SizedBox(height: 16),
                _buildLessonStatusCard(context, targetId),
                const SizedBox(height: 16),
                _buildAttendanceCard(context, targetId),
                const SizedBox(height: 16),
                _buildTestDateCard(context),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Test date card ──────────────────────────────────────────────────────────

  Widget _buildTestDateCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark ? Colors.grey : Colors.grey[700]!;
    final cardColor = Theme.of(context).cardColor;

    final llDate = AppDateUtils.formatDateForDisplay(
        studentDetails['learnersTestDate']?.toString());
    final dlDate = AppDateUtils.formatDateForDisplay(
        studentDetails['drivingTestDate']?.toString());

    if (llDate.isEmpty && dlDate.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(context, kAccentRed),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Test Date',
              style: TextStyle(
                  color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          if (llDate.isNotEmpty)
            _buildInfoRow(
                'Learners Test (LL)', llDate, textColor, subTextColor),
          if (dlDate.isNotEmpty)
            _buildInfoRow('Driving Test (DL)', dlDate, textColor, subTextColor),
        ],
      ),
    );
  }

  // ── Profile header ──────────────────────────────────────────────────────────

  Widget _buildProfileHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark ? Colors.grey : Colors.grey[700]!;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: _cardDecoration(context, kAccentRed),
      child: Row(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: kAccentRed,
            child: CircleAvatar(
              radius: 48,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              child: studentDetails['image'] != null &&
                      studentDetails['image'].isNotEmpty
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: studentDetails['image'],
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Center(
                          child: Text(
                            _initials,
                            style: TextStyle(fontSize: 40, color: textColor),
                          ),
                        ),
                        placeholder: (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                      ),
                    )
                  : Center(
                      child: Text(_initials,
                          style: TextStyle(fontSize: 40, color: textColor)),
                    ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  studentDetails['fullName'] ?? 'N/A',
                  style: TextStyle(
                      color: textColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'ID: ${studentDetails['studentId'] ?? 'N/A'}',
                  style: TextStyle(color: subTextColor, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: kAccentRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kAccentRed),
                  ),
                  child: Text(
                    'COV: ${studentDetails['cov'] ?? 'N/A'}',
                    style: const TextStyle(
                        color: kAccentRed,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _initials {
    final name = studentDetails['fullName'];
    if (name == null || name.isEmpty) return '';
    return name[0].toUpperCase();
  }

  // ── Personal info ───────────────────────────────────────────────────────────

  Widget _buildPersonalInfoCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark ? Colors.grey : Colors.grey[700]!;

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(context, kAccentRed),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Personal Info',
                style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            const SizedBox(height: 12),
            _buildInfoRow('Name', studentDetails['fullName'] ?? 'N/A',
                textColor, subTextColor),
            _buildInfoRow(
                'Guardian Name',
                studentDetails['guardianName'] ?? 'N/A',
                textColor,
                subTextColor),
            _buildInfoRow(
                'DOB', studentDetails['dob'] ?? 'N/A', textColor, subTextColor),
            _buildInfoRow('Mobile', studentDetails['mobileNumber'] ?? 'N/A',
                textColor, subTextColor),
          ],
        ),
      ),
    );
  }

  // ── Address card ────────────────────────────────────────────────────────────

  Widget _buildAddressCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark ? Colors.grey : Colors.grey[700]!;

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(context, kAccentRed),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Address',
                style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            const SizedBox(height: 12),
            _buildInfoRow('House', studentDetails['house'] ?? '', textColor,
                subTextColor),
            _buildInfoRow('Place', studentDetails['place'] ?? '', textColor,
                subTextColor),
            _buildInfoRow(
                'Post', studentDetails['post'] ?? '', textColor, subTextColor),
            _buildInfoRow('District', studentDetails['district'] ?? '',
                textColor, subTextColor),
            _buildInfoRow('PIN Code', studentDetails['pin'] ?? '', textColor,
                subTextColor),
          ],
        ),
      ),
    );
  }

  // ── Payment overview ────────────────────────────────────────────────────────

  Widget _buildPaymentOverviewCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark ? Colors.grey : Colors.grey[700]!;

    double total =
        double.tryParse(studentDetails['totalAmount']?.toString() ?? '0') ?? 0;
    double balance =
        double.tryParse(studentDetails['balanceAmount']?.toString() ?? '0') ??
            0;
    double paidAmount = total - balance;
    double progressValue = total > 0 ? paidAmount / total : 0;

    final schoolId = _workspaceController.currentSchoolId.value;
    final targetId =
        schoolId.isNotEmpty ? schoolId : FirebaseAuth.instance.currentUser?.uid;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(context, kAccentRed),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Payment Overview',
                  style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              Row(
                children: [
                  if (_selectedTransactionIds.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.receipt_long, color: kAccentRed),
                      onPressed: _generateSelectedReceipts,
                      tooltip: 'Generate Receipt for Selected',
                    ),
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(targetId)
                        .collection('students')
                        .doc(studentDetails['studentId'].toString())
                        .snapshots(),
                    builder: (context, snapshot) {
                      return IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.green),
                        onPressed: () {
                          if (snapshot.hasData) {
                            PaymentUtils.showAddPaymentDialog(
                              context: context,
                              doc: snapshot.data!
                                  as DocumentSnapshot<Map<String, dynamic>>,
                              targetId: targetId!,
                              branchId:
                                  _workspaceController.currentBranchId.value,
                              category: 'students',
                            );
                          }
                        },
                        tooltip: 'Add Payment',
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Fee:',
                      style: TextStyle(color: subTextColor, fontSize: 12)),
                  Text('Rs. $total',
                      style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Paid Amount',
                      style: TextStyle(color: subTextColor, fontSize: 12)),
                  Text('Rs. $paidAmount',
                      style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progressValue.clamp(0.0, 1.0),
            backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(kAccentRed),
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Outstanding Balance: Rs. $balance',
              style: TextStyle(color: subTextColor, fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Text('Transaction History',
              style: TextStyle(
                  color: textColor, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(targetId)
                .collection('students')
                .doc(studentDetails['studentId'].toString())
                .collection('payments')
                .orderBy('date', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('No transactions yet',
                        style: TextStyle(color: subTextColor, fontSize: 12)),
                  ),
                );
              }

              final docs = snapshot.data!.docs;
              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final date = (data['date'] as Timestamp).toDate();
                  final isSelected = _selectedTransactionIds.contains(doc.id);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[900] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(color: kAccentRed, width: 1)
                          : null,
                    ),
                    child: CheckboxListTile(
                      value: isSelected,
                      activeColor: kAccentRed,
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedTransactionIds.add(doc.id);
                          } else {
                            _selectedTransactionIds.remove(doc.id);
                          }
                        });
                      },
                      title: Text('Rs. ${data['amount']}',
                          style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      subtitle: Text(
                        '${DateFormat('dd MMM yyyy, hh:mm a').format(date)}\nMode: ${data['mode'] ?? 'N/A'}${data['note'] != null && data['note'].toString().isNotEmpty ? '\nNote: ${data['note']}' : ''}',
                        style: TextStyle(color: subTextColor, fontSize: 11),
                      ),
                      secondary: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.receipt, size: 20),
                            onPressed: () => _generateSingleReceipt(data),
                            tooltip: 'Receipt',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                size: 20, color: Colors.red),
                            onPressed: () => PaymentUtils.deletePayment(
                              context: context,
                              studentRef: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(targetId)
                                  .collection('students')
                                  .doc(studentDetails['studentId'].toString()),
                              paymentDoc: doc,
                              targetId: targetId!,
                            ),
                            tooltip: 'Delete Payment',
                          ),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Lesson status card ──────────────────────────────────────────────────────

  Widget _buildLessonStatusCard(BuildContext context, String targetId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final cardColor = Theme.of(context).cardColor;
    final lessonStatus = studentDetails['lessonStatus'] ?? 'none';
    final isLessonActive = lessonStatus == 'started';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLessonActive ? Colors.green : Colors.grey.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lesson Control',
                style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
              if (isLessonActive)
                const Icon(Icons.emergency_recording,
                    color: Colors.green, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isLessonActive
                ? 'Lesson is currently in progress. Location is being shared with the owner.'
                : 'Start a lesson to begin real-time location tracking for the owner.',
            style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 13),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _toggleLessonStatus(targetId, isLessonActive),
              style: ElevatedButton.styleFrom(
                backgroundColor: isLessonActive ? Colors.red : Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                isLessonActive ? 'End Lesson' : 'Start Lesson',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Attendance card ─────────────────────────────────────────────────────────

  Widget _buildAttendanceCard(BuildContext context, String targetId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final cardColor = Theme.of(context).cardColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(context, kAccentRed),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Attendance Logs',
                style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
              Row(
                children: [
                  // ✅ PDF download
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf,
                        color: kAccentRed, size: 20),
                    tooltip: 'Download PDF',
                    onPressed: () => _downloadAttendancePdf(context, targetId),
                  ),
                  TextButton.icon(
                    onPressed: () => _showAttendanceLogs(context, targetId),
                    icon:
                        const Icon(Icons.history, size: 18, color: kAccentRed),
                    label: const Text('View All',
                        style: TextStyle(color: kAccentRed)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(targetId)
                .collection('students')
                .doc(studentDetails['studentId'].toString())
                .collection('attendance')
                .orderBy('date', descending: true)
                .limit(2)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Text(
                  'No classes recorded yet.',
                  style: TextStyle(
                      color: textColor.withOpacity(0.5), fontSize: 13),
                );
              }

              return Column(
                children: snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final date =
                      (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
                  final startTime = (data['startTime'] as Timestamp?)?.toDate();
                  final endTime = (data['endTime'] as Timestamp?)?.toDate();

                  String timeRange = 'N/A';
                  if (startTime != null && endTime != null) {
                    timeRange =
                        '${DateFormat('hh:mm a').format(startTime)} - ${DateFormat('hh:mm a').format(endTime)}';
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('dd MMM yyyy').format(date),
                                style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13),
                              ),
                              Text(timeRange,
                                  style: TextStyle(
                                      color: textColor.withOpacity(0.6),
                                      fontSize: 11)),
                              Text(data['instructorName'] ?? 'Unknown',
                                  style: TextStyle(
                                      color: textColor.withOpacity(0.6),
                                      fontSize: 11)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              data['duration'] ?? 'N/A',
                              style: const TextStyle(
                                  color: kAccentRed,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13),
                            ),
                            Text(
                              data['distance'] ?? '0 KM',
                              style: TextStyle(
                                  color: textColor.withOpacity(0.6),
                                  fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Attendance PDF download ─────────────────────────────────────────────────

  Future<void> _downloadAttendancePdf(
      BuildContext context, String targetId) async {
    Uint8List? pdfBytes;
    try {
      pdfBytes = await LoadingUtils.wrapWithLoading(context, () async {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .doc(targetId)
            .collection('students')
            .doc(studentDetails['studentId'].toString())
            .collection('attendance')
            .orderBy('date', descending: false)
            .get();

        final records = snap.docs.map((d) => d.data()).toList();

        if (records.isEmpty) throw 'No attendance records found';

        final workspace = Get.find<WorkspaceController>();
        final companyData = workspace.companyData;
        Uint8List? logoBytes;
        if (companyData['companyLogo'] != null &&
            companyData['companyLogo'].toString().isNotEmpty) {
          logoBytes = await ImageCacheService()
              .fetchAndCache(companyData['companyLogo']);
        }

        return await AttendancePdfService.generate(
          studentName: studentDetails['fullName'] ?? 'N/A',
          studentId: studentDetails['studentId'].toString(),
          cov: studentDetails['cov'] ?? 'N/A',
          records: records,
          companyData: companyData,
          companyLogoBytes: logoBytes,
        );
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
      }
      return;
    }

    if (pdfBytes != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => PdfPreviewScreen(pdfBytes: pdfBytes!)),
      );
    }
  }

  // ── Full attendance history bottom sheet ────────────────────────────────────

  void _showAttendanceLogs(BuildContext context, String targetId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title + export button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Attendance History',
                      style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _downloadAttendancePdf(context, targetId);
                    },
                    icon: const Icon(Icons.picture_as_pdf,
                        color: kAccentRed, size: 18),
                    label: const Text('Export PDF',
                        style: TextStyle(
                            color: kAccentRed, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(targetId)
                    .collection('students')
                    .doc(studentDetails['studentId'].toString())
                    .collection('attendance')
                    .orderBy('date', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.history_edu_outlined,
                              size: 48, color: textColor.withOpacity(0.2)),
                          const SizedBox(height: 12),
                          Text('No attendance history found.',
                              style:
                                  TextStyle(color: textColor.withOpacity(0.5))),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    itemCount: snapshot.data!.docs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final data = snapshot.data!.docs[index].data()
                          as Map<String, dynamic>;
                      final date = (data['date'] as Timestamp?)?.toDate() ??
                          DateTime.now();
                      final startTime =
                          (data['startTime'] as Timestamp?)?.toDate();
                      final endTime = (data['endTime'] as Timestamp?)?.toDate();

                      String timeRange = 'N/A';
                      if (startTime != null && endTime != null) {
                        timeRange =
                            '${DateFormat('hh:mm a').format(startTime)} – ${DateFormat('hh:mm a').format(endTime)}';
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date block
                            Container(
                              width: 46,
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: kAccentRed.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    DateFormat('dd').format(date),
                                    style: const TextStyle(
                                        color: kAccentRed,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18),
                                  ),
                                  Text(
                                    DateFormat('MMM').format(date),
                                    style: TextStyle(
                                        color: textColor.withOpacity(0.5),
                                        fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat('EEEE, dd MMM yyyy')
                                        .format(date),
                                    style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13),
                                  ),
                                  const SizedBox(height: 3),
                                  Text('⏱ $timeRange',
                                      style: TextStyle(
                                          color: textColor.withOpacity(0.6),
                                          fontSize: 12)),
                                  Text(
                                      '👤 ${data['instructorName'] ?? 'Unknown'}',
                                      style: TextStyle(
                                          color: textColor.withOpacity(0.6),
                                          fontSize: 12)),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      _AttendanceBadge(
                                        icon: Icons.timer_outlined,
                                        label: data['duration'] ?? 'N/A',
                                        color: kAccentRed,
                                      ),
                                      const SizedBox(width: 8),
                                      _AttendanceBadge(
                                        icon: Icons.route_outlined,
                                        label: data['distance'] ?? '0 KM',
                                        color: Colors.blue,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Status
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'DONE',
                                style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Toggle lesson status ────────────────────────────────────────────────────

  Future<void> _toggleLessonStatus(String targetId, bool isLessonActive) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final studentId = studentDetails['studentId'].toString();
      final collection = FirebaseFirestore.instance
          .collection('users')
          .doc(targetId)
          .collection('students');

      if (!isLessonActive) {
        // Start Lesson
        await collection.doc(studentId).update({
          'lessonStatus': 'started',
          'assignedDriver': user.uid,
          'assignedDriverName': _workspaceController.userProfileData['name'] ??
              user.displayName ??
              'Unknown',
          'lessonStartTime': FieldValue.serverTimestamp(),
          'lessonDistanceKm': 0.0,
        });

        await BackgroundService.start();

        Get.snackbar(
          'Lesson Started',
          'Real-time tracking is now active for this session.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        // End Lesson
        final snapshot = await collection.doc(studentId).get();
        final data = snapshot.data();
        final startTime = (data?['lessonStartTime'] as Timestamp?)?.toDate();
        final now = DateTime.now();

        // Duration
        String durationStr = 'N/A';
        if (startTime != null) {
          final diff = now.difference(startTime);
          final hours = diff.inHours;
          final minutes = diff.inMinutes.remainder(60);
          durationStr = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
        }

        // ✅ Read lesson-specific distance — quadruple fallback
        double lessonDistanceMeters = 0.0;

        // 1. Try to get from lesson_paths collection (most reliable)
        try {
          final lessonPathDoc = await FirebaseFirestore.instance
              .collection('lesson_paths')
              .doc(studentId)
              .get();
          if (lessonPathDoc.exists) {
            final pathData = lessonPathDoc.data();
            final finalDistanceKm =
                (pathData?['finalDistanceKm'] as num?)?.toDouble() ?? 0.0;
            if (finalDistanceKm > 0) {
              lessonDistanceMeters = finalDistanceKm * 1000;
              print('Got distance from lesson_paths: $finalDistanceKm km');
            }
          }
        } catch (e) {
          print('Error reading lesson_paths: $e');
        }

        // 2. Try to get from RTDB via tracking repository
        if (lessonDistanceMeters <= 0) {
          try {
            final trackingRepo = Get.find<TrackingRepository>();
            lessonDistanceMeters =
                await trackingRepo.getDriverLessonDistance(user.uid);
          } catch (e) {
            print('Error getting distance from RTDB: $e');
          }
        }

        // 3. Try to get from student's lessonDistanceKm field
        if (lessonDistanceMeters <= 0) {
          final savedKm =
              (data?['lessonDistanceKm'] as num?)?.toDouble() ?? 0.0;
          lessonDistanceMeters = savedKm * 1000;
          if (savedKm > 0) {
            print('Got distance from student record: $savedKm km');
          }
        }

        // 4. Try to get from LocationTrackingService directly
        if (lessonDistanceMeters <= 0) {
          try {
            final ts = Get.find<LocationTrackingService>();
            lessonDistanceMeters = ts.lessonDistance;
            if (lessonDistanceMeters > 0) {
              print(
                  'Got distance from tracking service: ${lessonDistanceMeters / 1000} km');
            }
          } catch (_) {}
        }

        // Ensure we have at least 0 distance
        lessonDistanceMeters = lessonDistanceMeters.clamp(0.0, double.infinity);

        final distanceKm = (lessonDistanceMeters / 1000).toStringAsFixed(2);

        // Record attendance
        await collection.doc(studentId).collection('attendance').add({
          'instructorName': _workspaceController.userProfileData['name'] ??
              user.displayName ??
              'Unknown',
          'date': FieldValue.serverTimestamp(),
          'startTime': startTime != null ? Timestamp.fromDate(startTime) : null,
          'endTime': FieldValue.serverTimestamp(),
          'duration': durationStr,
          'distance': '$distanceKm KM',
          'distanceMeters': lessonDistanceMeters,
          'instructorId': user.uid,
        });

        await collection.doc(studentId).update({
          'lessonStatus': 'completed',
          'lessonEndTime': FieldValue.serverTimestamp(),
          'lessonDistanceKm': double.parse(distanceKm),
        });

        Get.snackbar(
          'Lesson Completed',
          'Attendance recorded: $durationStr · $distanceKm KM',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update lesson status: $e');
    }
  }

  // ── Receipts ────────────────────────────────────────────────────────────────

  Future<void> _generateSingleReceipt(Map<String, dynamic> transaction) async {
    _generateReceipts([transaction]);
  }

  Future<void> _generateSelectedReceipts() async {
    if (_selectedTransactionIds.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final targetId = _workspaceController.targetId;
    final query = await FirebaseFirestore.instance
        .collection('users')
        .doc(targetId)
        .collection('students')
        .doc(studentDetails['studentId'].toString())
        .collection('payments')
        .where(FieldPath.documentId, whereIn: _selectedTransactionIds)
        .get();

    final transactions = query.docs.map((d) => d.data()).toList();
    _generateReceipts(transactions);
  }

  Future<void> _generateReceipts(
      List<Map<String, dynamic>> transactions) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    Uint8List? pdfBytes;
    try {
      pdfBytes = await LoadingUtils.wrapWithLoading(context, () async {
        final workspace = Get.find<WorkspaceController>();
        final companyData = workspace.companyData;

        if (companyData['hasCompanyProfile'] != true) {
          throw 'Please set up your Company Profile first';
        }

        Uint8List? logoBytes;
        if (companyData['companyLogo'] != null &&
            companyData['companyLogo'].toString().isNotEmpty) {
          logoBytes = await ImageCacheService()
              .fetchAndCache(companyData['companyLogo']);
        }

        return await PdfService.generateReceipt(
          companyData: companyData,
          studentDetails: studentDetails,
          transactions: transactions,
          companyLogoBytes: logoBytes,
        );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
      return;
    }

    if (pdfBytes != null && mounted) {
      _showPdfPreview(context, pdfBytes);
    }
  }

  // ── Share student PDF ───────────────────────────────────────────────────────

  Future<void> _shareStudentDetails(BuildContext context) async {
    bool includePayment = false;

    final bool? shouldGenerate = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 30),
              decoration:
                  BoxDecoration(borderRadius: BorderRadius.circular(20)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Share PDF',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 18.0),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('Include Payment Overview'),
                    value: includePayment,
                    onChanged: (bool? value) {
                      setState(() {
                        includePayment = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: ActionButton(
                          text: 'Cancel',
                          backgroundColor: const Color(0xFFFFF1F1),
                          textColor: const Color(0xFFFF0000),
                          onPressed: () => Navigator.of(context).pop(false),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ActionButton(
                          text: 'Generate',
                          backgroundColor: const Color(0xFFF6FFF0),
                          textColor: Colors.black,
                          onPressed: () => Navigator.of(context).pop(true),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
      },
    );

    if (shouldGenerate != true) return;

    Uint8List? pdfBytes;
    try {
      pdfBytes = await LoadingUtils.wrapWithLoading(context, () async {
        final workspace = Get.find<WorkspaceController>();
        final companyData = workspace.companyData;

        Uint8List? studentImageBytes;
        if (studentDetails['image'] != null &&
            studentDetails['image'].isNotEmpty) {
          studentImageBytes =
              await ImageCacheService().fetchAndCache(studentDetails['image']);
        }

        Uint8List? logoBytes;
        if (companyData['hasCompanyProfile'] == true &&
            companyData['companyLogo'] != null &&
            companyData['companyLogo'].toString().isNotEmpty) {
          logoBytes = await ImageCacheService()
              .fetchAndCache(companyData['companyLogo']);
        }

        return await PdfService.generatePdf(
          title: 'Student Details',
          data: studentDetails,
          includePayment: includePayment,
          imageBytes: studentImageBytes,
          companyData: companyData,
          companyLogoBytes: logoBytes,
        );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
      return;
    }

    if (pdfBytes != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => PdfPreviewScreen(pdfBytes: pdfBytes!)),
      );
    }
  }

  void _showPdfPreview(BuildContext context, Uint8List pdfBytes) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PdfPreviewScreen(pdfBytes: pdfBytes)),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  BoxDecoration _cardDecoration(BuildContext context, Color borderColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: borderColor.withOpacity(0.5)),
      boxShadow: isDark
          ? null
          : [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
    );
  }

  Widget _buildInfoRow(
      String label, String value, Color textColor, Color subTextColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 13, fontFamily: 'Inter', color: textColor),
          children: [
            TextSpan(text: '$label: ', style: TextStyle(color: subTextColor)),
            TextSpan(text: value, style: TextStyle(color: textColor)),
          ],
        ),
      ),
    );
  }

  String _formatAddress() {
    return [
      studentDetails['house'],
      studentDetails['post'],
      studentDetails['district'],
      studentDetails['pin']
    ].where((e) => e != null && e.isNotEmpty).join(', ');
  }
}

// ── Attendance badge widget ───────────────────────────────────────────────────

class _AttendanceBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _AttendanceBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
