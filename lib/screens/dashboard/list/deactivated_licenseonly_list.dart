import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/screens/dashboard/form/edit_forms/edit_licence_only_details_form.dart';
import 'package:mds/screens/dashboard/list/details/license_only_details_page.dart';
import 'package:mds/screens/dashboard/list/widgets/search_widget.dart';
import 'package:mds/screens/dashboard/list/widgets/shimmer_loading_list.dart';
import 'package:mds/screens/profile/dialog_box.dart';

class DeactivatedLicenseOnlyList extends StatefulWidget {
  const DeactivatedLicenseOnlyList({super.key});

  @override
  State<DeactivatedLicenseOnlyList> createState() => _DeactivatedLicenseOnlyListState();
}

class _DeactivatedLicenseOnlyListState extends State<DeactivatedLicenseOnlyList> {
  User? user = FirebaseAuth.instance.currentUser;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _streamSubscription;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _allDeactivatedLicenses = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setupStream();
  }

  void _setupStream() {
    _streamSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user?.uid)
        .collection('deactivated_licenseonly')
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

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filteredLicenses(String query) {
    return _allDeactivatedLicenses.where((doc) {
      final data = doc.data();
      final fullName = data['fullName']?.toString().toLowerCase() ?? '';
      final mobileNumber = data['mobileNumber']?.toString().toLowerCase() ?? '';
      final searchQuery = query.toLowerCase();
      return fullName.contains(searchQuery) || mobileNumber.contains(searchQuery);
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
          'Deactivated License Only List',
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
                  .doc(user?.uid)
                  .collection('deactivated_licenseonly')
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
    return InkWell(
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
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 4,
        ),
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
                padding: const EdgeInsets.all(16),
                child: CircleAvatar(
                  backgroundColor: kPrimaryColor,
                  radius: 50,
                  child: CircleAvatar(
                    radius: 48,
                    backgroundImage: data['image'] != null && data['image'].toString().isNotEmpty
                        ? CachedNetworkImageProvider(data['image'])
                        : const AssetImage('assets/icons/user.png') as ImageProvider,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                    right: 16,
                    bottom: 8,
                    top: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            data['fullName']?.toString() ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'BL: ${data['balanceAmount']?.toString() ?? '0'}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: kPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        data['mobileNumber']?.toString() ?? 'N/A',
                        style: listTextStyle,
                      ),
                      Text(
                        data['cov']?.toString() ?? 'N/A',
                        style: listTextStyle,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 12,
                          bottom: 8,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditLicenseOnlyForm(
                                        initialValues: data,
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
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: AlignmentDirectional.topCenter,
                                      end: AlignmentDirectional.bottomCenter,
                                      colors: linearButtonColor,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text(
                                        'Update',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  await _showActivateConfirmationDialog(doc.id);
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: inactiveButtonColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text(
                                        'Activate',
                                        style: TextStyle(
                                          color: kRedInactiveTextColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _activateData(String licenseId) async {
    if (licenseId.isNotEmpty) {
      var licenseData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .collection('deactivated_licenseonly')
          .doc(licenseId)
          .get();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .collection('licenseonly')
          .doc(licenseId)
          .set(licenseData.data() ?? {});

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .collection('deactivated_licenseonly')
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
