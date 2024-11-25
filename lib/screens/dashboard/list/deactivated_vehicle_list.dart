import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/screens/dashboard/form/edit_forms/edit_vehicle_details_form.dart';
import 'package:mds/screens/dashboard/list/details/rc_details_page.dart';
import 'package:mds/screens/dashboard/list/widgets/search_widget.dart';
import 'package:mds/screens/dashboard/list/widgets/shimmer_loading_list.dart';
import 'package:mds/screens/profile/dialog_box.dart';

class DeactivatedVehicleList extends StatefulWidget {
  const DeactivatedVehicleList({super.key});

  @override
  State<DeactivatedVehicleList> createState() => _DeactivatedVehicleListState();
}

class _DeactivatedVehicleListState extends State<DeactivatedVehicleList> {
  User? user = FirebaseAuth.instance.currentUser;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _streamSubscription;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _allDeactivatedVehicles = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setupStream();
  }

  void _setupStream() {
    _streamSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user?.uid)
        .collection('deactivated_vehicleDetails')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _allDeactivatedVehicles = snapshot.docs;
        });
      }
    });
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filteredVehicles(String query) {
    return _allDeactivatedVehicles.where((doc) {
      final data = doc.data();
      final vehicleNumber = data['vehicleNumber']?.toString().toLowerCase() ?? '';
      final mobileNumber = data['mobileNumber']?.toString().toLowerCase() ?? '';
      final searchQuery = query.toLowerCase();
      return vehicleNumber.contains(searchQuery) || mobileNumber.contains(searchQuery);
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
          'Deactivated Vehicle List',
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
                  .doc(user?.uid)
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
                    return buildVehicleListItem(context, docs[index], data);
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
  ) {
    return InkWell(
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
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 4,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: kPrimaryColor,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      data['vehicleNumber']?.toString() ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'BL: ${data['balanceAmount']?.toString() ?? '0'}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: kPrimaryColor,
                      ),
                    ),
                  ],
                ),
                Text(
                  data['mobileNumber']?.toString() ?? 'N/A',
                  style: listTextStyle,
                ),
                Text(
                  data['service']?.toString() ?? 'N/A',
                  style: listTextStyle,
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    top: 12,
                    bottom: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditVehicleDetailsForm(
                                  initialData: data,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: AlignmentDirectional.topCenter,
                                end: AlignmentDirectional.bottomCenter,
                                colors: linearButtonColor,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'Update',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            await _showActivateConfirmationDialog(doc.id);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: inactiveButtonColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'Activate',
                                  style: TextStyle(
                                    color: kRedInactiveTextColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _activateData(String vehicleId) async {
    if (vehicleId.isNotEmpty) {
      var vehicleData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .collection('deactivated_vehicleDetails')
          .doc(vehicleId)
          .get();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .collection('vehicleDetails')
          .doc(vehicleId)
          .set(vehicleData.data() ?? {});

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
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
