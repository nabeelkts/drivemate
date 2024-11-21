import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mds/screens/dashboard/list/details/license_only_details_page.dart';
import 'package:mds/screens/widget/common_form.dart';

class LicenseOnly extends StatelessWidget {
  const LicenseOnly({super.key});

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    final CollectionReference usersCollection =
        FirebaseFirestore.instance.collection('users');
    final CollectionReference notificationsCollection =
        FirebaseFirestore.instance.collection('notifications');

    return Scaffold(
      appBar: AppBar(
        title: const Text('License Only'),
        elevation: 0,
      ),
      body: CommonForm(
        items: const [
          'M/C ',
          'LMV ',
          'LMV + M/C ',
        ],
        index: 2,
        showLicenseField: false,
        onFormSubmit: (licenseonly) {
          String studentId = licenseonly['studentId'];
          DateTime currentDate = DateTime.now();
          String formattedDate = currentDate.toLocal().toString();

          licenseonly['registrationDate'] = formattedDate;

          usersCollection
              .doc(user?.uid)
              .collection('licenseonly')
              .doc(studentId)
              .set(licenseonly)
              .then((value) {
            notificationsCollection.add({
              'title': 'New License Registration',
              'date': formattedDate,
              'details': 'Student Name: ${licenseonly['name']}\nCourse: ${licenseonly['course']}',
            }).then((value) {
              Fluttertoast.showToast(
                msg: 'License Only Registration Completed',
                fontSize: 18,
              );
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        LicenseOnlyDetailsPage(licenseDetails: licenseonly)),
              );
            }).catchError((error) {
              if (kDebugMode) {
                print('Failed to add notification: $error');
              }
            });
          }).catchError((error) {
            if (kDebugMode) {
              print('Failed to add license-only data: $error');
            }
          });
        },
      ),
    );
  }
}
