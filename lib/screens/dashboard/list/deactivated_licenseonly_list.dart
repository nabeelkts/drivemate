import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:drivemate/constants/colors.dart';
import 'package:drivemate/screens/dashboard/form/edit_forms/edit_licence_only_details_form.dart';
import 'package:get/get.dart';
import 'package:drivemate/controller/workspace_controller.dart';
import 'package:drivemate/screens/widget/custom_back_button.dart';
import 'package:drivemate/screens/dashboard/list/details/license_only_details_page.dart';
import 'package:drivemate/screens/dashboard/list/widgets/animated_search_widget.dart';
import 'package:drivemate/screens/dashboard/list/widgets/shimmer_loading_list.dart';
import 'package:drivemate/screens/dashboard/list/widgets/list_item_card.dart';
import 'package:drivemate/screens/dashboard/list/widgets/summary_header.dart';
import 'package:drivemate/screens/profile/dialog_box.dart';

class DeactivatedLicenseOnlyList extends StatefulWidget {
  const DeactivatedLicenseOnlyList({super.key});

  @override
  State<DeactivatedLicenseOnlyList> createState() =>
      _DeactivatedLicenseOnlyListState();
}

class _DeactivatedLicenseOnlyListState
    extends State<DeactivatedLicenseOnlyList> {
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _streamSubscription;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _allDeactivatedLicenses =
      [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _cachedLicenses =
      []; // Cache for immediate display
  final TextEditingController _searchController = TextEditingController();
  final WorkspaceController _workspaceController =
      Get.find<WorkspaceController>();

  @override
  void initState() {
    super.initState();
    _setupStream();
  }

  void _setupStream() {
    final schoolId = _workspaceController.currentSchoolId.value;
    final user = FirebaseAuth.instance.currentUser;
    final targetId = schoolId.isNotEmpty ? schoolId : user?.uid;

    _streamSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(targetId)
        .collection('deactivated_licenseOnly')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _allDeactivatedLicenses = snapshot.docs;
          _cachedLicenses = snapshot.docs; // Cache for immediate display
        });
      }
    });
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filteredLicenses(
      String query) {
    final filtered = _allDeactivatedLicenses.where((doc) {
      final data = doc.data();
      final fullName = data['fullName']?.toString().toLowerCase() ?? '';
      final mobileNumber = data['mobileNumber']?.toString().toLowerCase() ?? '';
      final searchQuery = query.toLowerCase();
      return fullName.contains(searchQuery) ||
          mobileNumber.contains(searchQuery);
    }).toList();

    // Sort by newest to oldest (registrationDate)
    filtered.sort((a, b) {
      final aDate = a.data()['registrationDate'] as String? ?? '';
      final bDate = b.data()['registrationDate'] as String? ?? '';
      return bDate.compareTo(aDate);
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? kBlack;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Course Completed Licenses',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: const CustomBackButton(),
      ),
      body: Column(
        children: [
          // Summary Header - 40%-60% split
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(_workspaceController.currentSchoolId.value.isNotEmpty
                    ? _workspaceController.currentSchoolId.value
                    : FirebaseAuth.instance.currentUser?.uid)
                .collection('deactivated_licenseOnly')
                .snapshots(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];
              double totalDues = 0;
              for (var doc in docs) {
                totalDues += double.tryParse(
                        doc.data()['balanceAmount']?.toString() ?? '0') ??
                    0;
              }
              return ListSummaryHeader(
                totalLabel: 'Total Completed:',
                totalCount: docs.length,
                pendingDues: totalDues, // Show actual pending dues
                isDark: isDark,
              );
            },
          ),
          AnimatedSearchWidget(
            primaryPlaceholder: 'Search by Name',
            secondaryPlaceholder: 'Search by Mobile Number',
            controller: _searchController,
            onChanged: (value) {
              setState(() {});
            },
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(_workspaceController.currentSchoolId.value.isNotEmpty
                      ? _workspaceController.currentSchoolId.value
                      : FirebaseAuth.instance.currentUser?.uid)
                  .collection('deactivated_licenseOnly')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${snapshot.error}',
                          style:
                              const TextStyle(color: Colors.red, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                // Show cached data first to avoid white screen on back navigation
                if (_cachedLicenses.isNotEmpty) {
                  var docs = _searchController.text.isNotEmpty
                      ? _filteredLicenses(_searchController.text)
                      : _cachedLicenses;

                  if (docs.isEmpty) {
                    return const Center(
                        child: Text('No deactivated licenses found'));
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data =
                          Map<String, dynamic>.from(docs[index].data());
                      return buildLicenseListItem(context, docs[index], data);
                    },
                  );
                }

                // Only show shimmer on initial load if no cached data
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ShimmerLoadingList();
                }

                var docs = _searchController.text.isNotEmpty
                    ? _filteredLicenses(_searchController.text)
                    : snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Center(
                      child: Text('No deactivated licenses found'));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = Map<String, dynamic>.from(docs[index].data());
                    return buildLicenseListItem(context, docs[index], data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildLicenseListItem(
    BuildContext context,
    DocumentSnapshot<Map<String, dynamic>> doc,
    Map<String, dynamic> data,
  ) {
    // Inject document ID for navigation to details page
    data['studentId'] = doc.id;
    data['id'] = doc.id;
    data['recordId'] = doc.id;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListItemCard(
      title: data['fullName'] ?? 'N/A',
      subTitle:
          'COV: ${data['cov'] ?? 'N/A'}\nMobile: ${data['mobileNumber'] ?? 'N/A'}',
      imageUrl: data['image'],
      isDark: isDark,
      status: data['testStatus'],
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LicenseOnlyDetailsPage(
              licenseDetails: data,
            ),
          ),
        );
      },
      onMenuPressed: () {
        _showMenuOptions(context, doc);
      },
    );
  }

  void _showMenuOptions(
      BuildContext context, DocumentSnapshot<Map<String, dynamic>> doc) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person_add, color: kPrimaryColor),
                title: const Text('Reactivate License Details'),
                onTap: () async {
                  Navigator.pop(context);
                  await _showActivateConfirmationDialog(
                      doc.id, doc.data() ?? {});
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.grey),
                title: const Text('Update Details'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditLicenseOnlyForm(
                        initialValues: doc.data() ?? {},
                        items: const [
                          'M/C Study',
                          'LMV Study',
                          'LMV Study + M/C Study',
                          'LMV Study + M/C License',
                          'Adapted Vehicle',
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _activateData(
      String licenseId, Map<String, dynamic> licenseData) async {
    final schoolId = _workspaceController.currentSchoolId.value;
    final user = FirebaseAuth.instance.currentUser;
    final targetId = schoolId.isNotEmpty ? schoolId : user?.uid;

    if (licenseId.isNotEmpty && licenseData.isNotEmpty) {
      if (targetId == null) return;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetId)
          .collection('licenseonly')
          .doc(licenseId)
          .set(licenseData);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetId)
          .collection('deactivated_licenseOnly')
          .doc(licenseId)
          .delete();
    }
  }

  Future<void> _showActivateConfirmationDialog(
      String documentId, Map<String, dynamic> licenseData) async {
    showCustomConfirmationDialog(
      context,
      'Confirm Activation?',
      'Are you sure ?',
      () async {
        await _activateData(documentId, licenseData);
        // Navigator.pop is now handled automatically by showCustomConfirmationDialog
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const DeactivatedLicenseOnlyList(),
            ),
          );
        }
      },
    );
  }
}
