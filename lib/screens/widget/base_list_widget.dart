import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mds/screens/widget/custom_back_button.dart';
import 'package:get/get.dart';
import 'package:mds/controller/workspace_controller.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/screens/dashboard/list/widgets/search_widget.dart';
import 'package:mds/screens/dashboard/list/widgets/shimmer_loading_list.dart';
import 'package:mds/screens/dashboard/list/widgets/summary_header.dart';

enum SortOrder { newestToOldest, oldestToNewest, aToZ, zToA }

class BaseListWidget extends StatefulWidget {
  final String title;
  final String collectionName;
  final String searchField;
  final Widget Function(
      BuildContext, QueryDocumentSnapshot<Map<String, dynamic>>) itemBuilder;
  final VoidCallback? onAddNew;
  final VoidCallback? onViewDeactivated;
  final String? addButtonText;
  final String summaryLabel;

  const BaseListWidget({
    required this.title,
    required this.collectionName,
    required this.searchField,
    required this.itemBuilder,
    this.onAddNew,
    this.onViewDeactivated,
    this.addButtonText,
    this.summaryLabel = 'Total Records:',
    super.key,
  });

  @override
  State<BaseListWidget> createState() => _BaseListWidgetState();
}

class _BaseListWidgetState extends State<BaseListWidget> {
  final _userStreamController =
      StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();
  late StreamSubscription<QuerySnapshot<Map<String, dynamic>>>
      _userStreamSubscription;
  final TextEditingController _searchController = TextEditingController();
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _allItems = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filteredItems = [];
  SortOrder _currentSortOrder = SortOrder.newestToOldest;
  final WorkspaceController _workspaceController =
      Get.find<WorkspaceController>();

  @override
  void initState() {
    super.initState();
    _setupStream();
  }

  void _setupStream() {
    _userStreamSubscription = _workspaceController
        .getFilteredCollection(widget.collectionName)
        .snapshots()
        .listen(
      (snapshot) {
        if (mounted) {
          _userStreamController.add(snapshot);
          setState(() {
            _allItems = snapshot.docs;
            _filterItems(_searchController.text);
          });
        }
      },
      onError: (error) {
        if (mounted) {
          _userStreamController.addError(error);
        }
      },
    );
  }

  @override
  void dispose() {
    _userStreamSubscription.cancel();
    _userStreamController.close();
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems(String query) {
    if (!mounted) return;

    setState(() {
      if (query.isEmpty) {
        _filteredItems = _allItems;
      } else {
        _filteredItems = _allItems.where((doc) {
          final fieldValue =
              doc.data()[widget.searchField]?.toString().toLowerCase() ?? '';
          return fieldValue.contains(query.toLowerCase());
        }).toList();
      }
      _sortItems();
    });
  }

  void _sortItems() {
    switch (_currentSortOrder) {
      case SortOrder.newestToOldest:
        _filteredItems.sort((a, b) {
          final aDate = a.data()['registrationDate'] as String? ?? '';
          final bDate = b.data()['registrationDate'] as String? ?? '';
          return bDate.compareTo(aDate);
        });
        break;
      case SortOrder.oldestToNewest:
        _filteredItems.sort((a, b) {
          final aDate = a.data()['registrationDate'] as String? ?? '';
          final bDate = b.data()['registrationDate'] as String? ?? '';
          return aDate.compareTo(bDate);
        });
        break;
      case SortOrder.aToZ:
        _filteredItems.sort((a, b) {
          final aName =
              a.data()[widget.searchField]?.toString().toLowerCase() ?? '';
          final bName =
              b.data()[widget.searchField]?.toString().toLowerCase() ?? '';
          return aName.compareTo(bName);
        });
        break;
      case SortOrder.zToA:
        _filteredItems.sort((a, b) {
          final aName =
              a.data()[widget.searchField]?.toString().toLowerCase() ?? '';
          final bName =
              b.data()[widget.searchField]?.toString().toLowerCase() ?? '';
          return bName.compareTo(aName);
        });
        break;
    }
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Sort By',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 18.0,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Newest to Oldest'),
                onTap: () {
                  setState(() {
                    _currentSortOrder = SortOrder.newestToOldest;
                    _sortItems();
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Oldest to Newest'),
                onTap: () {
                  setState(() {
                    _currentSortOrder = SortOrder.oldestToNewest;
                    _sortItems();
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('A to Z'),
                onTap: () {
                  setState(() {
                    _currentSortOrder = SortOrder.aToZ;
                    _sortItems();
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Z to A'),
                onTap: () {
                  setState(() {
                    _currentSortOrder = SortOrder.zToA;
                    _sortItems();
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          widget.title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: const CustomBackButton(),
        actions: widget.onViewDeactivated != null
            ? [
                IconButton(
                  onPressed: widget.onViewDeactivated,
                  icon: const Icon(
                    Icons.list_rounded,
                    color: kPrimaryColor,
                  ),
                ),
              ]
            : null,
      ),
      body: Column(
        children: [
          // New Summary Header
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _userStreamController.stream,
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];
              double totalDues = 0;
              for (var doc in docs) {
                totalDues += double.tryParse(
                        doc.data()['balanceAmount']?.toString() ?? '0') ??
                    0;
              }
              return ListSummaryHeader(
                totalLabel: widget.summaryLabel,
                totalCount: docs.length,
                pendingDues: totalDues,
                isDark: isDark,
              );
            },
          ),

          SearchWidget(
            placeholder: 'Search by ${widget.searchField}',
            controller: _searchController,
            onChanged: _filterItems,
          ),

          const SizedBox(height: 4),

          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _userStreamController.stream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: kRedInactiveTextColor,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(
                            color: kRedInactiveTextColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ShimmerLoadingList();
                }

                if (_filteredItems.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.search_off,
                          color: kPrimaryColor,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No data found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: _filteredItems.length,
                  padding: const EdgeInsets.only(bottom: 80),
                  itemBuilder: (context, index) =>
                      widget.itemBuilder(context, _filteredItems[index]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: widget.onAddNew != null
          ? FloatingActionButton(
              onPressed: widget.onAddNew,
              backgroundColor: kPrimaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
