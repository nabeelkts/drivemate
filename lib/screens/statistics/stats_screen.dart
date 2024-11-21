import 'package:flutter/material.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                buildChart(),
                const SizedBox(height: 16),
                buildCards(),
                const SizedBox(height: 16),
                buildButton(),
                const SizedBox(height: 16),
                buildTransactions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildChart() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24.35, vertical: 8.45),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildChartHeader(),
          const SizedBox(height: 24.35),
          buildBarChart(),
        ],
      ),
    );
  }

  Widget buildChartHeader() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Revenue Analysis',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 16.24,
            color: Color(0xFF1E1E1E),
          ),
        ),
        Row(
          children: [
            Text(
              'Daily Analysis',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                fontSize: 16.24,
                color: Color(0xFF1E1E1E),
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.filter_alt, color: Color(0xFF1E1E1E)),
          ],
        ),
      ],
    );
  }

  Widget buildBarChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '75,000',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                fontSize: 32,
                color: Color(0xFF1E1E1E),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.12, vertical: 4.06),
              decoration: BoxDecoration(
                color: const Color(0xFF7BC147),
                borderRadius: BorderRadius.circular(16.24),
              ),
              child: const Row(
                children: [
                  Icon(Icons.arrow_upward, color: Colors.white, size: 16.24),
                  SizedBox(width: 4.06),
                  Text(
                    '49,5%',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 14.21,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        buildBarChartContent(),
      ],
    );
  }

  Widget buildBarChartContent() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        buildBar('Dec\n23', Colors.orange),
        buildBar('Jan\n24', Colors.orange),
        buildBar('Feb\n24', Colors.deepOrange),
        buildBar('Mar\n24', Colors.orange),
        buildBar('Apr\n24', Colors.orange),
        buildBar('May\n24', Colors.orange),
        buildBar('Jun\n24', Colors.orange),
      ],
    );
  }

  Widget buildBar(String label, Color color) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 150,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4.06),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
            fontSize: 16.24,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

 Widget buildCards() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      buildCard('Revenue for\nthe month', 'Rs. 170,000/-'),
      const SizedBox(width: 10),
      buildCard('Outstanding\nDue', 'Rs. 170,000/-'),
    ],
  );
}

Widget buildCard(String title, String amount) {
  return Container(
    width: 180,
    height: 155,
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    decoration: BoxDecoration(
      color: const Color(0xFFFFFBF7),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          amount,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.black,
          ),
        ),
      ],
    ),
  );
}


  Widget buildButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF7),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Center(
        child: Text(
          'Receive money',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 16,
            foreground: Paint()
              ..shader = const LinearGradient(
                colors: <Color>[
                  Color(0xFFF46B45),
                  Color(0xFFEEA849),
                ],
              ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
          ),
        ),
      ),
    );
  }

  Widget buildTransactions() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          buildTransactionHeader(),
          buildTransactionRow('1015', '10-05-2022', 'Abin Muhammed Bukhari', 'Rs.7,500'),
          buildTransactionRow('1015', '10-05-2022', 'Muhammed Bilal', 'Rs.7,500'),
          buildTransactionRow('1015', '10-05-2022', 'Muhammed Nabeel', 'Rs.7,500'),
          buildTransactionRow('1015', '10-05-2022', 'Pattaalam Bhasi', 'Rs.7,500'),
          buildTransactionRow('1015', '10-05-2022', 'Muhammed Nabeel', 'Rs.7,500'),
          buildTransactionRow('1015', '10-05-2022', 'Pattaalam Bhasi', 'Rs.7,500'),
        ],
      ),
    );
  }

  Widget buildTransactionHeader() {
    return const Padding(
      padding: EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, color: Color(0xFF1E1E1E)),
              SizedBox(width: 8),
              Text(
                'Today’s Transactions',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Color(0xFF1E1E1E),
                ),
              ),
            ],
          ),
          Text(
            'Rs.16500',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Color(0xFF1E1E1E),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTransactionRow(String id, String date, String name, String amount) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            id,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Color(0xFF1E1E1E),
            ),
          ),
          Text(
            date,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Color(0xFF1E1E1E),
            ),
          ),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF1E1E1E),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Color(0xFF1E1E1E),
            ),
          ),
        ],
      ),
    );
  }
}
