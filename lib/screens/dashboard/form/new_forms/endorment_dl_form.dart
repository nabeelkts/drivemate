import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mds/screens/dashboard/list/details/endorsement_details_page.dart';
import 'package:mds/screens/widget/common_form.dart';

class EndorsementDL extends StatelessWidget {
  const EndorsementDL({super.key});

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
              'Endorsement to DL',
              style: TextStyle(fontSize: 25),
            ),
            border: Border(),
          ),
        ],
        body: CommonForm(
          items: const [
            'M/C',
            'LMV',
            'LMV + M/C ',
            'TRANS',
            'TRANS + M/C',
          ],
          index: 1,
          showLicenseField: true,
          onFormSubmit: (endorsement) {
            String studentId = endorsement['studentId'];
            // Get the current date and time
            DateTime currentDate = DateTime.now();
            String formattedDate = currentDate.toLocal().toString();

            // Include the date and time in the student data
            endorsement['registrationDate'] = formattedDate;
            // Append the student data to the 'endorsement' collection in Firestore
            // ignore: avoid_single_cascade_in_expression_statements
            usersCollection
                .doc(user?.uid) // Assuming the user is logged in
                .collection('endorsement')
              ..doc(studentId) // Set the document ID as the studentId
                  .set(endorsement)
                  .then((value) {
                // Show a toast or navigate to a success screen
                Fluttertoast.showToast(
                  msg: 'Endorsement Registration Completed',
                  fontSize: 18,
                ); // Navigate to the dashboard
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => EndorsementDetailsPage(
                          endorsementDetails: endorsement)),
                );
              }).catchError((error) {
                // Handle errors
                if (kDebugMode) {
                  print('Failed to add endorsement: $error');
                }
              });
          },
        ),
      ),
    );
  }
}
