import 'package:flutter/material.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/screens/dashboard/form/edit_forms/edit_vehicle_details_form.dart';
import 'package:mds/screens/widget/base_form_widget.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:mds/controller/workspace_controller.dart';
import 'package:mds/utils/payment_utils.dart';
import 'package:mds/utils/date_utils.dart';
import 'package:http/http.dart' as http;
import 'package:mds/screens/dashboard/list/details/pdf_preview_screen.dart';
import 'package:mds/services/pdf_service.dart';
import 'package:mds/utils/loading_utils.dart';
import 'package:share_plus/share_plus.dart';

class VehicleDetailsPage extends StatefulWidget {
  final Map<String, dynamic> vehicleDetails;

  const VehicleDetailsPage({required this.vehicleDetails, super.key});

  @override
  State<VehicleDetailsPage> createState() => _VehicleDetailsPageState();
}

class _VehicleDetailsPageState extends State<VehicleDetailsPage> {
  late Map<String, dynamic> vehicleDetails;
  final List<String> _selectedTransactionIds = [];
  Map<String, dynamic>? _cachedCompanyData;
  Uint8List? _cachedCompanyLogo;
  final WorkspaceController _workspaceController =
      Get.find<WorkspaceController>();

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
        if (snapshot.hasData && snapshot.data!.exists) {
          vehicleDetails = snapshot.data!.data() as Map<String, dynamic>;
        }

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
                        'Tax Payment',
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
          children: [
            FormSection(
              title: 'Personal Details',
              children: [
                _buildDetailRow(
                    'Full Name', vehicleDetails['fullName'] ?? 'N/A'),
                _buildDetailRow(
                    'Mobile Number', vehicleDetails['mobileNumber'] ?? 'N/A'),
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
                  _buildDetailRow(
                    'Registration Date',
                    _formatDate(vehicleDetails['registrationDate']),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _buildPaymentOverviewCard(BuildContext context, String targetId,
      AsyncSnapshot<DocumentSnapshot> snapshot) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark ? Colors.grey : Colors.grey[700]!;

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
            Row(
              children: [
                if (_selectedTransactionIds.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.receipt_long, color: kPrimaryColor),
                    onPressed: _generateSelectedReceipts,
                    tooltip: 'Receipt for Selected',
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
                        category: 'vehicleDetails',
                      );
                    }
                  },
                  tooltip: 'Add Payment',
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: progressValue.clamp(0.0, 1.0),
          backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
          valueColor: const AlwaysStoppedAnimation<Color>(kPrimaryColor),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
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
        Text('Transaction History',
            style: TextStyle(
                color: textColor, fontWeight: FontWeight.bold, fontSize: 14)),
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
                        ? Border.all(color: kPrimaryColor, width: 1)
                        : null,
                  ),
                  child: CheckboxListTile(
                    value: isSelected,
                    activeColor: kPrimaryColor,
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
                      '${DateFormat('dd MMM yyyy, hh:mm a').format(date)}\nMode: ${data['mode'] ?? 'N/A'}',
                      style: TextStyle(color: subTextColor, fontSize: 11),
                    ),
                    secondary: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.receipt,
                              size: 20, color: kPrimaryColor),
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
                                .doc(_workspaceController
                                        .currentSchoolId.value.isNotEmpty
                                    ? _workspaceController.currentSchoolId.value
                                    : (FirebaseAuth.instance.currentUser?.uid ??
                                        ''))
                                .collection('vehicleDetails')
                                .doc(vehicleDetails['studentId'].toString()),
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
      ],
    );
  }

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
        .collection('vehicleDetails')
        .doc(vehicleDetails['studentId'].toString())
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
        final targetId = _workspaceController.targetId;

        if (_cachedCompanyData == null) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(targetId)
              .get();
          _cachedCompanyData = userDoc.data();
        }

        if (_cachedCompanyData == null ||
            _cachedCompanyData!['hasCompanyProfile'] != true) {
          throw 'Please set up your Company Profile first';
        }

        if (_cachedCompanyData!['companyLogo'] != null &&
            _cachedCompanyData!['companyLogo'].toString().isNotEmpty &&
            _cachedCompanyLogo == null) {
          _cachedCompanyLogo = await _getImageBytes(
              NetworkImage(_cachedCompanyData!['companyLogo']));
        }

        // Adapt vehicle details for receipt title/details
        final receiptData = Map<String, dynamic>.from(vehicleDetails);
        receiptData['type'] = 'Vehicle Service';

        return await PdfService.generateReceipt(
          companyData: _cachedCompanyData!,
          studentDetails: receiptData,
          transactions: transactions,
          companyLogoBytes: _cachedCompanyLogo,
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

  Future<void> _shareVehicleDetails(BuildContext context) async {
    Uint8List? pdfBytes;
    try {
      pdfBytes = await LoadingUtils.wrapWithLoading(context, () async {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw 'User not logged in';

        if (_cachedCompanyData == null) {
          final targetId = _workspaceController.targetId;

          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(targetId)
              .get();
          _cachedCompanyData = doc.data();
        }

        if (_cachedCompanyData != null &&
            _cachedCompanyData!['hasCompanyProfile'] == true &&
            _cachedCompanyData!['companyLogo'] != null &&
            _cachedCompanyData!['companyLogo'].toString().isNotEmpty &&
            _cachedCompanyLogo == null) {
          _cachedCompanyLogo = await _getImageBytes(
              NetworkImage(_cachedCompanyData!['companyLogo']));
        }

        return await PdfService.generatePdf(
          title: 'Vehicle Details',
          data: vehicleDetails,
          includePayment: true,
          companyData: _cachedCompanyData,
          companyLogoBytes: _cachedCompanyLogo,
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

  Future<Uint8List?> _getImageBytes(ImageProvider imageProvider) async {
    try {
      if (imageProvider is NetworkImage) {
        final url = imageProvider.url;
        debugPrint('Attempting to load image from: $url');

        final response =
            await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          debugPrint(
              'Image loaded successfully: ${response.bodyBytes.length} bytes');
          return response.bodyBytes;
        } else {
          debugPrint('Image load failed with status: ${response.statusCode}');
          return null;
        }
      } else if (imageProvider is AssetImage) {
        final byteData = await rootBundle.load(imageProvider.assetName);
        return byteData.buffer.asUint8List();
      }
    } catch (e) {
      debugPrint('Error loading image for PDF: $e');
      return null;
    }
    return null;
  }

  void _showPdfPreview(BuildContext context, Uint8List pdfBytes) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfPreviewScreen(pdfBytes: pdfBytes),
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
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: kPrimaryColor,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
