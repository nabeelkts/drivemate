import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mds/screens/dashboard/form/edit_forms/edit_student_details_form.dart';
import 'package:mds/screens/dashboard/list/details/students_details_page.dart';
import 'package:mds/screens/dashboard/list/widgets/search_widget.dart';
import 'package:mds/screens/dashboard/list/widgets/shimmer_loading_list.dart';

class DeactivatedStudentList extends StatefulWidget {
  const DeactivatedStudentList({super.key});

  @override
  State<DeactivatedStudentList> createState() => _DeactivatedStudentListState();
}

User? user = FirebaseAuth.instance.currentUser;

class _DeactivatedStudentListState extends State<DeactivatedStudentList> {
  final _userStream = FirebaseFirestore.instance
      .collection('users')
      .doc(user?.uid)
      .collection('deactivated_students')
      .snapshots();
  final TextEditingController _searchController = TextEditingController();
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _allDeactivatedStudents =
      [];
  @override
  void initState() {
    super.initState();
    _userStream.listen((snapshot) {
      setState(() {
        _allDeactivatedStudents = snapshot.docs;
      });
    });
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filteredStudents(
      String query) {
    return _allDeactivatedStudents
        .where((doc) =>
            doc['fullName'].toLowerCase().contains(query.toLowerCase()) ||
            doc['mobileNumber'].toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(255, 251, 247, 1),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(255, 251, 247, 1),
        title: const Text(
          'Deactivated Students List',
          style: TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: CircleAvatar(
          backgroundColor: Colors.white,
          child: IconButton(
            icon: SvgPicture.asset(
              'assets/icons/left_circle.svg',
              height: 20,
              width: 20,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              top: 4,
              bottom: 4,
              right: 16,
              left: 16,
            ),
            child: SearchWidget(
              placeholder: 'Search by Name or Mobile Number',
              controller: _searchController,
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _userStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('Connection Error');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ShimmerLoadingList();
                }

                var deactivatedStudents = snapshot.data?.docs ?? [];
                var docs = _searchController.text.isNotEmpty
                    ? _filteredStudents(_searchController.text)
                    : (snapshot.data?.docs ?? []).map((doc) => doc).toList();
                return ListView.builder(
                  itemCount: deactivatedStudents.length,
                  itemBuilder: (context, index) {
                    // Sort the docs list alphabetically based on 'fullName'
                    docs.sort((a, b) => a['fullName'].compareTo(b['fullName']));
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
                        padding: const EdgeInsets.only(right: 16, left: 16),
                        child: Card(
                          shadowColor: const Color.fromARGB(238, 168, 73, 1),
                          color: Colors.white,
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                    top: 8, bottom: 8, left: 16, right: 16),
                                child: Center(
                                  child: CircleAvatar(
                                    backgroundColor:
                                        const Color.fromRGBO(221, 104, 98, 1),
                                    radius: 50,
                                    child: Center(
                                      child: CircleAvatar(
                                        radius: 48,
                                        backgroundImage:
                                            CachedNetworkImageProvider(
                                          docs[index]['image'] != null &&
                                                  docs[index]['image']
                                                      .isNotEmpty
                                              ? docs[index]['image']
                                              : 'assets/icons/user.png',
                                        ),
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
                                                color: Color.fromRGBO(
                                                    223, 124, 66, 1)),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        '${docs[index]['mobileNumber']}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        '${docs[index]['cov']}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
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
                                                    gradient: const LinearGradient(
                                                      begin:
                                                          AlignmentDirectional
                                                              .topCenter,
                                                      end: AlignmentDirectional
                                                          .bottomCenter,
                                                      colors: [
                                                        Color.fromRGBO(
                                                            255, 111, 97, 1),
                                                        Color.fromRGBO(
                                                            238, 168, 73, 1),
                                                      ],
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: const Center(
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsets.all(
                                                              8.0),
                                                      child: Text(
                                                        'Update',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 16,
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
                                                  await _showActivateConfirmationDialog(
                                                      docs[index].id);
                                                  setState(() {});
                                                },
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: const Color.fromRGBO(
                                                        254, 243, 237, 1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: const Center(
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsets.all(
                                                              8.0),
                                                      child: Text(
                                                        'Activate',
                                                        style: TextStyle(
                                                            color:
                                                                Color.fromRGBO(
                                                                    255,
                                                                    90,
                                                                    90,
                                                                    1),
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

  Future<void> _activateData(String studentId) async {
    if (studentId.isNotEmpty) {
      // Get the student data
      var studentData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .collection('deactivated_students')
          .doc(studentId)
          .get();
// Move the student data to the "students" collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .collection('students')
          .doc(studentId)
          .set(studentData.data() ?? {});
      // Delete the deactivated_students data from the original collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .collection('deactivated_students')
          .doc(studentId)
          .delete();
    }
  }

  Future<void> _showActivateConfirmationDialog(String documentId) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmation'),
          content:
              const Text('Are you sure you want to Activate this student?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await _activateData(documentId);
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
                'Activate',
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        );
      },
    );
  }
}
