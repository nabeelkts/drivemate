import 'dart:async';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/screens/widget/custom_back_button.dart';
import 'package:mds/controller/workspace_controller.dart';
import 'package:mds/screens/authentication/widgets/my_button.dart';
import 'package:mds/screens/dashboard/form/edit_forms/edit_vehicle_details_form.dart';
import 'package:intl/intl.dart';
import 'package:mds/utils/payment_utils.dart';
import 'package:mds/services/image_cache_service.dart';
import 'package:mds/utils/image_utils.dart';
import 'package:mds/screens/dashboard/list/widgets/shimmer_loading_list.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mds/widgets/additional_info_sheet.dart';
import 'package:mds/services/additional_info_service.dart';

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

  @override
  void initState() {
    super.initState();
    vehicleDetails = Map.from(widget.vehicleDetails);
    _initStreams();
  }

  late final Stream<DocumentSnapshot> _mainStream;
  late final Stream<QuerySnapshot> _paymentsStream;
  late final Stream<QuerySnapshot> _extraFeesStream;

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
        if (snapshot.hasData && snapshot.data!.exists)
          vehicleDetails = snapshot.data!.data() as Map<String, dynamic>;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            title: Text('RC Details', style: TextStyle(color: textColor)),
            elevation: 0,
            leading: const CustomBackButton(),
            actions: [
              _buildAdditionalInfoButton(),
              IconButton(
                icon: Icon(Icons.edit, color: subTextColor),
                onPressed: () => Navigator.push(
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
                            ))),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          spreadRadius: 2,
                          blurRadius: 10)
                    ],
                  ),
                  child: Column(
                    children: [
                      buildTableRow(
                          'Vehicle Number', vehicleDetails['vehicleNumber']),
                      const Divider(color: kDivider),
                      buildTableRow(
                          'Chassis Number', vehicleDetails['chassisNumber']),
                      const Divider(color: kDivider),
                      buildTableRow(
                          'Engine Number', vehicleDetails['engineNumber']),
                      const Divider(color: kDivider),
                      // ── Tappable mobile number ──
                      buildTappableMobileRow(context,
                          vehicleDetails['mobileNumber']?.toString() ?? 'N/A'),
                      const Divider(color: kDivider),
                      buildTableRow('Total Amount',
                          'Rs. ${vehicleDetails['totalAmount']}'),
                      const Divider(color: kDivider),
                      buildTableRow('Advance Amount',
                          'Rs. ${vehicleDetails['advanceAmount']}'),
                      const Divider(color: kDivider),
                      buildTableRow('Balance Amount',
                          'Rs. ${vehicleDetails['balanceAmount']}'),
                      const Divider(color: kDivider),
                      buildTableRow('Service', vehicleDetails['service']),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // ── Payment Actions ──────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10))),
                        onPressed: () => PaymentUtils.showReceiveMoneyDialog(
                            context: context,
                            doc: snapshot.data!
                                as DocumentSnapshot<Map<String, dynamic>>,
                            targetId: targetId,
                            category: 'vehicleDetails',
                            branchId:
                                _workspaceController.currentBranchId.value),
                        icon: const Icon(Icons.add_card, size: 20),
                        label: const Text('Add Payment'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                            foregroundColor: kAccentRed,
                            side: const BorderSide(color: kAccentRed),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10))),
                        onPressed: () => PaymentUtils.showAddExtraFeeDialog(
                            context: context,
                            doc: snapshot.data!
                                as DocumentSnapshot<Map<String, dynamic>>,
                            targetId: targetId,
                            category: 'vehicleDetails',
                            branchId:
                                _workspaceController.currentBranchId.value),
                        icon: const Icon(Icons.add_circle_outline, size: 20),
                        label: const Text('Add Fee'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Transaction History ──────────────────────────────────────
                StreamBuilder<QuerySnapshot>(
                  stream: _paymentsStream,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting)
                      return const ShimmerLoadingList();
                    final docs = snap.data?.docs ?? [];
                    List<Map<String, dynamic>> combinedDocs = docs.map((d) {
                      final map = d.data() as Map<String, dynamic>;
                      map['id'] = d.id;
                      map['docRef'] = d;
                      return map;
                    }).toList();
                    combinedDocs.sort((a, b) => (b['date'] as Timestamp)
                        .compareTo(a['date'] as Timestamp));
                    if (combinedDocs.isEmpty) return const SizedBox.shrink();

                    // Show only 2 items by default, expand to show all
                    final displayDocs = _isTransactionHistoryExpanded
                        ? combinedDocs
                        : combinedDocs.take(2).toList();
                    final hasMore = combinedDocs.length > 2;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Transaction History',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        ...displayDocs.map((data) {
                          final date = (data['date'] as Timestamp).toDate();
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color:
                                    isDark ? Colors.grey[900] : Colors.grey[50],
                                borderRadius: BorderRadius.circular(10)),
                            child: Row(
                              children: [
                                Icon(Icons.payment,
                                    color: Colors.green[400], size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text(data['description'] ?? 'Payment',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600)),
                                      Text('Rs. ${data['amount']}',
                                          style: TextStyle(
                                              color: Colors.green[600],
                                              fontWeight: FontWeight.bold)),
                                      Text(
                                          DateFormat('dd MMM yyyy, hh:mm a')
                                              .format(date),
                                          style: TextStyle(
                                              color: subTextColor,
                                              fontSize: 11)),
                                      if (data['mode'] != null)
                                        Text('Mode: ${data['mode']}',
                                            style: TextStyle(
                                                color: subTextColor,
                                                fontSize: 11)),
                                    ])),
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      size: 18, color: Colors.blue),
                                  onPressed: () =>
                                      PaymentUtils.showEditPaymentDialog(
                                          context: context,
                                          docRef: snapshot.data!.reference,
                                          paymentDoc: data['docRef'],
                                          targetId: targetId,
                                          category: 'vehicleDetails'),
                                ),
                              ],
                            ),
                          );
                        }),
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

                const SizedBox(height: 16),

                // ── Additional Fees ──────────────────────────────────────────
                StreamBuilder<QuerySnapshot>(
                  stream: _extraFeesStream,
                  builder: (context, snap) {
                    if (!snap.hasData || snap.data!.docs.isEmpty)
                      return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Additional Fees',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        ...snap.data!.docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final date = (data['date'] as Timestamp).toDate();
                          final isPaid = data['status'] == 'paid';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.grey[900]
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: isPaid
                                        ? Colors.green.withOpacity(0.3)
                                        : Colors.orange.withOpacity(0.3))),
                            child: Row(
                              children: [
                                Checkbox(
                                    value: _selectedTransactionIds
                                        .contains(doc.id),
                                    activeColor: kAccentRed,
                                    onChanged: isPaid
                                        ? (val) {
                                            setState(() {
                                              if (val == true)
                                                _selectedTransactionIds
                                                    .add(doc.id);
                                              else
                                                _selectedTransactionIds
                                                    .remove(doc.id);
                                            });
                                          }
                                        : null),
                                Expanded(
                                    child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8.0),
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(data['description'] ?? 'Fee',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold)),
                                              Text('Rs. ${data['amount']}',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600)),
                                              Text(
                                                  DateFormat('dd MMM yyyy')
                                                      .format(date),
                                                  style: TextStyle(
                                                      color: subTextColor,
                                                      fontSize: 11)),
                                              if (isPaid &&
                                                  data['paymentMode'] != null)
                                                Text(
                                                    'Mode: ${data['paymentMode']}',
                                                    style: TextStyle(
                                                        color: subTextColor,
                                                        fontSize: 11)),
                                              if (data['note'] != null &&
                                                  data['note']
                                                      .toString()
                                                      .trim()
                                                      .isNotEmpty)
                                                Text('Note: ${data['note']}',
                                                    style: TextStyle(
                                                        color: subTextColor,
                                                        fontSize: 11),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis),
                                            ]))),
                                Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (isPaid)
                                              const Padding(
                                                  padding: EdgeInsets.only(
                                                      right: 8.0),
                                                  child: Chip(
                                                      label: Text('Paid',
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 11)),
                                                      backgroundColor:
                                                          Colors.green,
                                                      visualDensity:
                                                          VisualDensity.compact,
                                                      padding: EdgeInsets.zero))
                                            else
                                              TextButton(
                                                  onPressed: () =>
                                                      PaymentUtils.showCollectExtraFeeDialog(
                                                          context: context,
                                                          docRef: snapshot
                                                              .data!.reference,
                                                          feeDoc: doc,
                                                          targetId: targetId,
                                                          branchId:
                                                              _workspaceController
                                                                  .currentBranchId
                                                                  .value),
                                                  style: TextButton.styleFrom(
                                                      foregroundColor:
                                                          Colors.green),
                                                  child: const Text('Collect',
                                                      style: TextStyle(fontSize: 12))),
                                          ]),
                                      Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                                icon: const Icon(
                                                    Icons.edit_outlined,
                                                    size: 18,
                                                    color: Colors.blue),
                                                onPressed: () => PaymentUtils
                                                    .showEditExtraFeeDialog(
                                                        context: context,
                                                        docRef: snapshot
                                                            .data!.reference,
                                                        feeDoc: doc,
                                                        targetId: targetId,
                                                        category:
                                                            'vehicleDetails'),
                                                tooltip: 'Edit'),
                                            IconButton(
                                                icon: const Icon(
                                                    Icons.delete_outline,
                                                    size: 18,
                                                    color: Colors.red),
                                                onPressed: () =>
                                                    PaymentUtils.deleteExtraFee(
                                                        context: context,
                                                        docRef: snapshot
                                                            .data!.reference,
                                                        feeDoc: doc,
                                                        targetId: targetId),
                                                tooltip: 'Delete'),
                                          ]),
                                    ]),
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
          ),
        );
      },
    );
  }

  // ── Tappable mobile row ─────────────────────────────────────────────────────

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

  // ── Additional Info button for AppBar ──────────────────────────────────────

  Widget _buildAdditionalInfoButton() {
    final additionalInfo =
        vehicleDetails['additionalInfo'] as Map<String, dynamic>?;
    final hasData = additionalInfo != null && additionalInfo.isNotEmpty;

    // Determine the correct collection based on record status
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
}
