import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/screens/authentication/widgets/my_button.dart';
import 'package:mds/screens/dashboard/form/edit_forms/edit_licence_only_details_form.dart';

class LicenseOnlyDetailsPage extends StatelessWidget {
  final Map<String, dynamic> licenseDetails;

  const LicenseOnlyDetailsPage({required this.licenseDetails, super.key});

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
        title: const Text('License Only Details'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 60,
              backgroundColor: kWhite,
              backgroundImage: licenseDetails['image'] != null && licenseDetails['image'].isNotEmpty
                  ? CachedNetworkImageProvider(licenseDetails['image'])
                  : null,
              child: licenseDetails['image'] == null || licenseDetails['image'].isEmpty
                  ? Text(
                      licenseDetails['fullName'] != null && licenseDetails['fullName'].isNotEmpty
                          ? licenseDetails['fullName'][0].toUpperCase()
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
                  buildTableRow('Student Id', licenseDetails['studentId']),
                  const Divider(color: kDivider),
                  buildTableRow('Full Name', licenseDetails['fullName']),
                  const Divider(color: kDivider),
                  buildTableRow('Guardian Name', licenseDetails['guardianName']),
                  const Divider(color: kDivider),
                  buildTableRow('Date of Birth', licenseDetails['dob']),
                  const Divider(color: kDivider),
                  buildTableRow('Mobile Number', licenseDetails['mobileNumber']),
                  const Divider(color: kDivider),
                  buildTableRow('Emergency Number', licenseDetails['emergencyNumber']),
                  const Divider(color: kDivider),
                  buildTableRow('Blood Group', licenseDetails['bloodGroup']),
                  const Divider(color: kDivider),
                  buildTableRow('Class of Vehicle', licenseDetails['cov']),
                  const Divider(color: kDivider),
                  buildAddressRow(),
                  const Divider(color: kDivider),
                  buildTableRow('License', licenseDetails['license']),
                  const Divider(color: kDivider),
                  buildTableRow('Total Amount', licenseDetails['totalAmount']),
                  const Divider(color: kDivider),
                  buildTableRow('Advance Amount', licenseDetails['advanceAmount']),
                  const Divider(color: kDivider),
                  buildTableRow('Balance Amount', licenseDetails['balanceAmount']),
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
                      builder: (context) => EditLicenseOnlyForm(
                        initialValues: licenseDetails,
                        items: const [
                          'M/C Study',
                          'LMV Study',
                          'LMV Study + M/C Study',
                          'LMV Study + M/C License',
                          'Adapted Vehicle',
                        ],
                      ),
                    ),
                  );
                },
                text: 'Update License Only',
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
                    licenseDetails['house'] ?? '',
                    style: valueStyle,
                  ),
                  Text(
                    licenseDetails['place'] ?? '',
                    style: valueStyle,
                  ),
                  Text(
                    licenseDetails['post'] ?? '',
                    style: valueStyle,
                  ),
                  Text(
                    licenseDetails['district'] ?? '',
                    style: valueStyle,
                  ),
                  Text(
                    licenseDetails['pin'] ?? '',
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
