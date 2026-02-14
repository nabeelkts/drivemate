import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/controller/workspace_controller.dart';
import 'package:mds/screens/authentication/widgets/my_button.dart';
import 'package:mds/screens/dashboard/form/edit_forms/edit_vehicle_details_form.dart';

class RCDetailsPage extends StatelessWidget {
  final Map<String, dynamic> vehicleDetails;

  const RCDetailsPage({required this.vehicleDetails, super.key});

  final TextStyle labelStyle = const TextStyle(
    fontFamily: 'Inter',
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: Color(0xFF000000),
    height: 15.73 / 13,
  );
  final TextStyle valueStyle = const TextStyle(
    fontFamily: 'Inter',
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: Color(0xFF747474),
    height: 15.73 / 13,
  );

  @override
  Widget build(BuildContext context) {
    final WorkspaceController workspaceController =
        Get.find<WorkspaceController>();
    final targetId = workspaceController.currentSchoolId.value.isNotEmpty
        ? workspaceController.currentSchoolId.value
        : (FirebaseAuth.instance.currentUser?.uid ?? '');

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(targetId)
          .collection('vehicleDetails')
          .doc(vehicleDetails['studentId'].toString())
          .snapshots(),
      builder: (context, snapshot) {
        var currentDetails = vehicleDetails;
        if (snapshot.hasData && snapshot.data!.exists) {
          currentDetails = snapshot.data!.data() as Map<String, dynamic>;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('RC Details'),
            elevation: 0,
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      buildTableRow(
                          'Vehicle Number', currentDetails['vehicleNumber']),
                      const Divider(color: kDivider),
                      buildTableRow(
                          'Chassis Number', currentDetails['chassisNumber']),
                      const Divider(color: kDivider),
                      buildTableRow(
                          'Engine Number', currentDetails['engineNumber']),
                      const Divider(color: kDivider),
                      buildTableRow(
                          'Mobile Number', currentDetails['mobileNumber']),
                      const Divider(color: kDivider),
                      buildTableRow(
                          'Total Amount', currentDetails['totalAmount']),
                      const Divider(color: kDivider),
                      buildTableRow(
                          'Advance Amount', currentDetails['advanceAmount']),
                      const Divider(color: kDivider),
                      buildTableRow(
                          'Balance Amount', currentDetails['balanceAmount']),
                      const Divider(color: kDivider),
                      buildTableRow('Service', currentDetails['service']),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                  child: MyButton(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditVehicleDetailsForm(
                            initialValues: currentDetails,
                            items: currentDetails.keys.toList(),
                          ),
                        ),
                      );
                    },
                    text: 'Update Vehicle details',
                    isLoading: false,
                    isEnabled: true,
                    width: double.infinity,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildTableRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: labelStyle,
          ),
          Flexible(
            child: Text(
              '$value',
              style: valueStyle,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
