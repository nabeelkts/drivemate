// ignore_for_file: avoid_single_cascade_in_expression_statements

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mds/screens/dashboard/list/details/students_details_page.dart';
import 'package:mds/screens/widget/common_form.dart';

class NewStudent extends StatelessWidget {
  const NewStudent({super.key});

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    final CollectionReference usersCollection =
        FirebaseFirestore.instance.collection('users');
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          const CupertinoSliverNavigationBar(
            backgroundColor: Colors.transparent,
            largeTitle: Text(
              'New Student',
              style: TextStyle(fontSize: 25),
            ),
            border: Border(),
          ),
        ],
        body: CommonForm(
          items: const [
            'M/C Study',
            'LMV Study',
            'LMV Study + M/C Study',
            'LMV Study + M/C License',
          ],
          index: 3,
          showLicenseField: false,
          onFormSubmit: (student) {
            String studentId = student['studentId'];
            // Get the current date and time
            DateTime currentDate = DateTime.now();
            String formattedDate = currentDate.toLocal().toString();

            // Include the date and time in the student data
            student['registrationDate'] = formattedDate;
            // Append the student data to the 'students' collection in Firestore
            usersCollection
                .doc(user?.uid) // Assuming the user is logged in
                .collection('students')
              ..doc(studentId) // Set the document ID as the studentId
                  .set(student)
                  .then((value) {
                // Show a toast or navigate to a success screen
                Fluttertoast.showToast(
                  msg: 'New Student Registration Completed',
                  fontSize: 18,
                ); // Navigate to the dashboard
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          StudentDetailsPage(studentDetails: student)),
                );
                // Replace with your dashboard screen
              }).catchError((error) {
                // Handle errors
                if (kDebugMode) {
                  print('Failed to add student: $error');
                }
              });
          },
        ),
      ),
    );
  }
}
