import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:iconly/iconly.dart';
import 'package:mds/utils/date_utils.dart';
import 'package:get/get.dart';
import 'package:mds/screens/widget/custom_back_button.dart';
import 'package:mds/controller/workspace_controller.dart';
import 'package:mds/screens/dashboard/list/widgets/shimmer_loading_list.dart';

class TestDateUpdaterScreen extends StatefulWidget {
  const TestDateUpdaterScreen({super.key});

  @override
  State<TestDateUpdaterScreen> createState() => _TestDateUpdaterScreenState();
}

class _TestDateUpdaterScreenState extends State<TestDateUpdaterScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allData = [];
  List<Map<String, dynamic>> _filteredResults = [];
  bool _isLoading = true;
  final WorkspaceController _workspaceController =
      Get.find<WorkspaceController>();

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final schoolId = _workspaceController.currentSchoolId.value;
    final targetId = schoolId.isNotEmpty ? schoolId : user.uid;

    final collections = ['students', 'licenseonly', 'endorsement'];
    List<Map<String, dynamic>> allResults = [];

    try {
      for (var col in collections) {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(targetId)
            .collection(col)
            .get();

        final data = snapshot.docs.map((doc) {
          final map = doc.data();
          return {
            ...map,
            'docId': doc.id,
            'collection': col,
            'fullName': map['fullName'] ?? 'N/A',
            'studentId': map['studentId'] ?? 'N/A',
          };
        }).toList();

        allResults.addAll(data);
      }

      setState(() {
        _allData = allResults;
        _filteredResults = allResults;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterResults(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredResults = _allData;
      });
      return;
    }

    final lowercaseQuery = query.toLowerCase();
    setState(() {
      _filteredResults = _allData.where((item) {
        final name = item['fullName'].toString().toLowerCase();
        final id = item['studentId'].toString().toLowerCase();
        return name.contains(lowercaseQuery) || id.contains(lowercaseQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Test Dates'),
        leading: const CustomBackButton(),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: _filterResults,
              decoration: InputDecoration(
                hintText: 'Search by Name or ID...',
                prefixIcon: const Icon(IconlyLight.search),
                filled: true,
                fillColor: isDark ? Colors.grey[900] : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const ShimmerLoadingList()
          : _filteredResults.isEmpty
              ? const Center(child: Text('No students found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredResults.length,
                  itemBuilder: (context, index) {
                    final item = _filteredResults[index];
                    return _buildStudentTile(context, item);
                  },
                ),
    );
  }

  Widget _buildStudentTile(BuildContext context, Map<String, dynamic> item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color subTextColor = isDark ? Colors.grey : Colors.grey[700]!;

    final llDate =
        AppDateUtils.formatDateForDisplay(item['learnersTestDate']?.toString());
    final dlDate =
        AppDateUtils.formatDateForDisplay(item['drivingTestDate']?.toString());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(item['fullName'],
            style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'ID: ${item['studentId']} | ${item['collection'].toUpperCase()}',
                style: TextStyle(color: subTextColor, fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildDateBadge('LL: ${llDate.isNotEmpty ? llDate : "N/A"}',
                    llDate.isNotEmpty),
                const SizedBox(width: 8),
                _buildDateBadge('DL: ${dlDate.isNotEmpty ? dlDate : "N/A"}',
                    dlDate.isNotEmpty),
              ],
            ),
          ],
        ),
        trailing: Icon(IconlyLight.edit, color: Theme.of(context).primaryColor),
        onTap: () => _showUpdateDialog(context, item),
      ),
    );
  }

  Widget _buildDateBadge(String text, bool hasDate) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: hasDate
            ? Colors.green.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border:
            Border.all(color: hasDate ? Colors.green : Colors.grey, width: 0.5),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 10,
              color: hasDate ? Colors.green : Colors.grey,
              fontWeight: FontWeight.bold)),
    );
  }

  Future<void> _showUpdateDialog(
      BuildContext context, Map<String, dynamic> item) async {
    final llDisplayController = TextEditingController(
        text: AppDateUtils.formatDateForDisplay(
            item['learnersTestDate']?.toString()));
    final dlDisplayController = TextEditingController(
        text: AppDateUtils.formatDateForDisplay(
            item['drivingTestDate']?.toString()));

    // We'll store the storage format in hidden variables or just convert on submit
    String tempLLStorage = item['learnersTestDate']?.toString() ?? '';
    String tempDLStorage = item['drivingTestDate']?.toString() ?? '';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Update Test Dates\n${item['fullName']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDateField(
                  context, 'Learners Test (LL)', llDisplayController,
                  (storageDate) {
                tempLLStorage = storageDate;
              }),
              const SizedBox(height: 16),
              _buildDateField(context, 'Driving Test (DL)', dlDisplayController,
                  (storageDate) {
                tempDLStorage = storageDate;
              }),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                await _updateDates(item, tempLLStorage, tempDLStorage);
                Navigator.pop(context);
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField(
      BuildContext context,
      String label,
      TextEditingController displayController,
      Function(String) onDateSelected) {
    return TextFormField(
      controller: displayController,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(IconlyLight.calendar),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onTap: () async {
        final initialDate = displayController.text.isNotEmpty
            ? AppDateUtils.parseDisplayDate(displayController.text)
            : DateTime.now();

        final date = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: AppDateUtils.firstDate,
          lastDate: AppDateUtils.lastDate,
        );
        if (date != null) {
          final storageDate =
              DateFormat(AppDateUtils.storageFormat).format(date);
          final displayDate =
              DateFormat(AppDateUtils.displayFormat).format(date);
          displayController.text = displayDate;
          onDateSelected(storageDate);
        }
      },
    );
  }

  Future<void> _updateDates(
      Map<String, dynamic> item, String llDate, String dlDate) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final schoolId = _workspaceController.currentSchoolId.value;
    final targetId = schoolId.isNotEmpty ? schoolId : user.uid;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetId)
          .collection(item['collection'])
          .doc(item['docId'])
          .update({
        'learnersTestDate': llDate,
        'drivingTestDate': dlDate,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dates updated successfully')),
      );

      // Update local state
      setState(() {
        final index =
            _allData.indexWhere((element) => element['docId'] == item['docId']);
        if (index != -1) {
          _allData[index]['learnersTestDate'] = llDate;
          _allData[index]['drivingTestDate'] = dlDate;
        }
        _filterResults(_searchController.text);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating dates: $e')),
      );
    }
  }
}
