import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/screens/authentication/widgets/my_button.dart';
import 'package:mds/screens/dashboard/form/edit_forms/edit_endorsement_details_form.dart';

class EndorsementDetailsPage extends StatelessWidget {
  final Map<String, dynamic> endorsementDetails;

  const EndorsementDetailsPage({required this.endorsementDetails, super.key});

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Endorsement Details'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 60,
              backgroundColor: kWhite,
              backgroundImage: endorsementDetails['image'] != null && endorsementDetails['image'].isNotEmpty
                  ? CachedNetworkImageProvider(endorsementDetails['image'])
                  : null,
              child: endorsementDetails['image'] == null || endorsementDetails['image'].isEmpty
                  ? Text(
                      endorsementDetails['fullName'] != null && endorsementDetails['fullName'].isNotEmpty
                          ? endorsementDetails['fullName'][0].toUpperCase()
                          : '',
                      style: const TextStyle(fontSize: 40, color: kPrimaryColor),
                    )
                  : null,
            ),
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
                  buildTableRow('Student Id', endorsementDetails['studentId']),
                  const Divider(color: kDivider),
                  buildTableRow('Full Name', endorsementDetails['fullName']),
                  const Divider(color: kDivider),
                  buildTableRow('Guardian Name', endorsementDetails['guardianName']),
                  const Divider(color: kDivider),
                  buildTableRow('Date of Birth', endorsementDetails['dob']),
                  const Divider(color: kDivider),
                  buildTableRow('Mobile Number', endorsementDetails['mobileNumber']),
                  const Divider(color: kDivider),
                  buildTableRow('Emergency Number', endorsementDetails['emergencyNumber']),
                  const Divider(color: kDivider),
                  buildTableRow('Blood Group', endorsementDetails['bloodGroup']),
                  const Divider(color: kDivider),
                  buildTableRow('Class of Vehicle', endorsementDetails['cov']),
                  const Divider(color: kDivider),
                  buildAddressRow(),
                  const Divider(color: kDivider),
                  buildTableRow('License', endorsementDetails['license']),
                  const Divider(color: kDivider),
                  buildTableRow('Total Amount', endorsementDetails['totalAmount']),
                  const Divider(color: kDivider),
                  buildTableRow('Advance Amount', endorsementDetails['advanceAmount']),
                  const Divider(color: kDivider),
                  buildTableRow('Balance Amount', endorsementDetails['balanceAmount']),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
              child: MyButton(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditEndorsementDetailsForm(
                        initialValues: endorsementDetails,
                        items: const [
                          'M/C',
                          'LMV',
                          'LMV + M/C ',
                          'TRANS',
                          'TRANS + M/C',
                          'EXCAVATOR',
                          'TRACTOR',
                        ],
                      ),
                    ),
                  );
                },
                text: 'Update Endorsements',
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

  Widget buildAddressRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Address:',
            style: labelStyle,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    endorsementDetails['house'] ?? '',
                    style: valueStyle,
                  ),
                  Text(
                    endorsementDetails['place'] ?? '',
                    style: valueStyle,
                  ),
                  Text(
                    endorsementDetails['post'] ?? '',
                    style: valueStyle,
                  ),
                  Text(
                    endorsementDetails['district'] ?? '',
                    style: valueStyle,
                  ),
                  Text(
                    endorsementDetails['pin'] ?? '',
                    style: valueStyle,
                  ),
                ].where((element) => element.data!.isNotEmpty).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
