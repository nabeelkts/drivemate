// ignore_for_file: use_build_context_synchronously, use_super_parameters

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mds/constants/colors.dart';
import 'package:get/get.dart';
import 'package:mds/controller/workspace_controller.dart';
import 'package:mds/screens/widget/custom_back_button.dart';
import 'package:mds/screens/authentication/widgets/my_button.dart';
import 'package:mds/screens/dashboard/form/edit_forms/edit_student_details_form.dart';
import 'package:mds/screens/dashboard/form/new_forms/new_student_form.dart';
import 'package:mds/screens/dashboard/list/deactivated_student_list.dart';
import 'package:mds/screens/dashboard/list/details/students_details_page.dart';
import 'package:mds/screens/dashboard/list/widgets/search_widget.dart';
import 'package:mds/screens/dashboard/list/widgets/shimmer_loading_list.dart';
import 'package:mds/screens/dashboard/list/widgets/summary_header.dart';
import 'package:mds/screens/dashboard/list/widgets/list_item_card.dart';
import 'package:mds/screens/profile/dialog_box.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StudentList extends StatefulWidget {
  final String userId;

  const StudentList({required this.userId, Key? key}) : super(key: key);

  @override
  State<StudentList> createState() => _StudentListState();
}

class _StudentListState extends State<StudentList> {
  final _userStreamController =
      StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();
  late StreamSubscription<QuerySnapshot<Map<String, dynamic>>>
      _userStreamSubscription;

  final TextEditingController _searchController = TextEditingController();
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _allStudents = [];
  final WorkspaceController _workspaceController =
      Get.find<WorkspaceController>();

  @override
  void initState() {
    super.initState();

    _userStreamSubscription = _workspaceController
        .getFilteredCollection('students')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        _userStreamController.add(snapshot);
        setState(() {
          _allStudents = snapshot.docs;
        });
      }
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color ?? kBlack;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Student List',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: const CustomBackButton(),
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
          // New Summary Header
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _userStreamController.stream,
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];
              double totalDues = 0;
              for (var doc in docs) {
                totalDues += double.tryParse(
                        doc.data()['balanceAmount']?.toString() ?? '0') ??
                    0;
              }
              return ListSummaryHeader(
                totalLabel: 'Total Students:',
                totalCount: docs.length,
                pendingDues: totalDues,
                isDark: isDark,
              );
            },
          ),

          SearchWidget(
            placeholder: 'Search by Name or Mobile Number',
            controller: _searchController,
            onChanged: (value) {
              setState(() {});
            },
          ),

          const SizedBox(height: 8),

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

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No data found',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: kPrimaryColor,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  padding: const EdgeInsets.only(
                      bottom: 80), // Space for FAB if needed
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
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
                            builder: (context) => StudentDetailsPage(
                              studentDetails: data,
                            ),
                          ),
                        );
                      },
                      onMenuPressed: () {
                        _showMenuOptions(context, docs[index]);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NewStudent()),
    );
  },
  backgroundColor: kPrimaryColor,
  icon: const Icon(Icons.add, color: Colors.white),
  label: const Text(
    'New Student',
    style: TextStyle(color: Colors.white),
  ),
),
    );
  }

  void _showMenuOptions(
      BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> doc) {
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
                leading: const Icon(Icons.check_circle_outline,
                    color: kPrimaryColor),
                title: const Text('Course Completed'),
                onTap: () async {
                  Navigator.pop(context);
                  await _showDeleteConfirmationDialog(doc.id, doc.data());
                  setState(() {});
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteData(
      String studentId, Map<String, dynamic> studentData) async {
    final schoolId = _workspaceController.currentSchoolId.value;
    final targetId = schoolId.isNotEmpty ? schoolId : widget.userId;

    if (studentId.isNotEmpty && studentData.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetId)
          .collection('deactivated_students')
          .doc(studentId)
          .set(studentData);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetId)
          .collection('students')
          .doc(studentId)
          .delete();
    }
  }

  Future<void> _showDeleteConfirmationDialog(
      String documentId, Map<String, dynamic> studentData) async {
    showCustomConfirmationDialog(
      context,
      'Confirm Course Completion',
      'Are you sure ?',
      () async {
        await _deleteData(documentId, studentData);
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

  Widget _buildInitials(DocumentSnapshot<Map<String, dynamic>> doc) {
    final fullName = doc['fullName'];
    return Center(
      child: Text(
        fullName != null && fullName.toString().isNotEmpty
            ? fullName[0].toUpperCase()
            : '',
        style: const TextStyle(
          fontSize: 28,
          color: kPrimaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
