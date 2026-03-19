import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:drivemate/constants/colors.dart';
import 'package:drivemate/screens/widget/custom_back_button.dart';
import 'package:drivemate/controller/workspace_controller.dart';
import 'package:drivemate/services/ownership_service.dart';
import 'package:drivemate/screens/dashboard/form/edit_forms/edit_vehicle_details_form.dart';
import 'package:drivemate/screens/profile/action_button.dart';
import 'package:intl/intl.dart';
import 'package:drivemate/utils/payment_utils.dart';
import 'package:drivemate/services/image_cache_service.dart';
import 'package:drivemate/utils/image_utils.dart';
import 'package:drivemate/screens/dashboard/list/widgets/shimmer_loading_list.dart';
import 'package:drivemate/services/additional_info_service.dart';
import 'package:drivemate/widgets/soft_delete_button.dart';
import 'package:drivemate/services/soft_delete_service.dart';
import 'package:drivemate/screens/profile/dialog_box.dart';
import 'package:image_picker/image_picker.dart';
import 'package:drivemate/services/storage_service.dart';
import 'package:drivemate/utils/loading_utils.dart';
import 'package:drivemate/screens/dashboard/list/details/pdf_preview_screen.dart';
import 'package:drivemate/screens/dashboard/list/details/document_preview_screen.dart';
import 'package:drivemate/services/pdf_service.dart';
import 'package:drivemate/screens/dashboard/list/widgets/details_tabs_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:drivemate/widgets/additional_info_sheet.dart';
import 'package:drivemate/utils/date_utils.dart';
import 'package:drivemate/utils/test_utils.dart';

class RCDetailsPage extends StatefulWidget {
  final Map<String, dynamic> vehicleDetails;

  const RCDetailsPage({required this.vehicleDetails, super.key});

  @override
  State<RCDetailsPage> createState() => _RCDetailsPageState();
}

class _RCDetailsPageState extends State<RCDetailsPage> {
  late Map<String, dynamic> vehicleDetails;
  final List<String> _selectedTransactionIds = [];
  static const Color kAccentRed = Color.fromRGBO(241, 135, 71, 1);
  final WorkspaceController _workspaceController =
      Get.find<WorkspaceController>();
  bool _isTransactionHistoryExpanded = false;

  final TextStyle labelStyle = const TextStyle(
      fontFamily: 'Inter',
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: Color(0xFF000000),
      height: 15.73 / 13);
  final TextStyle valueStyle = const TextStyle(
      fontFamily: 'Inter',
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: Color(0xFF747474),
      height: 15.73 / 13);

  late final String _docId = (widget.vehicleDetails['studentId'] ??
          widget.vehicleDetails['id'] ??
          widget.vehicleDetails['recordId'])
      .toString();

  List<Map<String, dynamic>> _cachedPayments = [];

  @override
  void initState() {
    super.initState();
    vehicleDetails = Map.from(widget.vehicleDetails);
    _initStreams();
  }

  late Stream<DocumentSnapshot> _mainStream;
  late Stream<QuerySnapshot> _paymentsStream;
  late Stream<QuerySnapshot> _extraFeesStream;
  late Stream<QuerySnapshot> _documentsStream;
  late Stream<QuerySnapshot> _notesStream;
  String _collectionName = 'rc_services';

  void _initStreams() {
    final targetId = _workspaceController.currentSchoolId.value.isNotEmpty
        ? _workspaceController.currentSchoolId.value
        : (FirebaseAuth.instance.currentUser?.uid ?? '');

    // Initialize with empty streams to prevent late init errors during first build
    _mainStream = Stream<DocumentSnapshot>.empty();
    _paymentsStream = Stream<QuerySnapshot>.empty();
    _extraFeesStream = Stream<QuerySnapshot>.empty();
    _documentsStream = Stream<QuerySnapshot>.empty();
    _notesStream = Stream<QuerySnapshot>.empty();

    final base = FirebaseFirestore.instance.collection('users').doc(targetId);
    base.collection('rc_services').doc(_docId).get().then((snap) async {
      _collectionName = snap.exists ? 'rc_services' : 'deactivated_rc_services';

      _mainStream = base.collection(_collectionName).doc(_docId).snapshots();

      // Check if subcollections were moved or still in original collection
      String subCollectionPath = _collectionName;
      if (_collectionName == 'deactivated_rc_services') {
        // Check if payments exist in deactivated collection
        final paymentSnap = await base
            .collection('deactivated_rc_services')
            .doc(_docId)
            .collection('payments')
            .limit(1)
            .get();
        if (paymentSnap.docs.isEmpty) {
          // If no payments in deactivated, check if they are still in rc_services
          final originalPaymentSnap = await base
              .collection('rc_services')
              .doc(_docId)
              .collection('payments')
              .limit(1)
              .get();
          if (originalPaymentSnap.docs.isNotEmpty) {
            subCollectionPath = 'rc_services';
          }
        }
      }

      _paymentsStream = base
          .collection(subCollectionPath)
          .doc(_docId)
          .collection('payments')
          .orderBy('date', descending: true)
          .snapshots();
      _extraFeesStream = base
          .collection(subCollectionPath)
          .doc(_docId)
          .collection('extra_fees')
          .orderBy('date', descending: true)
          .snapshots();
      _documentsStream = base
          .collection(subCollectionPath)
          .doc(_docId)
          .collection('documents')
          .orderBy('timestamp', descending: true)
          .snapshots();
      _notesStream = base
          .collection(subCollectionPath)
          .doc(_docId)
          .collection('notes')
          .orderBy('timestamp', descending: true)
          .snapshots();
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark ? Colors.grey : Colors.grey[700]!;

    final targetId = _workspaceController.currentSchoolId.value.isNotEmpty
        ? _workspaceController.currentSchoolId.value
        : (FirebaseAuth.instance.currentUser?.uid ?? '');

    return StreamBuilder<DocumentSnapshot>(
      stream: _mainStream,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          vehicleDetails = Map<String, dynamic>.from(
              snapshot.data!.data() as Map<String, dynamic>);
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            title: Text('RC Details', style: TextStyle(color: textColor)),
            elevation: 0,
            leading: const CustomBackButton(),
            actions: [
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: subTextColor),
                onSelected: (value) {
                  if (value == 'pdf') {
                    _shareRCDetails(context);
                  } else if (value == 'edit') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditVehicleDetailsForm(
                          initialValues: vehicleDetails,
                          items: const [
                            'Transfer of Ownership',
                            'Re-Registration',
                            'Hypothecation Addition',
                            'Hypothecation Termination',
                            'Duplicate RC',
                            'Fitness Renewal',
                            'Permit Renewal',
                            'Tax Payment',
                            'Registration Renewal',
                            'Echellan',
                            'Other'
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
                  if (_collectionName == 'rc_services')
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
          body: Builder(builder: (context) {
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
                    _buildTabSection(
                        context,
                        targetId,
                        snapshot.data
                            as DocumentSnapshot<Map<String, dynamic>>?),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }

  void _confirmSoftDelete(BuildContext context, String targetId) {
    showCustomConfirmationDialog(
      context,
      'Move to Recycle Bin?',
      'Move "${vehicleDetails['vehicleNumber'] ?? 'RC Service'}" to recycle bin?\n\nIt will be automatically deleted after 90 days if not restored.',
      () async {
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) throw Exception('User not logged in');

          final docRef = FirebaseFirestore.instance
              .collection('users')
              .doc(targetId)
              .collection(_collectionName)
              .doc(vehicleDetails['rcServiceId']?.toString() ??
                  vehicleDetails['id']?.toString() ??
                  '');

          await SoftDeleteService.softDelete(
            docRef: docRef,
            userId: user.uid,
            documentName: vehicleDetails['vehicleNumber'] ?? 'RC Service',
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
                color: kAccentRed.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.directions_car_outlined,
                color: kAccentRed, size: 40),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(vehicleDetails['vehicleNumber'] ?? 'N/A',
                    style: TextStyle(
                        color: textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Builder(builder: (context) {
                  String serviceLabel =
                      vehicleDetails['service']?.toString().trim() ?? '';
                  if (serviceLabel.isEmpty &&
                      vehicleDetails['serviceTypes'] is List) {
                    final list = (vehicleDetails['serviceTypes'] as List)
                        .where((e) => e != null && e.toString().isNotEmpty)
                        .map((e) => e.toString())
                        .toList();
                    if (list.isNotEmpty) {
                      serviceLabel = list.join(', ');
                      if (list.contains('Other') &&
                          (vehicleDetails['otherService']
                                  ?.toString()
                                  .isNotEmpty ??
                              false)) {
                        serviceLabel = serviceLabel.replaceAll(
                            'Other', vehicleDetails['otherService']);
                      }
                    }
                  }
                  if (serviceLabel.isEmpty &&
                      (vehicleDetails['cov']?.toString().isNotEmpty ?? false)) {
                    serviceLabel = vehicleDetails['cov'].toString();
                  }
                  if (serviceLabel.isEmpty) serviceLabel = 'N/A';
                  return Text('Service: $serviceLabel',
                      style: TextStyle(color: subTextColor, fontSize: 14));
                }),
                const SizedBox(height: 8),
                if (vehicleDetails['status'] != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6)),
                    child: Text(
                        vehicleDetails['status'].toString().toUpperCase(),
                        style: const TextStyle(
                            color: Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
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
                    'label': 'Service',
                    'value': vehicleDetails['serviceType'] ?? 'N/A'
                  },
                  {
                    'label': 'Full Name',
                    'value': vehicleDetails['fullName'] ?? 'N/A'
                  },
                  {
                    'label': 'Guardian',
                    'value': vehicleDetails['guardianName'] ?? 'N/A'
                  },
                  {
                    'label': 'Mobile',
                    'value': vehicleDetails['mobileNumber'] ?? 'N/A'
                  },
                  {
                    'label': 'Emergency',
                    'value': vehicleDetails['emergencyNumber'] ?? 'N/A'
                  },
                  {
                    'label': 'Blood Group',
                    'value': vehicleDetails['bloodGroup'] ?? 'N/A'
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
                    'value': vehicleDetails['house'] ?? 'N/A'
                  },
                  {'label': 'Place', 'value': vehicleDetails['place'] ?? 'N/A'},
                  {
                    'label': 'Post Office',
                    'value': vehicleDetails['post'] ?? 'N/A'
                  },
                  {
                    'label': 'District',
                    'value': vehicleDetails['district'] ?? 'N/A'
                  },
                  {
                    'label': 'PIN Code',
                    'value': vehicleDetails['pin'] ?? 'N/A'
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

  int _activeTab = 0;

  Widget _buildTabSection(BuildContext context, String targetId,
      DocumentSnapshot<Map<String, dynamic>>? rcSnapshot) {
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
          child: _getTabWidget(context, targetId, rcSnapshot),
        ),
      ],
    );
  }

  Widget _getTabWidget(BuildContext context, String targetId,
      DocumentSnapshot<Map<String, dynamic>>? rcSnapshot) {
    switch (_activeTab) {
      case 0:
        return _buildPaymentTab(context, targetId, rcSnapshot);
      case 1:
        return _buildDocumentsTab(context, targetId);
      case 2:
        return _buildNotesTab(context);
      case 3:
        return _buildAdditionalTab(context);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildAdditionalTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey : Colors.grey[700]!;
    final additionalInfo =
        vehicleDetails['additionalInfo'] as Map<String, dynamic>?;
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
            TextButton.icon(
              onPressed: () => _openRcAdditionalInfoSheet(context),
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
          if ((additionalInfo['applicationNumber'] ?? '').toString().isNotEmpty)
            _buildAdditionalInfoRow(
              'Application Number',
              additionalInfo['applicationNumber'].toString(),
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

  Widget _buildAdditionalInfoRow(
      String label, String value, Color textColor, Color subTextColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: subTextColor, fontSize: 11)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
                color: textColor, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Future<void> _openRcAdditionalInfoSheet(BuildContext context) async {
    final additionalInfo =
        vehicleDetails['additionalInfo'] as Map<String, dynamic>?;

    final result = await showAdditionalInfoSheet(
      context: context,
      type: AdditionalInfoType.rcService,
      collection: 'rc_services',
      documentId: _docId,
      existingData: additionalInfo,
    );

    if (result == true) {
      try {
        final service = AdditionalInfoService();
        final updated =
            await service.getRcServiceAdditionalInfo(documentId: _docId);
        if (mounted) {
          setState(() {
            if (updated != null) {
              vehicleDetails['additionalInfo'] = updated;
            }
          });
        }
      } catch (_) {
        if (mounted) setState(() {});
      }
    }
  }

  Widget _buildPaymentTab(BuildContext context, String targetId,
      DocumentSnapshot<Map<String, dynamic>>? snapshot) {
    if (snapshot == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final data = snapshot.data() ?? {};
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
                  onPressed: () => PaymentUtils.showAddExtraFeeDialog(
                      context: context,
                      doc: snapshot,
                      targetId: targetId,
                      category: 'rc_services'),
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
        _buildTransactionHistory(context, targetId),
        const SizedBox(height: 24),
        const Text(
          'Additional Fees',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 12),
        _buildExtraFees(context, targetId),
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

  Widget _buildTransactionHistory(BuildContext context, String targetId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _paymentsStream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final docs = snapshot.data?.docs ?? [];
          _cachedPayments = docs.map((d) {
            final map = d.data() as Map<String, dynamic>;
            map['id'] = d.id;
            map['docRef'] = d;
            return map;
          }).toList();
          _cachedPayments.sort((a, b) =>
              (b['date'] as Timestamp).compareTo(a['date'] as Timestamp));
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
              trailing: PopupMenuButton<String>(
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
                          leading:
                              Icon(Icons.delete, color: Colors.red, size: 18),
                          title: Text('Delete',
                              style: TextStyle(color: Colors.red)),
                          dense: true)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _handleTransactionAction(
      String action, Map<String, dynamic> data, String targetId) async {
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(targetId)
        .collection(_collectionName)
        .doc(_docId);
    if (action == 'edit') {
      await PaymentUtils.showEditPaymentDialog(
        context: context,
        docRef: docRef,
        paymentDoc: data['docRef'] as DocumentSnapshot,
        targetId: targetId,
        category: 'rc_services',
      );
    } else if (action == 'delete') {
      await PaymentUtils.deletePayment(
        context: context,
        studentRef: docRef,
        paymentDoc: data['docRef'] as DocumentSnapshot,
        targetId: targetId,
      );
    }
    setState(() {});
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
          studentDetails: vehicleDetails,
          transactions: selectedPayments,
          companyLogoBytes: logoBytes,
        );
      });
      if (pdfBytes != null) _showPdfPreview(context, pdfBytes);
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
          studentName: vehicleDetails['fullName'],
          studentPhone: vehicleDetails['mobileNumber'],
          fileName: 'rc_${vehicleDetails['vehicleNumber']}.pdf',
        ),
      ),
    );
  }

  Widget _buildExtraFees(BuildContext context, String targetId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _extraFeesStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
          return const SizedBox.shrink();
        final docs = snapshot.data!.docs;
        return Column(
          children: [
            const Row(children: [
              Text('Additional Fees',
                  style: TextStyle(fontWeight: FontWeight.bold))
            ]),
            const SizedBox(height: 12),
            ...docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final date = (data['date'] as Timestamp).toDate();
              final isPaid = data['status'] == 'paid';
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                        color: isPaid
                            ? Colors.green.withOpacity(0.5)
                            : Colors.grey[200]!)),
                child: ListTile(
                  title: Text(data['description'] ?? 'Fee',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Rs. ${data['amount']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isPaid)
                        TextButton(
                            onPressed:
                                () =>
                                    PaymentUtils.showCollectExtraFeeDialog(
                                        context: context,
                                        docRef: FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(targetId)
                                            .collection('rc_services')
                                            .doc(_docId),
                                        feeDoc: doc,
                                        targetId: targetId,
                                        branchId: _workspaceController
                                            .currentBranchId.value),
                            child: const Text('Collect')),
                      IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              color: Colors.blue, size: 20),
                          onPressed: () => PaymentUtils.showEditExtraFeeDialog(
                              context: context,
                              docRef: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(targetId)
                                  .collection('rc_services')
                                  .doc(_docId),
                              feeDoc: doc,
                              targetId: targetId,
                              category: 'rc_services')),
                      IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red, size: 20),
                          onPressed: () => PaymentUtils.deleteExtraFee(
                              context: context,
                              docRef: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(targetId)
                                  .collection('rc_services')
                                  .doc(_docId),
                              feeDoc: doc,
                              targetId: targetId)),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
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
            if (docs.isEmpty)
              return const Center(
                  child: Text('No documents uploaded yet',
                      style: TextStyle(color: Colors.grey)));
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
                return ListTile(
                  leading: const Icon(Icons.file_present, color: kAccentRed),
                  title: Text(name),
                  subtitle: subtitle != null ? Text(subtitle) : null,
                  trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () =>
                          _deleteDocument(docs[index].id, targetId)),
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
                (vehicleDetails['remarks'] ?? '').toString().trim();

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
          vehicleDetails['remarks'] = controller.text.trim();
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
          vehicleDetails.remove('remarks');
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

  Future<void> _shareRCDetails(BuildContext context) async {
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

        Uint8List? logoBytes;
        if (companyData['companyLogo'] != null &&
            companyData['companyLogo'].toString().isNotEmpty) {
          logoBytes = await ImageCacheService()
              .fetchAndCache(companyData['companyLogo']);
        }
        return await PdfService.generatePdf(
            title: 'RC Service Details',
            data: vehicleDetails,
            includePayment: includePayment,
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
            category: 'rc_services');
      }
    });
  }

  Future<void> _uploadDocument(BuildContext context, String targetId) async {
    final picker = ImagePicker();
    final image =
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
                .uploadFile(file: image, path: 'rc_docs/$_docId');
            await FirebaseFirestore.instance
                .collection('users')
                .doc(targetId)
                .collection('rc_services')
                .doc(_docId)
                .collection('documents')
                .add({
              'name': nameController.text.trim(),
              'url': url,
              'timestamp': FieldValue.serverTimestamp(),
            });
          }, message: 'Uploading document...');
          Get.snackbar('Success', 'Document uploaded');
        } catch (e) {
          Get.snackbar('Error', 'Upload failed: $e');
        }
      }
    }
  }

  Future<void> _deleteDocument(String docId, String targetId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetId)
          .collection('rc_services')
          .doc(_docId)
          .collection('documents')
          .doc(docId)
          .delete();
      Get.snackbar('Success', 'Document deleted');
    } catch (e) {
      Get.snackbar('Error', 'Deletion failed: $e');
    }
  }

  Widget buildTappableMobileRow(BuildContext context, String phone) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Mobile Number:', style: labelStyle),
          GestureDetector(
            onTap: () => _showContactOptions(context, phone),
            child: Text(phone,
                style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kAccentRed,
                    decoration: TextDecoration.underline,
                    height: 15.73 / 13)),
          ),
        ],
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
              leading: const FaIcon(FontAwesomeIcons.whatsapp,
                  color: Color(0xFF25D366)),
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

  Widget buildTableRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label:', style: labelStyle),
          Flexible(
              child: Text('$value',
                  style: valueStyle, textAlign: TextAlign.right)),
        ],
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
