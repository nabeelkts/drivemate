import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/screens/authentication/widgets/my_button.dart';
import 'package:mds/screens/dashboard/form/edit_forms/edit_student_details_form.dart';
import 'package:mds/screens/dashboard/list/deactivated_student_list.dart';
import 'package:mds/screens/dashboard/list/details/students_details_page.dart';
import 'package:mds/screens/dashboard/list/widgets/search_widget.dart';
import 'package:mds/screens/dashboard/list/widgets/shimmer_loading_list.dart';
import 'package:mds/screens/widget/student_form.dart';

class StudentList extends StatefulWidget {
  final String userId;

  const StudentList({required this.userId, Key? key}) : super(key: key);

  @override
  State<StudentList> createState() => _StudentListState();
}

User? user = FirebaseAuth.instance.currentUser;

class _StudentListState extends State<StudentList> {
  bool isLoading = false;
  final _userStreamController =
      StreamController<QuerySnapshot<Map<String, dynamic>>>();
  late StreamSubscription<QuerySnapshot<Map<String, dynamic>>>
      _userStreamSubscription;

  final TextEditingController _searchController = TextEditingController();
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _allStudents = [];

  @override
  void initState() {
    super.initState();
    _userStreamSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user?.uid)
        .collection('students')
        .snapshots()
        .listen((snapshot) {
      _userStreamController.add(snapshot);
      setState(() {
        _allStudents = snapshot.docs;
      });
    });
  }

  @override
  void dispose() {
    _userStreamSubscription.cancel();
    _userStreamController.close();
    super.dispose();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filteredStudents(
      String query) {
    return _allStudents
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
          'Student List',
          style: TextStyle(
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
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DeactivatedStudentList(),
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
                MaterialPageRoute(builder: (context) => const StudentForm()),
              );
            },
            text: 'Create New Student',
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
                    ? _filteredStudents(_searchController.text)
                    : (snapshot.data?.docs ?? []).map((doc) => doc).toList();

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StudentDetailsPage(
                              studentDetails: docs[index].data(),
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
                                                          EditStudentDetailsForm(
                                                        initialValues:
                                                            docs[index].data(),
                                                        items: const [
                                                          'M/C Study',
                                                          'LMV Study',
                                                          'LMV Study + M/C Study',
                                                          'LMV Study + M/C License'
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
          .collection('students')
          .doc(studentId)
          .get();

      // Move the student data to the "deactivated_students" collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .collection('deactivated_students')
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
                    builder: (context) => const DeactivatedStudentList(),
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
