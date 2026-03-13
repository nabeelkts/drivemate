import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:drivemate/constants/colors.dart';
import 'package:drivemate/screens/widget/custom_back_button.dart';
import 'package:drivemate/controller/workspace_controller.dart';
import 'package:drivemate/screens/dashboard/form/edit_forms/edit_vehicle_details_form.dart';
import 'package:intl/intl.dart';
import 'package:drivemate/utils/payment_utils.dart';
import 'package:drivemate/screens/dashboard/list/widgets/shimmer_loading_list.dart';
import 'package:drivemate/widgets/soft_delete_button.dart';
import 'package:image_picker/image_picker.dart';
import 'package:drivemate/services/storage_service.dart';
import 'package:drivemate/utils/loading_utils.dart';
import 'package:drivemate/screens/dashboard/list/details/pdf_preview_screen.dart';
import 'package:drivemate/screens/dashboard/list/details/document_preview_screen.dart';
import 'package:drivemate/services/pdf_service.dart';
import 'package:drivemate/services/image_cache_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:drivemate/widgets/additional_info_sheet.dart';
import 'package:drivemate/services/additional_info_service.dart';
import 'package:drivemate/utils/date_utils.dart';
import 'package:drivemate/utils/test_utils.dart';

class VehicleDetailsPage extends StatefulWidget {
  final Map<String, dynamic> vehicleDetails;

  const VehicleDetailsPage({required this.vehicleDetails, super.key});

  @override
  State<VehicleDetailsPage> createState() => _VehicleDetailsPageState();
}

class _VehicleDetailsPageState extends State<VehicleDetailsPage> {
  late Map<String, dynamic> vehicleDetails;
  static const Color kAccentRed = Color.fromRGBO(241, 135, 71, 1);
  final WorkspaceController _workspaceController =
      Get.find<WorkspaceController>();
  final List<String> _selectedTransactionIds = [];
  List<Map<String, dynamic>> _cachedPayments = [];

  late final String _docId = (widget.vehicleDetails['studentId'] ??
          widget.vehicleDetails['id'] ??
          widget.vehicleDetails['recordId'])
      .toString();

  late final Stream<DocumentSnapshot> _mainStream;
  late final Stream<QuerySnapshot> _paymentsStream;
  late final Stream<QuerySnapshot> _extraFeesStream;
  late final Stream<QuerySnapshot> _documentsStream;

  @override
  void initState() {
    super.initState();
    vehicleDetails = Map.from(widget.vehicleDetails);
    _initStreams();
  }

  void _initStreams() {
    final targetId = _workspaceController.currentSchoolId.value.isNotEmpty
        ? _workspaceController.currentSchoolId.value
        : (FirebaseAuth.instance.currentUser?.uid ?? '');

    _mainStream = FirebaseFirestore.instance
        .collection('users')
        .doc(targetId)
        .collection('vehicleDetails')
        .doc(_docId)
        .snapshots();
    _paymentsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(targetId)
        .collection('vehicleDetails')
        .doc(_docId)
        .collection('payments')
        .orderBy('date', descending: true)
        .snapshots();
    _extraFeesStream = FirebaseFirestore.instance
        .collection('users')
        .doc(targetId)
        .collection('vehicleDetails')
        .doc(_docId)
        .collection('extra_fees')
        .orderBy('date', descending: true)
        .snapshots();
    _documentsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(targetId)
        .collection('vehicleDetails')
        .doc(_docId)
        .collection('documents')
        .orderBy('timestamp', descending: true)
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
            title: Text('Vehicle Details', style: TextStyle(color: textColor)),
            elevation: 0,
            leading: const CustomBackButton(),
            actions: [
              IconButton(
                  icon: Icon(Icons.picture_as_pdf, color: subTextColor),
                  onPressed: () => _shareVehicleDetails(context)),
              SoftDeleteButton(
                docRef: FirebaseFirestore.instance
                    .collection('users')
                    .doc(targetId)
                    .collection('vehicleDetails')
                    .doc(_docId),
                documentName: vehicleDetails['vehicleNumber'] ?? 'Vehicle',
                onDeleteSuccess: () {
                  Get.snackbar('Success', 'Vehicle moved to recycle bin',
                      backgroundColor: Colors.green, colorText: Colors.white);
                },
              ),
              IconButton(
                icon: Icon(Icons.edit, color: subTextColor),
                onPressed: () async {
                  final updated = await Navigator.push<bool>(
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
                          'Tax Payment'
                        ],
                      ),
                    ),
                  );
                  if (updated == true) {
                    final targetId =
                        _workspaceController.currentSchoolId.value.isNotEmpty
                            ? _workspaceController.currentSchoolId.value
                            : (FirebaseAuth.instance.currentUser?.uid ?? '');

                    final snap = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(targetId)
                        .collection('vehicleDetails')
                        .doc(_docId)
                        .get();
                    if (snap.exists) {
                      setState(() {
                        vehicleDetails =
                            Map<String, dynamic>.from(snap.data()!);
                      });
                    }
                  }
                },
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
                    _buildProfileHeader(context),
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

  Widget _buildProfileHeader(BuildContext context) {
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
                Text('Owner: ${vehicleDetails['fullName'] ?? 'N/A'}',
                    style: TextStyle(color: subTextColor, fontSize: 14)),
                const SizedBox(height: 8),
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
                'Vehicle Information',
                [
                  {
                    'label': 'Vehicle Model',
                    'value':
                        (vehicleDetails['vehicleModel'] ?? 'N/A').toString()
                  },
                  {
                    'label': 'Chassis Number',
                    'value':
                        (vehicleDetails['chassisNumber'] ?? 'N/A').toString()
                  },
                  {
                    'label': 'Engine Number',
                    'value':
                        (vehicleDetails['engineNumber'] ?? 'N/A').toString()
                  },
                  {
                    'label': 'Mobile',
                    'value':
                        (vehicleDetails['mobileNumber'] ?? 'N/A').toString()
                  },
                ],
              ),
            ),
            if (vehicleDetails['cov'] == 'Transfer of Ownership') ...[
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoCard(
                  context,
                  'Address Information',
                  [
                    {
                      'label': 'House Name',
                      'value': (vehicleDetails['houseName'] ?? 'N/A').toString()
                    },
                    {
                      'label': 'Place',
                      'value': (vehicleDetails['place'] ?? 'N/A').toString()
                    },
                    {
                      'label': 'Post',
                      'value': (vehicleDetails['post'] ?? 'N/A').toString()
                    },
                    {
                      'label': 'District',
                      'value': (vehicleDetails['district'] ?? 'N/A').toString()
                    },
                    {
                      'label': 'PIN',
                      'value': (vehicleDetails['pin'] ?? 'N/A').toString()
                    },
                  ],
                ),
              ),
            ],
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
      DocumentSnapshot<Map<String, dynamic>>? vehicleSnapshot) {
    final tabs = [
      {'label': 'Payment', 'icon': Icons.account_balance_wallet},
      {'label': 'Documents', 'icon': Icons.description},
      {'label': 'Notes', 'icon': Icons.note},
      {'label': 'Additional', 'icon': Icons.info_outline},
    ];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(tabs.length, (index) {
              final isActive = _activeTab == index;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(tabs[index]['label'] as String),
                  selected: isActive,
                  onSelected: (selected) {
                    if (selected) setState(() => _activeTab = index);
                  },
                  avatar: Icon(
                    tabs[index]['icon'] as IconData,
                    size: 16,
                    color: isActive ? Colors.white : Colors.grey,
                  ),
                  selectedColor: kAccentRed,
                  labelStyle: TextStyle(
                    color: isActive
                        ? Colors.white
                        : (isDark ? Colors.grey : Colors.black87),
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                  backgroundColor: isDark ? Colors.grey[900] : Colors.grey[200],
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
              );
            }),
          ),
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
          child: _getTabWidget(context, targetId, vehicleSnapshot),
        ),
      ],
    );
  }

  Widget _getTabWidget(BuildContext context, String targetId,
      DocumentSnapshot<Map<String, dynamic>>? snapshot) {
    switch (_activeTab) {
      case 0:
        return _buildPaymentTab(context, targetId, snapshot);
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

  Widget _buildPaymentTab(BuildContext context, String targetId,
      DocumentSnapshot<Map<String, dynamic>>? snapshot) {
    if (snapshot == null) return const SizedBox.shrink();
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
                      category: 'vehicleDetails'),
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
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
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
                  const Icon(Icons.payment, color: Colors.green),
                ],
              ),
              title: Text('₹${(data['amount'] as num).toInt()}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.green)),
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
        .collection('vehicleDetails')
        .doc(_docId);
    if (action == 'edit') {
      await PaymentUtils.showEditPaymentDialog(
        context: context,
        docRef: docRef,
        paymentDoc: data['docRef'] as DocumentSnapshot,
        targetId: targetId,
        category: 'vehicleDetails',
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
        // Note: You may need to implement generateReceipt for vehicles or use a generic one
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
          fileName: 'vehicle_${vehicleDetails['vehicleNumber']}.pdf',
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
                                            .collection('vehicleDetails')
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
                                  .collection('vehicleDetails')
                                  .doc(_docId),
                              feeDoc: doc,
                              targetId: targetId,
                              category: 'vehicleDetails')),
                      IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red, size: 20),
                          onPressed: () => PaymentUtils.deleteExtraFee(
                              context: context,
                              docRef: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(targetId)
                                  .collection('vehicleDetails')
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
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Documents',
                style: TextStyle(fontWeight: FontWeight.bold)),
            IconButton(
                icon: const Icon(Icons.add_photo_alternate_outlined,
                    color: kAccentRed),
                onPressed: () => _uploadDocument(context, targetId)),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: _documentsStream,
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Center(
                child: Text(
                  'No documents uploaded yet',
                  style: TextStyle(color: Colors.grey),
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
    final hasNotes =
        (vehicleDetails['remarks'] ?? '').toString().trim().isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            color: isDark ? Colors.grey[900] : Colors.yellow[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.yellow[200]!,
            ),
          ),
          child: Text(
            hasNotes ? vehicleDetails['remarks'] : 'No remarks added yet.',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
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
            const Text('Additional Information',
                style: TextStyle(fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: () => _openAdditionalInfoSheet(context),
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
          if (vehicleDetails['registrationDate'] != null) ...[
            _buildInfoRow(
              'Registration Date',
              _formatDate(vehicleDetails['registrationDate']),
              textColor,
              subTextColor,
            ),
            const SizedBox(height: 8),
          ],
          ...additionalInfo.entries
              .where((e) => e.key != 'customFields' && e.key != 'updatedAt')
              .map(
                (e) => _buildInfoRow(
                  _prettyAdditionalLabel(e.key),
                  e.value.toString(),
                  textColor,
                  subTextColor,
                ),
              ),
          if (customFields.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Custom Fields',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
      ],
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    if (date is Timestamp)
      return DateFormat('dd MMM yyyy').format(date.toDate());
    if (date is String) return date;
    return 'N/A';
  }

  void _showReceiveMoneyDialog(BuildContext context, String targetId) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(targetId)
        .collection('vehicleDetails')
        .doc(_docId)
        .get()
        .then((snapshot) {
      if (snapshot.exists) {
        PaymentUtils.showReceiveMoneyDialog(
            context: context,
            doc: snapshot,
            targetId: targetId,
            branchId: _workspaceController.currentBranchId.value,
            category: 'vehicleDetails');
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
              hintText: 'Enter document name (e.g. RC Book)',
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
                .uploadFile(file: image, path: 'vehicle_docs/$_docId');
            await FirebaseFirestore.instance
                .collection('users')
                .doc(targetId)
                .collection('vehicleDetails')
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
          .collection('vehicleDetails')
          .doc(_docId)
          .collection('documents')
          .doc(docId)
          .delete();
      Get.snackbar('Success', 'Document deleted');
    } catch (e) {
      Get.snackbar('Error', 'Deletion failed: $e');
    }
  }

  Future<void> _shareVehicleDetails(BuildContext context) async {
    // PDF generation logic would go here
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
            TextSpan(text: value, style: TextStyle(color: textColor))
          ],
        ),
      ),
    );
  }

  String _prettyAdditionalLabel(String key) {
    switch (key) {
      case 'registrationRenewalOrFitnessExpiry':
        return 'Registration / Fitness Expiry';
      case 'insuranceExpiry':
        return 'Insurance Expiry';
      case 'taxExpiry':
        return 'Tax Expiry';
      case 'pollutionExpiry':
        return 'Pollution Expiry';
      case 'permitExpiry':
        return 'Permit Expiry';
      default:
        return key;
    }
  }

  Future<void> _openAdditionalInfoSheet(BuildContext context) async {
    final additionalInfo =
        vehicleDetails['additionalInfo'] as Map<String, dynamic>?;

    final isDeactivated = vehicleDetails['status'] == 'passed' ||
        vehicleDetails['deactivated'] == true;
    final collectionName =
        isDeactivated ? 'deactivated_vehicleDetails' : 'vehicleDetails';

    final result = await showAdditionalInfoSheet(
      context: context,
      type: AdditionalInfoType.rcService,
      collection: collectionName,
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
        if (mounted) {
          setState(() {});
        }
      }
    }
  }

  Widget _buildAdditionalInfoButton() {
    final additionalInfo =
        vehicleDetails['additionalInfo'] as Map<String, dynamic>?;
    final hasData = additionalInfo != null && additionalInfo.isNotEmpty;

    final isDeactivated = vehicleDetails['status'] == 'passed' ||
        vehicleDetails['deactivated'] == true;
    final collectionName =
        isDeactivated ? 'deactivated_vehicleDetails' : 'vehicleDetails';

    return IconButton(
      icon: Icon(
        hasData ? Icons.info : Icons.info_outline,
        color: hasData ? kPrimaryColor : Colors.grey,
      ),
      onPressed: () async {
        final result = await showAdditionalInfoSheet(
          context: context,
          type: AdditionalInfoType.rcService,
          collection: collectionName,
          documentId: _docId,
          existingData: additionalInfo,
        );
        if (result == true) {
          setState(() {});
        }
      },
      tooltip: 'Additional Information',
    );
  }

  Future<void> _editNotes(BuildContext context, {bool isNew = false}) async {
    final controller = TextEditingController(
      text: isNew ? '' : (vehicleDetails['remarks'] ?? ''),
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
      var collection = 'vehicleDetails';
      var snap = await base.collection(collection).doc(_docId).get();
      if (!snap.exists) {
        final altSnap = await base
            .collection('deactivated_vehicleDetails')
            .doc(_docId)
            .get();
        if (altSnap.exists) {
          collection = 'deactivated_vehicleDetails';
        }
      }
      await base
          .collection(collection)
          .doc(_docId)
          .set({'remarks': notes}, SetOptions(merge: true));

      setState(() {
        vehicleDetails['remarks'] = notes;
      });

      Get.snackbar(
        'Success',
        'Notes updated.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update notes: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _clearNotes(BuildContext context) async {
    if ((vehicleDetails['remarks'] ?? '').toString().trim().isEmpty) {
      return;
    }

    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Notes'),
        content: const Text(
          'Are you sure you want to delete all notes for this vehicle?',
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
      var collection = 'vehicleDetails';
      var snap = await base.collection(collection).doc(_docId).get();
      if (!snap.exists) {
        final altSnap = await base
            .collection('deactivated_vehicleDetails')
            .doc(_docId)
            .get();
        if (altSnap.exists) {
          collection = 'deactivated_vehicleDetails';
        }
      }
      await base
          .collection(collection)
          .doc(_docId)
          .update({'remarks': FieldValue.delete()});

      setState(() {
        vehicleDetails.remove('remarks');
      });

      Get.snackbar(
        'Success',
        'Notes deleted.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete notes: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
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
