import 'package:flutter/material.dart';

class LicenseOnlyDetailsPage extends StatelessWidget {
  final Map<String, dynamic> licenseDetails;

  LicenseOnlyDetailsPage({required this.licenseDetails, Key? key})
      : super(key: key);

  final TextStyle textStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.normal,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('License Only Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.95,
          height: MediaQuery.of(context).size.height * 0.95,
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            border: Border.all(),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.all(8),
          child: Table(
            columnWidths: {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(2),
            },
            children: [
              buildTableRow('Student Id', licenseDetails['studentId']),
              buildTableRow('Full Name', licenseDetails['fullName']),
              buildTableRow('Guardian Name', licenseDetails['guardianName']),
              buildTableRow('Date of Birth', licenseDetails['dob']),
              buildTableRow('Mobile Number', licenseDetails['mobileNumber']),
              buildTableRow(
                  'Emergency Number', licenseDetails['emergencyNumber']),
              buildTableRow('Blood Group', licenseDetails['bloodGroup']),
              buildTableRow('Class of Vehicle', licenseDetails['cov']),
              buildTableRow('House', licenseDetails['house']),
              buildTableRow('Place', licenseDetails['place']),
              buildTableRow('Post', licenseDetails['post']),
              buildTableRow('District', licenseDetails['district']),
              buildTableRow('Pin', licenseDetails['pin']),
              buildTableRow('License', licenseDetails['license']),
              buildTableRow('Total Amount', licenseDetails['totalAmount']),
              buildTableRow('Advance Amount', licenseDetails['advanceAmount']),
              buildTableRow('Balance Amount', licenseDetails['balanceAmount']),
            ],
          ),
        ),
      ),
    );
  }

  TableRow buildTableRow(String label, dynamic value) {
    return TableRow(
      children: [
        TableCell(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Text(
              '$label:',
              style: textStyle,
            ),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Text(
              '$value',
              style: textStyle.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
