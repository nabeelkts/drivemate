import 'package:flutter/material.dart';

class CashUtils extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 30,
        right: 30,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(
                Icons.history,
                color: Colors.blue,
                size: 30,
              ),
              SizedBox(width: 20),
              Text(
                "See all payment activity",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black.withOpacity(0.7),
                ),
              ),
              SizedBox(width: 32),
              Icon(Icons.arrow_forward_ios, size: 18),
            ],
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(
                Icons.account_balance,
                color: Colors.blue,
                size: 30,
              ),
              SizedBox(width: 20),
              Text(
                "Check account balance",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black.withOpacity(0.7),
                ),
              ),
              SizedBox(width: 32),
              Icon(Icons.arrow_forward_ios, size: 18),
            ],
          ),
        ],
      ),
    );
  }
}
