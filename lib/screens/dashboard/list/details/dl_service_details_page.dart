import 'dart:async';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:drivemate/constants/colors.dart';
import 'package:get/get.dart';
import 'package:drivemate/screens/widget/custom_back_button.dart';
import 'package:intl/intl.dart';
import 'package:drivemate/screens/widget/utils.dart';
import 'package:drivemate/widgets/additional_info_sheet.dart';
import 'package:drivemate/services/additional_info_service.dart';
import 'package:drivemate/controller/workspace_controller.dart';
import 'package:drivemate/screens/dashboard/list/widgets/shimmer_loading_list.dart';
import 'package:drivemate/screens/dashboard/form/edit_forms/edit_dl_service_form.dart';
import 'package:drivemate/screens/dashboard/list/details/pdf_preview_screen.dart';
import 'package:drivemate/screens/profile/action_button.dart';
import 'package:drivemate/services/pdf_service.dart';
import 'package:drivemate/services/image_cache_service.dart';
import 'package:drivemate/utils/date_utils.dart';
import 'package:drivemate/utils/loading_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:drivemate/utils/image_utils.dart';
import 'package:drivemate/utils/payment_utils.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:drivemate/widgets/soft_delete_button.dart';
import 'package:image_picker/image_picker.dart';
import 'package:drivemate/services/storage_service.dart';
import 'package:drivemate/utils/test_utils.dart';
import 'package:drivemate/screens/dashboard/list/details/document_preview_screen.dart';
import 'package:drivemate/screens/dashboard/list/widgets/details_tabs_bar.dart';

class DlServiceDetailsPage extends StatefulWidget {
  final Map<String, dynamic> serviceDetails;

  const DlServiceDetailsPage({required this.serviceDetails, super.key});

  @override
  State<DlServiceDetailsPage> createState() => _DlServiceDetailsPageState();
}

class _DlServiceDetailsPageState extends State<DlServiceDetailsPage> {
  late Map<String, dynamic> serviceDetails;
  final List<String> _selectedTransactionIds = [];
  static const Color kAccentRed = Color.fromRGBO(241, 135, 71, 1);
  final WorkspaceController _workspaceController =
      Get.find<WorkspaceController>();
  List<Map<String, dynamic>> _cachedPayments = [];
  int _activeTab = 0;
  late final String _docId;

  @override
  void initState() {
    super.initState();
    serviceDetails = Map.from(widget.serviceDetails);

    // Try multiple possible field names for document ID,
    // similar to other details pages (endorsement, license only, etc.)
    final id = serviceDetails['id']?.toString();
    final serviceId = serviceDetails['serviceId']?.toString();
    final recordId = serviceDetails['recordId']?.toString();
    final studentId = serviceDetails['studentId']?.toString();

    _docId = id ?? serviceId ?? recordId ?? studentId ?? '';

    if (_docId.isEmpty) {
      debugPrint(
          'WARNING: No document ID found in DlServiceDetailsPage. Keys: ${serviceDetails.keys.join(", ")}');
    }

    _initStreams();
  }

  Stream<DocumentSnapshot> _mainStream = const Stream.empty();
  Stream<QuerySnapshot> _paymentsStream = const Stream.empty();
  Stream<QuerySnapshot> _extraFeesStream = const Stream.empty();
  Stream<QuerySnapshot> _documentsStream = const Stream.empty();
  String _collectionName = 'dl_services';
  Future<void> _initStreams() async {
    final targetId = _workspaceController.currentSchoolId.value.isNotEmpty
        ? _workspaceController.currentSchoolId.value
        : (FirebaseAuth.instance.currentUser?.uid ?? '');

    // Safeguard against missing IDs to avoid invalid Firestore paths
    if (_docId.isEmpty) {
      _mainStream = const Stream.empty();
      _paymentsStream = const Stream.empty();
      _extraFeesStream = const Stream.empty();
      _documentsStream = const Stream.empty();
      return;
    }
    // Initialize with empty streams to prevent late init errors during first build
    _mainStream = const Stream.empty();
    _paymentsStream = const Stream.empty();
    _extraFeesStream = const Stream.empty();
    _documentsStream = const Stream.empty();

    // Determine active vs deactivated collection
    final base = FirebaseFirestore.instance.collection('users').doc(targetId);
    final activeSnap = await base.collection('dl_services').doc(_docId).get();
    _collectionName =
        activeSnap.exists ? 'dl_services' : 'deactivated_dl_services';

    _mainStream = base.collection(_collectionName).doc(_docId).snapshots();
    _paymentsStream = base
        .collection(_collectionName)
        .doc(_docId)
        .collection('payments')
        .orderBy('date', descending: true)
        .snapshots();
    _extraFeesStream = base
        .collection(_collectionName)
        .doc(_docId)
        .collection('extra_fees')
        .orderBy('date', descending: true)
        .snapshots();
    _documentsStream = base
        .collection(_collectionName)
        .doc(_docId)
        .collection('documents')
        .orderBy('timestamp', descending: true)
        .snapshots();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_docId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          leading: const CustomBackButton(),
          title: const Text('Service Details'),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'Invalid Document ID for this DL service.',
              style: TextStyle(color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
          ),
        ),
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
        title: Text('Service Details', style: TextStyle(color: textColor)),
        elevation: 0,
        leading: const CustomBackButton(),
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf, color: subTextColor),
            onPressed: () => _shareServiceDetails(context),
          ),
          // Soft Delete Button - Move to Recycle Bin
          if (_collectionName == 'dl_services')
            SoftDeleteButton(
              docRef: FirebaseFirestore.instance
                  .collection('users')
                  .doc(targetId)
                  .collection(_collectionName)
                  .doc(_docId) as DocumentReference<Object?>,
              documentName: serviceDetails['fullName'] ?? 'DL Service',
              onDeleteSuccess: () {
                Get.snackbar(
                  'Success',
                  'DL service moved to recycle bin',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                  duration: const Duration(seconds: 2),
                );
              },
            ),
          IconButton(
            icon: Icon(Icons.edit, color: subTextColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditDlServiceForm(
                    initialValues: serviceDetails,
                    items: const [
                      'Renewal Of DL',
                      'Change of Address',
                      'Change of Name',
                      'Change of Photo & Signature',
                      'Duplicate License',
                      'Change of DOB',
                      'Endorsement to DL',
                      'Issue of PSV Badge',
                      'Other',
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
          final DocumentSnapshot<Map<String, dynamic>>? serviceSnapshot =
              snapshot.data as DocumentSnapshot<Map<String, dynamic>>?;

          if (snapshot.hasData && snapshot.data!.exists) {
            serviceDetails = Map<String, dynamic>.from(
                snapshot.data!.data() as Map<String, dynamic>);
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              serviceDetails.isEmpty) {
            return const Center(child: CircularProgressIndicator());
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
                  _buildTabSection(context, targetId, serviceSnapshot),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Additional Info button for AppBar ──────────────────────────────────────

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
        children: [
          InkWell(
            onTap: () {
              final imageUrl = serviceDetails['image']?.toString() ?? '';
              if (imageUrl.isEmpty) return;
              ImageUtils.showImagePopup(
                context,
                imageUrl,
                serviceDetails['fullName']?.toString() ?? 'Profile Photo',
              );
            },
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
                child: serviceDetails['image'] != null &&
                        serviceDetails['image'].toString().isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: serviceDetails['image'],
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor:
                              isDark ? Colors.grey[800]! : Colors.grey[300]!,
                          highlightColor:
                              isDark ? Colors.grey[700]! : Colors.grey[100]!,
                          child: Container(color: Colors.white),
                        ),
                        errorWidget: (context, url, error) => Container(
                          alignment: Alignment.center,
                          child: Text(
                            serviceDetails['fullName'] != null &&
                                    serviceDetails['fullName']
                                        .toString()
                                        .isNotEmpty
                                ? serviceDetails['fullName'][0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 40,
                              color: textColor,
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          serviceDetails['fullName'] != null &&
                                  serviceDetails['fullName']
                                      .toString()
                                      .isNotEmpty
                              ? serviceDetails['fullName'][0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 40,
                            color: Colors.white,
                          ),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  serviceDetails['fullName'] ?? 'N/A',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ID: ${serviceDetails['studentId'] ?? 'N/A'}',
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 14,
                  ),
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
                    'Service: ${serviceDetails['serviceType'] ?? 'N/A'}',
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
              .collection('dl_services')
              .doc(_docId)
              .update({'image': url});
        });
        Get.snackbar('Success', 'Profile image updated');
      } catch (e) {
        Get.snackbar('Error', 'Failed to update profile image: $e');
      }
    }
  }

  Future<void> _generateSingleReceipt(Map<String, dynamic> transaction) async {
    _generateReceipts([transaction]);
  }

  Future<void> _generateSelectedReceipts() async {
    if (_selectedTransactionIds.isEmpty) return;

    final targetId = _workspaceController.currentSchoolId.value.isNotEmpty
        ? _workspaceController.currentSchoolId.value
        : (FirebaseAuth.instance.currentUser?.uid ?? '');

    final List<Map<String, dynamic>> allTransactions = [];

    // Check payments collection
    final paymentsQuery = await FirebaseFirestore.instance
        .collection('users')
        .doc(targetId)
        .collection('dl_services')
        .doc(_docId)
        .collection('payments')
        .where(FieldPath.documentId, whereIn: _selectedTransactionIds)
        .get();

    for (var doc in paymentsQuery.docs) {
      final data = doc.data();
      data['id'] = doc.id;
      allTransactions.add(data);
    }

    // Check extra_fees collection
    final feesQuery = await FirebaseFirestore.instance
        .collection('users')
        .doc(targetId)
        .collection('dl_services')
        .doc(_docId)
        .collection('extra_fees')
        .where(FieldPath.documentId, whereIn: _selectedTransactionIds)
        .get();

    for (var doc in feesQuery.docs) {
      final data = doc.data();
      allTransactions.add({
        'id': doc.id,
        'amount': data['amount'],
        'description': data['description'] ?? 'Additional Fee',
        'mode': data['paymentMode'] ?? 'Cash',
        'date': data['paymentDate'] ?? data['date'],
        'note': data['paymentNote'] ?? data['note'],
      });
    }

    if (allTransactions.isEmpty) return;

    // Sort by date descending
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
    try {
      final pdfBytes = await LoadingUtils.wrapWithLoading(context, () async {
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
          studentDetails: serviceDetails,
          transactions: transactions,
          companyLogoBytes: logoBytes,
        );
      });
      if (pdfBytes != null) _showPdfPreview(context, pdfBytes);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _buildInfoGrid(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildInfoCard(
            context,
            'Personal Information',
            [
              {
                'label': 'Guardian',
                'value': serviceDetails['guardianName'] ?? 'N/A'
              },
              {
                'label': 'Date of Birth',
                'value': formatDisplayDate(serviceDetails['dob'])
              },
              {
                'label': 'Mobile',
                'value': serviceDetails['mobileNumber'] ?? 'N/A'
              },
              {
                'label': 'Emergency',
                'value': serviceDetails['emergencyNumber'] ?? 'N/A'
              },
              {
                'label': 'Blood Group',
                'value': serviceDetails['bloodGroup'] ?? 'N/A'
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
                'value': serviceDetails['house'] ?? 'N/A'
              },
              {'label': 'Place', 'value': serviceDetails['place'] ?? 'N/A'},
              {
                'label': 'Post Office',
                'value': serviceDetails['post'] ?? 'N/A'
              },
              {
                'label': 'District',
                'value': serviceDetails['district'] ?? 'N/A'
              },
              {'label': 'Pincode', 'value': serviceDetails['pin'] ?? 'N/A'},
            ],
          ),
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

  Widget _buildTabSection(BuildContext context, String targetId,
      DocumentSnapshot<Map<String, dynamic>>? serviceSnapshot) {
    final tabs = const [
      DetailsTabItem(label: 'Payment', icon: Icons.account_balance_wallet),
      DetailsTabItem(label: 'Documents', icon: Icons.description),
      DetailsTabItem(label: 'Notes', icon: Icons.note),
      DetailsTabItem(label: 'Additional', icon: Icons.info_outline),
    ];

    return Column(
      children: [
        DetailsTabsBar(
          tabs: tabs,
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
          child: _getTabWidget(context, targetId, serviceSnapshot),
        ),
      ],
    );
  }

  Widget _getTabWidget(BuildContext context, String targetId,
      DocumentSnapshot<Map<String, dynamic>>? serviceSnapshot) {
    switch (_activeTab) {
      case 0:
        if (serviceSnapshot == null) {
          return _buildPaymentTabFallback(context, targetId);
        }
        return _buildPaymentTab(context, targetId, serviceSnapshot);
      case 1:
        return _buildDocumentsTab(context, targetId);
      case 2:
        return _buildNotesTab(context);
      case 3:
        return _buildAdditionalTab(context);
      default:
        return const SizedBox();
    }
  }

  Widget _buildPaymentTabFallback(BuildContext context, String targetId) {
    final data = serviceDetails;
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
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(targetId)
                        .collection(_collectionName)
                        .doc(_docId)
                        .get()
                        .then((snap) {
                      if (snap.exists) {
                        PaymentUtils.showAddExtraFeeDialog(
                          context: context,
                          doc: snap,
                          targetId: targetId,
                          category: 'dl_services',
                        );
                      }
                    });
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
        _buildExtraFeesSection(context, targetId),
      ],
    );
  }

  Widget _buildPaymentTab(BuildContext context, String targetId,
      DocumentSnapshot<Map<String, dynamic>> serviceSnapshot) {
    final data = serviceSnapshot.data() ?? {};
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
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(targetId)
                        .collection('dl_services')
                        .doc(_docId)
                        .get()
                        .then((snap) {
                      if (snap.exists) {
                        PaymentUtils.showAddExtraFeeDialog(
                          context: context,
                          doc: snap,
                          targetId: targetId,
                          category: 'dl_services',
                        );
                      }
                    });
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
                            category: 'dl_services',
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

  Widget _buildExtraFeesSection(BuildContext context, String targetId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Additional Fees',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: _extraFeesStream,
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) return const SizedBox.shrink();

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final isPaid =
                    (data['status']?.toString() ?? '').toLowerCase() == 'paid';

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.label_important_outline,
                      color: isPaid ? Colors.green : Colors.blue),
                  title: Text(data['description'] ?? 'N/A'),
                  subtitle: Text('Rs. ${data['amount']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isPaid)
                        TextButton(
                          onPressed: () =>
                              PaymentUtils.showCollectExtraFeeDialog(
                            context: context,
                            docRef: FirebaseFirestore.instance
                                .collection('users')
                                .doc(targetId)
                                .collection('dl_services')
                                .doc(_docId),
                            feeDoc: docs[index],
                            targetId: targetId,
                            branchId:
                                _workspaceController.currentBranchId.value,
                          ),
                          child: const Text('Collect',
                              style: TextStyle(color: Colors.green)),
                        ),
                      PopupMenuButton<String>(
                        onSelected: (val) {
                          if (val == 'edit') {
                            PaymentUtils.showEditExtraFeeDialog(
                              context: context,
                              docRef: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(targetId)
                                  .collection('dl_services')
                                  .doc(_docId),
                              feeDoc: docs[index],
                              targetId: targetId,
                              category: 'dl_services',
                            );
                          } else if (val == 'delete') {
                            PaymentUtils.deleteExtraFee(
                              context: context,
                              docRef: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(targetId)
                                  .collection('dl_services')
                                  .doc(_docId),
                              feeDoc: docs[index],
                              targetId: targetId,
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                              value: 'edit', child: Text('Edit')),
                          const PopupMenuItem(
                              value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    ],
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
    if (_docId.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('Invalid document ID',
              style: TextStyle(color: Colors.red, fontSize: 12)),
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
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }
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

  Widget _buildTestCard(
      BuildContext context, String type, String date, IconData icon) {
    final hasDate = date.isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (hasDate ? Colors.green : kAccentRed).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color:
                      (hasDate ? Colors.green : kAccentRed).withOpacity(0.3)),
            ),
            child: Text(
              hasDate ? 'Scheduled' : 'Pending',
              style: TextStyle(
                color: hasDate ? Colors.green : kAccentRed,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesTab(BuildContext context) {
    final hasNotes =
        (serviceDetails['remarks'] ?? '').toString().trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Notes & Remarks',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add, size: 20, color: kAccentRed),
                  tooltip: 'Add Notes',
                  onPressed: () => _editNotes(context, isNew: true),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20, color: kAccentRed),
                  tooltip: hasNotes ? 'Edit Notes' : 'Add Notes',
                  onPressed: () => _editNotes(context),
                ),
                if (hasNotes)
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 20, color: Colors.red),
                    tooltip: 'Delete Notes',
                    onPressed: () => _clearNotes(context),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.yellow[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.yellow[200]!),
          ),
          child: Text(
            hasNotes ? serviceDetails['remarks'] : 'No remarks added yet.',
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey : Colors.grey[700]!;
    final additionalInfo =
        serviceDetails['additionalInfo'] as Map<String, dynamic>?;
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
            const Text('Additional Information',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: () => _openDlAdditionalInfoSheet(context),
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
          ...additionalInfo.entries
              .where((e) => e.key != 'customFields' && e.key != 'updatedAt')
              .map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.key.toUpperCase(),
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 10)),
                      const SizedBox(height: 2),
                      Text(e.value.toString(),
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: textColor)),
                    ],
                  ),
                ),
              ),
          if (customFields.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Custom Fields',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            ...customFields.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.key,
                        style: TextStyle(
                            color: subTextColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(
                      e.value.toString(),
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: textColor),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ],
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
          category: 'dl_services',
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
                .collection('dl_services')
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
          .collection('dl_services')
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

  Future<void> _editNotes(BuildContext context, {bool isNew = false}) async {
    final controller = TextEditingController(
      text: isNew ? '' : (serviceDetails['remarks'] ?? ''),
    );

    final bool? shouldSave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Notes'),
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

    final notes = controller.text.trim();
    try {
      final targetId = _workspaceController.currentSchoolId.value.isNotEmpty
          ? _workspaceController.currentSchoolId.value
          : (FirebaseAuth.instance.currentUser?.uid ?? '');

      final base = FirebaseFirestore.instance.collection('users').doc(targetId);
      var collection = 'dl_services';
      var snap = await base.collection(collection).doc(_docId).get();
      if (!snap.exists) {
        final altSnap =
            await base.collection('deactivated_dl_services').doc(_docId).get();
        if (altSnap.exists) {
          collection = 'deactivated_dl_services';
        }
      }
      await base
          .collection(collection)
          .doc(_docId)
          .set({'remarks': notes}, SetOptions(merge: true));

      setState(() {
        serviceDetails['remarks'] = notes;
      });

      Get.snackbar(
        'Success',
        'Notes updated.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update notes: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _clearNotes(BuildContext context) async {
    if ((serviceDetails['remarks'] ?? '').toString().trim().isEmpty) {
      return;
    }

    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Notes'),
        content: const Text(
          'Are you sure you want to delete all notes for this DL service?',
        ),
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
      final targetId = _workspaceController.currentSchoolId.value.isNotEmpty
          ? _workspaceController.currentSchoolId.value
          : (FirebaseAuth.instance.currentUser?.uid ?? '');

      final base = FirebaseFirestore.instance.collection('users').doc(targetId);
      var collection = 'dl_services';
      var snap = await base.collection(collection).doc(_docId).get();
      if (!snap.exists) {
        final altSnap =
            await base.collection('deactivated_dl_services').doc(_docId).get();
        if (altSnap.exists) {
          collection = 'deactivated_dl_services';
        }
      }
      await base
          .collection(collection)
          .doc(_docId)
          .update({'remarks': FieldValue.delete()});

      setState(() {
        serviceDetails.remove('remarks');
      });

      Get.snackbar(
        'Success',
        'Notes deleted.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete notes: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showPdfPreview(BuildContext context, Uint8List pdfBytes) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfPreviewScreen(pdfBytes: pdfBytes),
      ),
    );
  }

  Future<void> _shareServiceDetails(BuildContext context) async {
    bool includePayment = false;

    final bool? shouldGenerate = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 30),
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

        if (companyData['hasCompanyProfile'] != true) {
          throw 'Please set up your Company Profile first';
        }

        // Fetch student image
        Uint8List? studentImage;
        if (serviceDetails['image'] != null &&
            serviceDetails['image'].toString().isNotEmpty) {
          studentImage =
              await ImageCacheService().fetchAndCache(serviceDetails['image']);
        }

        // Fetch company logo
        Uint8List? logoBytes;
        if (companyData['companyLogo'] != null &&
            companyData['companyLogo'].toString().isNotEmpty) {
          logoBytes = await ImageCacheService()
              .fetchAndCache(companyData['companyLogo']);
        }

        return await PdfService.generatePdf(
          title: 'Service Details',
          data: serviceDetails,
          includePayment: includePayment,
          imageBytes: studentImage,
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
      _showPdfPreview(context, pdfBytes);
    }
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

  Future<void> _openDlAdditionalInfoSheet(BuildContext context) async {
    final additionalInfo =
        serviceDetails['additionalInfo'] as Map<String, dynamic>?;

    final result = await showAdditionalInfoSheet(
      context: context,
      type: AdditionalInfoType.dlService,
      collection: 'dl_services',
      documentId: _docId,
      existingData: additionalInfo,
    );

    if (result == true) {
      try {
        final service = AdditionalInfoService();
        final updated =
            await service.getDlServiceAdditionalInfo(documentId: _docId);
        if (mounted) {
          setState(() {
            if (updated != null) {
              serviceDetails['additionalInfo'] = updated;
            }
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {});
        }
      }
    }
  }

  void _showContactOptions(BuildContext context, String phone) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.call, color: Colors.green),
              title: const Text('Call Customer'),
              onTap: () async {
                final uri = Uri.parse('tel:$phone');
                if (await canLaunchUrl(uri)) launchUrl(uri);
              },
            ),
            ListTile(
              leading: const Icon(Icons.message, color: Colors.blue),
              title: const Text('WhatsApp'),
              onTap: () async {
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
}
