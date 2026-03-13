import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:drivemate/constants/colors.dart';
import 'package:get/get.dart';
import 'package:drivemate/controller/workspace_controller.dart';
import 'package:drivemate/screens/widget/custom_back_button.dart';
import 'package:drivemate/screens/authentication/widgets/my_button.dart';
import 'package:drivemate/screens/dashboard/form/edit_forms/edit_student_details_form.dart';
import 'package:drivemate/screens/dashboard/form/new_forms/new_student_form.dart';
import 'package:drivemate/screens/dashboard/list/deactivated_student_list.dart';
import 'package:drivemate/screens/dashboard/list/details/students_details_page.dart';
import 'package:drivemate/screens/dashboard/list/widgets/animated_search_widget.dart';
import 'package:drivemate/screens/dashboard/list/widgets/shimmer_loading_list.dart';
import 'package:drivemate/screens/dashboard/list/widgets/summary_header.dart';
import 'package:drivemate/screens/dashboard/list/widgets/list_item_card.dart';
import 'package:drivemate/screens/profile/dialog_box.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StudentList extends StatefulWidget {
  final String userId;

  const StudentList({required this.userId, super.key});

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
        print('📊 StudentList received ${snapshot.docs.length} docs');
        _userStreamController.add(snapshot);
        setState(() {
          // Filter out soft-deleted and invalid documents
          _allStudents = snapshot.docs.where((doc) {
            final data = doc.data();
            // Exclude soft-deleted items (in recycle bin)
            if (data['isDeleted'] == true) return false;
            // Only include documents with basic required fields
            return data.containsKey('fullName') ||
                data.containsKey('name') ||
                data.containsKey('mobileNumber');
          }).toList();
          print('   After filtering: ${_allStudents.length} students');
        });
      }
    }, onError: (error) {
      print('❌ Firestore error in student list: $error');
      if (mounted) {
        // Add error to stream so it can be displayed
        _userStreamController.addError(error);
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
    final filtered = _allStudents.where((doc) {
      // Check for both possible field names
      final fullName = doc['fullName']?.toString().toLowerCase() ??
          doc['name']?.toString().toLowerCase() ??
          '';
      final mobileNumber = doc['mobileNumber']?.toString().toLowerCase() ?? '';
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

          AnimatedSearchWidget(
            primaryPlaceholder: 'Search by Name',
            secondaryPlaceholder: 'Search by Mobile Number',
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
                  print('❌ Firestore Error Details:');
                  print('   Error: ${snapshot.error}');
                  print('   Stack Trace: ${snapshot.stackTrace}');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        const Text(
                          'Error Loading Data',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            '${snapshot.error}',
                            style: const TextStyle(
                                fontSize: 14, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Check console for details',
                          style: TextStyle(fontSize: 12, color: Colors.orange),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ShimmerLoadingList();
                }

                var docs = _searchController.text.isNotEmpty
                    ? _filteredStudents(_searchController.text)
                    : (snapshot.data?.docs ?? []).map((doc) => doc).toList();

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
                      title: data['fullName'] ?? data['name'] ?? 'N/A',
                      subTitle:
                          'COV: ${data['cov'] ?? 'N/A'}\nMobile: ${data['mobileNumber'] ?? 'N/A'}',
                      imageUrl: data['image'],
                      isDark: isDark,
                      status: data['testStatus'],
                      onTap: () {
                        final enriched = Map<String, dynamic>.from(data);
                        enriched['id'] = docs[index].id;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                StudentDetailsPage(studentDetails: enriched),
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
              const Padding(
                padding: EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Student Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Test Passed'),
                onTap: () async {
                  Navigator.pop(context);
                  await _showStatusConfirmationDialog(
                      doc.id, doc.data(), 'passed');
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.red),
                title: const Text('Test Failed'),
                onTap: () async {
                  Navigator.pop(context);
                  await _showStatusConfirmationDialog(
                      doc.id, doc.data(), 'failed');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateStudentStatus(
      String studentId, Map<String, dynamic> studentData, String status) async {
    final schoolId = _workspaceController.currentSchoolId.value;
    final targetId = schoolId.isNotEmpty ? schoolId : widget.userId;

    if (studentId.isNotEmpty && studentData.isNotEmpty) {
      // Add status to student data
      studentData['testStatus'] = status;
      studentData['testDate'] = DateTime.now().toIso8601String();

      if (status == 'passed') {
        // Move to course completed (deactivated_students)
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
      } else {
        // Just update the status in place for failed students
        await FirebaseFirestore.instance
            .collection('users')
            .doc(targetId)
            .collection('students')
            .doc(studentId)
            .update({
          'testStatus': status,
          'testDate': DateTime.now().toIso8601String(),
        });
      }
    }
  }

  Future<void> _showStatusConfirmationDialog(String documentId,
      Map<String, dynamic> studentData, String status) async {
    final isPassed = status == 'passed';
    showCustomConfirmationDialog(
      context,
      isPassed ? 'Confirm Test Passed' : 'Confirm Test Failed',
      isPassed
          ? 'Are you sure the student passed the test? This will move them to Course Completed.'
          : 'Are you sure the student failed the test? A failed badge will be shown.',
      () async {
        await _updateStudentStatus(documentId, studentData, status);
        // Navigator.pop is now handled automatically by showCustomConfirmationDialog
        if (isPassed) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const DeactivatedStudentList(),
            ),
          );
        } else {
          setState(() {});
        }
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
