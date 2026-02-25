import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:get/get.dart';
import 'package:mds/controller/workspace_controller.dart';
import 'dart:io';

class TodaysTests extends StatefulWidget {
  final String type;
  const TodaysTests({super.key, required this.type});

  @override
  State<TodaysTests> createState() => _TodaysTestsState();
}

class _TodaysTestsState extends State<TodaysTests> {
  DateTime selectedDate = DateTime.now();
  List<Map<String, dynamic>> students = [];
  bool isLoading = true;
  final DateFormat displayDateFormat = DateFormat('dd-MM-yyyy');
  final DateFormat storageDateFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  Future<void> fetchStudents() async {
    setState(() {
      isLoading = true;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      final WorkspaceController workspaceController =
          Get.find<WorkspaceController>();
      if (user == null) return;

      final dateStr = storageDateFormat.format(selectedDate);
      final field =
          widget.type == 'learners' ? 'learnersTestDate' : 'drivingTestDate';

      final collections = ['students', 'licenseonly', 'endorsement'];
      final List<Map<String, dynamic>> allStudents = [];

      for (String col in collections) {
        final snapshot = await workspaceController
            .getFilteredCollection(col)
            .where(field, isEqualTo: dateStr)
            .get();

        allStudents.addAll(snapshot.docs.map((doc) => {
              ...doc.data(),
              'id': doc.id,
              '_collection': col,
            }));
      }

      setState(() {
        students = allStudents;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching students: $e')),
        );
      }
    }
  }

  Future<void> selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      fetchStudents();
    }
  }

  Future<void> _editStudentDetails(Map<String, dynamic> student) async {
    final TextEditingController fullNameController =
        TextEditingController(text: student['fullName'] ?? '');
    final TextEditingController studentIdController =
        TextEditingController(text: student['studentId'] ?? '');
    final TextEditingController mobileController =
        TextEditingController(text: student['mobileNumber'] ?? '');
    final TextEditingController covController =
        TextEditingController(text: student['cov'] ?? '');
    final TextEditingController learnersDateController = TextEditingController(
        text: student['learnersTestDate'] != null
            ? displayDateFormat
                .format(DateTime.parse(student['learnersTestDate']))
            : '');
    final TextEditingController drivingTestDateController =
        TextEditingController(
            text: student['drivingTestDate'] != null
                ? displayDateFormat
                    .format(DateTime.parse(student['drivingTestDate']))
                : '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Student Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: fullNameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              TextField(
                controller: studentIdController,
                decoration: const InputDecoration(labelText: 'Student ID'),
              ),
              TextField(
                controller: mobileController,
                decoration: const InputDecoration(labelText: 'Mobile Number'),
              ),
              TextField(
                controller: covController,
                decoration: const InputDecoration(labelText: 'Course'),
              ),
              TextField(
                controller: learnersDateController,
                decoration: const InputDecoration(
                  labelText: 'Learners Test Date',
                  hintText: 'DD-MM-YYYY',
                ),
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: student['learnersTestDate'] != null
                        ? DateTime.parse(student['learnersTestDate'])
                        : DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    learnersDateController.text =
                        displayDateFormat.format(date);
                  }
                },
              ),
              TextField(
                controller: drivingTestDateController,
                decoration: const InputDecoration(
                  labelText: 'Driving Test Date',
                  hintText: 'DD-MM-YYYY',
                ),
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: student['drivingTestDate'] != null
                        ? DateTime.parse(student['drivingTestDate'])
                        : DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    drivingTestDateController.text =
                        displayDateFormat.format(date);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final user = FirebaseAuth.instance.currentUser;
                final WorkspaceController workspaceController =
                    Get.find<WorkspaceController>();
                if (user == null) return;

                final schoolId = workspaceController.currentSchoolId.value;
                final targetId = schoolId.isNotEmpty ? schoolId : user.uid;

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(targetId)
                    .collection(student['_collection'] ?? 'students')
                    .doc(student['id'])
                    .update({
                  'fullName': fullNameController.text,
                  'studentId': studentIdController.text,
                  'mobileNumber': mobileController.text,
                  'cov': covController.text,
                  'learnersTestDate': learnersDateController.text.isNotEmpty
                      ? storageDateFormat.format(
                          displayDateFormat.parse(learnersDateController.text))
                      : null,
                  'drivingTestDate': drivingTestDateController.text.isNotEmpty
                      ? storageDateFormat.format(displayDateFormat
                          .parse(drivingTestDateController.text))
                      : null,
                });
                if (mounted) {
                  Navigator.pop(context);
                  fetchStudents();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Student details updated successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating student: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _editLicenseDetails(Map<String, dynamic> student) async {
    final TextEditingController licenseNumberController =
        TextEditingController(text: student['licenseNumber'] ?? '');
    final TextEditingController licenseExpiryController = TextEditingController(
        text: student['licenseExpiry'] != null
            ? displayDateFormat.format(DateTime.parse(student['licenseExpiry']))
            : '');
    final TextEditingController learnersDateController = TextEditingController(
        text: student['learnersTestDate'] != null
            ? displayDateFormat
                .format(DateTime.parse(student['learnersTestDate']))
            : '');
    final TextEditingController drivingTestDateController =
        TextEditingController(
            text: student['drivingTestDate'] != null
                ? displayDateFormat
                    .format(DateTime.parse(student['drivingTestDate']))
                : '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit License Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: licenseNumberController,
                decoration: const InputDecoration(labelText: 'License Number'),
              ),
              TextField(
                controller: licenseExpiryController,
                decoration: const InputDecoration(
                  labelText: 'License Expiry Date',
                  hintText: 'DD-MM-YYYY',
                ),
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: student['licenseExpiry'] != null
                        ? DateTime.parse(student['licenseExpiry'])
                        : DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    licenseExpiryController.text =
                        displayDateFormat.format(date);
                  }
                },
              ),
              TextField(
                controller: learnersDateController,
                decoration: const InputDecoration(
                  labelText: 'Learners Test Date',
                  hintText: 'DD-MM-YYYY',
                ),
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: student['learnersTestDate'] != null
                        ? DateTime.parse(student['learnersTestDate'])
                        : DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    learnersDateController.text =
                        displayDateFormat.format(date);
                  }
                },
              ),
              TextField(
                controller: drivingTestDateController,
                decoration: const InputDecoration(
                  labelText: 'Driving Test Date',
                  hintText: 'DD-MM-YYYY',
                ),
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: student['drivingTestDate'] != null
                        ? DateTime.parse(student['drivingTestDate'])
                        : DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    drivingTestDateController.text =
                        displayDateFormat.format(date);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final user = FirebaseAuth.instance.currentUser;
                final WorkspaceController workspaceController =
                    Get.find<WorkspaceController>();
                if (user == null) return;

                final schoolId = workspaceController.currentSchoolId.value;
                final targetId = schoolId.isNotEmpty ? schoolId : user.uid;

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(targetId)
                    .collection(student['_collection'] ?? 'students')
                    .doc(student['id'])
                    .update({
                  'licenseNumber': licenseNumberController.text,
                  'licenseExpiry': licenseExpiryController.text.isNotEmpty
                      ? storageDateFormat.format(
                          displayDateFormat.parse(licenseExpiryController.text))
                      : null,
                  'learnersTestDate': learnersDateController.text.isNotEmpty
                      ? storageDateFormat.format(
                          displayDateFormat.parse(learnersDateController.text))
                      : null,
                  'drivingTestDate': drivingTestDateController.text.isNotEmpty
                      ? storageDateFormat.format(displayDateFormat
                          .parse(drivingTestDateController.text))
                      : null,
                });
                if (mounted) {
                  Navigator.pop(context);
                  fetchStudents();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('License details updated successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating license: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _editEndorsementDetails(Map<String, dynamic> student) async {
    final TextEditingController endorsementController =
        TextEditingController(text: student['endorsement'] ?? '');
    final TextEditingController endorsementDateController =
        TextEditingController(
            text: student['endorsementDate'] != null
                ? displayDateFormat
                    .format(DateTime.parse(student['endorsementDate']))
                : '');
    final TextEditingController learnersDateController = TextEditingController(
        text: student['learnersTestDate'] != null
            ? displayDateFormat
                .format(DateTime.parse(student['learnersTestDate']))
            : '');
    final TextEditingController drivingTestDateController =
        TextEditingController(
            text: student['drivingTestDate'] != null
                ? displayDateFormat
                    .format(DateTime.parse(student['drivingTestDate']))
                : '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Endorsement Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: endorsementController,
                decoration: const InputDecoration(labelText: 'Endorsement'),
                maxLines: 3,
              ),
              TextField(
                controller: endorsementDateController,
                decoration: const InputDecoration(
                  labelText: 'Endorsement Date',
                  hintText: 'DD-MM-YYYY',
                ),
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: student['endorsementDate'] != null
                        ? DateTime.parse(student['endorsementDate'])
                        : DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    endorsementDateController.text =
                        displayDateFormat.format(date);
                  }
                },
              ),
              TextField(
                controller: learnersDateController,
                decoration: const InputDecoration(
                  labelText: 'Learners Test Date',
                  hintText: 'DD-MM-YYYY',
                ),
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: student['learnersTestDate'] != null
                        ? DateTime.parse(student['learnersTestDate'])
                        : DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    learnersDateController.text =
                        displayDateFormat.format(date);
                  }
                },
              ),
              TextField(
                controller: drivingTestDateController,
                decoration: const InputDecoration(
                  labelText: 'Driving Test Date',
                  hintText: 'DD-MM-YYYY',
                ),
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: student['drivingTestDate'] != null
                        ? DateTime.parse(student['drivingTestDate'])
                        : DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    drivingTestDateController.text =
                        displayDateFormat.format(date);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final user = FirebaseAuth.instance.currentUser;
                final WorkspaceController workspaceController =
                    Get.find<WorkspaceController>();
                if (user == null) return;

                final schoolId = workspaceController.currentSchoolId.value;
                final targetId = schoolId.isNotEmpty ? schoolId : user.uid;

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(targetId)
                    .collection(student['_collection'] ?? 'students')
                    .doc(student['id'])
                    .update({
                  'endorsement': endorsementController.text,
                  'endorsementDate': endorsementDateController.text.isNotEmpty
                      ? storageDateFormat.format(displayDateFormat
                          .parse(endorsementDateController.text))
                      : null,
                  'learnersTestDate': learnersDateController.text.isNotEmpty
                      ? storageDateFormat.format(
                          displayDateFormat.parse(learnersDateController.text))
                      : null,
                  'drivingTestDate': drivingTestDateController.text.isNotEmpty
                      ? storageDateFormat.format(displayDateFormat
                          .parse(drivingTestDateController.text))
                      : null,
                });
                if (mounted) {
                  Navigator.pop(context);
                  fetchStudents();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Endorsement details updated successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating endorsement: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            "${widget.type == 'learners' ? 'Learners' : 'Driving'} Test - ${displayDateFormat.format(selectedDate)}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => selectDate(context),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : students.isEmpty
              ? Center(
                  child: Text(
                    'No ${widget.type == 'learners' ? 'learners' : 'driving'} tests scheduled for this date',
                    style: const TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ExpansionTile(
                        title: Text(student['fullName'] ?? ''),
                        subtitle: Text('ID: ${student['studentId'] ?? ''}'),
                        children: [
                          ListTile(
                            title: const Text('Edit Student Details'),
                            leading: const Icon(Icons.person),
                            onTap: () => _editStudentDetails(student),
                          ),
                          ListTile(
                            title: const Text('Edit License Details'),
                            leading:
                                const Icon(Icons.drive_file_rename_outline),
                            onTap: () => _editLicenseDetails(student),
                          ),
                          ListTile(
                            title: const Text('Edit Endorsement'),
                            leading: const Icon(Icons.note_add),
                            onTap: () => _editEndorsementDetails(student),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    'Learners Date: ${student['learnersTestDate'] != null ? displayDateFormat.format(DateTime.parse(student['learnersTestDate'])) : 'Not set'}'),
                                const SizedBox(height: 8),
                                Text(
                                    'Test Date: ${student['drivingTestDate'] != null ? displayDateFormat.format(DateTime.parse(student['drivingTestDate'])) : 'Not set'}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
