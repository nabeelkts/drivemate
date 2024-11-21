/* lib/screens/dashboard/form/new_forms/new_student_form.dart */
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    final CollectionReference notificationsCollection =
        FirebaseFirestore.instance.collection('notifications');

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Student'),
        elevation: 0,
      ),
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
          DateTime currentDate = DateTime.now();
          String formattedDate = currentDate.toLocal().toString();

          student['registrationDate'] = formattedDate;

          usersCollection
              .doc(user?.uid)
              .collection('students')
              .doc(studentId)
              .set(student)
              .then((value) {
            notificationsCollection.add({
              'title': 'New Student Registration',
              'date': formattedDate,
              'details': 'Student Name: ${student['name']}\nCourse: ${student['course']}',
            }).then((value) {
              Fluttertoast.showToast(
                msg: 'New Student Registration Completed',
                fontSize: 18,
              );
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        StudentDetailsPage(studentDetails: student)),
              );
            }).catchError((error) {
              if (kDebugMode) {
                print('Failed to add notification: $error');
              }
            });
          }).catchError((error) {
            if (kDebugMode) {
              print('Failed to add student: $error');
            }
          });
        },
      ),
    );
  }
}
