import 'dart:io';
import 'dart:typed_data';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/services.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/screens/widget/custom_back_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mds/screens/authentication/widgets/my_button.dart';
import 'package:mds/screens/dashboard/form/edit_forms/edit_student_details_form.dart';
import 'package:mds/screens/dashboard/list/widgets/shimmer_loading_list.dart';
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
import 'package:mds/screens/widget/utils.dart';
import 'package:get/get.dart';
import 'package:mds/controller/workspace_controller.dart';
import 'package:mds/utils/payment_utils.dart';
import 'package:iconly/iconly.dart';
import 'package:mds/utils/test_utils.dart';
import 'package:mds/utils/image_utils.dart';
import 'package:mds/utils/date_utils.dart';
import 'package:mds/widgets/additional_info_sheet.dart';
import 'package:mds/services/additional_info_service.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mds/features/tracking/services/background_service.dart';
import 'package:mds/features/tracking/data/repositories/tracking_repository.dart';
import 'package:mds/features/tracking/services/location_tracking_service.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool _isTransactionHistoryExpanded = false;

  @override
  void initState() {
    super.initState();
    studentDetails = Map.from(widget.studentDetails);
    _docId = studentDetails['studentId'].toString();
    _initStreams();
  }

  late final String _docId;
  late final Stream<DocumentSnapshot> _mainStream;
  late final Stream<QuerySnapshot> _paymentsStream;
  late final Stream<QuerySnapshot> _extraFeesStream;
  late final Stream<QuerySnapshot> _attendanceLimitStream;
  late final Stream<QuerySnapshot> _attendanceHistoryStream;

  void _initStreams() {
    final targetId = _workspaceController.currentSchoolId.value.isNotEmpty
        ? _workspaceController.currentSchoolId.value
        : (FirebaseAuth.instance.currentUser?.uid ?? '');

    _mainStream = FirebaseFirestore.instance
        .collection('users')
        .doc(targetId)
        .collection('students')
        .doc(_docId)
        .snapshots();

    _paymentsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(targetId)
        .collection('students')
        .doc(_docId)
        .collection('payments')
        .orderBy('date', descending: true)
        .snapshots();

    _extraFeesStream = FirebaseFirestore.instance
        .collection('users')
        .doc(targetId)
        .collection('students')
        .doc(_docId)
        .collection('extra_fees')
        .orderBy('date', descending: true)
        .snapshots();

    _attendanceLimitStream = FirebaseFirestore.instance
        .collection('users')
        .doc(targetId)
        .collection('students')
        .doc(_docId)
        .collection('attendance')
        .orderBy('date', descending: true)
        .limit(2)
        .snapshots();

    _attendanceHistoryStream = FirebaseFirestore.instance
        .collection('users')
        .doc(targetId)
        .collection('students')
        .doc(_docId)
        .collection('attendance')
        .orderBy('date', descending: true)
        .snapshots();
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
          _buildLessonControlButton(targetId),
          _buildAdditionalInfoButton(),
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
        stream: _mainStream,
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
    final cardColor = Theme.of(context).cardColor;

    final llDate = AppDateUtils.formatDateForDisplay(
      studentDetails['learnersTestDate']?.toString(),
    );
    final dlDate = AppDateUtils.formatDateForDisplay(
      studentDetails['drivingTestDate']?.toString(),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kAccentRed.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Test Dates',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(IconlyLight.edit, color: kAccentRed, size: 20),
                onPressed: () => TestUtils.showUpdateTestDateDialog(
                  context: context,
                  item: studentDetails,
                  collection: 'students',
                  studentId: _docId,
                  onUpdate: () => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTestDateRow(
            'Learners Test (LL)',
            llDate,
            IconlyBold.calendar,
            Colors.blue,
            isDark,
          ),
          const Divider(height: 16),
          _buildTestDateRow(
            'Driving Test (DL)',
            dlDate,
            IconlyBold.calendar,
            Colors.green,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildTestDateRow(
    String label,
    String date,
    IconData icon,
    Color iconColor,
    bool isDark,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
              ),
            ),
            Text(
              date.isEmpty ? 'Pick test date' : date,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
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
          Builder(
            builder: (context) {
              Timer? holdTimer;
              return GestureDetector(
                onTapDown: (_) {
                  if (studentDetails['image'] != null &&
                      studentDetails['image'].toString().isNotEmpty) {
                    holdTimer = Timer(const Duration(seconds: 1), () {
                      ImageUtils.showImagePopup(
                        context,
                        studentDetails['image'],
                        studentDetails['fullName'],
                      );
                    });
                  }
                },
                onTapUp: (_) => holdTimer?.cancel(),
                onTapCancel: () => holdTimer?.cancel(),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: kAccentRed,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 3,
                    ),
                  ),
                  child: ClipOval(
                    child: (studentDetails['image'] != null &&
                            studentDetails['image'].toString().isNotEmpty)
                        ? CachedNetworkImage(
                            imageUrl: studentDetails['image'],
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: isDark
                                  ? Colors.grey[800]!
                                  : Colors.grey[300]!,
                              highlightColor: isDark
                                  ? Colors.grey[700]!
                                  : Colors.grey[100]!,
                              child: Container(color: Colors.white),
                            ),
                            errorWidget: (context, url, error) => Container(
                              alignment: Alignment.center,
                              child: Text(
                                _initials,
                                style: TextStyle(
                                  fontSize: 40,
                                  color: textColor,
                                  height: 1.0,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : Container(
                            alignment: Alignment.center,
                            child: Text(
                              _initials,
                              style: TextStyle(
                                fontSize: 40,
                                color: textColor,
                                height: 1.0,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                  ),
                ),
              );
            },
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
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ID: ${studentDetails['studentId'] ?? 'N/A'}',
                  style: TextStyle(color: subTextColor, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
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
                      fontWeight: FontWeight.bold,
                    ),
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
            Text(
              'Personal Info',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Name',
              studentDetails['fullName'] ?? 'N/A',
              textColor,
              subTextColor,
            ),
            _buildInfoRow(
              'Guardian',
              studentDetails['guardianName'] ?? 'N/A',
              textColor,
              subTextColor,
            ),
            _buildInfoRow(
              'DOB',
              formatDisplayDate(studentDetails['dob']),
              textColor,
              subTextColor,
            ),
            // ── Tappable mobile number ──
            _buildMobileRow(
              studentDetails['mobileNumber'] ?? 'N/A',
              textColor,
              subTextColor,
              context,
            ),
            _buildInfoRow(
              'Emergency',
              studentDetails['emergencyNumber'] ?? 'N/A',
              textColor,
              subTextColor,
            ),
            _buildInfoRow(
              'Blood Group',
              studentDetails['bloodGroup'] ?? 'N/A',
              textColor,
              subTextColor,
            ),
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
            Text(
              'Address',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'House',
              studentDetails['house'] ?? '',
              textColor,
              subTextColor,
            ),
            _buildInfoRow(
              'Place',
              studentDetails['place'] ?? '',
              textColor,
              subTextColor,
            ),
            _buildInfoRow(
              'Post',
              studentDetails['post'] ?? '',
              textColor,
              subTextColor,
            ),
            _buildInfoRow(
              'District',
              studentDetails['district'] ?? '',
              textColor,
              subTextColor,
            ),
            _buildInfoRow(
              'PIN Code',
              studentDetails['pin'] ?? '',
              textColor,
              subTextColor,
            ),
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
              Text(
                'Payment Overview',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
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
                      return Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.post_add,
                              color: Colors.blue,
                            ),
                            onPressed: () {
                              if (snapshot.hasData) {
                                PaymentUtils.showAddExtraFeeDialog(
                                  context: context,
                                  doc: snapshot.data!
                                      as DocumentSnapshot<Map<String, dynamic>>,
                                  targetId: targetId!,
                                  branchId: _workspaceController
                                      .currentBranchId.value,
                                  category: 'students',
                                );
                              }
                            },
                            tooltip: 'Add Extra Fee',
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.add_circle,
                              color: Colors.green,
                            ),
                            onPressed: () {
                              if (snapshot.hasData) {
                                PaymentUtils.showAddPaymentDialog(
                                  context: context,
                                  doc: snapshot.data!
                                      as DocumentSnapshot<Map<String, dynamic>>,
                                  targetId: targetId!,
                                  branchId: _workspaceController
                                      .currentBranchId.value,
                                  category: 'students',
                                );
                              }
                            },
                            tooltip: 'Add Payment',
                          ),
                        ],
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
                  Text(
                    'Total Fee:',
                    style: TextStyle(color: subTextColor, fontSize: 12),
                  ),
                  Text(
                    'Rs. $total',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Paid Amount',
                    style: TextStyle(color: subTextColor, fontSize: 12),
                  ),
                  Text(
                    'Rs. $paidAmount',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Transaction History',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              if (_selectedTransactionIds.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.receipt_long, color: kAccentRed),
                  onPressed: _generateSelectedReceipts,
                  tooltip: 'Generate Receipt for Selected',
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: _paymentsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ShimmerLoadingList();
              }

              final docs = snapshot.data?.docs ?? [];

              List<Map<String, dynamic>> combinedDocs = docs.map((d) {
                final map = d.data() as Map<String, dynamic>;
                map['id'] = d.id;
                map['docRef'] = d;
                return map;
              }).toList();

              if (combinedDocs.isEmpty) {
                final advAmt = double.tryParse(
                      studentDetails['advanceAmount']?.toString() ?? '0',
                    ) ??
                    0;
                if (advAmt > 0) {
                  final regDate = DateTime.tryParse(
                        studentDetails['registrationDate']?.toString() ?? '',
                      ) ??
                      DateTime(2000);
                  combinedDocs.add({
                    'id': 'legacy_adv',
                    'amount': advAmt,
                    'date': Timestamp.fromDate(regDate),
                    'mode': studentDetails['paymentMode'] ?? 'Cash',
                    'description': 'Initial Advance',
                    'isLegacy': true,
                  });
                }
              }

              combinedDocs.sort(
                (a, b) =>
                    (b['date'] as Timestamp).compareTo(a['date'] as Timestamp),
              );

              if (combinedDocs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'No transactions yet',
                      style: TextStyle(color: subTextColor, fontSize: 12),
                    ),
                  ),
                );
              }

              // Show only 2 items by default, expand to show all
              final displayDocs = _isTransactionHistoryExpanded
                  ? combinedDocs
                  : combinedDocs.take(2).toList();
              final hasMore = combinedDocs.length > 2;

              return Column(
                children: [
                  ...displayDocs.map((data) {
                    final date = (data['date'] as Timestamp).toDate();
                    final isSelected = _selectedTransactionIds.contains(
                      data['id'],
                    );

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
                              _selectedTransactionIds.add(data['id']);
                            } else {
                              _selectedTransactionIds.remove(data['id']);
                            }
                          });
                        },
                        title: Text(
                          'Rs. ${data['amount']}',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          '${DateFormat('dd MMM yyyy, hh:mm a').format(date)}\nMode: ${data['mode'] ?? 'N/A'}${data['note'] != null && data['note'].toString().trim().isNotEmpty ? '\nNote: ${data['note']}' : (data['description'] != null && data['description'].toString().trim().isNotEmpty ? '\n${data['description']}' : '')}',
                          style: TextStyle(color: subTextColor, fontSize: 11),
                        ),
                        secondary: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit_outlined,
                                size: 20,
                                color: Colors.blue,
                              ),
                              onPressed: () {
                                PaymentUtils.showEditPaymentDialog(
                                  context: context,
                                  docRef: FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(targetId)
                                      .collection('students')
                                      .doc(
                                        studentDetails['studentId'].toString(),
                                      ),
                                  paymentDoc: data['docRef'],
                                  targetId: targetId.toString(),
                                  category: 'students',
                                );
                              },
                              tooltip: 'Edit Payment',
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                PaymentUtils.deletePayment(
                                  context: context,
                                  studentRef: FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(targetId)
                                      .collection('students')
                                      .doc(
                                        studentDetails['studentId'].toString(),
                                      ),
                                  paymentDoc: data['docRef'],
                                  targetId: targetId.toString(),
                                );
                              },
                              tooltip: 'Delete Payment',
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  }).toList(),
                  if (hasMore)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _isTransactionHistoryExpanded =
                              !_isTransactionHistoryExpanded;
                        });
                      },
                      icon: Icon(
                        _isTransactionHistoryExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: kAccentRed,
                      ),
                      label: Text(
                        _isTransactionHistoryExpanded
                            ? 'Show Less'
                            : 'Show ${combinedDocs.length - 2} More',
                        style: const TextStyle(color: kAccentRed),
                      ),
                    ),
                ],
              );
            },
          ),
          // ── Additional Fees ─────────────────────────────────────────────
          StreamBuilder<QuerySnapshot>(
            stream: _extraFeesStream,
            builder: (context, feesSnapshot) {
              if (!feesSnapshot.hasData || feesSnapshot.data!.docs.isEmpty) {
                return const SizedBox.shrink();
              }
              final feeDocs = feesSnapshot.data!.docs;
              final baseDocRef = FirebaseFirestore.instance
                  .collection('users')
                  .doc(targetId)
                  .collection('students')
                  .doc(studentDetails['studentId'].toString());
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Additional Fees',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (_selectedTransactionIds.isNotEmpty)
                        IconButton(
                          icon: const Icon(
                            Icons.receipt_long,
                            color: kAccentRed,
                          ),
                          onPressed: _generateSelectedReceipts,
                          tooltip: 'Generate Receipt for Selected',
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...feeDocs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final date = (data['date'] as Timestamp).toDate();
                    final isPaid = data['status'] == 'paid';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[900] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: _selectedTransactionIds.contains(doc.id)
                            ? Border.all(color: kAccentRed, width: 1)
                            : isPaid
                                ? Border.all(
                                    color: Colors.green.withOpacity(0.4))
                                : null,
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _selectedTransactionIds.contains(doc.id),
                            activeColor: kAccentRed,
                            onChanged: isPaid
                                ? (val) {
                                    setState(() {
                                      if (val == true) {
                                        _selectedTransactionIds.add(doc.id);
                                      } else {
                                        _selectedTransactionIds.remove(doc.id);
                                      }
                                    });
                                  }
                                : null,
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['description'] ?? 'N/A',
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Rs. ${data['amount']}',
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormat('dd MMM yyyy').format(date),
                                    style: TextStyle(
                                      color: subTextColor,
                                      fontSize: 11,
                                    ),
                                  ),
                                  if (isPaid &&
                                      data['paymentMode'] != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Mode: ${data['paymentMode']}',
                                      style: TextStyle(
                                        color: subTextColor,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                  if (data['note'] != null &&
                                      data['note']
                                          .toString()
                                          .trim()
                                          .isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Note: ${data['note']}',
                                      style: TextStyle(
                                        color: subTextColor,
                                        fontSize: 11,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isPaid)
                                const Padding(
                                  padding: EdgeInsets.only(right: 8.0),
                                  child: Chip(
                                    label: Text(
                                      'Paid',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                      ),
                                    ),
                                    backgroundColor: Colors.green,
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                  ),
                                )
                              else
                                TextButton(
                                  onPressed: () =>
                                      PaymentUtils.showCollectExtraFeeDialog(
                                    context: context,
                                    docRef: baseDocRef,
                                    feeDoc: doc,
                                    targetId: targetId.toString(),
                                    branchId: _workspaceController
                                        .currentBranchId.value,
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.redAccent,
                                  ),
                                  child: const Text(
                                    'Collect',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 18,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () =>
                                        PaymentUtils.showEditExtraFeeDialog(
                                      context: context,
                                      docRef: baseDocRef,
                                      feeDoc: doc,
                                      targetId: targetId.toString(),
                                      category: 'students',
                                    ),
                                    tooltip: 'Edit',
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: Colors.red,
                                    ),
                                    onPressed: () =>
                                        PaymentUtils.deleteExtraFee(
                                      context: context,
                                      docRef: baseDocRef,
                                      feeDoc: doc,
                                      targetId: targetId.toString(),
                                    ),
                                    tooltip: 'Delete',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Lesson control button for AppBar ───────────────────────────────────────

  Widget _buildLessonControlButton(String targetId) {
    final lessonStatus = studentDetails['lessonStatus'] ?? 'none';
    final isLessonActive = lessonStatus == 'started';

    return IconButton(
      icon: Icon(
        isLessonActive ? Icons.stop_circle : Icons.play_circle,
        color: isLessonActive ? Colors.red : Colors.green,
        size: 28,
      ),
      onPressed: () => _toggleLessonStatus(targetId, isLessonActive),
      tooltip: isLessonActive ? 'End Lesson' : 'Start Lesson',
    );
  }

  // ── Additional Info button for AppBar ──────────────────────────────────────

  Widget _buildAdditionalInfoButton() {
    final additionalInfo =
        studentDetails['additionalInfo'] as Map<String, dynamic>?;
    final hasData = additionalInfo != null && additionalInfo.isNotEmpty;

    // Determine the correct collection based on student status
    final isDeactivated = studentDetails['status'] == 'passed' ||
        studentDetails['deactivated'] == true;
    final collectionName = isDeactivated ? 'deactivated_students' : 'students';

    return IconButton(
      icon: Icon(
        hasData ? Icons.info : Icons.info_outline,
        color: hasData ? kPrimaryColor : Colors.grey,
      ),
      onPressed: () async {
        final result = await showAdditionalInfoSheet(
          context: context,
          type: AdditionalInfoType.student,
          collection: collectionName,
          documentId: _docId,
          existingData: additionalInfo,
        );
        if (result == true) {
          // Refresh data
          setState(() {});
        }
      },
      tooltip: 'Additional Information',
    );
  }

  // ── Lesson status card (DEPRECATED - now in AppBar) ─────────────────────────

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
                  fontSize: 16,
                ),
              ),
              if (isLessonActive)
                const Icon(
                  Icons.emergency_recording,
                  color: Colors.green,
                  size: 20,
                ),
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
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isLessonActive ? 'End Lesson' : 'Start Lesson',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
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
                  fontSize: 16,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.picture_as_pdf,
                      color: kAccentRed,
                      size: 20,
                    ),
                    tooltip: 'Download PDF',
                    onPressed: () => _downloadAttendancePdf(context, targetId),
                  ),
                  TextButton.icon(
                    onPressed: () => _showAttendanceLogs(context, targetId),
                    icon: const Icon(
                      Icons.history,
                      size: 18,
                      color: kAccentRed,
                    ),
                    label: const Text(
                      'View All',
                      style: TextStyle(color: kAccentRed),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: _attendanceLimitStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Text(
                  'No classes recorded yet.',
                  style: TextStyle(
                    color: textColor.withOpacity(0.5),
                    fontSize: 13,
                  ),
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
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                timeRange,
                                style: TextStyle(
                                  color: textColor.withOpacity(0.6),
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                data['instructorName'] ?? 'Unknown',
                                style: TextStyle(
                                  color: textColor.withOpacity(0.6),
                                  fontSize: 11,
                                ),
                              ),
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
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              data['distance'] ?? '0 KM',
                              style: TextStyle(
                                color: textColor.withOpacity(0.6),
                                fontSize: 11,
                              ),
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

  // ── Attendance PDF ──────────────────────────────────────────────────────────

  Future<void> _downloadAttendancePdf(
    BuildContext context,
    String targetId,
  ) async {
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
          logoBytes = await ImageCacheService().fetchAndCache(
            companyData['companyLogo'],
          );
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
      }
      return;
    }

    if (pdfBytes != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfPreviewScreen(pdfBytes: pdfBytes!),
        ),
      );
    }
  }

  // ── Attendance logs bottom sheet ────────────────────────────────────────────

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
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
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
                        fontSize: 18,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _downloadAttendancePdf(context, targetId);
                    },
                    icon: const Icon(
                      Icons.picture_as_pdf,
                      color: kAccentRed,
                      size: 18,
                    ),
                    label: const Text(
                      'Export PDF',
                      style: TextStyle(
                        color: kAccentRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _attendanceHistoryStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const ShimmerLoadingList();
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.history_edu_outlined,
                            size: 48,
                            color: textColor.withOpacity(0.2),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No attendance history found.',
                            style: TextStyle(color: textColor.withOpacity(0.5)),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
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
                                      fontSize: 18,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('MMM').format(date),
                                    style: TextStyle(
                                      color: textColor.withOpacity(0.5),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat(
                                      'EEEE, dd MMM yyyy',
                                    ).format(date),
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '⏱ $timeRange',
                                    style: TextStyle(
                                      color: textColor.withOpacity(0.6),
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '👤 ${data['instructorName'] ?? 'Unknown'}',
                                    style: TextStyle(
                                      color: textColor.withOpacity(0.6),
                                      fontSize: 12,
                                    ),
                                  ),
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
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'DONE',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
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

  // ── Toggle lesson ───────────────────────────────────────────────────────────

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
        final snapshot = await collection.doc(studentId).get();
        final data = snapshot.data();
        final startTime = (data?['lessonStartTime'] as Timestamp?)?.toDate();
        final now = DateTime.now();

        String durationStr = 'N/A';
        if (startTime != null) {
          final diff = now.difference(startTime);
          final hours = diff.inHours;
          final minutes = diff.inMinutes.remainder(60);
          durationStr = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
        }

        double lessonDistanceMeters = 0.0;

        try {
          final lessonPathDoc = await FirebaseFirestore.instance
              .collection('lesson_paths')
              .doc(studentId)
              .get();
          if (lessonPathDoc.exists) {
            final pathData = lessonPathDoc.data();
            final finalDistanceKm =
                (pathData?['finalDistanceKm'] as num?)?.toDouble() ?? 0.0;
            if (finalDistanceKm > 0)
              lessonDistanceMeters = finalDistanceKm * 1000;
          }
        } catch (e) {
          print('Error reading lesson_paths: $e');
        }

        if (lessonDistanceMeters <= 0) {
          try {
            final trackingRepo = Get.find<TrackingRepository>();
            lessonDistanceMeters = await trackingRepo.getDriverLessonDistance(
              user.uid,
            );
          } catch (e) {
            print('Error getting distance from RTDB: $e');
          }
        }

        if (lessonDistanceMeters <= 0) {
          final savedKm =
              (data?['lessonDistanceKm'] as num?)?.toDouble() ?? 0.0;
          lessonDistanceMeters = savedKm * 1000;
        }

        if (lessonDistanceMeters <= 0) {
          try {
            final ts = Get.find<LocationTrackingService>();
            lessonDistanceMeters = ts.lessonDistance;
          } catch (_) {}
        }

        lessonDistanceMeters = lessonDistanceMeters.clamp(0.0, double.infinity);
        final distanceKm = (lessonDistanceMeters / 1000).toStringAsFixed(2);

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

  Future<void> _generateSelectedReceipts() async {
    if (_selectedTransactionIds.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final targetId = _workspaceController.targetId;
    final studentId = studentDetails['studentId'].toString();
    final List<Map<String, dynamic>> allTransactions = [];

    final paymentsQuery = await FirebaseFirestore.instance
        .collection('users')
        .doc(targetId)
        .collection('students')
        .doc(studentId)
        .collection('payments')
        .where(FieldPath.documentId, whereIn: _selectedTransactionIds)
        .get();
    allTransactions.addAll(paymentsQuery.docs.map((d) => d.data()));

    final feesQuery = await FirebaseFirestore.instance
        .collection('users')
        .doc(targetId)
        .collection('students')
        .doc(studentId)
        .collection('extra_fees')
        .where(FieldPath.documentId, whereIn: _selectedTransactionIds)
        .get();

    allTransactions.addAll(
      feesQuery.docs.map((d) {
        final data = d.data();
        return {
          'amount': data['amount'],
          'description': data['description'] ?? 'Additional Fee',
          'mode': data['paymentMode'] ?? 'Cash',
          'date': data['paymentDate'] ?? data['date'],
          'note': data['paymentNote'] ?? data['note'],
        };
      }),
    );

    if (allTransactions.isEmpty) return;

    allTransactions.sort((a, b) {
      final dateA =
          a['date'] is DateTime ? a['date'] : (a['date'] as Timestamp).toDate();
      final dateB =
          b['date'] is DateTime ? b['date'] : (b['date'] as Timestamp).toDate();
      return dateB.compareTo(dateA);
    });

    _generateReceipts(allTransactions);
  }

  Future<void> _generateReceipts(
    List<Map<String, dynamic>> transactions,
  ) async {
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
          logoBytes = await ImageCacheService().fetchAndCache(
            companyData['companyLogo'],
          );
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 48,
                  horizontal: 30,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Share PDF',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 18.0,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text('Include Payment Overview'),
                      value: includePayment,
                      onChanged: (bool? value) {
                        setState(() => includePayment = value ?? false);
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
          },
        );
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
          studentImageBytes = await ImageCacheService().fetchAndCache(
            studentDetails['image'],
          );
        }

        Uint8List? logoBytes;
        if (companyData['hasCompanyProfile'] == true &&
            companyData['companyLogo'] != null &&
            companyData['companyLogo'].toString().isNotEmpty) {
          logoBytes = await ImageCacheService().fetchAndCache(
            companyData['companyLogo'],
          );
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
      return;
    }

    if (pdfBytes != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfPreviewScreen(pdfBytes: pdfBytes!),
        ),
      );
    }
  }

  // ── Show PDF preview with WhatsApp FAB ─────────────────────────────────────

  void _showPdfPreview(BuildContext context, Uint8List pdfBytes) {
    final phone = studentDetails['mobileNumber'] ?? '';
    final studentName = studentDetails['fullName'] ?? 'Student';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfPreviewScreen(
          pdfBytes: pdfBytes,
          studentName: studentDetails['fullName'],
          studentPhone: studentDetails['mobileNumber'],
          fileName: 'receipt_${studentDetails['fullName']}.pdf',
        ),
      ),
    );
  }
  // ── Send PDF directly to student's WhatsApp using jid ──────────────────────

  Future<void> sendReceiptWhatsApp({
    required String phone,
    required String studentName,
    required Uint8List pdfBytes,
  }) async {
    try {
      // 1️⃣ Save PDF to temp directory
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/receipt_$studentName.pdf');
      await file.writeAsBytes(pdfBytes);

      // 2️⃣ Clean phone number
      String cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleaned.startsWith('0')) cleaned = cleaned.substring(1);

      // ⚠️ Change country code if needed
      final internationalNumber = '91$cleaned';

      // 3️⃣ Prefilled message
      final message = 'Hello $studentName, here is your fee receipt.';

      // 4️⃣ Android Intent to open WhatsApp with PDF and message
      final whatsappUrl = Uri.parse(
          'whatsapp://send?phone=$internationalNumber&text=${Uri.encodeComponent(message)}');

      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);

        // Wait a short moment before opening attachment to ensure chat is loaded
        await Future.delayed(const Duration(milliseconds: 500));

        // Open PDF file using default share intent
        await launchUrl(
          Uri.file(file.path),
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw 'WhatsApp is not installed.';
      }
    } catch (e) {
      print('Error sharing to WhatsApp: $e');
    }
  }

  // ── Tappable mobile row ─────────────────────────────────────────────────────

  Widget _buildMobileRow(
    String phone,
    Color textColor,
    Color subTextColor,
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: GestureDetector(
        onTap: () => _showContactOptions(context, phone),
        child: RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'Inter',
              color: textColor,
            ),
            children: [
              TextSpan(
                text: 'Mobile: ',
                style: TextStyle(color: subTextColor),
              ),
              TextSpan(
                text: phone,
                style: const TextStyle(
                  color: kAccentRed,
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Call / WhatsApp bottom sheet ────────────────────────────────────────────

  void _showContactOptions(BuildContext context, String phone) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              phone,
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black54,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              tileColor: Colors.green.withOpacity(0.08),
              leading: const Icon(Icons.phone_rounded, color: Colors.green),
              title: Text(
                'Call',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                final uri = Uri(scheme: 'tel', path: phone);
                if (await canLaunchUrl(uri)) launchUrl(uri);
              },
            ),
            const SizedBox(height: 10),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              tileColor: const Color(0xFF25D366).withOpacity(0.08),
              leading: const Icon(Icons.chat_rounded, color: Color(0xFF25D366)),
              title: Text(
                'WhatsApp',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                final cleaned =
                    phone.startsWith('0') ? phone.substring(1) : phone;
                final uri = Uri.parse('https://wa.me/91$cleaned');
                if (await canLaunchUrl(uri)) {
                  launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
          ],
        ),
      ),
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
    String label,
    String value,
    Color textColor,
    Color subTextColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 13, fontFamily: 'Inter', color: textColor),
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(color: subTextColor),
            ),
            TextSpan(
              text: value,
              style: TextStyle(color: textColor),
            ),
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
      studentDetails['pin'],
    ].where((e) => e != null && e.isNotEmpty).join(', ');
  }
}

// ── Attendance badge ──────────────────────────────────────────────────────────

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
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
