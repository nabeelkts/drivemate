import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/screens/dashboard/form/edit_forms/edit_student_details_form.dart';
import 'package:get/get.dart';
import 'package:mds/screens/widget/custom_back_button.dart';
import 'package:mds/controller/workspace_controller.dart';
import 'package:mds/screens/dashboard/list/details/students_details_page.dart';
import 'package:mds/screens/dashboard/list/widgets/animated_search_widget.dart';
import 'package:mds/screens/dashboard/list/widgets/shimmer_loading_list.dart';
import 'package:mds/screens/dashboard/list/widgets/list_item_card.dart';
import 'package:mds/screens/profile/dialog_box.dart';

class DeactivatedStudentList extends StatefulWidget {
  const DeactivatedStudentList({super.key});

  @override
  State<DeactivatedStudentList> createState() => _DeactivatedStudentListState();
}

class _DeactivatedStudentListState extends State<DeactivatedStudentList> {
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _streamSubscription;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _allDeactivatedStudents =
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
        .collection('deactivated_students')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _allDeactivatedStudents = snapshot.docs;
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

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filteredStudents(
      String query) {
    final filtered = _allDeactivatedStudents.where((doc) {
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

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Course Completed Students',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: const CustomBackButton(),
      ),
      body: Column(
        children: [
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
                  .collection('deactivated_students')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('Connection Error');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ShimmerLoadingList();
                }

                var docs = _searchController.text.isNotEmpty
                    ? _filteredStudents(_searchController.text)
                    : snapshot.data?.docs ?? [];

                // Sort by newest to oldest (registrationDate) when not searching
                if (_searchController.text.isEmpty) {
                  docs.sort((a, b) {
                    final aDate = a.data()['registrationDate'] as String? ?? '';
                    final bDate = b.data()['registrationDate'] as String? ?? '';
                    return bDate.compareTo(aDate);
                  });
                }

                if (docs.isEmpty) {
                  return const Center(
                    child: Text('No deactivated students found'),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    return buildStudentListItem(context, docs[index], data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildStudentListItem(
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
      status: data['testStatus'],
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StudentDetailsPage(
              studentDetails: data,
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
                title: const Text('Reactivate Student'),
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
                      builder: (context) => EditStudentDetailsForm(
                        initialValues: doc.data() ?? {},
                        items: const [
                          'MC Study',
                          'MCWOG Study',
                          'LMV Study',
                          'LMV Study + MC Study',
                          'LMV Study + MCWOG Study',
                          'LMV Study + MC License',
                          'LMV Study + MCWOG License',
                          'LMV License + MC Study',
                          'LMV License + MCWOG Study',
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
      String studentId, Map<String, dynamic> studentData) async {
    final schoolId = _workspaceController.currentSchoolId.value;
    final user = FirebaseAuth.instance.currentUser;
    final targetId = schoolId.isNotEmpty ? schoolId : user?.uid;

    if (studentId.isNotEmpty && studentData.isNotEmpty) {
      if (targetId == null) return;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetId)
          .collection('students')
          .doc(studentId)
          .set(studentData);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetId)
          .collection('deactivated_students')
          .doc(studentId)
          .delete();
    }
  }

  Future<void> _showActivateConfirmationDialog(
      String documentId, Map<String, dynamic> studentData) async {
    showCustomConfirmationDialog(
      context,
      'Confirm Activation?',
      'Are you sure ?',
      () async {
        await _activateData(documentId, studentData);
        Navigator.of(context).pop();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const DeactivatedStudentList(),
          ),
        );
      },
    );
  }
}
