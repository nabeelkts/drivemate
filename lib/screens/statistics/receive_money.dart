import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/screens/dashboard/list/widgets/search_widget.dart';
import 'package:get/get.dart';
import 'package:mds/controller/workspace_controller.dart';
import 'package:mds/utils/payment_utils.dart';

class ReceiveMoneyPage extends StatefulWidget {
  const ReceiveMoneyPage({super.key});

  @override
  _ReceiveMoneyPageState createState() => _ReceiveMoneyPageState();
}

class _ReceiveMoneyPageState extends State<ReceiveMoneyPage> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _allData = [];
  bool _isLoading = true;
  User? user = FirebaseAuth.instance.currentUser;
  final WorkspaceController _workspaceController =
      Get.find<WorkspaceController>();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (user == null) return;
    setState(() => _isLoading = true);
    try {
      final collections = [
        'students',
        'licenseonly',
        'endorsement',
        'vehicleDetails',
        'dl_services'
      ];
      List<QueryDocumentSnapshot<Map<String, dynamic>>> allDocs = [];

      final schoolId = _workspaceController.currentSchoolId.value;
      final targetId = schoolId.isNotEmpty ? schoolId : user!.uid;

      for (var col in collections) {
        final snapshot = await _firestore
            .collection('users')
            .doc(targetId)
            .collection(col)
            .get();
        allDocs.addAll(snapshot.docs);
      }

      // Sort alphabetically
      allDocs.sort((a, b) {
        final nameA =
            (a.data()['fullName'] ?? a.data()['vehicleNumber'] ?? 'N/A')
                .toString()
                .toLowerCase();
        final nameB =
            (b.data()['fullName'] ?? b.data()['vehicleNumber'] ?? 'N/A')
                .toString()
                .toLowerCase();
        return nameA.compareTo(nameB);
      });

      if (mounted) {
        setState(() {
          _allData = allDocs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _getFilteredData() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _allData;

    return _allData.where((doc) {
      final d = doc.data();
      final name = (d['fullName'] ?? '').toString().toLowerCase();
      final mobile = (d['mobileNumber'] ?? '').toString().toLowerCase();
      final vehicle = (d['vehicleNumber'] ?? '').toString().toLowerCase();
      return name.contains(query) ||
          mobile.contains(query) ||
          vehicle.contains(query);
    }).toList();
  }

  Future<void> _showAddInstallmentDialog(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    if (!mounted) return;

    final schoolId = _workspaceController.currentSchoolId.value;
    final targetId = schoolId.isNotEmpty ? schoolId : (user?.uid ?? '');

    await PaymentUtils.showReceiveMoneyDialog(
      context: context,
      doc: doc,
      targetId: targetId,
      category: doc.reference.parent.id, // e.g., 'students', 'vehicleDetails'
    );

    if (mounted) {
      _loadInitialData(); // Refresh list to show updated balance
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Receive Money'),
      ),
      body: Column(
        children: [
          SearchWidget(
            placeholder: 'Search by Name, Mobile, or Vehicle Number',
            controller: _searchController,
            onChanged: (value) {
              setState(() {});
            },
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _getFilteredData().isEmpty
                    ? const Center(
                        child: Text('No results. Try different keywords.'))
                    : ListView.builder(
                        itemCount: _getFilteredData().length,
                        itemBuilder: (context, index) {
                          final doc = _getFilteredData()[index];
                          final data = doc.data();
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 4),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: kPrimaryColor,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4, horizontal: 8),
                                    child: CircleAvatar(
                                      backgroundColor: kPrimaryColor,
                                      radius: 30,
                                      child: CircleAvatar(
                                        radius: 28,
                                        backgroundColor: Colors.white,
                                        backgroundImage: data['image'] !=
                                                    null &&
                                                data['image'].isNotEmpty
                                            ? CachedNetworkImageProvider(
                                                data['image']) as ImageProvider
                                            : null,
                                        child: data['image'] == null ||
                                                data['image'].isEmpty
                                            ? Text(
                                                data['fullName']?[0]
                                                        .toUpperCase() ??
                                                    'N/A',
                                                style: const TextStyle(
                                                    fontSize: 24,
                                                    color: kPrimaryColor),
                                              )
                                            : null,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4, horizontal: 12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  data['fullName'] ??
                                                      data['vehicleNumber'] ??
                                                      'N/A',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              FittedBox(
                                                child: Text(
                                                  'BL: ${data['balanceAmount'] ?? 0}',
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: kPrimaryColor),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            '${data['mobileNumber'] ?? 'N/A'}',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500),
                                          ),
                                          if (data['cov'] != null)
                                            Text(
                                              '${data['cov']}',
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500),
                                            ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                top: 4, bottom: 2),
                                            child: Align(
                                              alignment: Alignment.bottomRight,
                                              child: ElevatedButton.icon(
                                                onPressed: () =>
                                                    _showAddInstallmentDialog(
                                                        doc),
                                                icon: const Icon(
                                                    Icons
                                                        .account_balance_wallet,
                                                    size: 16),
                                                label: const Text(
                                                  'Receive Money',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      kPrimaryColor,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      vertical: 8,
                                                      horizontal: 16),
                                                  minimumSize: Size.zero,
                                                  tapTargetSize:
                                                      MaterialTapTargetSize
                                                          .shrinkWrap,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
