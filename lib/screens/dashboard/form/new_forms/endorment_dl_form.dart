import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Endorsement to DL'),
        elevation: 0,
      ),
      body: CommonForm(
        items: const [
          'M/C',
          'LMV',
          'LMV + M/C ',
          'TRANS',
          'TRANS + M/C',
        ],
        index: 1,
        showLicenseField: true, // Ensure this is true to show the license field
        onFormSubmit: (endorsement) {
          String studentId = endorsement['studentId'];
          DateTime currentDate = DateTime.now();
          String formattedDate = currentDate.toLocal().toString();

          endorsement['registrationDate'] = formattedDate;

          usersCollection
              .doc(user?.uid)
              .collection('endorsement')
              .doc(studentId)
              .set(endorsement)
              .then((value) {
            Fluttertoast.showToast(
              msg: 'Endorsement Registration Completed',
              fontSize: 18,
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      EndorsementDetailsPage(endorsementDetails: endorsement)),
            );
          }).catchError((error) {
            if (kDebugMode) {
              print('Failed to add endorsement: $error');
            }
          });
        },
      ),
    );
  }
}
