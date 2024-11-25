// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/screens/authentication/widgets/my_button.dart';
import 'package:mds/screens/dashboard/form/edit_forms/edit_licence_only_details_form.dart';
import 'package:mds/screens/dashboard/form/new_forms/license_only_form.dart';
import 'package:mds/screens/dashboard/list/deactivated_licenseonly_list.dart';
import 'package:mds/screens/dashboard/list/details/license_only_details_page.dart';
import 'package:mds/screens/dashboard/list/widgets/search_widget.dart';
import 'package:mds/screens/dashboard/list/widgets/shimmer_loading_list.dart';
import 'package:mds/screens/profile/dialog_box.dart';

class LicenseOnlyList extends StatefulWidget {
  final String userId;

  const LicenseOnlyList({required this.userId, super.key});

  @override
  State<LicenseOnlyList> createState() => _LicenseOnlyListState();
}

User? user = FirebaseAuth.instance.currentUser;

class _LicenseOnlyListState extends State<LicenseOnlyList> {
  bool isLoading = false;
  final _userStreamController =
      StreamController<QuerySnapshot<Map<String, dynamic>>>();
  late StreamSubscription<QuerySnapshot<Map<String, dynamic>>>
      _userStreamSubscription;

  final TextEditingController _searchController = TextEditingController();
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _allLicenseEntries = [];

  @override
  void initState() {
    super.initState();
    _userStreamSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user?.uid)
        .collection('licenseonly')
        .snapshots()
        .listen((snapshot) {
      _userStreamController.add(snapshot);
      setState(() {
        _allLicenseEntries = snapshot.docs;
      });
    });
  }

  @override
  void dispose() {
    _userStreamSubscription.cancel();
    _userStreamController.close();
    super.dispose();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filteredLicenseEntries(
      String query) {
    return _allLicenseEntries
        .where((doc) =>
            doc['fullName'].toLowerCase().contains(query.toLowerCase()) ||
            doc['mobileNumber'].toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     // backgroundColor: kBackgroundColor,
      appBar: AppBar(
       // backgroundColor: kBackgroundColor,
        elevation: 0,
        title: const Text(
          'License Only List',
          style: TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: Center(
          child: CircleAvatar(
            backgroundColor: kPrimaryColor,
            radius: 15,
            child: Center(
              child: CircleAvatar(
                radius: 14,
                backgroundColor: kWhite,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: kPrimaryColor,
                    size: 15,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DeactivatedLicenseOnlyList(),
                ),
              );
            },
            icon: const Icon(
              Icons.list_rounded,
              color: kPrimaryColor,
            ),
          ),
        ],
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
            child: MyButton(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LicenseOnly()),
                );
              },
              text: 'Create New License Only',
              isLoading: isLoading,
              isEnabled: true,
              width: double.infinity, // Ensure full width
            ),
          ),
          const SizedBox(
            height: 4,
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _userStreamController.stream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('Connection Error');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ShimmerLoadingList();
                }

                var docs = _searchController.text.isNotEmpty
                    ? _filteredLicenseEntries(_searchController.text)
                    : (snapshot.data?.docs ?? []).map((doc) => doc).toList();

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LicenseOnlyDetailsPage(
                              licenseDetails: docs[index].data(),
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(
                          right: 20,
                          left: 20,
                          top: 4,
                          bottom: 4,
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
                                padding: const EdgeInsets.only(
                                    top: 8, bottom: 8, left: 16, right: 16),
                                child: Center(
                                  child: CircleAvatar(
                                    backgroundColor: kPrimaryColor,
                                    radius: 50,
                                    child: Center(
                                      child: CircleAvatar(
                                        radius: 48,
                                        backgroundImage: docs[index]['image'] !=
                                                    null &&
                                                docs[index]['image'].isNotEmpty
                                            ? CachedNetworkImageProvider(
                                                    docs[index]['image'])
                                                as ImageProvider
                                            : const AssetImage(
                                                'assets/icons/user.png'),
                                      ),
                                    ),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            docs[index]['fullName'],
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            'BL: ${docs[index]['balanceAmount']}',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: kPrimaryColor),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        '${docs[index]['mobileNumber']}',
                                        style: listTextStyle,
                                      ),
                                      Text(
                                        '${docs[index]['cov']}',
                                        style: listTextStyle,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            top: 12, bottom: 8),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          EditLicenseOnlyForm(
                                                        initialValues:
                                                            docs[index].data(),
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
                                                    gradient:
                                                        const LinearGradient(
                                                      begin:
                                                          AlignmentDirectional
                                                              .topCenter,
                                                      end: AlignmentDirectional
                                                          .bottomCenter,
                                                      colors: linearButtonColor,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: const Center(
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsets.all(8.0),
                                                      child: Text(
                                                        'Update',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w600,
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
                                                  await _showDeleteConfirmationDialog(
                                                      docs[index].id);
                                                  setState(() {});
                                                },
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: inactiveButtonColor,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: const Center(
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsets.all(8.0),
                                                      child: Text(
                                                        'Inactive',
                                                        style: TextStyle(
                                                            color:
                                                                kRedInactiveTextColor,
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteData(String studentId) async {
    if (studentId.isNotEmpty) {
      var studentData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .collection('licenseonly')
          .doc(studentId)
          .get();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .collection('deactivated_licenseonly')
          .doc(studentId)
          .set(studentData.data() ?? {});

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .collection('licenseonly')
          .doc(studentId)
          .delete();
    }
  }

  Future<void> _showDeleteConfirmationDialog(String documentId) async {
  showCustomConfirmationDialog(
    context,
    'Confirm Deactivation?',
    'Are you sure ?',
    () async {
      await _deleteData(documentId);
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