import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/screens/widget/custom_back_button.dart';
import 'package:mds/screens/dashboard/form/edit_forms/edit_vehicle_details_form.dart';
import 'package:mds/screens/widget/base_form_widget.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:mds/controller/workspace_controller.dart';
import 'package:mds/screens/dashboard/list/widgets/shimmer_loading_list.dart';
import 'package:mds/utils/payment_utils.dart';
import 'package:mds/utils/date_utils.dart';
import 'package:http/http.dart' as http;
import 'package:mds/screens/dashboard/list/details/pdf_preview_screen.dart';
import 'package:mds/services/pdf_service.dart';
import 'package:mds/services/image_cache_service.dart';
import 'package:mds/utils/loading_utils.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class VehicleDetailsPage extends StatefulWidget {
  final Map<String, dynamic> vehicleDetails;

  const VehicleDetailsPage({required this.vehicleDetails, super.key});

  @override
  State<VehicleDetailsPage> createState() => _VehicleDetailsPageState();
}

class _VehicleDetailsPageState extends State<VehicleDetailsPage> {
  static const Color kAccentRed = Color.fromRGBO(241, 135, 71, 1);
  late Map<String, dynamic> vehicleDetails;
  final List<String> _selectedTransactionIds = [];
  final WorkspaceController _workspaceController =
      Get.find<WorkspaceController>();
  bool _isTransactionHistoryExpanded = false;

  @override
  void initState() {
    super.initState();
    vehicleDetails = Map.from(widget.vehicleDetails);
  }

  @override
  Widget build(BuildContext context) {
    final targetId = _workspaceController.currentSchoolId.value.isNotEmpty
        ? _workspaceController.currentSchoolId.value
        : (FirebaseAuth.instance.currentUser?.uid ?? '');

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(targetId)
          .collection('vehicleDetails')
          .doc(vehicleDetails['studentId'].toString())
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists)
          vehicleDetails = snapshot.data!.data() as Map<String, dynamic>;

        return BaseFormWidget(
          title: 'Vehicle Details',
          onBack: () => Navigator.pop(context),
          actions: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: kPrimaryColor),
              onPressed: () => _shareVehicleDetails(context),
              tooltip: 'Export PDF',
            ),
            IconButton(
              icon: Icon(Icons.edit,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87),
              onPressed: () {
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
                                'Tax Payment'
                              ],
                            )));
              },
            ),
          ],
          children: [
            FormSection(
              title: 'Personal Details',
              children: [
                _buildDetailRow(
                    'Full Name', vehicleDetails['fullName'] ?? 'N/A'),
                // ── Tappable mobile number ──
                _buildTappableMobileRow(
                    context, vehicleDetails['mobileNumber'] ?? 'N/A'),
              ],
            ),
            FormSection(
              title: 'Vehicle Details',
              children: [
                _buildDetailRow(
                    'Vehicle Number', vehicleDetails['vehicleNumber'] ?? 'N/A'),
                _buildDetailRow(
                    'Vehicle Model', vehicleDetails['vehicleModel'] ?? 'N/A'),
                _buildDetailRow(
                    'Chassis Number', vehicleDetails['chassisNumber'] ?? 'N/A'),
                _buildDetailRow(
                    'Engine Number', vehicleDetails['engineNumber'] ?? 'N/A'),
                _buildDetailRow('Service Type', vehicleDetails['cov'] ?? 'N/A'),
              ],
            ),
            if (vehicleDetails['cov'] == 'Transfer of Ownership')
              FormSection(
                title: 'Address',
                children: [
                  _buildDetailRow(
                      'House Name', vehicleDetails['houseName'] ?? 'N/A'),
                  _buildDetailRow('Place', vehicleDetails['place'] ?? 'N/A'),
                  _buildDetailRow('Post', vehicleDetails['post'] ?? 'N/A'),
                  _buildDetailRow(
                      'District', vehicleDetails['district'] ?? 'N/A'),
                  _buildDetailRow('PIN', vehicleDetails['pin'] ?? 'N/A'),
                ],
              ),
            _buildPaymentOverviewCard(context, targetId, snapshot),
            if (vehicleDetails['registrationDate'] != null)
              FormSection(
                title: 'Registration',
                children: [
                  _buildDetailRow('Registration Date',
                      _formatDate(vehicleDetails['registrationDate']))
                ],
              ),
          ],
        );
      },
    );
  }

  // ── Tappable mobile row for FormSection ─────────────────────────────────────

  Widget _buildTappableMobileRow(BuildContext context, String phone) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
              flex: 2,
              child: Text('Mobile Number',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: kPrimaryColor))),
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: () => _showContactOptions(context, phone),
              child: Text(phone,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: kAccentRed,
                      decoration: TextDecoration.underline)),
            ),
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

  Future<void> _shareReceiptToWhatsApp(String phone, Uint8List pdfBytes) async {
    try {
      final dir = await getTemporaryDirectory();
      final name = (vehicleDetails['fullName'] ?? 'vehicle')
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
            text: 'Receipt for ${vehicleDetails['fullName'] ?? 'Customer'}');
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error sending to WhatsApp: $e')));
    }
  }

  Widget _buildPaymentOverviewCard(BuildContext context, String targetId,
      AsyncSnapshot<DocumentSnapshot> snapshot) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark ? Colors.grey : Colors.grey[700]!;
    final baseDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(targetId)
        .collection('vehicleDetails')
        .doc(vehicleDetails['studentId'].toString());

    double total =
        double.tryParse(vehicleDetails['totalAmount']?.toString() ?? '0') ?? 0;
    double balance =
        double.tryParse(vehicleDetails['balanceAmount']?.toString() ?? '0') ??
            0;
    double paidAmount = total - balance;
    double progressValue = total > 0 ? paidAmount / total : 0;

    return FormSection(
      title: 'Payment Overview',
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Total Fee:',
                  style: TextStyle(color: subTextColor, fontSize: 12)),
              Text('Rs. $total',
                  style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ]),
            Row(children: [
              if (_selectedTransactionIds.isNotEmpty)
                IconButton(
                    icon: const Icon(Icons.receipt_long, color: kPrimaryColor),
                    onPressed: _generateSelectedReceipts,
                    tooltip: 'Receipt for Selected'),
              IconButton(
                  icon: const Icon(Icons.post_add, color: Colors.blue),
                  onPressed: () {
                    if (snapshot.hasData)
                      PaymentUtils.showAddExtraFeeDialog(
                          context: context,
                          doc: snapshot.data!
                              as DocumentSnapshot<Map<String, dynamic>>,
                          targetId: targetId,
                          category: 'vehicleDetails');
                  },
                  tooltip: 'Add Extra Fee'),
              IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  onPressed: () {
                    if (snapshot.hasData)
                      PaymentUtils.showAddPaymentDialog(
                          context: context,
                          doc: snapshot.data!
                              as DocumentSnapshot<Map<String, dynamic>>,
                          targetId: targetId,
                          category: 'vehicleDetails');
                  },
                  tooltip: 'Add Payment'),
            ]),
          ],
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
            value: progressValue.clamp(0.0, 1.0),
            backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(kPrimaryColor),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Paid: Rs. $paidAmount',
                style: TextStyle(color: subTextColor, fontSize: 12)),
            Text('Balance: Rs. $balance',
                style: TextStyle(
                    color: balance > 0 ? Colors.red : Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Transaction History',
                style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
            if (_selectedTransactionIds.isNotEmpty)
              IconButton(
                  icon: const Icon(Icons.receipt_long, color: kAccentRed),
                  onPressed: _generateSelectedReceipts,
                  tooltip: 'Generate Receipt for Selected',
                  visualDensity: VisualDensity.compact),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(_workspaceController.currentSchoolId.value.isNotEmpty
                  ? _workspaceController.currentSchoolId.value
                  : (FirebaseAuth.instance.currentUser?.uid ?? ''))
              .collection('vehicleDetails')
              .doc(vehicleDetails['studentId'].toString())
              .collection('payments')
              .orderBy('date', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return const ShimmerLoadingList();
            final docs = snapshot.data?.docs ?? [];
            List<Map<String, dynamic>> combinedDocs = docs.map((d) {
              final map = d.data() as Map<String, dynamic>;
              map['id'] = d.id;
              map['docRef'] = d;
              return map;
            }).toList();

            if (combinedDocs.isEmpty) {
              final advAmt = double.tryParse(
                      vehicleDetails['advanceAmount']?.toString() ?? '0') ??
                  0;
              if (advAmt > 0) {
                final regDate = DateTime.tryParse(
                        vehicleDetails['registrationDate']?.toString() ?? '') ??
                    DateTime(2000);
                combinedDocs.add({
                  'id': 'legacy_adv',
                  'amount': advAmt,
                  'date': Timestamp.fromDate(regDate),
                  'mode': vehicleDetails['paymentMode'] ?? 'Cash',
                  'description': 'Initial Advance',
                  'isLegacy': true
                });
              }
            }

            combinedDocs.sort((a, b) =>
                (b['date'] as Timestamp).compareTo(a['date'] as Timestamp));
            if (combinedDocs.isEmpty)
              return Center(
                  child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('No transactions yet',
                          style:
                              TextStyle(color: subTextColor, fontSize: 12))));

            // Show only 2 items by default, expand to show all
            final displayDocs = _isTransactionHistoryExpanded
                ? combinedDocs
                : combinedDocs.take(2).toList();
            final hasMore = combinedDocs.length > 2;

            return Column(
              children: [
                ...displayDocs.map((data) {
                  final date = (data['date'] as Timestamp).toDate();
                  final isSelected =
                      _selectedTransactionIds.contains(data['id']);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                        color: isDark ? Colors.grey[900] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? Border.all(color: kPrimaryColor, width: 1)
                            : null),
                    child: CheckboxListTile(
                      value: isSelected,
                      activeColor: kPrimaryColor,
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
                          style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      subtitle: Text(
                          '${DateFormat('dd MMM yyyy, hh:mm a').format(date)}\nMode: ${data['mode'] ?? 'N/A'}${data['note'] != null && data['note'].toString().trim().isNotEmpty ? '\nNote: ${data['note']}' : (data['description'] != null && data['description'].toString().trim().isNotEmpty ? '\n${data['description']}' : '')}',
                          style: TextStyle(color: subTextColor, fontSize: 11)),
                      secondary: data['isLegacy'] == true
                          ? null
                          : Row(mainAxisSize: MainAxisSize.min, children: [
                              IconButton(
                                  icon: const Icon(Icons.edit_outlined,
                                      size: 20, color: Colors.blue),
                                  onPressed: () =>
                                      PaymentUtils.showEditPaymentDialog(
                                          context: context,
                                          docRef: FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(targetId)
                                              .collection('vehicleDetails')
                                              .doc(vehicleDetails['studentId']
                                                  .toString()),
                                          paymentDoc: data['docRef'],
                                          targetId: targetId,
                                          category: 'vehicleDetails'),
                                  tooltip: 'Edit Payment'),
                              IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      size: 20, color: Colors.red),
                                  onPressed: () => PaymentUtils.deletePayment(
                                      context: context,
                                      studentRef: FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(targetId)
                                          .collection('vehicleDetails')
                                          .doc(vehicleDetails['studentId']
                                              .toString()),
                                      paymentDoc: data['docRef'],
                                      targetId: targetId),
                                  tooltip: 'Delete Payment'),
                            ]),
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
        StreamBuilder<QuerySnapshot>(
          stream: baseDocRef
              .collection('extra_fees')
              .orderBy('date', descending: true)
              .snapshots(),
          builder: (context, feesSnapshot) {
            if (!feesSnapshot.hasData || feesSnapshot.data!.docs.isEmpty)
              return const SizedBox.shrink();
            final feeDocs = feesSnapshot.data!.docs;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Additional Fees',
                        style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    if (_selectedTransactionIds.isNotEmpty)
                      IconButton(
                          icon:
                              const Icon(Icons.receipt_long, color: kAccentRed),
                          onPressed: _generateSelectedReceipts,
                          tooltip: 'Generate Receipt for Selected',
                          visualDensity: VisualDensity.compact),
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
                                : null),
                    child: CheckboxListTile(
                      value: _selectedTransactionIds.contains(doc.id),
                      activeColor: kAccentRed,
                      enabled: isPaid,
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (val) {
                        setState(() {
                          if (val == true)
                            _selectedTransactionIds.add(doc.id);
                          else
                            _selectedTransactionIds.remove(doc.id);
                        });
                      },
                      title: Text(
                          '${data['description']} — Rs. ${data['amount']}',
                          style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                      subtitle: Text(
                          '${DateFormat('dd MMM yyyy').format(date)}${data['note'] != null && data['note'].toString().trim().isNotEmpty ? "\nNote: ${data['note']}" : ''}',
                          style: TextStyle(color: subTextColor, fontSize: 11)),
                      secondary: Row(mainAxisSize: MainAxisSize.min, children: [
                        if (isPaid)
                          const Padding(
                              padding: EdgeInsets.only(right: 8.0),
                              child: Chip(
                                  label: Text('Paid',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 11)),
                                  backgroundColor: Colors.green,
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero))
                        else
                          TextButton(
                              onPressed: () =>
                                  PaymentUtils.showCollectExtraFeeDialog(
                                      context: context,
                                      docRef: baseDocRef,
                                      feeDoc: doc,
                                      targetId: targetId,
                                      branchId: _workspaceController
                                          .currentBranchId.value),
                              style: TextButton.styleFrom(
                                  foregroundColor: Colors.green),
                              child: const Text('Collect',
                                  style: TextStyle(fontSize: 12))),
                        IconButton(
                            icon: const Icon(Icons.edit_outlined,
                                size: 18, color: Colors.blue),
                            onPressed: () =>
                                PaymentUtils.showEditExtraFeeDialog(
                                    context: context,
                                    docRef: baseDocRef,
                                    feeDoc: doc,
                                    targetId: targetId,
                                    category: 'vehicleDetails'),
                            tooltip: 'Edit'),
                        IconButton(
                            icon: const Icon(Icons.delete_outline,
                                size: 18, color: Colors.red),
                            onPressed: () => PaymentUtils.deleteExtraFee(
                                context: context,
                                docRef: baseDocRef,
                                feeDoc: doc,
                                targetId: targetId),
                            tooltip: 'Delete'),
                      ]),
                      isThreeLine: data['note'] != null &&
                          data['note'].toString().trim().isNotEmpty,
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _generateSingleReceipt(Map<String, dynamic> transaction) async =>
      _generateReceipts([transaction]);

  Future<void> _generateSelectedReceipts() async {
    if (_selectedTransactionIds.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final targetId = _workspaceController.targetId;
    final studentId = vehicleDetails['studentId'].toString();
    final List<Map<String, dynamic>> allTransactions = [];

    final paymentsQuery = await FirebaseFirestore.instance
        .collection('users')
        .doc(targetId)
        .collection('vehicleDetails')
        .doc(studentId)
        .collection('payments')
        .where(FieldPath.documentId, whereIn: _selectedTransactionIds)
        .get();
    allTransactions.addAll(paymentsQuery.docs.map((d) => d.data()));

    final feesQuery = await FirebaseFirestore.instance
        .collection('users')
        .doc(targetId)
        .collection('vehicleDetails')
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

    if (_selectedTransactionIds.contains('legacy_adv')) {
      final double amount =
          double.tryParse(vehicleDetails['advanceAmount']?.toString() ?? '0') ??
              0;
      if (amount > 0)
        allTransactions.add({
          'amount': amount,
          'date': DateTime.tryParse(
                  vehicleDetails['registrationDate']?.toString() ?? '') ??
              DateTime(2000),
          'mode': vehicleDetails['paymentMode'] ?? 'Cash',
          'description': 'Initial Advance'
        });
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
            companyData['companyLogo'].toString().isNotEmpty)
          logoBytes = await ImageCacheService()
              .fetchAndCache(companyData['companyLogo']);
        final receiptData = Map<String, dynamic>.from(vehicleDetails);
        receiptData['type'] = 'Vehicle Service';
        return await PdfService.generateReceipt(
            companyData: companyData,
            studentDetails: receiptData,
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

  Future<void> _shareVehicleDetails(BuildContext context) async {
    Uint8List? pdfBytes;
    try {
      pdfBytes = await LoadingUtils.wrapWithLoading(context, () async {
        final workspace = Get.find<WorkspaceController>();
        final companyData = workspace.companyData;
        if (companyData['hasCompanyProfile'] != true)
          throw 'Please set up your Company Profile first';
        Uint8List? logoBytes;
        if (companyData['companyLogo'] != null &&
            companyData['companyLogo'].toString().isNotEmpty)
          logoBytes = await ImageCacheService()
              .fetchAndCache(companyData['companyLogo']);
        return await PdfService.generatePdf(
            title: 'Vehicle Details',
            data: vehicleDetails,
            includePayment: true,
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

  void _showPdfPreview(BuildContext context, Uint8List pdfBytes) {
    final phone = vehicleDetails['mobileNumber'] ?? '';
    final studentName = vehicleDetails['fullName'] ?? 'Student';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfPreviewScreen(
          pdfBytes: pdfBytes,
          studentName: vehicleDetails['fullName'],
          studentPhone: vehicleDetails['mobileNumber'],
          fileName: 'receipt_${vehicleDetails['fullName']}.pdf',
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              flex: 2,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: kPrimaryColor))),
          Expanded(
              flex: 3,
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w400))),
        ],
      ),
    );
  }
}
