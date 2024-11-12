import 'package:flutter/material.dart';

class StudentDetailsPage extends StatelessWidget {
  final Map<String, dynamic> studentDetails;

  StudentDetailsPage({required this.studentDetails, Key? key})
      : super(key: key);

  final TextStyle labelStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.normal,
  );
  final TextStyle valueStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Details'),
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
              buildTableRow('Student Id', studentDetails['studentId']),
              buildTableRow('Full Name', studentDetails['fullName']),
              buildTableRow('Guardian Name', studentDetails['guardianName']),
              buildTableRow('Date of Birth', studentDetails['dob']),
              buildTableRow('Mobile Number', studentDetails['mobileNumber']),
              buildTableRow(
                  'Emergency Number', studentDetails['emergencyNumber']),
              buildTableRow('Blood Group', studentDetails['bloodGroup']),
              buildTableRow('Class of Vehicle', studentDetails['cov']),
              buildTableRow('House', studentDetails['house']),
              buildTableRow('Place', studentDetails['place']),
              buildTableRow('Post', studentDetails['post']),
              buildTableRow('District', studentDetails['district']),
              buildTableRow('Pin', studentDetails['pin']),
              buildTableRow('Total Amount', studentDetails['totalAmount']),
              buildTableRow('Advance Amount', studentDetails['advanceAmount']),
              buildTableRow('Balance Amount', studentDetails['balanceAmount']),
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
              style: labelStyle,
            ),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Text(
              '$value',
              style: valueStyle,
            ),
          ),
        ),
      ],
    );
  }
}
