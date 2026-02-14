import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/screens/dashboard/form/edit_forms/edit_licence_only_details_form.dart';
import 'package:get/get.dart';
import 'package:mds/controller/workspace_controller.dart';
import 'package:mds/screens/dashboard/list/details/license_only_details_page.dart';
import 'package:mds/screens/dashboard/list/widgets/search_widget.dart';
import 'package:mds/screens/dashboard/list/widgets/shimmer_loading_list.dart';
import 'package:mds/screens/dashboard/list/widgets/list_item_card.dart';
import 'package:mds/screens/profile/dialog_box.dart';

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
    return _allDeactivatedLicenses.where((doc) {
      final data = doc.data();
      final fullName = data['fullName']?.toString().toLowerCase() ?? '';
      final mobileNumber = data['mobileNumber']?.toString().toLowerCase() ?? '';
      final searchQuery = query.toLowerCase();
      return fullName.contains(searchQuery) ||
          mobileNumber.contains(searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? kBlack;

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
        leading: Stack(
          children: [
            Positioned(
              left: 12,
              right: 12,
              top: 12,
              bottom: 12,
              child: CircleAvatar(
                backgroundColor: kPrimaryColor,
                radius: 16,
                child: CircleAvatar(
                  radius: 15,
                  backgroundColor: kWhite,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: kPrimaryColor,
                      size: 16,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          SearchWidget(
            placeholder: 'Search by Name or Mobile Number',
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
                  return const Text('Connection Error');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ShimmerLoadingList();
                }

                var docs = _searchController.text.isNotEmpty
                    ? _filteredLicenses(_searchController.text)
                    : snapshot.data?.docs ?? [];

                // Safely sort the documents
                docs.sort((a, b) {
                  final aName = a.data()['fullName']?.toString() ?? '';
                  final bName = b.data()['fullName']?.toString() ?? '';
                  return aName.compareTo(bName);
                });

                if (docs.isEmpty) {
                  return const Center(
                    child: Text('No deactivated licenses found'),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListItemCard(
      title: data['fullName'] ?? 'N/A',
      subTitle:
          'COV: ${data['cov'] ?? 'N/A'}\nMobile: ${data['mobileNumber'] ?? 'N/A'}',
      imageUrl: data['image'],
      isDark: isDark,
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
                  await _showActivateConfirmationDialog(doc.id);
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

  Future<void> _activateData(String licenseId) async {
    final schoolId = _workspaceController.currentSchoolId.value;
    final user = FirebaseAuth.instance.currentUser;
    final targetId = schoolId.isNotEmpty ? schoolId : user?.uid;

    if (licenseId.isNotEmpty) {
      if (targetId == null) return;
      var licenseData = await FirebaseFirestore.instance
          .collection('users')
          .doc(targetId)
          .collection('deactivated_licenseOnly')
          .doc(licenseId)
          .get();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetId)
          .collection('licenseonly')
          .doc(licenseId)
          .set(licenseData.data() ?? {});

      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetId)
          .collection('deactivated_licenseOnly')
          .doc(licenseId)
          .delete();
    }
  }

  Future<void> _showActivateConfirmationDialog(String documentId) async {
    showCustomConfirmationDialog(
      context,
      'Confirm Activation?',
      'Are you sure ?',
      () async {
        await _activateData(documentId);
        Navigator.of(context).pop();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const DeactivatedLicenseOnlyList(),
          ),
        );
      },
    );
  }
}
