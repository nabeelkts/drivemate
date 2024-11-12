import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/screens/authentication/widgets/my_button.dart';
import 'package:mds/screens/dashboard/form/edit_forms/edit_vehicle_details_form.dart';
import 'package:mds/screens/dashboard/form/new_forms/rc_details_form.dart';
import 'package:mds/screens/dashboard/list/deactivated_vehicle_list.dart';
import 'package:mds/screens/dashboard/list/details/rc_details_page.dart';
import 'package:mds/screens/dashboard/list/widgets/search_widget.dart';
import 'package:mds/screens/dashboard/list/widgets/shimmer_loading_list.dart';

class VehicleDetailsList extends StatefulWidget {
  final String userId;

  const VehicleDetailsList({required this.userId, Key? key}) : super(key: key);

  @override
  State<VehicleDetailsList> createState() => _VehicleDetailsListState();
}

User? user = FirebaseAuth.instance.currentUser;

class _VehicleDetailsListState extends State<VehicleDetailsList> {
  bool isLoading = false;
  final _userStreamController =
      StreamController<QuerySnapshot<Map<String, dynamic>>>();
  late StreamSubscription<QuerySnapshot<Map<String, dynamic>>>
      _userStreamSubscription;

  TextEditingController _searchController = TextEditingController();
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _allVehicleDetails = [];

  @override
  void initState() {
    super.initState();
    _userStreamSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user?.uid)
        .collection('vehicleDetails')
        .snapshots()
        .listen((snapshot) {
      _userStreamController.add(snapshot);
      setState(() {
        _allVehicleDetails = snapshot.docs;
      });
    });
  }

  @override
  void dispose() {
    _userStreamSubscription.cancel();
    _userStreamController.close();
    super.dispose();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filteredVehicleDetails(
      String query) {
    return _allVehicleDetails
        .where((doc) =>
            doc['vehicleNumber'].toLowerCase().contains(query.toLowerCase()) ||
            doc['mobileNumber'].toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: const Text(
          'Vehicle Details List',
          style: TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: Center(
          child: CircleAvatar(
            backgroundColor: kWhite,
            child: CircleAvatar(
              backgroundColor: kPrimaryColor,
              radius:
                  15, // Increase the radius to provide enough space for the IconButton
              child: Center(
                child: CircleAvatar(
                  radius:
                      14, // Adjust the radius to make the inner CircleAvatar smaller
                  backgroundColor: kWhite,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: kPrimaryColor,
                      size: 15,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DeactivatedVehicleList(),
                ),
              );
            },
            icon: const Icon(
              Icons.list_rounded,
              color: kPrimaryColor,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          SearchWidget(
            placeholder: 'Search by Vehicle Number',
            controller: _searchController,
            onChanged: (value) {
              setState(() {});
            },
          ),
          MyButton(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RcDetails()),
              );
            },
            text: 'Create New RC Details',
            isLoading: isLoading,
            isEnabled: true,
          ),
          const SizedBox(
            height: 4,
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _userStreamController.stream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('Connection Error');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ShimmerLoadingList();
                }

                var docs = _searchController.text.isNotEmpty
                    ? _filteredVehicleDetails(_searchController.text)
                    : snapshot.data!.docs
                        .map((doc) =>
                            doc as QueryDocumentSnapshot<Map<String, dynamic>>)
                        .toList();

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RCDetailsPage(
                              vehicleDetails: docs[index].data(),
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(
                          right: 20,
                          left: 20,
                          top: 4,
                          bottom: 4,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: kWhite, // Set the card background color
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: kPrimaryColor, // Set the border color
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                    top: 8, bottom: 8, left: 16, right: 16),
                                child: Center(
                                  child: CircleAvatar(
                                    backgroundColor: kPrimaryColor,
                                    radius: 50,
                                    child: Center(
                                      child: CircleAvatar(
                                        radius: 48,
                                        backgroundImage: docs[index]['image'] !=
                                                    null &&
                                                docs[index]['image'].isNotEmpty
                                            ? CachedNetworkImageProvider(
                                                    docs[index]['image'])
                                                as ImageProvider
                                            : AssetImage(
                                                'assets/icons/vehicle_rc.png'),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    right: 16,
                                    bottom: 8,
                                    top: 8,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            docs[index]['vehicleNumber'],
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            'BL: ${docs[index]['balanceAmount']}',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: kPrimaryColor),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        'Mobile: ${docs[index]['mobileNumber']}',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      Text(
                                        'Service: ${docs[index]['service']}',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            top: 12, bottom: 8),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () {
                                                  // Handle edit action
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          EditVehicleDetailsForm(
                                                        initialData:
                                                            docs[index].data(),
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    gradient:
                                                        const LinearGradient(
                                                      begin:
                                                          AlignmentDirectional
                                                              .topCenter,
                                                      end: AlignmentDirectional
                                                          .bottomCenter,
                                                      colors: linearButtonColor,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: const Center(
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsets.all(8.0),
                                                      child: Text(
                                                        'Update',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w600,
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
                                                  await _showDeleteConfirmationDialog(
                                                      docs[index].id);
                                                  setState(() {});
                                                },
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: inactiveButtonColor,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: const Center(
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsets.all(8.0),
                                                      child: Text(
                                                        'Inactive',
                                                        style: TextStyle(
                                                            color:
                                                                kRedInactiveTextColor,
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteData(String documentId) async {
    if (documentId.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .collection('vehicleDetails')
          .doc(documentId)
          .delete();
    }
  }

  Future<void> _showDeleteConfirmationDialog(String documentId) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmation'),
          content:
              Text('Are you sure you want to delete this vehicle details?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await _deleteData(documentId);
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
