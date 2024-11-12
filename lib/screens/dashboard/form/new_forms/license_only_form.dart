import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
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
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          const CupertinoSliverNavigationBar(
            backgroundColor: Colors.transparent,
            largeTitle: Text(
              'License Only',
              style: TextStyle(fontSize: 25),
            ),
            border: Border(),
          ),
        ],
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

            // Include the date and time in the student data
            licenseonly['registrationDate'] = formattedDate;
            // Append the student data to the 'licenseonly' collection in Firestore
            usersCollection
                .doc(user?.uid) // Assuming the user is logged in
                .collection('licenseonly')
              ..doc(studentId) // Set the document ID as the studentId
                  .set(licenseonly)
                  .then((value) {
                // Show a toast or navigate to a success screen
                Fluttertoast.showToast(
                  msg: 'License Only Registration Completed',
                  fontSize: 18,
                ); // Navigate to the LicenseOnlyDetailsPage
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          LicenseOnlyDetailsPage(licenseDetails: licenseonly)),
                );
              }).catchError((error) {
                // Handle errors
              });
          },
        ),
      ),
    );
  }
}
