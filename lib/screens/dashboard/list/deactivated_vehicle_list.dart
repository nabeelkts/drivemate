import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/screens/dashboard/form/edit_forms/edit_vehicle_details_form.dart';
import 'package:get/get.dart';
import 'package:mds/controller/workspace_controller.dart';
import 'package:mds/screens/dashboard/list/details/rc_details_page.dart';
import 'package:mds/screens/dashboard/list/widgets/search_widget.dart';
import 'package:mds/screens/dashboard/list/widgets/shimmer_loading_list.dart';
import 'package:mds/screens/dashboard/list/widgets/list_item_card.dart';
import 'package:mds/screens/profile/dialog_box.dart';

class DeactivatedVehicleList extends StatefulWidget {
  const DeactivatedVehicleList({super.key});

  @override
  State<DeactivatedVehicleList> createState() => _DeactivatedVehicleListState();
}

class _DeactivatedVehicleListState extends State<DeactivatedVehicleList> {
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _streamSubscription;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _allDeactivatedVehicles =
      [];
  final TextEditingController _searchController = TextEditingController();
  final WorkspaceController _workspaceController =
      Get.find<WorkspaceController>();

  @override
  void initState() {
    super.initState();
    _setupStream();
  }

  void _setupStream() {
    final schoolId = _workspaceController.currentSchoolId.value;
    final user = FirebaseAuth.instance.currentUser;
    final targetId = schoolId.isNotEmpty ? schoolId : user?.uid;

    _streamSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(targetId)
        .collection('deactivated_vehicleDetails')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _allDeactivatedVehicles = snapshot.docs;
        });
        print('Fetched ${snapshot.docs.length} deactivated vehicles');
      }
    });
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filteredVehicles(
      String query) {
    return _allDeactivatedVehicles.where((doc) {
      final data = doc.data();
      final vehicleNumber =
          data['vehicleNumber']?.toString().toLowerCase() ?? '';
      final mobileNumber = data['mobileNumber']?.toString().toLowerCase() ?? '';
      final searchQuery = query.toLowerCase();
      return vehicleNumber.contains(searchQuery) ||
          mobileNumber.contains(searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? kBlack;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Services Completed Vehicles',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: Stack(
          children: [
            Positioned(
              left: 12,
              right: 12,
              top: 12,
              bottom: 12,
              child: CircleAvatar(
                backgroundColor: kPrimaryColor,
                radius: 16,
                child: CircleAvatar(
                  radius: 15,
                  backgroundColor: kWhite,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: kPrimaryColor,
                      size: 16,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          SearchWidget(
            placeholder: 'Search by Vehicle Number or Mobile Number',
            controller: _searchController,
            onChanged: (value) {
              setState(() {});
            },
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(_workspaceController.currentSchoolId.value.isNotEmpty
                      ? _workspaceController.currentSchoolId.value
                      : FirebaseAuth.instance.currentUser?.uid)
                  .collection('deactivated_vehicleDetails')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('Connection Error');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ShimmerLoadingList();
                }

                var docs = _searchController.text.isNotEmpty
                    ? _filteredVehicles(_searchController.text)
                    : snapshot.data?.docs ?? [];

                // Safely sort the documents
                docs.sort((a, b) {
                  final aNumber = a.data()['vehicleNumber']?.toString() ?? '';
                  final bNumber = b.data()['vehicleNumber']?.toString() ?? '';
                  return aNumber.compareTo(bNumber);
                });

                if (docs.isEmpty) {
                  return const Center(
                    child: Text('No deactivated vehicles found'),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final vehicleNumber = data['vehicleNumber'] ?? '';
                    final lastFourDigits = vehicleNumber.length >= 4
                        ? vehicleNumber.substring(vehicleNumber.length - 4)
                        : vehicleNumber;

                    return buildVehicleListItem(
                        context, docs[index], data, lastFourDigits);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildVehicleListItem(
    BuildContext context,
    DocumentSnapshot<Map<String, dynamic>> doc,
    Map<String, dynamic> data,
    String lastFourDigits,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListItemCard(
      title: data['vehicleNumber'] ?? 'N/A',
      subTitle: 'Mobile: ${(data['mobileNumber'] ?? 'N/A')}',
      imageUrl: data['image'],
      isDark: isDark,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RCDetailsPage(
              vehicleDetails: data,
            ),
          ),
        );
      },
      onMenuPressed: () {
        _showMenuOptions(context, doc);
      },
    );
  }

  void _showMenuOptions(
      BuildContext context, DocumentSnapshot<Map<String, dynamic>> doc) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.directions_car, color: kPrimaryColor),
                title: const Text('Reactivate Vehicle'),
                onTap: () async {
                  Navigator.pop(context);
                  await _showActivateConfirmationDialog(doc.id);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.grey),
                title: const Text('Update Details'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditVehicleDetailsForm(
                        initialValues: doc.data() ?? {},
                        items: [doc.data()?['vehicleNumber'].toString() ?? ''],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _activateData(String vehicleId) async {
    final schoolId = _workspaceController.currentSchoolId.value;
    final user = FirebaseAuth.instance.currentUser;
    final targetId = schoolId.isNotEmpty ? schoolId : user?.uid;

    if (vehicleId.isNotEmpty) {
      if (targetId == null) return;
      var vehicleData = await FirebaseFirestore.instance
          .collection('users')
          .doc(targetId)
          .collection('deactivated_vehicleDetails')
          .doc(vehicleId)
          .get();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetId)
          .collection('vehicleDetails')
          .doc(vehicleId)
          .set(vehicleData.data() ?? {});

      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetId)
          .collection('deactivated_vehicleDetails')
          .doc(vehicleId)
          .delete();
    }
  }

  Future<void> _showActivateConfirmationDialog(String documentId) async {
    showCustomConfirmationDialog(
      context,
      'Confirm Activation?',
      'Are you sure ?',
      () async {
        await _activateData(documentId);
        Navigator.of(context).pop();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const DeactivatedVehicleList(),
          ),
        );
      },
    );
  }
}
