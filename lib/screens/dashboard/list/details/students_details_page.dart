import 'dart:io';
import 'dart:typed_data';
import 'package:drivemate/widgets/persistent_cached_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/services.dart';
import 'package:drivemate/constants/colors.dart';
import 'package:drivemate/screens/widget/custom_back_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:drivemate/screens/authentication/widgets/my_button.dart';
import 'package:drivemate/screens/dashboard/form/edit_forms/edit_student_details_form.dart';
import 'package:drivemate/screens/dashboard/list/widgets/shimmer_loading_list.dart';
import 'package:drivemate/screens/dashboard/list/details/pdf_preview_screen.dart';
import 'package:drivemate/service/attendance_pdf_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:drivemate/services/pdf_service.dart';
import 'package:drivemate/services/image_cache_service.dart';
import 'package:drivemate/screens/profile/action_button.dart';
import 'package:drivemate/utils/loading_utils.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:drivemate/screens/widget/utils.dart';
import 'package:get/get.dart';
import 'package:drivemate/controller/workspace_controller.dart';
import 'package:drivemate/utils/payment_utils.dart';
import 'package:iconly/iconly.dart';
import 'package:drivemate/utils/test_utils.dart';
import 'package:drivemate/utils/image_utils.dart';
import 'package:drivemate/utils/date_utils.dart';
import 'package:drivemate/widgets/additional_info_sheet.dart';
import 'package:drivemate/services/additional_info_service.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:drivemate/features/tracking/services/background_service.dart';
import 'package:drivemate/features/tracking/data/repositories/tracking_repository.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:drivemate/features/tracking/services/location_tracking_service.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:drivemate/widgets/soft_delete_button.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:drivemate/services/storage_service.dart';
import 'package:drivemate/screens/dashboard/list/details/attendance_details_page.dart';
import 'package:drivemate/screens/dashboard/list/details/document_preview_screen.dart';
import 'package:drivemate/screens/dashboard/list/widgets/details_tabs_bar.dart';
import 'package:drivemate/screens/profile/dialog_box.dart';
import 'package:drivemate/services/soft_delete_service.dart';

class StudentDetailsPage extends StatefulWidget {
  final Map<String, dynamic> studentDetails;
  final bool isStudentView; // true when viewed by student themselves

  const StudentDetailsPage({
    required this.studentDetails,
    this.isStudentView = false,
    super.key,
  });

  @override
  State<StudentDetailsPage> createState() => _StudentDetailsPageState();
}

class _StudentDetailsPageState extends State<StudentDetailsPage> {
  static const Color kAccentRed = Color.fromRGBO(241, 135, 71, 1);
  late Map<String, dynamic> studentDetails;
  final List<String> _selectedTransactionIds = [];
  final WorkspaceController _workspaceController =
      Get.find<WorkspaceController>();
  List<Map<String, dynamic>> _cachedPayments = [];
  int _activeTab = 0;
  String get _docId =>
      studentDetails['id']?.toString() ??
      studentDetails['studentId']?.toString() ??
      '';
  late Stream<DocumentSnapshot> _mainStream;
  late Stream<QuerySnapshot> _paymentsStream;
  late Stream<QuerySnapshot> _attendanceHistoryStream;
  late Stream<QuerySnapshot> _extraFeesStream;
  late Stream<QuerySnapshot> _documentsStream;
  late Stream<QuerySnapshot> _notesStream;
  String _collectionName = 'students';

  @override
  void initState() {
    super.initState();
    studentDetails = Map.from(widget.studentDetails);
    _initStreams();
  }

  Future<void> _initStreams() async {
    final targetId = _workspaceController.currentSchoolId.value.isNotEmpty
        ? _workspaceController.currentSchoolId.value
        : (FirebaseAuth.instance.currentUser?.uid ?? '');

    final base = FirebaseFirestore.instance.collection('users').doc(targetId);
    String docIdForStreams = _docId;
    String collectionForStreams = 'students';

    // Initialize with empty streams immediately to avoid LateInitializationError
    _mainStream = Stream<DocumentSnapshot>.empty();
    _paymentsStream = Stream<QuerySnapshot>.empty();
    _attendanceHistoryStream = Stream<QuerySnapshot>.empty();
    _extraFeesStream = Stream<QuerySnapshot>.empty();
    _documentsStream = Stream<QuerySnapshot>.empty();
    _notesStream = Stream<QuerySnapshot>.empty();

    if (docIdForStreams.isEmpty) {
      debugPrint('StudentDetailsPage: _docId is empty');
      return;
    }

    // Initialize with default 'students' collection streams immediately
    // so they start loading while we check for deactivation/alternative IDs
    _mainStream =
        base.collection(collectionForStreams).doc(docIdForStreams).snapshots();
    _paymentsStream = base
        .collection(collectionForStreams)
        .doc(docIdForStreams)
        .collection('payments')
        .orderBy('date', descending: true)
        .snapshots();
    _attendanceHistoryStream = base
        .collection(collectionForStreams)
        .doc(docIdForStreams)
        .collection('attendance')
        .orderBy('date', descending: true)
        .snapshots();
    _extraFeesStream = base
        .collection(collectionForStreams)
        .doc(docIdForStreams)
        .collection('extra_fees')
        .orderBy('date', descending: true)
        .snapshots();
    _documentsStream = base
        .collection(collectionForStreams)
        .doc(docIdForStreams)
        .collection('documents')
        .orderBy('timestamp', descending: true)
        .snapshots();
    _notesStream = base
        .collection(collectionForStreams)
        .doc(docIdForStreams)
        .collection('notes')
        .orderBy('timestamp', descending: true)
        .snapshots();

    try {
      // Try exact doc in students to confirm collection
      var snap = await base.collection('students').doc(docIdForStreams).get();
      bool collectionChanged = false;

      if (!snap.exists) {
        // Try lookup by studentId field in students
        final sid = studentDetails['studentId']?.toString();
        if (sid != null && sid.isNotEmpty) {
          final q = await base
              .collection('students')
              .where('studentId', isEqualTo: sid)
              .limit(1)
              .get();
          if (q.docs.isNotEmpty) {
            docIdForStreams = q.docs.first.id;
            collectionForStreams = 'students';
            collectionChanged = true;
          } else {
            // Try deactivated collections
            var deact = await base
                .collection('deactivated_students')
                .doc(docIdForStreams)
                .get();
            if (!deact.exists) {
              final dq = await base
                  .collection('deactivated_students')
                  .where('studentId', isEqualTo: sid)
                  .limit(1)
                  .get();
              if (dq.docs.isNotEmpty) {
                docIdForStreams = dq.docs.first.id;
                collectionForStreams = 'deactivated_students';
                collectionChanged = true;
              }
            } else {
              collectionForStreams = 'deactivated_students';
              collectionChanged = true;
            }
          }
        } else {
          // Fallback: check deactivated by doc id
          var deact = await base
              .collection('deactivated_students')
              .doc(docIdForStreams)
              .get();
          if (deact.exists) {
            collectionForStreams = 'deactivated_students';
            collectionChanged = true;
          }
        }
      }

      if (collectionChanged) {
        // Update streams if we found the document in a different collection or with different ID
        _collectionName = collectionForStreams;
        studentDetails['id'] = docIdForStreams;

        // Check if subcollections were moved or still in original collection
        String subCollectionPath = collectionForStreams;
        if (collectionForStreams == 'deactivated_students') {
          // Check if payments exist in deactivated collection
          final paymentSnap = await base
              .collection('deactivated_students')
              .doc(docIdForStreams)
              .collection('payments')
              .limit(1)
              .get();
          if (paymentSnap.docs.isEmpty) {
            // If no payments in deactivated, check if they are still in students
            final originalPaymentSnap = await base
                .collection('students')
                .doc(docIdForStreams)
                .collection('payments')
                .limit(1)
                .get();
            if (originalPaymentSnap.docs.isNotEmpty) {
              subCollectionPath = 'students';
            }
          }
        }

        _mainStream = base
            .collection(collectionForStreams)
            .doc(docIdForStreams)
            .snapshots();
        _paymentsStream = base
            .collection(subCollectionPath)
            .doc(docIdForStreams)
            .collection('payments')
            .orderBy('date', descending: true)
            .snapshots();
        _attendanceHistoryStream = base
            .collection(subCollectionPath)
            .doc(docIdForStreams)
            .collection('attendance')
            .orderBy('date', descending: true)
            .snapshots();
        _extraFeesStream = base
            .collection(subCollectionPath)
            .doc(docIdForStreams)
            .collection('extra_fees')
            .orderBy('date', descending: true)
            .snapshots();
        _documentsStream = base
            .collection(subCollectionPath)
            .doc(docIdForStreams)
            .collection('documents')
            .orderBy('timestamp', descending: true)
            .snapshots();
        _notesStream = base
            .collection(subCollectionPath)
            .doc(docIdForStreams)
            .collection('notes')
            .orderBy('timestamp', descending: true)
            .snapshots();
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error initializing StudentDetailsPage streams: $e');
    }
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
        elevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        leadingWidth: widget.isStudentView ? 0 : null,
        leading: widget.isStudentView
            ? const SizedBox.shrink()
            : const CustomBackButton(),
        title: Text(
          widget.isStudentView ? 'My Dashboard' : 'Student Details',
          style: TextStyle(color: textColor),
        ),
        actions: [
          if (!widget.isStudentView) _buildLessonControlButton(targetId),
          if (!widget.isStudentView)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: subTextColor),
              onSelected: (value) {
                if (value == 'pdf') {
                  _shareStudentDetails(context);
                } else if (value == 'edit') {
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
                } else if (value == 'delete') {
                  _confirmSoftDelete(context, targetId);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit_outlined, size: 20),
                    title: Text('Edit Details'),
                    dense: true,
                  ),
                ),
                const PopupMenuItem(
                  value: 'pdf',
                  child: ListTile(
                    leading: Icon(Icons.picture_as_pdf_outlined, size: 20),
                    title: Text('Generate PDF'),
                    dense: true,
                  ),
                ),
                if (_collectionName == 'students')
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline,
                          color: Colors.red, size: 20),
                      title:
                          Text('Delete', style: TextStyle(color: Colors.red)),
                      dense: true,
                    ),
                  ),
              ],
            ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _mainStream,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.exists) {
            studentDetails = Map<String, dynamic>.from(
                snapshot.data!.data() as Map<String, dynamic>);
          }

          final bottomInset = MediaQuery.of(context).padding.bottom;
          return SafeArea(
            bottom: true,
            child: SingleChildScrollView(
              padding:
                  EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0 + bottomInset),
              child: Column(
                children: [
                  _buildProfileHeader(context, targetId),
                  const SizedBox(height: 16),
                  _buildInfoGrid(context),
                  const SizedBox(height: 16),
                  _buildCustomTabBar(context),
                  const SizedBox(height: 16),
                  _buildTabContent(context, targetId),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, String targetId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark ? Colors.grey : Colors.grey[700]!;
    final cardColor = Theme.of(context).cardColor;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kAccentRed.withOpacity(0.5)),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
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
            child: InkWell(
              onTap: () {
                final imageUrl = studentDetails['image']?.toString() ?? '';
                if (imageUrl.isEmpty) return;
                ImageUtils.showImagePopup(
                  context,
                  imageUrl,
                  studentDetails['fullName']?.toString() ?? 'Profile Photo',
                );
              },
              child: ClipOval(
                child: (studentDetails['image'] != null &&
                        studentDetails['image'].toString().isNotEmpty)
                    ? PersistentCachedImage(
                        imageUrl: studentDetails['image'],
                        fit: BoxFit.cover,
                        memCacheWidth: 300,
                        memCacheHeight: 300,
                        placeholder: Shimmer.fromColors(
                          baseColor:
                              isDark ? Colors.grey[800]! : Colors.grey[300]!,
                          highlightColor:
                              isDark ? Colors.grey[700]! : Colors.grey[100]!,
                          child: Container(color: Colors.white),
                        ),
                        errorWidget: _buildInitialsPlaceholder(),
                      )
                    : _buildInitialsPlaceholder(),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  studentDetails['fullName'] ?? 'N/A',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  softWrap: true,
                  maxLines: 3,
                  overflow: TextOverflow.visible,
                ),
                const SizedBox(height: 4),
                Text(
                  'Student ID: ${studentDetails['studentId'] ?? 'N/A'}',
                  style: TextStyle(color: subTextColor, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: kAccentRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kAccentRed.withOpacity(0.3)),
                  ),
                  child: Text(
                    'COV: ${studentDetails['cov'] ?? 'N/A'}',
                    style: const TextStyle(
                      color: kAccentRed,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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

  Widget _buildInitialsPlaceholder() {
    return Center(
      child: Text(
        _initials,
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildInfoGrid(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildInfoCard(context, 'Personal Information', [
            {
              'label': 'Guardian',
              'value': studentDetails['guardianName'] ?? 'N/A'
            },
            {
              'label': 'Date of Birth',
              'value': formatDisplayDate(studentDetails['dob'])
            },
            {
              'label': 'Blood Group',
              'value': studentDetails['bloodGroup'] ?? 'N/A'
            },
            {
              'label': 'Mobile',
              'value': studentDetails['mobileNumber'] ?? 'N/A'
            },
            {
              'label': 'Emergency',
              'value': studentDetails['emergencyNumber'] ?? 'N/A'
            },
          ]),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildInfoCard(context, 'Address Details', [
            {'label': 'House', 'value': studentDetails['house'] ?? ''},
            {'label': 'Place', 'value': studentDetails['place'] ?? ''},
            {'label': 'Post', 'value': studentDetails['post'] ?? ''},
            {'label': 'District', 'value': studentDetails['district'] ?? ''},
            {'label': 'PIN', 'value': studentDetails['pin'] ?? ''},
          ]),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
      BuildContext context, String title, List<Map<String, String>> data,
      {Widget? extraContent}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey : Colors.grey[700]!;
    final cardColor = Theme.of(context).cardColor;

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kAccentRed.withOpacity(0.5)),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: kAccentRed,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...data
                .where((d) => d['value']!.toString().isNotEmpty)
                .map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['label']!,
                            style: TextStyle(color: subTextColor, fontSize: 11),
                          ),
                          const SizedBox(height: 2),
                          item['label'] == 'Mobile'
                              ? _buildMobileRow(item['value']!, textColor,
                                  subTextColor, context)
                              : Text(
                                  item['value']!,
                                  style: TextStyle(
                                      color: textColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ],
                      ),
                    )),
            if (extraContent != null) extraContent,
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTabBar(BuildContext context) {
    // Build tabs dynamically - Additional tab always visible but view-only for students
    final tabs = <DetailsTabItem>[
      const DetailsTabItem(
          label: 'Payment', icon: Icons.account_balance_wallet),
      const DetailsTabItem(label: 'Attendance', icon: Icons.calendar_today),
      const DetailsTabItem(label: 'Tests', icon: Icons.assignment),
      const DetailsTabItem(label: 'Documents', icon: Icons.description),
      // Additional tab is always visible (but view-only for students)
      const DetailsTabItem(label: 'Additional', icon: Icons.info_outline),
    ];

    // Only show Notes tab for non-student views (staff/owner)
    if (!widget.isStudentView) {
      tabs.add(const DetailsTabItem(label: 'Notes', icon: Icons.note));
    }

    return DetailsTabsBar(
      tabs: tabs,
      activeIndex: _activeTab,
      onChanged: (i) => setState(() => _activeTab = i),
    );
  }

  Widget _buildTabContent(BuildContext context, String targetId) {
    final cardColor = Theme.of(context).cardColor;
    return Container(
      constraints: const BoxConstraints(minHeight: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kAccentRed.withOpacity(0.5)),
      ),
      child: _getTabWidget(context, targetId),
    );
  }

  Widget _getTabWidget(BuildContext context, String targetId) {
    // Build tabs list to get correct index mapping - Additional tab always at index 4
    final tabs = <int, Widget>{
      0: _buildPaymentTab(context, targetId),
      1: _buildAttendanceTab(context, targetId),
      2: _buildTestsTab(context),
      3: _buildDocumentsTab(context, targetId),
      4: _buildAdditionalTab(
          context), // Always available (view-only for students)
    };

    // Only add Notes tab for non-student views (staff/owner)
    if (!widget.isStudentView) {
      tabs[5] = _buildNotesTab(context);
    }

    // Ensure active tab is within bounds using local variable
    final maxTab = widget.isStudentView ? 4 : 5;
    final effectiveTab = _activeTab > maxTab ? maxTab : _activeTab;

    return tabs[effectiveTab] ?? const SizedBox();
  }

  Widget _buildPaymentTab(BuildContext context, String targetId) {
    double total =
        double.tryParse(studentDetails['totalAmount']?.toString() ?? '0') ?? 0;
    double balance =
        double.tryParse(studentDetails['balanceAmount']?.toString() ?? '0') ??
            0;
    double paidAmount = total - balance;
    double progressValue = total > 0 ? paidAmount / total : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Payment Summary',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            // Show receipt button for all roles (including students)
            // Staff and Owner can add payments/fees, Students can only generate receipts
            if (_selectedTransactionIds.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.receipt_long, color: kAccentRed),
                onPressed: _generateSelectedReceipts,
              ),
            // Only Staff and Owner can add payments/fees
            if (!widget.isStudentView)
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.post_add, color: Colors.blue),
                    onPressed: () => _showAddExtraFeeDialog(context, targetId),
                  ),
                  IconButton(
                    icon: const Icon(Icons.account_balance_wallet,
                        color: Colors.green),
                    onPressed: () => _showReceiveMoneyDialog(context, targetId),
                    tooltip: 'Receive Money',
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child: _buildSummaryTile(
                    context, 'Total Fee', '₹${total.toInt()}', Colors.grey)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildSummaryTile(
                    context, 'Paid', '₹${paidAmount.toInt()}', Colors.green)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildSummaryTile(
                    context, 'Balance', '₹${balance.toInt()}', kAccentRed)),
          ],
        ),
        const SizedBox(height: 24),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progressValue.clamp(0.0, 1.0),
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(kAccentRed),
            minHeight: 10,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            '${(progressValue * 100).round()}% Completed',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Transaction History',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 12),
        _buildTransactionHistory(context, targetId),
        const SizedBox(height: 24),
        const Text(
          'Additional Fees',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 12),
        _buildExtraFeesList(context, targetId),
      ],
    );
  }

  Widget _buildSummaryTile(
      BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildAttendanceTab(BuildContext context, String targetId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _attendanceHistoryStream,
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        double totalKm = 0;
        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final distStr = data['distance']?.toString() ?? '0';
          totalKm += double.tryParse(distStr.split(' ')[0]) ?? 0;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                    child: _buildAttendanceSummaryCard(context, 'Sessions',
                        docs.length.toString(), Icons.event)),
                const SizedBox(width: 16),
                Expanded(
                    child: _buildAttendanceSummaryCard(context, 'Total KM',
                        totalKm.toStringAsFixed(1), Icons.speed)),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Sessions',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf, color: kAccentRed),
                  onPressed: () => _downloadAttendancePdf(context, targetId),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (docs.isEmpty)
              const Center(
                  child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No attendance records found.')))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                itemBuilder: (context, index) => _buildAttendanceItem(
                    context, docs[index].data() as Map<String, dynamic>),
              ),
          ],
        );
      },
    );
  }

  Widget _buildAttendanceSummaryCard(
      BuildContext context, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kAccentRed.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kAccentRed.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: kAccentRed),
          const SizedBox(height: 8),
          Text(value,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildAttendanceItem(BuildContext context, Map<String, dynamic> data) {
    final date = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
    final startTime = (data['startTime'] as Timestamp?)?.toDate();
    final endTime = (data['endTime'] as Timestamp?)?.toDate();
    String timeRange = 'N/A';
    if (startTime != null && endTime != null) {
      timeRange =
          '${DateFormat('hh:mm a').format(startTime)} - ${DateFormat('hh:mm a').format(endTime)}';
    }

    final targetId = _workspaceController.currentSchoolId.value.isNotEmpty
        ? _workspaceController.currentSchoolId.value
        : (FirebaseAuth.instance.currentUser?.uid ?? '');

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[200]!)),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AttendanceDetailsPage(
                attendanceData: data,
                studentId: _docId,
                targetId: targetId,
              ),
            ),
          );
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(DateFormat('dd MMM yyyy').format(date),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(timeRange),
            Text('Instructor: ${data['instructorName'] ?? 'Unknown'}',
                style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(data['duration'] ?? 'N/A',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: kAccentRed)),
            Text(data['distance'] ?? '0 KM',
                style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildTestsTab(BuildContext context) {
    final llDate = AppDateUtils.formatDateForDisplay(
        studentDetails['learnersTestDate']?.toString());
    final dlDate = AppDateUtils.formatDateForDisplay(
        studentDetails['drivingTestDate']?.toString());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Test Schedule',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            // Hide edit button for students - view only
            if (!widget.isStudentView)
              IconButton(
                icon: const Icon(Icons.edit_calendar, color: kAccentRed),
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
        const SizedBox(height: 16),
        _buildTestCard(context, 'Learners Test (LL)', llDate, Icons.assignment),
        const SizedBox(height: 12),
        _buildTestCard(
            context, 'Driving Test (DL)', dlDate, Icons.directions_car),
      ],
    );
  }

  Widget _buildTestCard(
      BuildContext context, String type, String date, IconData icon) {
    final hasDate = date.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50]!,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: hasDate ? Colors.green : kAccentRed),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(hasDate ? date : 'Not Scheduled',
                    style: TextStyle(
                        color: hasDate ? Colors.black87 : Colors.grey)),
              ],
            ),
          ),
          StatusBadge(
              text: hasDate ? 'Scheduled' : 'Pending',
              color: hasDate ? Colors.green : kAccentRed),
        ],
      ),
    );
  }

  Widget _buildDocumentsTab(BuildContext context, String targetId) {
    // Hide documents tab content for students - show view only message
    if (widget.isStudentView) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Documents can only be managed by staff.',
            style: TextStyle(color: Colors.grey, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Documents',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            IconButton(
              icon: const Icon(Icons.add_photo_alternate_outlined,
                  color: kAccentRed),
              tooltip: 'Upload Document',
              onPressed: () => _uploadDocument(context, targetId),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: _documentsStream,
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return Column(
                children: [
                  _buildDocListItem('Aadhaar Card', 'Pending', kAccentRed),
                  _buildDocListItem(
                      'Passport Size Photo', 'Pending', kAccentRed),
                  _buildDocListItem('Application Form', 'Pending', kAccentRed),
                ],
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final name = data['name'] ?? 'Document';
                final status = data['status'] ?? 'Uploaded';
                final statusColor =
                    (status == 'Uploaded') ? Colors.green : kAccentRed;
                final timestamp = data['timestamp'] as Timestamp?;
                final subtitle = timestamp != null
                    ? DateFormat('dd MMM yyyy').format(timestamp.toDate())
                    : null;

                return ListTile(
                  leading: const Icon(Icons.file_present, color: kAccentRed),
                  title: Text(name),
                  subtitle: subtitle != null ? Text(subtitle) : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StatusBadge(text: status, color: statusColor),
                      IconButton(
                        icon:
                            const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () =>
                            _deleteDocument(docs[index].id, targetId),
                      ),
                    ],
                  ),
                  onTap: () {
                    final url = data['url']?.toString() ?? '';
                    if (url.isEmpty) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DocumentPreviewScreen(
                          docName: name,
                          docUrl: url,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildDocListItem(String name, String status, Color color) {
    return ListTile(
      leading: const Icon(Icons.file_present),
      title: Text(name),
      trailing: StatusBadge(text: status, color: color),
    );
  }

  Widget _buildNotesTab(BuildContext context) {
    // Hide notes tab for students - not needed for them
    if (widget.isStudentView) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Notes are only visible to staff.',
            style: TextStyle(color: Colors.grey, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final targetId = _workspaceController.currentSchoolId.value.isNotEmpty
        ? _workspaceController.currentSchoolId.value
        : (FirebaseAuth.instance.currentUser?.uid ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Notes & Remarks',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            IconButton(
              icon: const Icon(Icons.add_comment_outlined, color: kAccentRed),
              tooltip: 'Add Note',
              onPressed: () => _addNote(context, targetId),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: _notesStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data?.docs ?? [];

            // If subcollection is empty, check if there's a legacy remark
            final legacyRemark =
                (studentDetails['remarks'] ?? '').toString().trim();

            if (docs.isEmpty && legacyRemark.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'No notes added yet.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length + (legacyRemark.isNotEmpty ? 1 : 0),
              itemBuilder: (context, index) {
                // Show legacy remark first if it exists
                if (legacyRemark.isNotEmpty && index == 0) {
                  return _buildNoteItem(
                    context,
                    id: 'legacy',
                    content: legacyRemark,
                    timestamp: null,
                    isDark: isDark,
                    targetId: targetId,
                    isLegacy: true,
                  );
                }

                final noteDoc =
                    docs[legacyRemark.isNotEmpty ? index - 1 : index];
                final data = noteDoc.data() as Map<String, dynamic>;
                final content = data['content'] ?? '';
                final timestamp = data['timestamp'] as Timestamp?;

                return _buildNoteItem(
                  context,
                  id: noteDoc.id,
                  content: content,
                  timestamp: timestamp,
                  isDark: isDark,
                  targetId: targetId,
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildNoteItem(
    BuildContext context, {
    required String id,
    required String content,
    required Timestamp? timestamp,
    required bool isDark,
    required String targetId,
    bool isLegacy = false,
  }) {
    final dateStr = timestamp != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(timestamp.toDate())
        : 'Legacy Note';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.yellow[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.yellow[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateStr,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        size: 18, color: Colors.blue),
                    onPressed: () => _editNoteDialog(
                      context,
                      targetId,
                      id: id,
                      existingContent: content,
                      isLegacy: isLegacy,
                    ),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 18, color: Colors.red),
                    onPressed: () => _deleteNoteDialog(
                      context,
                      targetId,
                      id: id,
                      isLegacy: isLegacy,
                    ),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addNote(BuildContext context, String targetId) async {
    final controller = TextEditingController();

    final bool? shouldSave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Note'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Enter notes or remarks',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (shouldSave != true || controller.text.trim().isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetId)
          .collection(_collectionName)
          .doc(_docId)
          .collection('notes')
          .add({
        'content': controller.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      Get.snackbar('Success', 'Note added.',
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Failed to add note: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> _editNoteDialog(
    BuildContext context,
    String targetId, {
    required String id,
    required String existingContent,
    bool isLegacy = false,
  }) async {
    final controller = TextEditingController(text: existingContent);

    final bool? shouldSave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Note'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Enter notes or remarks',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (shouldSave != true) return;

    try {
      final base = FirebaseFirestore.instance
          .collection('users')
          .doc(targetId)
          .collection(_collectionName)
          .doc(_docId);

      if (isLegacy) {
        await base.update({'remarks': controller.text.trim()});
      } else {
        await base.collection('notes').doc(id).update({
          'content': controller.text.trim(),
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      Get.snackbar('Success', 'Note updated.',
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Failed to update note: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> _deleteNoteDialog(
    BuildContext context,
    String targetId, {
    required String id,
    bool isLegacy = false,
  }) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      final base = FirebaseFirestore.instance
          .collection('users')
          .doc(targetId)
          .collection(_collectionName)
          .doc(_docId);

      if (isLegacy) {
        await base.update({'remarks': FieldValue.delete()});
      } else {
        await base.collection('notes').doc(id).delete();
      }

      Get.snackbar('Success', 'Note deleted.',
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete note: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Widget _buildTransactionHistory(BuildContext context, String targetId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _paymentsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red, fontSize: 12)));
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            _cachedPayments.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData) {
          final docs = snapshot.data?.docs ?? [];
          final transactions = docs.map((d) {
            final map = d.data() as Map<String, dynamic>;
            map['id'] = d.id;
            map['docRef'] = d;
            return map;
          }).toList();

          // Add legacy payments if no payments exist in subcollection
          if (transactions.isEmpty) {
            // 1. Check for Advance
            final advAmt = double.tryParse(
                    studentDetails['advanceAmount']?.toString() ?? '0') ??
                0;
            if (advAmt > 0) {
              final regDate = DateTime.tryParse(
                      studentDetails['registrationDate']?.toString() ??
                          studentDetails['date']?.toString() ??
                          '') ??
                  DateTime.now();
              transactions.add({
                'id': 'legacy_adv',
                'amount': advAmt,
                'date': Timestamp.fromDate(regDate),
                'mode': studentDetails['paymentMode'] ?? 'Cash',
                'description': 'Initial Advance',
                'isLegacy': true
              });
            }

            // 2. Check for numbered installments (installment1, installment2, etc.)
            for (int i = 1; i <= 20; i++) {
              final key = 'installment$i';
              final timeKey = 'installment${i}Time';
              final instAmt =
                  double.tryParse(studentDetails[key]?.toString() ?? '0') ?? 0;
              if (instAmt > 0) {
                final instDateStr = studentDetails[timeKey]?.toString() ?? '';
                final instDate = DateTime.tryParse(instDateStr) ??
                    DateTime.now().subtract(Duration(days: i));
                transactions.add({
                  'id': 'legacy_inst$i',
                  'amount': instAmt,
                  'date': Timestamp.fromDate(instDate),
                  'mode': 'Cash',
                  'description': 'Installment $i',
                  'isLegacy': true
                });
              }
            }

            // 3. Check for second/third installments (specific fields)
            final secondAmt = double.tryParse(
                    studentDetails['secondInstallment']?.toString() ?? '0') ??
                0;
            if (secondAmt > 0 &&
                !transactions.any((t) => t['id'] == 'legacy_inst2')) {
              final secondDateStr =
                  studentDetails['secondInstallmentTime']?.toString() ?? '';
              final secondDate = DateTime.tryParse(secondDateStr) ??
                  DateTime.now().subtract(const Duration(days: 1));
              transactions.add({
                'id': 'legacy_inst2',
                'amount': secondAmt,
                'date': Timestamp.fromDate(secondDate),
                'mode': 'Cash',
                'description': 'Second Installment',
                'isLegacy': true
              });
            }

            final thirdAmt = double.tryParse(
                    studentDetails['thirdInstallment']?.toString() ?? '0') ??
                0;
            if (thirdAmt > 0 &&
                !transactions.any((t) => t['id'] == 'legacy_inst3')) {
              final thirdDateStr =
                  studentDetails['thirdInstallmentTime']?.toString() ?? '';
              final thirdDate = DateTime.tryParse(thirdDateStr) ??
                  DateTime.now().subtract(const Duration(days: 2));
              transactions.add({
                'id': 'legacy_inst3',
                'amount': thirdAmt,
                'date': Timestamp.fromDate(thirdDate),
                'mode': 'Cash',
                'description': 'Third Installment',
                'isLegacy': true
              });
            }
          }

          transactions.sort((a, b) =>
              (b['date'] as Timestamp).compareTo(a['date'] as Timestamp));
          _cachedPayments = transactions;
        }

        if (_cachedPayments.isEmpty)
          return const Center(
              child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No transactions yet.')));

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _cachedPayments.length,
          itemBuilder: (context, index) {
            final data = _cachedPayments[index];
            final date = (data['date'] as Timestamp).toDate();
            final transactionId = data['id'];
            final isSelected = _selectedTransactionIds.contains(transactionId);

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              leading: Checkbox(
                value: isSelected,
                onChanged: (val) {
                  setState(() {
                    if (val == true)
                      _selectedTransactionIds.add(transactionId);
                    else
                      _selectedTransactionIds.remove(transactionId);
                  });
                },
                activeColor: kAccentRed,
              ),
              title: Row(
                children: [
                  const Icon(Icons.payment, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Text('₹${(data['amount'] as num).toInt()}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
              subtitle: Text(
                  '${DateFormat('dd MMM yyyy, hh:mm a').format(date)} · ${data['mode']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Hide edit/delete buttons for students - they can only view and generate receipts
                  if (!widget.isStudentView) ...[
                    if (data['isLegacy'] == true)
                      IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            size: 18, color: Colors.blue),
                        onPressed: () =>
                            _handleTransactionAction('edit', data, targetId),
                      )
                    else
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 20),
                        onSelected: (value) =>
                            _handleTransactionAction(value, data, targetId),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                              value: 'edit',
                              child: ListTile(
                                  leading: Icon(Icons.edit, size: 18),
                                  title: Text('Edit'),
                                  dense: true)),
                          const PopupMenuItem(
                              value: 'delete',
                              child: ListTile(
                                  leading: Icon(Icons.delete,
                                      color: Colors.red, size: 18),
                                  title: Text('Delete',
                                      style: TextStyle(color: Colors.red)),
                                  dense: true)),
                        ],
                      ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  String get _initials {
    final name = studentDetails['fullName']?.toString() ?? '';
    if (name.isEmpty) return '??';
    final parts = name.trim().split(' ');
    if (parts.length > 1) return (parts[0][0] + parts[1][0]).toUpperCase();
    return name[0].toUpperCase();
  }

  Future<void> _shareStudentDetails(BuildContext context) async {
    bool includePayment = false;
    final bool? shouldGenerate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate PDF'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => CheckboxListTile(
            title: const Text('Include Payment Overview'),
            value: includePayment,
            onChanged: (val) =>
                setDialogState(() => includePayment = val ?? false),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Generate')),
        ],
      ),
    );

    if (shouldGenerate != true) return;

    try {
      final pdfBytes = await LoadingUtils.wrapWithLoading(context, () async {
        final workspace = Get.find<WorkspaceController>();
        final companyData = workspace.companyData;
        Uint8List? studentImageBytes;
        if (studentDetails['image'] != null &&
            studentDetails['image'].toString().isNotEmpty) {
          studentImageBytes =
              await ImageCacheService().fetchAndCache(studentDetails['image']);
        }
        Uint8List? logoBytes;
        if (companyData['hasCompanyProfile'] == true &&
            companyData['companyLogo'] != null) {
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
      _showPdfPreview(context, pdfBytes);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showPdfPreview(BuildContext context, Uint8List pdfBytes) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfPreviewScreen(
          pdfBytes: pdfBytes,
          studentName: studentDetails['fullName'],
          studentPhone: studentDetails['mobileNumber'],
          fileName: 'student_${studentDetails['fullName']}.pdf',
        ),
      ),
    );
  }

  Widget _buildMobileRow(
      String phone, Color textColor, Color subTextColor, BuildContext context) {
    return InkWell(
      onTap: () => _showContactOptions(context, phone),
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Row(
          children: [
            const Icon(Icons.phone, size: 14, color: kAccentRed),
            const SizedBox(width: 4),
            Text(phone,
                style: const TextStyle(
                    color: kAccentRed,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline)),
          ],
        ),
      ),
    );
  }

  void _showContactOptions(BuildContext context, String phone) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text(phone,
                style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontSize: 13)),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              tileColor: Colors.green.withOpacity(0.08),
              leading: const Icon(Icons.phone_rounded, color: Colors.green),
              title: Text('Call Student',
                  style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w600)),
              onTap: () async {
                Navigator.pop(context);
                final uri = Uri.parse('tel:$phone');
                if (await canLaunchUrl(uri)) launchUrl(uri);
              },
            ),
            const SizedBox(height: 10),
            ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              tileColor: const Color(0xFF25D366).withOpacity(0.08),
              leading: const FaIcon(FontAwesomeIcons.whatsapp,
                  color: Color(0xFF25D366)),
              title: Text('WhatsApp',
                  style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w600)),
              onTap: () async {
                Navigator.pop(context);
                final cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
                final uri = Uri.parse('https://wa.me/91$cleaned');
                if (await canLaunchUrl(uri))
                  launchUrl(uri, mode: LaunchMode.externalApplication);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadAttendancePdf(
      BuildContext context, String targetId) async {
    try {
      final workspace = Get.find<WorkspaceController>();
      final companyData = workspace.companyData;
      Uint8List? logoBytes;
      if (companyData['hasCompanyProfile'] == true &&
          companyData['companyLogo'] != null) {
        logoBytes =
            await ImageCacheService().fetchAndCache(companyData['companyLogo']);
      }
      final attendanceSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(targetId)
          .collection('students')
          .doc(_docId)
          .collection('attendance')
          .orderBy('date', descending: true)
          .get();
      final logs = attendanceSnap.docs.map((d) => d.data()).toList();
      final pdfBytes = await AttendancePdfService.generate(
        studentName: studentDetails['fullName'] ?? 'N/A',
        studentId: studentDetails['studentId'].toString(),
        cov: studentDetails['cov'] ?? 'N/A',
        records: logs,
        companyData: companyData,
        companyLogoBytes: logoBytes,
      );
      _showPdfPreview(context, pdfBytes);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  bool _isLessonUpdating = false;

  Future<void> _toggleLessonStatus(String targetId, bool isLessonActive) async {
    if (_isLessonUpdating) return;

    setState(() {
      _isLessonUpdating = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('StudentDetailsPage: No authenticated user');
        return;
      }

      // Ensure collection is resolved
      final base = FirebaseFirestore.instance.collection('users').doc(targetId);
      String confirmedCollection = _collectionName;

      // Check if student exists in currently resolved collection, if not, find it
      var checkSnap =
          await base.collection(confirmedCollection).doc(_docId).get();
      if (!checkSnap.exists) {
        // Fallback search
        var activeSnap = await base.collection('students').doc(_docId).get();
        if (activeSnap.exists) {
          confirmedCollection = 'students';
        } else {
          var deactSnap =
              await base.collection('deactivated_students').doc(_docId).get();
          if (deactSnap.exists) {
            confirmedCollection = 'deactivated_students';
          }
        }
        _collectionName = confirmedCollection;
      }

      if (!isLessonActive) {
        // ── START LESSON FLOW ──────────────────────────────────────────────

        // Check for location services and permissions
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          Get.snackbar('Location Disabled', 'Please enable location services.',
              backgroundColor: Colors.red, colorText: Colors.white);
          return;
        }

        LocationPermission p = await Geolocator.checkPermission();
        if (p == LocationPermission.denied) {
          p = await Geolocator.requestPermission();
          if (p == LocationPermission.denied) {
            Get.snackbar(
                'Permission Denied', 'Location permission is required.',
                backgroundColor: Colors.red, colorText: Colors.white);
            return;
          }
        }

        if (p == LocationPermission.deniedForever) {
          Get.snackbar(
              'Permission Denied', 'Location permission is permanently denied.',
              backgroundColor: Colors.red, colorText: Colors.white);
          return;
        }

        // Fetch school vehicles for selection
        final vehiclesSnap = await base.collection('school_vehicles').get();
        final vehicles = vehiclesSnap.docs;

        String? selectedVehicleId;
        String? selectedVehicleNumber;
        final startKmController = TextEditingController();

        final bool? startConfirmed =
            await showCustomStatefulDialogResult<bool?>(
          context,
          'Start Lesson',
          (context, setDialogState, onResult) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Select Vehicle'),
                items: vehicles.map((v) {
                  final data = v.data();
                  return DropdownMenuItem(
                    value: v.id,
                    child: Text(data['vehicleNumber'] ?? 'Unknown'),
                  );
                }).toList(),
                onChanged: (val) {
                  setDialogState(() {
                    selectedVehicleId = val;
                    selectedVehicleNumber = vehicles
                        .firstWhere((v) => v.id == val)
                        .data()['vehicleNumber'];
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: startKmController,
                decoration: const InputDecoration(
                  labelText: 'Starting Odometer (KM)',
                  hintText: 'e.g. 12450.5',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
          confirmText: 'Start',
          cancelText: 'Cancel',
          onConfirmResult: () {
            if (startKmController.text.isEmpty) {
              Get.snackbar('Required', 'Please enter starting KM',
                  backgroundColor: Colors.orange);
              return null;
            }
            return true;
          },
        );

        if (startConfirmed != true) return;

        final startKm = double.tryParse(startKmController.text) ?? 0.0;
        final lessonSessionId =
            '${_docId}_${DateTime.now().millisecondsSinceEpoch}';

        await base.collection(confirmedCollection).doc(_docId).update({
          'lessonStatus': 'started',
          'assignedDriver': user.uid,
          'lessonStartTime': FieldValue.serverTimestamp(),
          'lessonSessionId': lessonSessionId,
          'currentVehicleId': selectedVehicleId,
          'currentVehicleNumber': selectedVehicleNumber,
          'startKm': startKm,
        });

        // Start background service and tell it the lesson ID
        try {
          await BackgroundService.start();
          final service = FlutterBackgroundService();
          service.invoke('startLesson', {'lessonId': lessonSessionId});

          // Also update foreground service if it's running
          try {
            final trackingService = Get.find<LocationTrackingService>();
            trackingService.setManualLessonId(lessonSessionId);
          } catch (_) {}
        } catch (e) {
          debugPrint('BackgroundService error: $e');
        }

        Get.snackbar('Lesson Started', 'Real-time tracking active.',
            backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        // ── STOP LESSON FLOW ───────────────────────────────────────────────

        final snap =
            await base.collection(confirmedCollection).doc(_docId).get();

        if (!snap.exists) {
          Get.snackbar('Error', 'Student record not found.',
              backgroundColor: Colors.red, colorText: Colors.white);
          return;
        }

        final studentData = snap.data() as Map<String, dynamic>;
        final startTime =
            (studentData['lessonStartTime'] as Timestamp?)?.toDate();
        final lessonSessionId = studentData['lessonSessionId'];
        final startKm = (studentData['startKm'] as num?)?.toDouble() ?? 0.0;
        final vehicleId = studentData['currentVehicleId'];
        final vehicleNumber = studentData['currentVehicleNumber'];

        final endKmController =
            TextEditingController(text: startKm > 0 ? startKm.toString() : '');

        final bool? stopConfirmed = await showCustomStatefulDialogResult<bool?>(
          context,
          'Complete Lesson',
          (context, setDialogState, onResult) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Vehicle: ${vehicleNumber ?? 'N/A'}'),
              const SizedBox(height: 8),
              Text('Started at: ${startKm.toStringAsFixed(1)} KM'),
              const SizedBox(height: 16),
              TextField(
                controller: endKmController,
                decoration: const InputDecoration(
                  labelText: 'Ending Odometer (KM)',
                  hintText: 'e.g. 12460.2',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
          confirmText: 'Complete',
          cancelText: 'Cancel',
          onConfirmResult: () {
            if (endKmController.text.isEmpty) {
              Get.snackbar('Required', 'Please enter ending KM',
                  backgroundColor: Colors.orange);
              return null;
            }
            final end = double.tryParse(endKmController.text) ?? 0.0;
            if (end < startKm) {
              Get.snackbar('Invalid', 'Ending KM cannot be less than start KM',
                  backgroundColor: Colors.orange);
              return null;
            }
            return true;
          },
        );

        if (stopConfirmed != true) return;

        final endKm = double.tryParse(endKmController.text) ?? 0.0;
        final now = DateTime.now();
        String duration = startTime != null
            ? '${now.difference(startTime).inMinutes}m'
            : 'N/A';

        // Get distance from tracking service if available
        double gpsDistanceKm = 0.0;
        try {
          final trackingService = Get.find<LocationTrackingService>();
          gpsDistanceKm = trackingService.lessonDistance / 1000;
        } catch (e) {
          debugPrint('TrackingService not found or error: $e');
        }

        // Add to attendance subcollection
        await base
            .collection(confirmedCollection)
            .doc(_docId)
            .collection('attendance')
            .add({
          'instructorName':
              _workspaceController.userProfileData['name'] ?? 'Unknown',
          'date': FieldValue.serverTimestamp(),
          'startTime': startTime != null ? Timestamp.fromDate(startTime) : null,
          'endTime': FieldValue.serverTimestamp(),
          'duration': duration,
          'distance': '${(endKm - startKm).toStringAsFixed(2)} KM',
          'gpsDistanceKm': gpsDistanceKm,
          'startKm': startKm,
          'endKm': endKm,
          'vehicleId': vehicleId,
          'vehicleNumber': vehicleNumber,
          'lessonSessionId': lessonSessionId,
          'instructorId': user.uid,
        });

        // Reset lesson status
        await base.collection(confirmedCollection).doc(_docId).update({
          'lessonStatus': 'completed',
          'lessonSessionId': FieldValue.delete(),
          'currentVehicleId': FieldValue.delete(),
          'currentVehicleNumber': FieldValue.delete(),
          'startKm': FieldValue.delete(),
        });

        // Tell tracking services to stop lesson tracking
        try {
          final service = FlutterBackgroundService();
          service.invoke('stopLesson');

          try {
            final trackingService = Get.find<LocationTrackingService>();
            trackingService.setManualLessonId(null);
          } catch (_) {}

          // ✅ Completely stop background service when lesson ends to save resources
          await BackgroundService.stop();
        } catch (_) {}

        Get.snackbar('Lesson Completed', 'Attendance recorded: $duration',
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      debugPrint('Error in _toggleLessonStatus: $e');
      Get.snackbar('Error', 'Failed to update lesson: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      if (mounted) {
        setState(() {
          _isLessonUpdating = false;
        });
      }
    }
  }

  Future<void> _generateSelectedReceipts() async {
    if (_selectedTransactionIds.isEmpty) return;
    try {
      final pdfBytes = await LoadingUtils.wrapWithLoading(context, () async {
        final workspace = Get.find<WorkspaceController>();
        final companyData = workspace.companyData;
        final selectedPayments = _cachedPayments
            .where((p) => _selectedTransactionIds.contains(p['id']))
            .toList();
        Uint8List? logoBytes;
        if (companyData['hasCompanyProfile'] == true &&
            companyData['companyLogo'] != null) {
          logoBytes = await ImageCacheService()
              .fetchAndCache(companyData['companyLogo']);
        }
        return await PdfService.generateReceipt(
          companyData: companyData,
          studentDetails: studentDetails,
          transactions: selectedPayments,
          companyLogoBytes: logoBytes,
        );
      });
      _showPdfPreview(context, pdfBytes);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _buildLessonControlButton(String targetId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _mainStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          // Fallback to initial values if stream not ready or doc not found yet
          final isLessonActive =
              (studentDetails['lessonStatus'] ?? 'none') == 'started';
          return _lessonControlButtonUI(targetId, isLessonActive);
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final isLessonActive = (data?['lessonStatus'] ?? 'none') == 'started';
        return _lessonControlButtonUI(targetId, isLessonActive);
      },
    );
  }

  Widget _lessonControlButtonUI(String targetId, bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: TextButton.icon(
        onPressed: _isLessonUpdating
            ? null
            : () => _toggleLessonStatus(targetId, isActive),
        style: TextButton.styleFrom(
          backgroundColor: _isLessonUpdating
              ? Colors.grey.withOpacity(0.1)
              : (isActive
                  ? Colors.red.withOpacity(0.1)
                  : Colors.green.withOpacity(0.1)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: _isLessonUpdating
                  ? Colors.grey
                  : (isActive ? Colors.red : Colors.green),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        icon: _isLessonUpdating
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey)))
            : Icon(isActive ? Icons.stop_circle : Icons.play_circle_outline,
                size: 18, color: isActive ? Colors.red : Colors.green),
        label: Text(
          _isLessonUpdating ? '...' : (isActive ? 'STOP' : 'START'),
          style: TextStyle(
            color: _isLessonUpdating
                ? Colors.grey
                : (isActive ? Colors.red : Colors.green),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  void _confirmSoftDelete(BuildContext context, String targetId) {
    showCustomConfirmationDialog(
      context,
      'Move to Recycle Bin?',
      'Move "${studentDetails['fullName'] ?? 'Student'}" to recycle bin?\n\nIt will be automatically deleted after 90 days if not restored.',
      () async {
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) throw Exception('User not logged in');

          final docRef = FirebaseFirestore.instance
              .collection('users')
              .doc(targetId)
              .collection(_collectionName)
              .doc(_docId);

          await SoftDeleteService.softDelete(
            docRef: docRef,
            userId: user.uid,
            documentName: studentDetails['fullName'] ?? 'Student',
          );

          if (mounted) {
            Get.snackbar(
              'Success',
              'Moved to recycle bin',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green,
              colorText: Colors.white,
            );
            Navigator.pop(context); // Close details page
          }
        } catch (e) {
          Get.snackbar(
            'Error',
            'Failed to Delete: $e',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      },
      confirmText: 'Delete',
      cancelText: 'Cancel',
    );
  }

  void _showReceiveMoneyDialog(BuildContext context, String targetId) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(targetId)
        .collection(_collectionName)
        .doc(_docId)
        .get()
        .then((snapshot) {
      if (snapshot.exists) {
        PaymentUtils.showReceiveMoneyDialog(
          context: context,
          doc: snapshot,
          targetId: targetId,
          branchId: _workspaceController.currentBranchId.value,
          category: 'students',
        );
      }
    });
  }

  Future<void> _uploadDocument(BuildContext context, String targetId) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image != null) {
      final nameController = TextEditingController();
      final bool? shouldUpload = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Document Name'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              hintText: 'Enter document name (e.g. Aadhaar Card)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Upload'),
            ),
          ],
        ),
      );

      if (shouldUpload != true || nameController.text.trim().isEmpty) {
        return;
      }

      try {
        await LoadingUtils.wrapWithLoading(context, () async {
          final url = await StorageService()
              .uploadFile(file: image, path: 'student_docs/$_docId');
          await FirebaseFirestore.instance
              .collection('users')
              .doc(targetId)
              .collection(_collectionName)
              .doc(_docId)
              .collection('documents')
              .add({
            'name': nameController.text.trim(),
            'url': url,
            'timestamp': FieldValue.serverTimestamp(),
            'status': 'Uploaded',
          });
        }, message: 'Uploading document...');
        Get.snackbar('Success', 'Document uploaded.',
            backgroundColor: Colors.green, colorText: Colors.white);
      } catch (e) {
        Get.snackbar('Error', 'Failed to upload document: $e');
      }
    }
  }

  Future<void> _deleteDocument(String docId, String targetId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetId)
          .collection(_collectionName)
          .doc(_docId)
          .collection('documents')
          .doc(docId)
          .delete();
      Get.snackbar(
        'Success',
        'Document deleted.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete document: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Widget _buildAdditionalTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey : Colors.grey[700]!;
    final additionalInfo =
        studentDetails['additionalInfo'] as Map<String, dynamic>?;
    final hasAdditionalInfo =
        additionalInfo != null && additionalInfo.isNotEmpty;
    final Map<String, dynamic> customFields =
        (additionalInfo?['customFields'] as Map<String, dynamic>?) ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Additional Information',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            // Hide edit/add button for students - view only
            if (!widget.isStudentView)
              TextButton.icon(
                onPressed: () => _openStudentAdditionalInfoSheet(context),
                icon: const Icon(Icons.edit, size: 18, color: kAccentRed),
                label: Text(
                  hasAdditionalInfo ? 'Edit' : 'Add',
                  style: const TextStyle(color: kAccentRed, fontSize: 12),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (!hasAdditionalInfo)
          const Text(
            'No additional information added yet.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          )
        else ...[
          // Core fields
          if ((additionalInfo['applicationNumber'] ?? '').toString().isNotEmpty)
            _buildAdditionalInfoRow(
              'Application Number',
              additionalInfo['applicationNumber'].toString(),
              textColor,
              subTextColor,
            ),
          if ((additionalInfo['learnersLicenseNumber'] ?? '')
              .toString()
              .isNotEmpty)
            _buildAdditionalInfoRow(
              "Learner's License Number",
              additionalInfo['learnersLicenseNumber'].toString(),
              textColor,
              subTextColor,
            ),
          if ((additionalInfo['learnersLicenseExpiry'] ?? '')
              .toString()
              .isNotEmpty)
            _buildAdditionalInfoRow(
              "Learner's License Expiry",
              additionalInfo['learnersLicenseExpiry'].toString(),
              textColor,
              subTextColor,
            ),
          if ((additionalInfo['drivingLicenseNumber'] ?? '')
              .toString()
              .isNotEmpty)
            _buildAdditionalInfoRow(
              'Driving License Number',
              additionalInfo['drivingLicenseNumber'].toString(),
              textColor,
              subTextColor,
            ),
          if ((additionalInfo['drivingLicenseExpiry'] ?? '')
              .toString()
              .isNotEmpty)
            _buildAdditionalInfoRow(
              'Driving License Expiry',
              additionalInfo['drivingLicenseExpiry'].toString(),
              textColor,
              subTextColor,
            ),
          if (customFields.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Custom Fields',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            ...customFields.entries.map(
              (e) => _buildAdditionalInfoRow(
                e.key,
                e.value.toString(),
                textColor,
                subTextColor,
              ),
            ),
          ],
        ],
      ],
    );
  }

  Future<void> _openStudentAdditionalInfoSheet(BuildContext context) async {
    final existing = studentDetails['additionalInfo'] as Map<String, dynamic>?;

    final result = await showAdditionalInfoSheet(
      context: context,
      type: AdditionalInfoType.student,
      collection: 'students',
      documentId: _docId,
      existingData: existing,
    );

    if (result == true) {
      try {
        final service = AdditionalInfoService();
        final updated = await service.getStudentTypeAdditionalInfo(
          collection: 'students',
          documentId: _docId,
        );
        if (mounted && updated != null) {
          setState(() {
            studentDetails['additionalInfo'] = updated;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {});
        }
      }
    }
  }

  Widget _buildAdditionalInfoRow(
    String label,
    String value,
    Color textColor,
    Color subTextColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: subTextColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateProfileImage(
      BuildContext context, String targetId) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await showDialog<XFile?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Profile Photo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () async {
                final img = await picker.pickImage(
                    source: ImageSource.gallery, imageQuality: 50);
                if (mounted) Navigator.pop(ctx, img);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () async {
                final img = await picker.pickImage(
                    source: ImageSource.camera, imageQuality: 50);
                if (mounted) Navigator.pop(ctx, img);
              },
            ),
          ],
        ),
      ),
    );

    if (image != null) {
      try {
        await LoadingUtils.wrapWithLoading(context, () async {
          final url = await StorageService().uploadStudentImage(image);
          await FirebaseFirestore.instance
              .collection('users')
              .doc(targetId)
              .collection('students')
              .doc(_docId)
              .update({'image': url});
        });
        Get.snackbar('Success', 'Profile photo updated.',
            backgroundColor: Colors.green, colorText: Colors.white);
      } catch (e) {
        Get.snackbar('Error', 'Failed to upload photo: $e',
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    }
  }

  void _showAddExtraFeeDialog(BuildContext context, String targetId) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(targetId)
        .collection('students')
        .doc(_docId)
        .get()
        .then((snapshot) {
      if (snapshot.exists) {
        PaymentUtils.showAddExtraFeeDialog(
          context: context,
          doc: snapshot,
          targetId: targetId,
          category: 'students',
        );
      }
    });
  }

  void _handleTransactionAction(
      String action, Map<String, dynamic> data, String targetId) async {
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(targetId)
        .collection(_collectionName)
        .doc(_docId);

    if (data['isLegacy'] == true) {
      if (action == 'edit') {
        await PaymentUtils.showEditLegacyPaymentDialog(
          context: context,
          docRef: docRef,
          legacyId: data['id'],
          parentData: studentDetails,
          targetId: targetId,
          category: 'students',
        );
      }
    } else {
      if (action == 'edit') {
        await PaymentUtils.showEditPaymentDialog(
          context: context,
          docRef: docRef,
          paymentDoc: data['docRef'] as DocumentSnapshot,
          targetId: targetId,
          category: 'students',
        );
      } else if (action == 'delete') {
        await PaymentUtils.deletePayment(
          context: context,
          studentRef: docRef,
          paymentDoc: data['docRef'] as DocumentSnapshot,
          targetId: targetId,
        );
      }
    }
    setState(() {});
  }

  void _handleExtraFeeAction(
      String action, DocumentSnapshot feeDoc, String targetId) async {
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(targetId)
        .collection('students')
        .doc(_docId);
    if (action == 'edit') {
      await PaymentUtils.showEditExtraFeeDialog(
        context: context,
        docRef: docRef,
        feeDoc: feeDoc,
        targetId: targetId,
        category: 'students',
      );
    } else if (action == 'delete') {
      await PaymentUtils.deleteExtraFee(
        context: context,
        docRef: docRef,
        feeDoc: feeDoc,
        targetId: targetId,
      );
    }
    setState(() {});
  }

  Widget _buildExtraFeesList(BuildContext context, String targetId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _extraFeesStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red, fontSize: 12)));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final original = snapshot.data?.docs ?? [];
        final docs = List<QueryDocumentSnapshot>.from(original);
        docs.sort((a, b) {
          final ad = (a.data() as Map<String, dynamic>)['date'];
          final bd = (b.data() as Map<String, dynamic>)['date'];
          final at = ad is Timestamp ? ad : null;
          final bt = bd is Timestamp ? bd : null;
          final atMillis = at?.millisecondsSinceEpoch ?? 0;
          final btMillis = bt?.millisecondsSinceEpoch ?? 0;
          return btMillis.compareTo(atMillis);
        });
        if (docs.isEmpty)
          return const Center(
              child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No extra fees added.')));

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final date =
                (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
            final isPaid =
                (data['status']?.toString() ?? '').toLowerCase() == 'paid';
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: isPaid
                    ? Checkbox(
                        value: _selectedTransactionIds.contains(docs[index].id),
                        onChanged: (val) {
                          setState(() {
                            if (val == true)
                              _selectedTransactionIds.add(docs[index].id);
                            else
                              _selectedTransactionIds.remove(docs[index].id);
                          });
                        },
                      )
                    : const Icon(Icons.label_important_outline, color: Colors.blue),
                title: Text(data['description'] ?? 'No Description',
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text(DateFormat('dd MMM yyyy').format(date)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('₹${(data['amount'] as num?)?.toInt() ?? 0}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isPaid ? Colors.green : Colors.red)),
                    if (!widget.isStudentView && !isPaid)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        child: TextButton(
                          onPressed: () =>
                              PaymentUtils.showCollectExtraFeeDialog(
                            context: context,
                            docRef: FirebaseFirestore.instance
                                .collection('users')
                                .doc(targetId)
                                .collection('students')
                                .doc(_docId),
                            feeDoc: docs[index],
                            targetId: targetId,
                            branchId:
                                _workspaceController.currentBranchId.value,
                          ),
                          child: const Text('Collect',
                              style: TextStyle(color: Colors.green, fontSize: 12)),
                        ),
                      ),
                    if (!widget.isStudentView && !isPaid)
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 20),
                        onSelected: (value) =>
                            _handleExtraFeeAction(value, docs[index], targetId),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                              value: 'edit',
                              child: ListTile(
                                  leading: Icon(Icons.edit, size: 18),
                                  title: Text('Edit'),
                                  dense: true)),
                          const PopupMenuItem(
                              value: 'delete',
                              child: ListTile(
                                  leading: Icon(Icons.delete,
                                      color: Colors.red, size: 18),
                                  title: Text('Delete',
                                      style: TextStyle(color: Colors.red)),
                                  dense: true)),
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
  }
}

class StatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  const StatusBadge({required this.text, required this.color, super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3))),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
