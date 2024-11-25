import 'package:async/async.dart'; // Import the async package
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mds/screens/dashboard/list/details/endorsement_details_page.dart';
import 'package:mds/screens/dashboard/list/details/license_only_details_page.dart';
import 'package:mds/screens/dashboard/list/details/rc_details_page.dart';
import 'package:mds/screens/dashboard/list/details/students_details_page.dart';
import 'package:shimmer/shimmer.dart'; // Import the shimmer package

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? user = FirebaseAuth.instance.currentUser;
  DateTime selectedDate = DateTime.now();
  String selectedFilter = 'Date';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
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
    return StreamBuilder<List<QuerySnapshot<Map<String, dynamic>>>>(
      stream: StreamZip([
        _firestore.collection('users').doc(user?.uid).collection('students').snapshots(),
        _firestore.collection('users').doc(user?.uid).collection('licenseonly').snapshots(),
        _firestore.collection('users').doc(user?.uid).collection('endorsement').snapshots(),
        _firestore.collection('users').doc(user?.uid).collection('vehicleDetails').snapshots(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Error loading chart data');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return buildShimmerChart();
        }

        final allDocuments = snapshot.data?.expand((snapshot) => snapshot.docs).toList() ?? [];
        Map<String, double> revenueData = {};

        if (selectedFilter == 'Date') {
          List<DateTime> dateRange = List.generate(6, (index) => selectedDate.subtract(Duration(days: index)));
          dateRange.sort((a, b) => a.compareTo(b));

          for (var date in dateRange) {
            String key = DateFormat('dd/MM').format(date);
            revenueData[key] = 0.0;
          }

          for (var doc in allDocuments) {
            final data = doc.data();
            double advanceAmount = double.tryParse(data['advanceAmount']?.toString() ?? '0') ?? 0.0;
            double secondInstallment = double.tryParse(data['secondInstallment']?.toString() ?? '0') ?? 0.0;
            double thirdInstallment = double.tryParse(data['thirdInstallment']?.toString() ?? '0') ?? 0.0;

            DateTime transactionDate = DateTime.tryParse(data['registrationDate'] ?? '') ?? DateTime.now();
            String key = DateFormat('dd/MM').format(transactionDate);

            if (revenueData.containsKey(key)) {
              revenueData[key] = (revenueData[key] ?? 0) + advanceAmount + secondInstallment + thirdInstallment;
            }
          }
        } else if (selectedFilter == 'Month') {
          List<DateTime> monthRange = List.generate(6, (index) {
            DateTime date = DateTime(selectedDate.year, selectedDate.month - index, 1);
            return DateTime(date.year, date.month, 1);
          });
          monthRange.sort((a, b) => a.compareTo(b));

          for (var date in monthRange) {
            String key = DateFormat('MM/yy').format(date);
            revenueData[key] = 0.0;
          }

          for (var doc in allDocuments) {
            final data = doc.data();
            double advanceAmount = double.tryParse(data['advanceAmount']?.toString() ?? '0') ?? 0.0;
            double secondInstallment = double.tryParse(data['secondInstallment']?.toString() ?? '0') ?? 0.0;
            double thirdInstallment = double.tryParse(data['thirdInstallment']?.toString() ?? '0') ?? 0.0;

            DateTime transactionDate = DateTime.tryParse(data['registrationDate'] ?? '') ?? DateTime.now();
            String key = DateFormat('MM/yy').format(transactionDate);

            if (revenueData.containsKey(key)) {
              revenueData[key] = (revenueData[key] ?? 0) + advanceAmount + secondInstallment + thirdInstallment;
            }
          }
        } else if (selectedFilter == 'Year') {
          List<DateTime> yearRange = List.generate(6, (index) {
            return DateTime(selectedDate.year - index, 1, 1);
          });
          yearRange.sort((a, b) => a.compareTo(b));

          for (var date in yearRange) {
            String key = DateFormat('yyyy').format(date);
            revenueData[key] = 0.0;
          }

          for (var doc in allDocuments) {
            final data = doc.data();
            double advanceAmount = double.tryParse(data['advanceAmount']?.toString() ?? '0') ?? 0.0;
            double secondInstallment = double.tryParse(data['secondInstallment']?.toString() ?? '0') ?? 0.0;
            double thirdInstallment = double.tryParse(data['thirdInstallment']?.toString() ?? '0') ?? 0.0;

            DateTime transactionDate = DateTime.tryParse(data['registrationDate'] ?? '') ?? DateTime.now();
            String key = DateFormat('yyyy').format(transactionDate);

            if (revenueData.containsKey(key)) {
              revenueData[key] = (revenueData[key] ?? 0) + advanceAmount + secondInstallment + thirdInstallment;
            }
          }
        }

        return buildBarChart(revenueData);
      },
    );
  }

  Widget buildShimmerChart() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
        ),
      ),
    );
  }

  Widget buildBarChart(Map<String, double> revenueData) {
    if (revenueData.isEmpty) {
      return const Text('No data available for the selected period.');
    }

    double maxValue = revenueData.values.reduce((a, b) => a > b ? a : b);
    double scaleFactor = 150 / (maxValue > 0 ? maxValue : 1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          const SizedBox(height: 24),
          Container(
            height: 200,
            padding: const EdgeInsets.only(bottom: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: revenueData.entries.map((entry) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 12,
                      height: entry.value * scaleFactor,
                      decoration: BoxDecoration(
                        color: entry.value == maxValue ? Colors.green : Colors.orange,
                        borderRadius: BorderRadius.circular(4.06),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      entry.key,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        fontSize: 10,
                        color: Colors.black,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildChartHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Revenue Analysis',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 16.24,
            color: Color(0xFF1E1E1E),
          ),
        ),
        DropdownButton<String>(
          iconEnabledColor: Colors.black,
          value: selectedFilter,
          items: <String>['Date', 'Month', 'Year'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              selectedFilter = newValue!;
            });
          },
        ),
      ],
    );
  }

  Widget buildCards() {
    return StreamBuilder<List<QuerySnapshot<Map<String, dynamic>>>>(
      stream: StreamZip([
        _firestore.collection('users').doc(user?.uid).collection('students').snapshots(),
        _firestore.collection('users').doc(user?.uid).collection('licenseonly').snapshots(),
        _firestore.collection('users').doc(user?.uid).collection('endorsement').snapshots(),
        _firestore.collection('users').doc(user?.uid).collection('vehicleDetails').snapshots(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Error loading data');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return buildShimmerCards();
        }

        final allDocuments = snapshot.data?.expand((snapshot) => snapshot.docs).toList() ?? [];
        double totalRevenue = 0.0;
        double totalBalanceAmount = 0.0;

        for (var doc in allDocuments) {
          final data = doc.data();
          double advanceAmount = double.tryParse(data['advanceAmount']?.toString() ?? '0') ?? 0.0;
          double secondInstallment = double.tryParse(data['secondInstallment']?.toString() ?? '0') ?? 0.0;
          double thirdInstallment = double.tryParse(data['thirdInstallment']?.toString() ?? '0') ?? 0.0;
          double balanceAmount = double.tryParse(data['balanceAmount']?.toString() ?? '0') ?? 0.0;

          totalRevenue += advanceAmount + secondInstallment + thirdInstallment;
          totalBalanceAmount += balanceAmount;
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildCard('Revenue for\nthe month', 'Rs. ${totalRevenue.toStringAsFixed(2)}'),
            const SizedBox(width: 10),
            buildCard('Outstanding\nDue', 'Rs. ${totalBalanceAmount.toStringAsFixed(2)}'),
          ],
        );
      },
    );
  }

  Widget buildShimmerCards() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        buildShimmerCard(),
        const SizedBox(width: 10),
        buildShimmerCard(),
      ],
    );
  }

  Widget buildShimmerCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: 180,
        height: 155,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
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
    return GestureDetector(
      onTap: () {
        // Handle button tap
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receive money button tapped')),
        );
      },
      child: Container(
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
      ),
    );
  }

  Widget buildTransactions() {
    return StreamBuilder<List<QuerySnapshot<Map<String, dynamic>>>>(
      stream: StreamZip([
        _firestore.collection('users').doc(user?.uid).collection('students').snapshots(),
        _firestore.collection('users').doc(user?.uid).collection('licenseonly').snapshots(),
        _firestore.collection('users').doc(user?.uid).collection('endorsement').snapshots(),
        _firestore.collection('users').doc(user?.uid).collection('vehicleDetails').snapshots(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Error loading transactions');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return buildShimmerTransactions();
        }

        final allDocuments = snapshot.data?.expand((snapshot) => snapshot.docs).toList() ?? [];

        // Create a list of transactions with their respective times
        List<Map<String, dynamic>> transactions = [];

        for (var doc in allDocuments) {
          final data = doc.data();
          double advanceAmount = double.tryParse(data['advanceAmount']?.toString() ?? '0') ?? 0.0;
          double secondInstallment = double.tryParse(data['secondInstallment']?.toString() ?? '0') ?? 0.0;
          double thirdInstallment = double.tryParse(data['thirdInstallment']?.toString() ?? '0') ?? 0.0;

          DateTime registrationDate = DateTime.tryParse(data['registrationDate'] ?? '') ?? DateTime.now();
          DateTime secondInstallmentTime = DateTime.tryParse(data['secondInstallmentTime'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
          DateTime thirdInstallmentTime = DateTime.tryParse(data['thirdInstallmentTime'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);

          // Determine the correct name field based on the collection
          String nameField;
          if (doc.reference.parent.id == 'vehicleDetails') {
            nameField = data['vehicleNumber'] ?? 'N/A';
          } else {
            nameField = data['fullName'] ?? 'N/A';
          }

          // Add transactions with their respective times
          if (advanceAmount > 0) {
            transactions.add({
              'time': registrationDate,
              'description': 'Advance: Rs.${advanceAmount.toStringAsFixed(0)}',
              'name': nameField,
              'doc': doc,
            });
          }
          if (secondInstallment > 0) {
            transactions.add({
              'time': secondInstallmentTime,
              'description': '2nd Installment: Rs.${secondInstallment.toStringAsFixed(0)}',
              'name': nameField,
              'doc': doc,
            });
          }
          if (thirdInstallment > 0) {
            transactions.add({
              'time': thirdInstallmentTime,
              'description': '3rd Installment: Rs.${thirdInstallment.toStringAsFixed(0)}',
              'name': nameField,
              'doc': doc,
            });
          }
        }

        // Filter transactions for the selected date and sort by time
        transactions = transactions.where((transaction) {
          return isSameDate(transaction['time'], selectedDate);
        }).toList();

        transactions.sort((a, b) => b['time'].compareTo(a['time'])); // Sort in descending order

        double totalTransactionAmount = transactions.fold(0.0, (sum, transaction) {
          return sum + (double.tryParse(transaction['description'].split('Rs.').last) ?? 0.0);
        });

        List<Widget> transactionRows = transactions.map((transaction) {
          return buildTransactionRow(
            transaction['doc'],
            formatTime(transaction['time']),
            transaction['name'],
            transaction['description'],
          );
        }).toList();

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white60,
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
              buildTransactionHeader(totalTransactionAmount),
              ...transactionRows,
            ],
          ),
        );
      },
    );
  }

  Widget buildShimmerTransactions() {
    return Column(
      children: List.generate(5, (index) => buildShimmerTransactionRow()),
    );
  }

  Widget buildShimmerTransactionRow() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  DateTime getLatestInstallmentTime(Map<String, dynamic> data) {
    DateTime secondInstallmentTime = DateTime.tryParse(data['secondInstallmentTime'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
    DateTime thirdInstallmentTime = DateTime.tryParse(data['thirdInstallmentTime'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
    return secondInstallmentTime.isAfter(thirdInstallmentTime) ? secondInstallmentTime : thirdInstallmentTime;
  }

  String formatDate(String dateStr) {
    try {
      DateTime date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return 'Invalid Date';
    }
  }

  String formatTime(DateTime dateTime) {
    return DateFormat('hh:mm a').format(dateTime);
  }

  bool isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  Widget buildTransactionHeader(double totalTransactionAmount) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.calendar_today, color: Color(0xFF1E1E1E)),
                onPressed: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (pickedDate != null && pickedDate != selectedDate) {
                    setState(() {
                      selectedDate = pickedDate;
                    });
                  }
                },
              ),
              const SizedBox(width: 4),
              Text(
                'Transactions for ${DateFormat('dd/MM/yy').format(selectedDate)}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Color(0xFF1E1E1E),
                ),
              ),
            ],
          ),
          Text(
            'Total: Rs.${totalTransactionAmount.toStringAsFixed(0)}',
            style: const TextStyle(
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

  Widget buildTransactionRow(DocumentSnapshot<Map<String, dynamic>> doc, String transactionTime, String fullName, String amountDescription) {
    return GestureDetector(
      onTap: () {
        // Determine the collection and navigate to the appropriate details page
        if (doc.reference.parent.id == 'licenseonly') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LicenseOnlyDetailsPage(licenseDetails: doc.data()!),
            ),
          );
        } else if (doc.reference.parent.id == 'endorsement') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EndorsementDetailsPage(endorsementDetails: doc.data()!),
            ),
          );
        } else if (doc.reference.parent.id == 'vehicleDetails') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RCDetailsPage(vehicleDetails: doc.data()!),
            ),
          );
        } else if (doc.reference.parent.id == 'students') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudentDetailsPage(studentDetails: doc.data()!),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4), // Add margin for spacing between rows
        decoration: BoxDecoration(
          color: Colors.white60,
          borderRadius: BorderRadius.circular(10), // Circular border radius
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              transactionTime,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF1E1E1E),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                fullName,
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
              amountDescription,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF1E1E1E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
