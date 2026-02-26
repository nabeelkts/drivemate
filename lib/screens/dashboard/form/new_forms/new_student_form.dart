import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:mds/controller/workspace_controller.dart';
import 'package:mds/screens/dashboard/list/details/students_details_page.dart';
import 'package:mds/screens/widget/common_form.dart';
import 'package:mds/screens/widget/custom_back_button.dart';
import 'package:mds/screens/widget/utils.dart';

class NewStudent extends StatefulWidget {
  const NewStudent({super.key});

  @override
  State<NewStudent> createState() => _NewStudentState();
}

class _NewStudentState extends State<NewStudent> {
  final GlobalKey<CommonFormState> _formKey = GlobalKey<CommonFormState>();
  final WorkspaceController _workspaceController =
      Get.find<WorkspaceController>();

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (kDebugMode) {
        print('Error: No authenticated user found');
      }
      return const Scaffold(
        body: Center(
          child: Text('Please login to continue'),
        ),
      );
    }

    final CollectionReference usersCollection =
        FirebaseFirestore.instance.collection('users');

    final schoolId = _workspaceController.currentSchoolId.value;
    final targetId = schoolId.isNotEmpty ? schoolId : user.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Student'),
        leading: const CustomBackButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined),
            onPressed: () => _formKey.currentState?.smartFill(),
            tooltip: 'Smart Fill',
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => _formKey.currentState?.submitForm(),
          ),
        ],
        elevation: 0,
      ),
      body: CommonForm(
        key: _formKey,
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
        index: 3,
        showLicenseField: false,
        onFormSubmit: (student) async {
          try {
            if (kDebugMode) {
              print('Form submitted with data:');
              print('Student data: $student');
            }

            // Validate required fields
            if (student['fullName'] == null ||
                student['fullName'].toString().isEmpty) {
              throw Exception('Full name is required');
            }
            if (student['cov'] == null || student['cov'].toString().isEmpty) {
              throw Exception('Class of vehicle is required');
            }

            // Generate a date-based unique studentId if not provided (ddMMyyyy0001)
            String? studentId = student['studentId'];
            if (studentId == null || studentId.isEmpty) {
              studentId = await generateStudentId(targetId);
              student['studentId'] = studentId;
            }

            DateTime currentDate = DateTime.now();
            String formattedDate = currentDate.toIso8601String();
            student['registrationDate'] = formattedDate;

            String fullName = student['fullName'] ?? '';
            String cov = student['cov'] ?? '';

            // Inject Branch Info
            final branchId = _workspaceController.currentBranchId.value;
            final branchData = _workspaceController.currentBranchData;
            final branchName = branchData['branchName'] ?? 'Main';

            student['branchId'] = branchId;
            student['branchName'] = branchName;

            if (kDebugMode) {
              print('Adding student with ID: $studentId');
              print('Full Name: $fullName');
              print('Type: $cov');
            }

            // Prepare all Firestore operations
            final List<Future> operations = [];

            // 1. Add student document
            operations.add(usersCollection
                .doc(targetId)
                .collection('students')
                .doc(studentId)
                .set(student));

            // 2. Record initial payment transaction if any
            final advance =
                double.tryParse(student['advanceAmount']?.toString() ?? '0') ??
                    0;
            if (advance > 0) {
              operations.add(usersCollection
                  .doc(targetId)
                  .collection('students')
                  .doc(studentId)
                  .collection('payments')
                  .add({
                'amount': advance,
                'mode': student['paymentMode'] ?? 'Cash',
                'date': Timestamp.now(),
                'description': 'Initial Advance',
                'createdAt': FieldValue.serverTimestamp(),
                'targetId': targetId,
                'recordId': studentId,
                'recordName': fullName,
                'category': 'students',
                'branchId': branchId,
                'branchName': branchName,
              }));
            }

            // 3. Add notification
            operations.add(
                usersCollection.doc(targetId).collection('notifications').add({
              'title': 'New Student Registration',
              'date': formattedDate,
              'details': 'Name: $fullName\nCourse: $cov',
              'read': false,
              'type': 'student',
              'studentId': studentId,
              'timestamp': FieldValue.serverTimestamp(),
              'branchId': branchId,
              'branchName': branchName,
            }));

            // 4. Add to recent activity
            operations.add(
                usersCollection.doc(targetId).collection('recentActivity').add({
              'title': 'New Student Registration',
              'details': '$fullName\n$cov',
              'timestamp': FieldValue.serverTimestamp(),
              'studentId': studentId,
              'type': 'student',
              'imageUrl': student['image'],
              'branchId': branchId,
              'branchName': branchName,
            }));

            // Execute operations in parallel WITHOUT awaiting them all to prevent UI hang
            // Firestore persistence will handle the background synchronization.
            unawaited(Future.wait(operations).then((_) {
              if (kDebugMode) {
                print('All background sync operations initiated successfully');
              }
            }).catchError((e) {
              if (kDebugMode) {
                print('Background sync error (safe to ignore if offline): $e');
              }
            }));

            Fluttertoast.showToast(
              msg: 'Registration initiated...',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
            );

            if (context.mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      StudentDetailsPage(studentDetails: student),
                ),
              );
            }
          } catch (error) {
            if (kDebugMode) {
              print('Error in form submission: $error');
            }
            Fluttertoast.showToast(
              msg: 'Error: ${error.toString()}',
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Colors.red,
            );
          }
        },
      ),
    );
  }
}
