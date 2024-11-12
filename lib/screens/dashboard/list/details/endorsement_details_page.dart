import 'package:flutter/material.dart';

class EndorsementDetailsPage extends StatelessWidget {
  final Map<String, dynamic> endorsementDetails;

  EndorsementDetailsPage({required this.endorsementDetails, Key? key})
      : super(key: key);

  final TextStyle textStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.normal,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Endorsement Details'),
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
              buildTableRow('Student Id', endorsementDetails['studentId']),
              buildTableRow('Full Name', endorsementDetails['fullName']),
              buildTableRow(
                  'Guardian Name', endorsementDetails['guardianName']),
              buildTableRow('Date of Birth', endorsementDetails['dob']),
              buildTableRow(
                  'Mobile Number', endorsementDetails['mobileNumber']),
              buildTableRow(
                  'Emergency Number', endorsementDetails['emergencyNumber']),
              buildTableRow('Blood Group', endorsementDetails['bloodGroup']),
              buildTableRow('Class of Vehicle', endorsementDetails['cov']),
              buildTableRow('House', endorsementDetails['house']),
              buildTableRow('Place', endorsementDetails['place']),
              buildTableRow('Post', endorsementDetails['post']),
              buildTableRow('District', endorsementDetails['district']),
              buildTableRow('Pin', endorsementDetails['pin']),
              buildTableRow('License', endorsementDetails['license']),
              buildTableRow('Total Amount', endorsementDetails['totalAmount']),
              buildTableRow(
                  'Advance Amount', endorsementDetails['advanceAmount']),
              buildTableRow(
                  'Balance Amount', endorsementDetails['balanceAmount']),
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
