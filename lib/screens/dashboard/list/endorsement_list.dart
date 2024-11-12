import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/screens/authentication/widgets/my_button.dart';
import 'package:mds/screens/dashboard/form/edit_forms/edit_endorsement_details_form.dart';
import 'package:mds/screens/dashboard/form/new_forms/endorment_dl_form.dart';
import 'package:mds/screens/dashboard/list/deactivated_endorsement_list.dart';
import 'package:mds/screens/dashboard/list/details/endorsement_details_page.dart';
import 'package:mds/screens/dashboard/list/widgets/search_widget.dart';
import 'package:mds/screens/dashboard/list/widgets/shimmer_loading_list.dart';

class EndorsementList extends StatefulWidget {
  final String userId;

  const EndorsementList({required this.userId, Key? key}) : super(key: key);

  @override
  State<EndorsementList> createState() => _EndorsementListState();
}

User? user = FirebaseAuth.instance.currentUser;

class _EndorsementListState extends State<EndorsementList> {
  bool isLoading = false;
  final _userStreamController =
      StreamController<QuerySnapshot<Map<String, dynamic>>>();
  late StreamSubscription<QuerySnapshot<Map<String, dynamic>>>
      _userStreamSubscription;

  TextEditingController _searchController = TextEditingController();
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _allEndorsements = [];

  @override
  void initState() {
    super.initState();
    _userStreamSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user?.uid)
        .collection('endorsement')
        .snapshots()
        .listen((snapshot) {
      _userStreamController.add(snapshot);
      setState(() {
        _allEndorsements = snapshot.docs;
      });
    });
  }

  @override
  void dispose() {
    _userStreamSubscription.cancel();
    _userStreamController.close();
    super.dispose();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filteredEndorsements(
      String query) {
    return _allEndorsements
        .where((doc) =>
            doc['fullName'].toLowerCase().contains(query.toLowerCase()) ||
            doc['mobileNumber'].toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: const Text(
          'Endorsement List',
          style: TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: Center(
          child: CircleAvatar(
            backgroundColor: kWhite,
            child: CircleAvatar(
              backgroundColor: kPrimaryColor,
              radius:
                  15, // Increase the radius to provide enough space for the IconButton
              child: Center(
                child: CircleAvatar(
                  radius:
                      14, // Adjust the radius to make the inner CircleAvatar smaller
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
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DeactivatedEndorsementList(),
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
          MyButton(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EndorsementDL()),
              );
            },
            text: 'Create New Endorsement',
            isLoading: isLoading,
            isEnabled: true,
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
                    ? _filteredEndorsements(_searchController.text)
                    : (snapshot.data?.docs ?? []).map((doc) => doc).toList();

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EndorsementDetailsPage(
                              endorsementDetails: docs[index].data(),
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
                            color: kWhite, // Set the card background color
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: kPrimaryColor, // Set the border color
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
                                            : AssetImage(
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
                                            style: TextStyle(
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
                                                  // Handle edit action
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          EditEndorsementDetailsForm(
                                                        initialValues:
                                                            docs[index].data(),
                                                        items: [
                                                          'M/C',
                                                          'LMV',
                                                          'LMV + M/C ',
                                                          'TRANS',
                                                          'TRANS + M/C',
                                                          'EXCAVATOR',
                                                          'TRACTOR',
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
      // Get the student data
      var studentData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .collection('endorsement')
          .doc(studentId)
          .get();

// Move the student data to the "deactivated_students" collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .collection('deactivated_endorsement')
          .doc(studentId)
          .set(studentData.data() ?? {});

      // Delete the student data from the original collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .collection('students')
          .doc(studentId)
          .delete();
    }
  }

  Future<void> _showDeleteConfirmationDialog(String documentId) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmation'),
          content:
              const Text('Are you sure you want to Deactivate this student?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await _deleteData(documentId);
                // ignore: use_build_context_synchronously
                Navigator.of(context).pop(); // Close the dialog

                // Navigate to the "Deactivated List" page
                // ignore: use_build_context_synchronously
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DeactivatedEndorsementList(),
                  ),
                );
              },
              child: const Text(
                'Deactivate',
                style: TextStyle(color: kRed),
              ),
            ),
          ],
        );
      },
    );
  }
}
