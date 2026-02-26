import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mds/screens/widget/custom_back_button.dart';
import 'package:mds/screens/authentication/widgets/my_button.dart';
import 'package:mds/screens/dashboard/form/edit_forms/edit_endorsement_details_form.dart';
import 'package:mds/screens/profile/action_button.dart';
import 'package:mds/screens/dashboard/list/details/pdf_preview_screen.dart';
import 'package:mds/services/pdf_service.dart';
import 'package:mds/services/image_cache_service.dart';
import 'package:mds/utils/loading_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';

import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:mds/utils/test_utils.dart';
import 'package:mds/utils/image_utils.dart';
import 'package:mds/utils/date_utils.dart';
import 'dart:async';
import 'package:mds/controller/workspace_controller.dart';
import 'package:mds/utils/payment_utils.dart';
import 'package:http/http.dart' as http;

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

  @override
  void initState() {
    super.initState();
    endorsementDetails = Map.from(widget.endorsementDetails);
    _docId = (endorsementDetails['studentId'] ??
            endorsementDetails['id'] ??
            endorsementDetails['recordId'])
        .toString();
    _initStreams();
  }

  late final String _docId;
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
        .collection('endorsement')
        .doc(_docId)
        .snapshots();

    _paymentsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(targetId)
        .collection('endorsement')
        .doc(_docId)
        .collection('payments')
        .orderBy('date', descending: true)
        .snapshots();

    _extraFeesStream = FirebaseFirestore.instance
        .collection('users')
        .doc(targetId)
        .collection('endorsement')
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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text('Endorsement Details', style: TextStyle(color: textColor)),
        elevation: 0,
        leading: const CustomBackButton(),
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf, color: subTextColor),
            onPressed: () => _shareEndorsementDetails(context),
          ),
          IconButton(
            icon: Icon(Icons.edit, color: subTextColor),
            onPressed: () {
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
                      'AGRICULTURAL TRACTOR',
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
            endorsementDetails = snapshot.data!.data() as Map<String, dynamic>;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
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
                _buildPaymentOverviewCard(context, targetId, snapshot),
                const SizedBox(height: 16),
                _buildTestDateCard(context),
                const SizedBox(height: 16),
                const SizedBox(height: 24),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTestDateCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark ? Colors.grey : Colors.grey[700]!;
    final cardColor = Theme.of(context).cardColor;

    final llDate = AppDateUtils.formatDateForDisplay(
        endorsementDetails['learnersTestDate']?.toString());
    final dlDate = AppDateUtils.formatDateForDisplay(
        endorsementDetails['drivingTestDate']?.toString());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Test Date',
                  style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              IconButton(
                icon: const Icon(IconlyLight.edit, color: kAccentRed, size: 20),
                onPressed: () => TestUtils.showUpdateTestDateDialog(
                  context: context,
                  item: endorsementDetails,
                  collection: 'endorsement',
                  studentId: endorsementDetails['studentId'].toString(),
                ),
                tooltip: 'Update Test Dates',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (llDate.isEmpty && dlDate.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                'No test dates. Pick test date',
                style: TextStyle(
                    color: subTextColor.withOpacity(0.7),
                    fontSize: 13,
                    fontStyle: FontStyle.italic),
              ),
            )
          else ...[
            if (llDate.isNotEmpty)
              _buildInfoRow(
                  'Learners Test (LL)', llDate, textColor, subTextColor),
            if (dlDate.isNotEmpty)
              _buildInfoRow(
                  'Driving Test (DL)', dlDate, textColor, subTextColor),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark ? Colors.grey : Colors.grey[700]!;
    final cardColor = Theme.of(context).cardColor;
    Timer? holdTimer;

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
          Builder(builder: (context) {
            return GestureDetector(
              onTapDown: (_) {
                if (endorsementDetails['image'] != null &&
                    endorsementDetails['image'].toString().isNotEmpty) {
                  holdTimer = Timer(const Duration(seconds: 1), () {
                    ImageUtils.showImagePopup(
                        context,
                        endorsementDetails['image'],
                        endorsementDetails['fullName']);
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
                  child: endorsementDetails['image'] != null &&
                          endorsementDetails['image'].toString().isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: endorsementDetails['image'],
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              const CircularProgressIndicator(strokeWidth: 2),
                          errorWidget: (context, url, error) => Container(
                            alignment: Alignment.center,
                            child: Text(
                              endorsementDetails['fullName'] != null &&
                                      endorsementDetails['fullName']
                                          .toString()
                                          .isNotEmpty
                                  ? endorsementDetails['fullName'][0]
                                      .toUpperCase()
                                  : '',
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
                            endorsementDetails['fullName'] != null &&
                                    endorsementDetails['fullName']
                                        .toString()
                                        .isNotEmpty
                                ? endorsementDetails['fullName'][0]
                                    .toUpperCase()
                                : '',
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
          }),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  endorsementDetails['fullName'] ?? 'N/A',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ID: ${endorsementDetails['studentId'] ?? 'N/A'}',
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                if (endorsementDetails['cov'] != null &&
                    endorsementDetails['cov'].toString().isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: kAccentRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: kAccentRed),
                    ),
                    child: Text(
                      'COV: ${endorsementDetails['cov']}',
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

  Widget _buildPersonalInfoCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark ? Colors.grey : Colors.grey[700]!;
    final cardColor = Theme.of(context).cardColor;

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
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
            _buildInfoRow('Name', endorsementDetails['fullName'] ?? 'N/A',
                textColor, subTextColor),
            _buildInfoRow(
                'Guardian Name',
                endorsementDetails['guardianName'] ?? 'N/A',
                textColor,
                subTextColor),
            _buildInfoRow('DOB', endorsementDetails['dob'] ?? 'N/A', textColor,
                subTextColor),
            _buildInfoRow('Mobile', endorsementDetails['mobileNumber'] ?? 'N/A',
                textColor, subTextColor),
            _buildInfoRow(
                'Emergency',
                endorsementDetails['emergencyNumber'] ?? 'N/A',
                textColor,
                subTextColor),
            _buildInfoRow(
                'Blood Group',
                endorsementDetails['bloodGroup'] ?? 'N/A',
                textColor,
                subTextColor),
            _buildInfoRow(
                'License Number',
                endorsementDetails['license'] ?? 'N/A',
                textColor,
                subTextColor),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark ? Colors.grey : Colors.grey[700]!;
    final cardColor = Theme.of(context).cardColor;

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
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
            _buildInfoRow('House', endorsementDetails['house'] ?? '', textColor,
                subTextColor),
            _buildInfoRow('Place', endorsementDetails['place'] ?? '', textColor,
                subTextColor),
            _buildInfoRow('Post', endorsementDetails['post'] ?? '', textColor,
                subTextColor),
            _buildInfoRow('District', endorsementDetails['district'] ?? '',
                textColor, subTextColor),
            _buildInfoRow('PIN Code', endorsementDetails['pin'] ?? '',
                textColor, subTextColor),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOverviewCard(BuildContext context, String targetId,
      AsyncSnapshot<DocumentSnapshot> snapshot) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark ? Colors.grey : Colors.grey[700]!;
    final cardColor = Theme.of(context).cardColor;

    double total =
        double.tryParse(endorsementDetails['totalAmount']?.toString() ?? '0') ??
            0;
    double balance = double.tryParse(
            endorsementDetails['balanceAmount']?.toString() ?? '0') ??
        0;
    double paidAmount = total - balance;
    double progressValue = total > 0 ? paidAmount / total : 0;

    return Container(
      padding: const EdgeInsets.all(16),
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
                  IconButton(
                    icon: const Icon(Icons.post_add, color: Colors.blue),
                    onPressed: () {
                      if (snapshot.hasData) {
                        PaymentUtils.showAddExtraFeeDialog(
                          context: context,
                          doc: snapshot.data!
                              as DocumentSnapshot<Map<String, dynamic>>,
                          targetId: targetId,
                          branchId: _workspaceController.currentBranchId.value,
                          category: 'endorsement',
                        );
                      }
                    },
                    tooltip: 'Add Extra Fee',
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.green),
                    onPressed: () {
                      if (snapshot.hasData) {
                        PaymentUtils.showAddPaymentDialog(
                          context: context,
                          doc: snapshot.data!
                              as DocumentSnapshot<Map<String, dynamic>>,
                          targetId: targetId,
                          branchId: _workspaceController.currentBranchId.value,
                          category: 'endorsement',
                        );
                      }
                    },
                    tooltip: 'Add Payment',
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
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: _paymentsStream,
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
                        '${DateFormat('dd MMM yyyy, hh:mm a').format(date)}\nMode: ${data['mode'] ?? 'N/A'}${data['note'] != null && data['note'].toString().trim().isNotEmpty ? '\nNote: ${data['note']}' : (data['description'] != null && data['description'].toString().trim().isNotEmpty ? '\n${data['description']}' : '')}',
                        style: TextStyle(color: subTextColor, fontSize: 11),
                      ),
                      secondary: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined,
                                size: 20, color: Colors.blue),
                            onPressed: () => PaymentUtils.showEditPaymentDialog(
                              context: context,
                              docRef: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(targetId)
                                  .collection('endorsement')
                                  .doc(_docId),
                              paymentDoc: doc,
                              targetId: targetId,
                              category: 'endorsement',
                            ),
                            tooltip: 'Edit Payment',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                size: 20, color: Colors.red),
                            onPressed: () => PaymentUtils.deletePayment(
                              context: context,
                              studentRef: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(_workspaceController
                                          .currentSchoolId.value.isNotEmpty
                                      ? _workspaceController
                                          .currentSchoolId.value
                                      : (FirebaseAuth
                                              .instance.currentUser?.uid ??
                                          ''))
                                  .collection('endorsement')
                                  .doc(_docId),
                              paymentDoc: doc,
                              targetId: _workspaceController
                                      .currentSchoolId.value.isNotEmpty
                                  ? _workspaceController.currentSchoolId.value
                                  : (FirebaseAuth.instance.currentUser?.uid ??
                                      ''),
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
          // ── Additional Fees (inline) ─────────────────────────────────────────
          StreamBuilder<QuerySnapshot>(
            stream: _extraFeesStream,
            builder: (context, feesSnapshot) {
              if (!feesSnapshot.hasData || feesSnapshot.data!.docs.isEmpty) {
                return const SizedBox.shrink();
              }
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
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(data['description'] ?? 'N/A',
                                      style: TextStyle(
                                          color: textColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14)),
                                  const SizedBox(height: 2),
                                  Text('Rs. ${data['amount']}',
                                      style: TextStyle(
                                          color: textColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                  const SizedBox(height: 2),
                                  Text(DateFormat('dd MMM yyyy').format(date),
                                      style: TextStyle(
                                          color: subTextColor, fontSize: 11)),
                                  if (isPaid &&
                                      data['paymentMode'] != null) ...[
                                    const SizedBox(height: 2),
                                    Text('Mode: ${data['paymentMode']}',
                                        style: TextStyle(
                                            color: subTextColor, fontSize: 11)),
                                  ],
                                  if (data['note'] != null &&
                                      data['note']
                                          .toString()
                                          .trim()
                                          .isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text('Note: ${data['note']}',
                                        style: TextStyle(
                                            color: subTextColor, fontSize: 11),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isPaid)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 8.0),
                                      child: Chip(
                                        label: Text('Paid',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 11)),
                                        backgroundColor: Colors.green,
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                      ),
                                    )
                                  else
                                    TextButton(
                                      onPressed: () => PaymentUtils
                                          .showCollectExtraFeeDialog(
                                        context: context,
                                        docRef: FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(targetId)
                                            .collection('endorsement')
                                            .doc(_docId),
                                        feeDoc: doc,
                                        targetId: targetId.toString(),
                                        branchId: _workspaceController
                                            .currentBranchId.value,
                                      ),
                                      style: TextButton.styleFrom(
                                          foregroundColor: Colors.green),
                                      child: const Text('Collect',
                                          style: TextStyle(fontSize: 12)),
                                    ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined,
                                        size: 18, color: Colors.blue),
                                    onPressed: () =>
                                        PaymentUtils.showEditExtraFeeDialog(
                                      context: context,
                                      docRef: FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(targetId)
                                          .collection('endorsement')
                                          .doc(_docId),
                                      feeDoc: doc,
                                      targetId: targetId.toString(),
                                      category: 'endorsement',
                                    ),
                                    tooltip: 'Edit',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        size: 18, color: Colors.red),
                                    onPressed: () =>
                                        PaymentUtils.deleteExtraFee(
                                      context: context,
                                      docRef: FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(targetId)
                                          .collection('endorsement')
                                          .doc(_docId),
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

  // Removed manual payment logic as it's now handled by PaymentUtils

  Future<void> _generateSingleReceipt(Map<String, dynamic> transaction) async {
    _generateReceipts([transaction]);
  }

  Future<void> _generateSelectedReceipts() async {
    if (_selectedTransactionIds.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final targetId = _workspaceController.targetId;
    final studentId = endorsementDetails['studentId'].toString();

    final List<Map<String, dynamic>> allTransactions = [];

    // Check payments collection
    final paymentsQuery = await FirebaseFirestore.instance
        .collection('users')
        .doc(targetId)
        .collection('endorsement')
        .doc(studentId)
        .collection('payments')
        .where(FieldPath.documentId, whereIn: _selectedTransactionIds)
        .get();
    allTransactions.addAll(paymentsQuery.docs.map((d) => d.data()));

    // Check extra_fees collection
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
      if (data['date'] is Timestamp) {
        data['date'] = (data['date'] as Timestamp).toDate();
      }
      return data;
    }));

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
          studentDetails: endorsementDetails,
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

  void _showPdfPreview(BuildContext context, Uint8List pdfBytes) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfPreviewScreen(pdfBytes: pdfBytes),
      ),
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

  Future<void> _shareEndorsementDetails(BuildContext context) async {
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
        if (endorsementDetails['image'] != null &&
            endorsementDetails['image'].toString().isNotEmpty) {
          studentImage = await ImageCacheService()
              .fetchAndCache(endorsementDetails['image']);
        }

        // Fetch company logo
        Uint8List? logoBytes;
        if (companyData['companyLogo'] != null &&
            companyData['companyLogo'].toString().isNotEmpty) {
          logoBytes = await ImageCacheService()
              .fetchAndCache(companyData['companyLogo']);
        }

        return await PdfService.generatePdf(
          title: 'Endorsement Details',
          data: endorsementDetails,
          includePayment: includePayment,
          imageBytes: studentImage,
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
      _showPdfPreview(context, pdfBytes);
    }
  }
}
