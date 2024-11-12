import 'package:flutter/material.dart';

class RCDetailsPage extends StatelessWidget {
  final Map<String, dynamic> vehicleDetails;

  RCDetailsPage({required this.vehicleDetails, Key? key}) : super(key: key);

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
        title: Text('RC Details'),
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
              buildTableRow('Vehicle Number', vehicleDetails['vehicleNumber']),
              buildTableRow('Chassis Number', vehicleDetails['chassisNumber']),
              buildTableRow('Engine Number', vehicleDetails['engineNumber']),
              buildTableRow('Mobile Number', vehicleDetails['mobileNumber']),
              buildTableRow('Total Amount', vehicleDetails['totalAmount']),
              buildTableRow('Advance Amount', vehicleDetails['advanceAmount']),
              buildTableRow('Balance Amount', vehicleDetails['balanceAmount']),
              buildTableRow('Service', vehicleDetails['service']),
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
