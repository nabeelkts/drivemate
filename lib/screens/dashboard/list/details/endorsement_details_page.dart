import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:drivemate/constants/colors.dart';
import 'package:flutter/services.dart';
import 'package:drivemate/screens/widget/custom_back_button.dart';
import 'package:drivemate/screens/authentication/widgets/my_button.dart';
import 'package:drivemate/screens/dashboard/form/edit_forms/edit_endorsement_details_form.dart';
import 'package:drivemate/screens/profile/action_button.dart';
import 'package:drivemate/screens/dashboard/list/details/pdf_preview_screen.dart';
import 'package:drivemate/services/pdf_service.dart';
import 'package:drivemate/services/image_cache_service.dart';
import 'package:drivemate/utils/loading_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:drivemate/screens/widget/utils.dart';
import 'package:drivemate/widgets/additional_info_sheet.dart';
import 'package:drivemate/services/additional_info_service.dart';
import 'package:get/get.dart';
import 'package:drivemate/screens/profile/dialog_box.dart';
import 'package:iconly/iconly.dart';
import 'package:drivemate/utils/test_utils.dart';
import 'package:drivemate/utils/image_utils.dart';
import 'package:drivemate/utils/date_utils.dart';
import 'dart:async';
import 'package:drivemate/controller/workspace_controller.dart';
import 'package:drivemate/screens/dashboard/list/widgets/shimmer_loading_list.dart';
import 'package:drivemate/utils/payment_utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:drivemate/services/storage_service.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:drivemate/widgets/soft_delete_button.dart';
import 'package:drivemate/services/soft_delete_service.dart';
import 'package:drivemate/screens/dashboard/list/details/document_preview_screen.dart';
import 'package:drivemate/screens/dashboard/list/widgets/details_tabs_bar.dart';

class EndorsementDetailsPage extends StatefulWidget {
  final Map<String, dynamic> endorsementDetails;

  const EndorsementDetailsPage({required this.endorsementDetails, super.key});

  @override
  State<EndorsementDetailsPage> createState() => _EndorsementDetailsPageState();
}

class _EndorsementDetailsPageState extends State<EndorsementDetailsPage> {
  late Map<String, dynamic> endorsementDetails;
  final List<String> _selectedTransactionIds = [];
  static const Color kAccentRed = Color.fromRGBO(241, 135, 71, 1);
  final WorkspaceController _workspaceController =
      Get.find<WorkspaceController>();
  bool _isTransactionHistoryExpanded = false;
  List<Map<String, dynamic>> _cachedPayments =
      []; // Cache for seamless transitions

  late final String _docId;

  @override
  void initState() {
    super.initState();
    endorsementDetails = Map.from(widget.endorsementDetails);

    // Try multiple possible field names for document ID
    final id = endorsementDetails['id']?.toString();
    final endorsementId = endorsementDetails['endorsementId']?.toString();
    final recordId = endorsementDetails['recordId']?.toString();
    final serviceId = endorsementDetails['serviceId']?.toString();
    final studentId = endorsementDetails['studentId']?.toString();

    _docId = id ?? endorsementId ?? recordId ?? serviceId ?? studentId ?? '';

    // Debug: log what we found
    if (_docId.isEmpty) {
      print('WARNING: No document ID found in endorsementDetails');
      print('Available keys: ${endorsementDetails.keys.join(", ")}');
    }

    _initStreams();
  }

  late Stream<DocumentSnapshot> _mainStream;
  late Stream<QuerySnapshot> _paymentsStream;
  late Stream<QuerySnapshot> _extraFeesStream;
  late Stream<QuerySnapshot> _documentsStream;
  late Stream<QuerySnapshot> _notesStream;
  String _collectionName = 'endorsement';

  void _initStreams() {
    final targetId = _workspaceController.currentSchoolId.value.isNotEmpty
        ? _workspaceController.currentSchoolId.value
        : (FirebaseAuth.instance.currentUser?.uid ?? '');

    // Initialize with empty streams immediately to avoid late initialization errors
    _mainStream = Stream<DocumentSnapshot>.empty();
    _paymentsStream = Stream<QuerySnapshot>.empty();
    _extraFeesStream = Stream<QuerySnapshot>.empty();
    _documentsStream = Stream<QuerySnapshot>.empty();
    _notesStream = Stream<QuerySnapshot>.empty();

    if (_docId.isEmpty) return;

    final base = FirebaseFirestore.instance.collection('users').doc(targetId);
    base.collection('endorsement').doc(_docId).get().then((snap) async {
      _collectionName = snap.exists ? 'endorsement' : 'deactivated_endorsement';

      _mainStream = base.collection(_collectionName).doc(_docId).snapshots();

      // Check if subcollections were moved or still in original collection
      String subCollectionName = _collectionName;
      if (_collectionName == 'deactivated_endorsement') {
        // Check if payments exist in deactivated collection
        final paymentSnap = await base
            .collection('deactivated_endorsement')
            .doc(_docId)
            .collection('payments')
            .limit(1)
            .get();
        if (paymentSnap.docs.isEmpty) {
          // If no payments in deactivated, check if they are still in endorsement
          final originalPaymentSnap = await base
              .collection('endorsement')
              .doc(_docId)
              .collection('payments')
              .limit(1)
              .get();
          if (originalPaymentSnap.docs.isNotEmpty) {
            subCollectionName = 'endorsement';
          }
        }
      }

      _paymentsStream = base
          .collection(subCollectionName)
          .doc(_docId)
          .collection('payments')
          .orderBy('date', descending: true)
          .snapshots();
      _extraFeesStream = base
          .collection(subCollectionName)
          .doc(_docId)
          .collection('extra_fees')
          .orderBy('date', descending: true)
          .snapshots();
      _documentsStream = base
          .collection(subCollectionName)
          .doc(_docId)
          .collection('documents')
          .orderBy('timestamp', descending: true)
          .snapshots();
      _notesStream = base
          .collection(subCollectionName)
          .doc(_docId)
          .collection('notes')
          .orderBy('timestamp', descending: true)
          .snapshots();
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_docId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Invalid Document ID')),
      );
    }

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
        title: Text('Endorsement Details', style: TextStyle(color: textColor)),
        elevation: 0,
        leading: const CustomBackButton(),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: subTextColor),
            onSelected: (value) {
              if (value == 'pdf') {
                _shareEndorsementDetails(context);
              } else if (value == 'edit') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditEndorsementDetailsForm(
                      initialValues: endorsementDetails,
                      items: const [
                        'MC',
                        'MCWOG',
                        'LMV',
                        'LMV + MC ',
                        'LMV + MCWOG',
                        'ADAPTED VEHICLE',
                        'TRANS',
                        'TRANS + MC',
                        'TRANS + MCWOG',
                        'EXCAVATOR',
                        'CRANE',
                        'FORKLIFT',
                        'CONSTRUCTION EQUIPMENT',
                        'TOW TRUCK',
                        'TRAILER',
                        'AGRICULTURAL TRACTOR'
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
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading:
                      Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  title: Text('Delete', style: TextStyle(color: Colors.red)),
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
            endorsementDetails = Map<String, dynamic>.from(
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
                  _buildTabSection(context, targetId,
                      snapshot.data as DocumentSnapshot<Map<String, dynamic>>?),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Additional Info button for AppBar ──────────────────────────────────────

  void _confirmSoftDelete(BuildContext context, String targetId) {
    showCustomConfirmationDialog(
      context,
      'Move to Recycle Bin?',
      'Move "${endorsementDetails['fullName'] ?? 'Endorsement'}" to recycle bin?\n\nIt will be automatically deleted after 90 days if not restored.',
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
            documentName: endorsementDetails['fullName'] ?? 'Endorsement',
          );

          if (mounted) {
            Get.snackbar(
              'Success',
              'Moved to recycle bin',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green,
              colorText: Colors.white,
              duration: const Duration(seconds: 2),
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
                    offset: const Offset(0, 5))
              ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: () {
                  if (endorsementDetails['image'] != null &&
                      endorsementDetails['image'].toString().isNotEmpty) {
                    ImageUtils.showImagePopup(
                        context,
                        endorsementDetails['image'],
                        endorsementDetails['fullName']);
                  }
                },
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                      color: kAccentRed.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: kAccentRed, width: 2)),
                  child: ClipOval(
                    child: endorsementDetails['image'] != null &&
                            endorsementDetails['image'].toString().isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: endorsementDetails['image'],
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Shimmer.fromColors(
                                baseColor: isDark
                                    ? Colors.grey[800]!
                                    : Colors.grey[300]!,
                                highlightColor: isDark
                                    ? Colors.grey[700]!
                                    : Colors.grey[100]!,
                                child: Container(color: Colors.white)),
                            errorWidget: (context, url, error) =>
                                _buildInitials())
                        : _buildInitials(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(endorsementDetails['fullName'] ?? 'N/A',
                    style: TextStyle(
                        color: textColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('ID: ${endorsementDetails['studentId'] ?? 'N/A'}',
                    style: TextStyle(color: subTextColor, fontSize: 14)),
                const SizedBox(height: 8),
                if (endorsementDetails['cov'] != null &&
                    endorsementDetails['cov'].toString().isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: kAccentRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: kAccentRed)),
                    child: Text('COV: ${endorsementDetails['cov']}',
                        style: const TextStyle(
                            color: kAccentRed,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitials() {
    final name = endorsementDetails['fullName'] ?? '';
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
            fontSize: 40, color: kAccentRed, fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<void> _updateProfileImage(
      BuildContext context, String targetId) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await showModalBottomSheet<XFile?>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Photo Gallery'),
            onTap: () async => Navigator.pop(
                context, await picker.pickImage(source: ImageSource.gallery)),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Camera'),
            onTap: () async => Navigator.pop(
                context, await picker.pickImage(source: ImageSource.camera)),
          ),
        ],
      ),
    );

    if (image != null) {
      try {
        await LoadingUtils.wrapWithLoading(context, () async {
          final url = await StorageService().uploadFile(
            file: image,
            path: 'profile_images/$_docId/${image.name}',
          );
          await FirebaseFirestore.instance
              .collection('users')
              .doc(targetId)
              .collection('endorsement')
              .doc(_docId)
              .update({'image': url});
        });
        Get.snackbar('Success', 'Profile image updated');
      } catch (e) {
        Get.snackbar('Error', 'Failed to update profile image: $e');
      }
    }
  }

  Widget _buildInfoGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildInfoCard(
                context,
                'Personal Information',
                [
                  {
                    'label': 'Guardian',
                    'value': endorsementDetails['guardianName'] ?? 'N/A'
                  },
                  {
                    'label': 'DOB',
                    'value': formatDisplayDate(endorsementDetails['dob'])
                  },
                  {
                    'label': 'Mobile',
                    'value': endorsementDetails['mobileNumber'] ?? 'N/A'
                  },
                  {
                    'label': 'Emergency',
                    'value': endorsementDetails['emergencyNumber'] ?? 'N/A'
                  },
                  {
                    'label': 'Blood Group',
                    'value': endorsementDetails['bloodGroup'] ?? 'N/A'
                  },
                  {
                    'label': 'License No',
                    'value': endorsementDetails['license'] ?? 'N/A'
                  },
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInfoCard(
                context,
                'Address Details',
                [
                  {
                    'label': 'House Name',
                    'value': endorsementDetails['house'] ?? 'N/A'
                  },
                  {
                    'label': 'Place',
                    'value': endorsementDetails['place'] ?? 'N/A'
                  },
                  {
                    'label': 'Post Office',
                    'value': endorsementDetails['post'] ?? 'N/A'
                  },
                  {
                    'label': 'District',
                    'value': endorsementDetails['district'] ?? 'N/A'
                  },
                  {
                    'label': 'PIN Code',
                    'value': endorsementDetails['pin'] ?? 'N/A'
                  },
                ],
              ),
            ),
          ],
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
                .where((d) =>
                    d['value']!.toString().isNotEmpty && d['value'] != 'N/A')
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
                          (item['label'] == 'Mobile' ||
                                  item['label'] == 'Emergency')
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

  int _activeTab = 0;

  Widget _buildTabSection(BuildContext context, String targetId,
      DocumentSnapshot<Map<String, dynamic>>? endorsementSnapshot) {
    return Column(
      children: [
        DetailsTabsBar(
          tabs: const [
            DetailsTabItem(
                label: 'Payment', icon: Icons.account_balance_wallet),
            DetailsTabItem(label: 'Tests', icon: Icons.assignment),
            DetailsTabItem(label: 'Documents', icon: Icons.description),
            DetailsTabItem(label: 'Notes', icon: Icons.note),
            DetailsTabItem(label: 'Additional', icon: Icons.info_outline),
          ],
          activeIndex: _activeTab,
          onChanged: (i) => setState(() => _activeTab = i),
        ),
        const SizedBox(height: 16),
        Container(
          constraints: const BoxConstraints(minHeight: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kAccentRed.withOpacity(0.5)),
          ),
          child: _getTabWidget(context, targetId, endorsementSnapshot),
        ),
      ],
    );
  }

  Widget _getTabWidget(BuildContext context, String targetId,
      DocumentSnapshot<Map<String, dynamic>>? endorsementSnapshot) {
    switch (_activeTab) {
      case 0:
        if (endorsementSnapshot == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return _buildPaymentTab(context, targetId, endorsementSnapshot);
      case 1:
        return _buildTestsTab(context);
      case 2:
        return _buildDocumentsTab(context, targetId);
      case 3:
        return _buildNotesTab(context);
      case 4:
        return _buildAdditionalTab(context);
      default:
        return const SizedBox();
    }
  }

  Widget _buildPaymentTab(BuildContext context, String targetId,
      DocumentSnapshot<Map<String, dynamic>> endorsementSnapshot) {
    final data = endorsementSnapshot.data() ?? {};
    double total = double.tryParse(data['totalAmount']?.toString() ?? '0') ?? 0;
    double balance =
        double.tryParse(data['balanceAmount']?.toString() ?? '0') ?? 0;
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
            Row(
              children: [
                if (_selectedTransactionIds.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.receipt_long, color: kAccentRed),
                    onPressed: _generateSelectedReceipts,
                  ),
                IconButton(
                  icon: const Icon(Icons.post_add, color: Colors.blue),
                  onPressed: () {
                    PaymentUtils.showAddExtraFeeDialog(
                      context: context,
                      doc: endorsementSnapshot,
                      targetId: targetId,
                      category: 'endorsement',
                    );
                  },
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
        _buildTransactionHistorySection(context, targetId),
        const SizedBox(height: 24),
        const Text(
          'Additional Fees',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 12),
        _buildExtraFeesSection(context, targetId),
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

  Widget _buildExtraFeesSection(BuildContext context, String targetId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.grey : Colors.grey[700]!;

    return StreamBuilder<QuerySnapshot>(
      stream: _extraFeesStream,
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No extra fees added.'),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final date = (data['date'] as Timestamp).toDate();
              final isPaid =
                  (data['status']?.toString() ?? '').toLowerCase() == 'paid';

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                      color: isPaid
                          ? Colors.green.withOpacity(0.5)
                          : Colors.grey[200]!),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _selectedTransactionIds.contains(doc.id),
                        onChanged: isPaid
                            ? (val) {
                                setState(() {
                                  if (val == true)
                                    _selectedTransactionIds.add(doc.id);
                                  else
                                    _selectedTransactionIds.remove(doc.id);
                                });
                              }
                            : null,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['description'] ?? 'Fee',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Text('Rs. ${data['amount']}',
                                style: const TextStyle(
                                    color: kAccentRed,
                                    fontWeight: FontWeight.bold)),
                            Text(DateFormat('dd MMM yyyy').format(date),
                                style: TextStyle(
                                    color: subTextColor, fontSize: 11)),
                          ],
                        ),
                      ),
                      if (!isPaid)
                        TextButton(
                          onPressed: () =>
                              PaymentUtils.showCollectExtraFeeDialog(
                            context: context,
                            docRef: FirebaseFirestore.instance
                                .collection('users')
                                .doc(targetId)
                                .collection('endorsement')
                                .doc(_docId),
                            feeDoc: doc,
                            targetId: targetId,
                            branchId:
                                _workspaceController.currentBranchId.value,
                          ),
                          child: const Text('Collect'),
                        )
                      else
                        const Icon(Icons.check_circle,
                            color: Colors.green, size: 20),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            color: Colors.blue, size: 20),
                        onPressed: () => PaymentUtils.showEditExtraFeeDialog(
                          context: context,
                          docRef: FirebaseFirestore.instance
                              .collection('users')
                              .doc(targetId)
                              .collection('endorsement')
                              .doc(_docId),
                          feeDoc: doc,
                          targetId: targetId,
                          category: 'endorsement',
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red, size: 20),
                        onPressed: () => PaymentUtils.deleteExtraFee(
                          context: context,
                          docRef: FirebaseFirestore.instance
                              .collection('users')
                              .doc(targetId)
                              .collection('endorsement')
                              .doc(_docId),
                          feeDoc: doc,
                          targetId: targetId,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildTransactionHistorySection(
      BuildContext context, String targetId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Transaction History',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: _paymentsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                _cachedPayments.isEmpty) {
              return const ShimmerLoadingList();
            }
            final docs = snapshot.data?.docs ?? [];
            _cachedPayments = docs.map((d) {
              final data = d.data() as Map<String, dynamic>;
              data['id'] = d.id;
              data['docRef'] = d;
              return data;
            }).toList();

            if (_cachedPayments.isEmpty) {
              return const Center(
                  child: Text('No transactions yet',
                      style: TextStyle(fontSize: 12, color: Colors.grey)));
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _cachedPayments.length,
              itemBuilder: (context, index) {
                final data = _cachedPayments[index];
                final date = (data['date'] as Timestamp).toDate();
                final isSelected = _selectedTransactionIds.contains(data['id']);

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                        color: isSelected ? kAccentRed : Colors.grey[200]!),
                  ),
                  child: CheckboxListTile(
                    value: isSelected,
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (val) {
                      setState(() {
                        if (val == true)
                          _selectedTransactionIds.add(data['id']);
                        else
                          _selectedTransactionIds.remove(data['id']);
                      });
                    },
                    title: Text('Rs. ${data['amount']}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle:
                        Text(DateFormat('dd MMM yyyy, hh:mm a').format(date)),
                    secondary: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              color: Colors.blue, size: 20),
                          onPressed: () => PaymentUtils.showEditPaymentDialog(
                            context: context,
                            docRef: FirebaseFirestore.instance
                                .collection('users')
                                .doc(targetId)
                                .collection(_collectionName)
                                .doc(_docId),
                            paymentDoc: data['docRef'],
                            targetId: targetId,
                            category: 'endorsement',
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red, size: 20),
                          onPressed: () => PaymentUtils.deletePayment(
                            context: context,
                            studentRef: FirebaseFirestore.instance
                                .collection('users')
                                .doc(targetId)
                                .collection(_collectionName)
                                .doc(_docId),
                            paymentDoc: data['docRef'],
                            targetId: targetId,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildDocumentsTab(BuildContext context, String targetId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Documents',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            IconButton(
              icon: const Icon(Icons.add_photo_alternate_outlined,
                  color: kAccentRed),
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
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'No documents uploaded yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final name = data['name'] ?? 'Document';
                final timestamp = data['timestamp'] as Timestamp?;
                final subtitle = timestamp != null
                    ? DateFormat('dd MMM yyyy').format(timestamp.toDate())
                    : null;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.file_present, color: kAccentRed),
                    title: Text(name),
                    subtitle: subtitle != null ? Text(subtitle) : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () =>
                          _deleteDocument(docs[index].id, targetId),
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
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildTestsTab(BuildContext context) {
    // Safely get test dates, defaulting to empty string if null
    final llDate = AppDateUtils.formatDateForDisplay(
        endorsementDetails['learnersTestDate']?.toString() ?? '');
    final dlDate = AppDateUtils.formatDateForDisplay(
        endorsementDetails['drivingTestDate']?.toString() ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Test Schedule',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            IconButton(
              icon: const Icon(Icons.edit_calendar, color: kAccentRed),
              onPressed: () => TestUtils.showUpdateTestDateDialog(
                context: context,
                item: endorsementDetails,
                collection: 'endorsement',
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

  Widget _buildNotesTab(BuildContext context) {
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
                (endorsementDetails['remarks'] ?? '').toString().trim();

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
        setState(() {
          endorsementDetails['remarks'] = controller.text.trim();
        });
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
        setState(() {
          endorsementDetails.remove('remarks');
        });
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

  Widget _buildAdditionalTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey : Colors.grey[700]!;
    final additionalInfo =
        endorsementDetails['additionalInfo'] as Map<String, dynamic>?;
    final hasAdditionalInfo =
        additionalInfo != null && additionalInfo.isNotEmpty;
    final Map<String, dynamic> customFields =
        (additionalInfo?['customFields'] as Map<String, dynamic>?) ?? {};

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Additional Information',
                style: TextStyle(
                    color: kAccentRed,
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () => _openEndorsementAdditionalInfoSheet(context),
                icon: const Icon(Icons.edit, size: 18, color: kAccentRed),
                label: Text(
                  hasAdditionalInfo ? 'Edit' : 'Add',
                  style: const TextStyle(color: kAccentRed, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (!hasAdditionalInfo)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No additional information added',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((additionalInfo['applicationNumber'] ?? '')
                      .toString()
                      .isNotEmpty)
                    _buildInfoRow(
                      'Application Number',
                      additionalInfo['applicationNumber'].toString(),
                      textColor,
                      subTextColor,
                    ),
                  if ((additionalInfo['learnersLicenseNumber'] ?? '')
                      .toString()
                      .isNotEmpty)
                    _buildInfoRow(
                      "Learner's License Number",
                      additionalInfo['learnersLicenseNumber'].toString(),
                      textColor,
                      subTextColor,
                    ),
                  if ((additionalInfo['learnersLicenseExpiry'] ?? '')
                      .toString()
                      .isNotEmpty)
                    _buildInfoRow(
                      "Learner's License Expiry",
                      additionalInfo['learnersLicenseExpiry'].toString(),
                      textColor,
                      subTextColor,
                    ),
                  if ((additionalInfo['drivingLicenseNumber'] ?? '')
                      .toString()
                      .isNotEmpty)
                    _buildInfoRow(
                      'Driving License Number',
                      additionalInfo['drivingLicenseNumber'].toString(),
                      textColor,
                      subTextColor,
                    ),
                  if ((additionalInfo['drivingLicenseExpiry'] ?? '')
                      .toString()
                      .isNotEmpty)
                    _buildInfoRow(
                      'Driving License Expiry',
                      additionalInfo['drivingLicenseExpiry'].toString(),
                      textColor,
                      subTextColor,
                    ),
                  if (customFields.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Custom Fields',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    ...customFields.entries.map(
                      (e) => _buildInfoRow(
                        e.key,
                        e.value.toString(),
                        textColor,
                        subTextColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      String label, String value, Color textColor, Color subTextColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: TextStyle(
                  color: subTextColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
                color: textColor, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Future<void> _openEndorsementAdditionalInfoSheet(BuildContext context) async {
    final additionalInfo =
        endorsementDetails['additionalInfo'] as Map<String, dynamic>?;

    final result = await showAdditionalInfoSheet(
      context: context,
      type: AdditionalInfoType.student,
      collection: 'endorsement',
      documentId: _docId,
      existingData: additionalInfo,
    );

    if (result == true) {
      try {
        final service = AdditionalInfoService();
        final updated = await service.getStudentTypeAdditionalInfo(
          collection: 'endorsement',
          documentId: _docId,
        );
        if (mounted && updated != null) {
          setState(() {
            endorsementDetails['additionalInfo'] = updated;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {});
        }
      }
    }
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
          category: 'endorsement',
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
              hintText: 'Enter document name',
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

      if (shouldUpload == true && nameController.text.trim().isNotEmpty) {
        try {
          await LoadingUtils.wrapWithLoading(context, () async {
            final url = await StorageService()
                .uploadFile(file: image, path: 'service_docs/$_docId');
            await FirebaseFirestore.instance
                .collection('users')
                .doc(targetId)
                .collection('endorsement')
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
  }

  Future<void> _deleteDocument(String docId, String targetId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetId)
          .collection('endorsement')
          .doc(_docId)
          .collection('documents')
          .doc(docId)
          .delete();
      Get.snackbar('Success', 'Document deleted.',
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete document: $e');
    }
  }

  Future<void> _generateSingleReceipt(Map<String, dynamic> transaction) async =>
      _generateReceipts([transaction]);

  Future<void> _generateSelectedReceipts() async {
    if (_selectedTransactionIds.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final targetId = _workspaceController.targetId;
    final studentId = endorsementDetails['studentId'].toString();
    final List<Map<String, dynamic>> allTransactions = [];

    final paymentsQuery = await FirebaseFirestore.instance
        .collection('users')
        .doc(targetId)
        .collection('endorsement')
        .doc(studentId)
        .collection('payments')
        .where(FieldPath.documentId, whereIn: _selectedTransactionIds)
        .get();
    allTransactions.addAll(paymentsQuery.docs.map((d) => d.data()));

    final feesQuery = await FirebaseFirestore.instance
        .collection('users')
        .doc(targetId)
        .collection('endorsement')
        .doc(studentId)
        .collection('extra_fees')
        .where(FieldPath.documentId, whereIn: _selectedTransactionIds)
        .get();
    allTransactions.addAll(feesQuery.docs.map((d) {
      final data = d.data();
      return {
        'amount': data['amount'],
        'description': data['description'] ?? 'Additional Fee',
        'mode': data['paymentMode'] ?? 'Cash',
        'date': data['paymentDate'] ?? data['date'],
        'note': data['paymentNote'] ?? data['note']
      };
    }));

    for (String id in _selectedTransactionIds) {
      if (id == 'legacy_adv') {
        final double amount = double.tryParse(
                endorsementDetails['advanceAmount']?.toString() ?? '0') ??
            0;
        if (amount > 0)
          allTransactions.add({
            'amount': amount,
            'date': DateTime.tryParse(
                    endorsementDetails['registrationDate']?.toString() ?? '') ??
                DateTime(2000),
            'mode': endorsementDetails['paymentMode'] ?? 'Cash',
            'description': 'Initial Advance'
          });
      } else if (id.startsWith('legacy_inst')) {
        final int index = int.tryParse(id.replaceFirst('legacy_inst', '')) ?? 0;
        if (index > 0) {
          final double amount = double.tryParse(
                  endorsementDetails['installment$index']?.toString() ?? '0') ??
              0;
          if (amount > 0)
            allTransactions.add({
              'amount': amount,
              'date': DateTime.tryParse(
                      endorsementDetails['installment${index}Time']
                              ?.toString() ??
                          '') ??
                  DateTime(2000),
              'mode': 'Cash',
              'description': 'Installment $index'
            });
        }
      }
    }

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
      List<Map<String, dynamic>> transactions) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    Uint8List? pdfBytes;
    try {
      pdfBytes = await LoadingUtils.wrapWithLoading(context, () async {
        final workspace = Get.find<WorkspaceController>();
        final companyData = workspace.companyData;
        if (companyData['hasCompanyProfile'] != true)
          throw 'Please set up your Company Profile first';
        Uint8List? logoBytes;
        if (companyData['companyLogo'] != null &&
            companyData['companyLogo'].toString().isNotEmpty) {
          logoBytes = await ImageCacheService()
              .fetchAndCache(companyData['companyLogo']);
        }
        return await PdfService.generateReceipt(
            companyData: companyData,
            studentDetails: endorsementDetails,
            transactions: transactions,
            companyLogoBytes: logoBytes);
      });
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      return;
    }
    if (pdfBytes != null && mounted) _showPdfPreview(context, pdfBytes);
  }

  // ── Tappable mobile row ─────────────────────────────────────────────────────

  Widget _buildMobileRow(
      String phone, Color textColor, Color subTextColor, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: GestureDetector(
        onTap: () => _showContactOptions(context, phone),
        child: RichText(
          text: TextSpan(
            style:
                TextStyle(fontSize: 13, fontFamily: 'Inter', color: textColor),
            children: [
              TextSpan(
                  text: phone,
                  style: const TextStyle(
                      color: kAccentRed,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w600)),
            ],
          ),
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
              title: Text('Call',
                  style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w600)),
              onTap: () async {
                Navigator.pop(context);
                final uri = Uri(scheme: 'tel', path: phone);
                if (await canLaunchUrl(uri)) launchUrl(uri);
              },
            ),
            const SizedBox(height: 10),
            ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              tileColor: const Color(0xFF25D366).withOpacity(0.08),
              leading: const Icon(Icons.chat_rounded, color: Color(0xFF25D366)),
              title: Text('WhatsApp',
                  style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w600)),
              onTap: () async {
                Navigator.pop(context);
                final cleaned =
                    phone.startsWith('0') ? phone.substring(1) : phone;
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

  Future<void> _shareReceiptToWhatsApp(String phone, Uint8List pdfBytes) async {
    try {
      final dir = await getTemporaryDirectory();
      final name = (endorsementDetails['fullName'] ?? 'endorsement')
          .toString()
          .replaceAll(' ', '_');
      final file = File('${dir.path}/receipt_$name.pdf');
      await file.writeAsBytes(pdfBytes);
      final cleaned = phone.startsWith('0') ? phone.substring(1) : phone;
      final jid = '91$cleaned@s.whatsapp.net';
      if (Platform.isAndroid) {
        final intent = AndroidIntent(
            action: 'android.intent.action.SEND',
            package: 'com.whatsapp',
            type: 'application/pdf',
            arguments: {
              'android.intent.extra.STREAM': file.absolute.path,
              'jid': jid
            },
            flags: [
              0x00000001
            ]);
        await intent.launch();
      } else {
        await Share.shareXFiles([XFile(file.path, mimeType: 'application/pdf')],
            text:
                'Fee Receipt for ${endorsementDetails['fullName'] ?? 'Customer'}');
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error sending to WhatsApp: $e')));
    }
  }

  void _showPdfPreview(BuildContext context, Uint8List pdfBytes) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfPreviewScreen(
          pdfBytes: pdfBytes,
          studentName: endorsementDetails['fullName'],
          studentPhone: endorsementDetails['mobileNumber'],
          fileName: 'receipt_${endorsementDetails['fullName']}.pdf',
        ),
      ),
    );
  }

  Future<void> _shareEndorsementDetails(BuildContext context) async {
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
                  const Text('Share PDF',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: 18.0)),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                      title: const Text('Include Payment Overview'),
                      value: includePayment,
                      onChanged: (bool? value) =>
                          setState(() => includePayment = value ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                          child: ActionButton(
                              text: 'Cancel',
                              backgroundColor: const Color(0xFFFFF1F1),
                              textColor: const Color(0xFFFF0000),
                              onPressed: () =>
                                  Navigator.of(context).pop(false))),
                      const SizedBox(width: 16),
                      Expanded(
                          child: ActionButton(
                              text: 'Generate',
                              backgroundColor: const Color(0xFFF6FFF0),
                              textColor: Colors.black,
                              onPressed: () =>
                                  Navigator.of(context).pop(true))),
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
        if (companyData['hasCompanyProfile'] != true)
          throw 'Please set up your Company Profile first';
        Uint8List? studentImage;
        if (endorsementDetails['image'] != null &&
            endorsementDetails['image'].toString().isNotEmpty)
          studentImage = await ImageCacheService()
              .fetchAndCache(endorsementDetails['image']);
        Uint8List? logoBytes;
        if (companyData['companyLogo'] != null &&
            companyData['companyLogo'].toString().isNotEmpty)
          logoBytes = await ImageCacheService()
              .fetchAndCache(companyData['companyLogo']);
        return await PdfService.generatePdf(
            title: 'Endorsement Details',
            data: endorsementDetails,
            includePayment: includePayment,
            imageBytes: studentImage,
            companyData: companyData,
            companyLogoBytes: logoBytes);
      });
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      return;
    }
    if (pdfBytes != null && mounted) _showPdfPreview(context, pdfBytes);
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
