import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:drivemate/screens/widget/custom_back_button.dart';
import 'package:get/get.dart';
import 'package:drivemate/controller/workspace_controller.dart';
import 'package:drivemate/constants/colors.dart';
import 'package:drivemate/utils/soft_delete_utils.dart';
import 'package:drivemate/screens/dashboard/list/widgets/animated_search_widget.dart';
import 'package:drivemate/screens/dashboard/list/widgets/shimmer_loading_list.dart';
import 'package:drivemate/screens/dashboard/list/widgets/summary_header.dart';
import 'package:drivemate/screens/dashboard/import/import_screen.dart';
import 'package:drivemate/screens/dashboard/export/export_screen.dart';
import 'package:drivemate/services/excel_import_service.dart';

enum SortOrder { newestToOldest, oldestToNewest, aToZ, zToA }

class BaseListWidget extends StatefulWidget {
  final String title;
  final String collectionName;
  final String searchField;
  final String? secondarySearchField; // New field for mobile number search
  final Widget Function(
      BuildContext, QueryDocumentSnapshot<Map<String, dynamic>>) itemBuilder;
  final VoidCallback? onAddNew;
  final VoidCallback? onViewDeactivated;
  final VoidCallback? onImport; // New import callback
  final VoidCallback? onExport; // New export callback
  final ImportType? importType; // Import type for this list
  final ImportType? exportType; // Export type for this list
  final String? addButtonText;
  final String summaryLabel;

  const BaseListWidget({
    required this.title,
    required this.collectionName,
    required this.searchField,
    this.secondarySearchField, // Make it optional
    required this.itemBuilder,
    this.onAddNew,
    this.onViewDeactivated,
    this.onImport,
    this.onExport,
    this.importType,
    this.exportType,
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
          print(
              '📊 BaseListWidget [${widget.collectionName}] received ${snapshot.docs.length} docs');
          _userStreamController.add(snapshot);
          setState(() {
            // Filter out soft-deleted items
            _allItems = SoftDeleteUtils.filterDeletedDocuments(snapshot.docs);
            print('   After filtering: ${_allItems.length} docs');
            _filterItems(_searchController.text);
          });
        }
      },
      onError: (error) {
        print('❌ BaseListWidget [${widget.collectionName}] error: $error');
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

  List<Widget> _buildActions() {
    final List<Widget> actions = [];

    // Add import/export menu button if either callback is provided
    if (widget.onImport != null || widget.onExport != null) {
      actions.add(
        PopupMenuButton<String>(
          icon: const Icon(
            Icons.swap_vert,
            color: kPrimaryColor,
          ),
          tooltip: 'Import / Export',
          onSelected: (value) {
            if (value == 'import') {
              if (widget.onImport != null) {
                widget.onImport!();
              } else if (widget.importType != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ImportScreen(
                      importType: widget.importType!,
                    ),
                  ),
                );
              }
            } else if (value == 'export') {
              if (widget.onExport != null) {
                widget.onExport!();
              } else if (widget.exportType != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ExportScreen(
                      exportType: widget.exportType!,
                    ),
                  ),
                );
              }
            }
          },
          itemBuilder: (context) => [
            if (widget.onImport != null || widget.importType != null)
              const PopupMenuItem<String>(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.upload_file, color: kPrimaryColor),
                    SizedBox(width: 12),
                    Text('Import Records'),
                  ],
                ),
              ),
            if (widget.onExport != null || widget.exportType != null)
              const PopupMenuItem<String>(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download, color: kPrimaryColor),
                    SizedBox(width: 12),
                    Text('Export Records'),
                  ],
                ),
              ),
          ],
        ),
      );
    }

    // Add deactivated list button if provided
    if (widget.onViewDeactivated != null) {
      actions.add(
        IconButton(
          onPressed: widget.onViewDeactivated,
          icon: const Icon(
            Icons.list_rounded,
            color: kPrimaryColor,
          ),
        ),
      );
    }

    return actions;
  }

  void _filterItems(String query) {
    if (!mounted) return;
    setState(() {
      _filterItemsLocally(query);
    });
  }

  // Internal helper to filter items without triggering setState if already in build/stream update
  void _filterItemsLocally(String query) {
    if (query.isEmpty) {
      _filteredItems = List.from(_allItems);
    } else {
      _filteredItems = _allItems.where((doc) {
        final data = doc.data();
        final primaryFieldValue =
            data[widget.searchField]?.toString().toLowerCase() ?? '';
        final matchesPrimary = primaryFieldValue.contains(query.toLowerCase());

        bool matchesSecondary = false;
        if (widget.secondarySearchField != null) {
          final secondaryFieldValue =
              data[widget.secondarySearchField]?.toString().toLowerCase() ?? '';
          matchesSecondary = secondaryFieldValue.contains(query.toLowerCase());
        }

        return matchesPrimary || matchesSecondary;
      }).toList();
    }
    _sortItems();
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
        actions: _buildActions(),
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

          AnimatedSearchWidget(
            primaryPlaceholder: 'Search by ${widget.searchField}',
            secondaryPlaceholder: widget.secondarySearchField != null
                ? 'Search by ${widget.secondarySearchField}'
                : 'Search by ${widget.searchField}',
            controller: _searchController,
            onChanged: _filterItems,
          ),

          const SizedBox(height: 4),

          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _userStreamController.stream,
              builder: (context, snapshot) {
                // ALWAYS check for error first - this prevents white screen
                if (snapshot.hasError) {
                  print(
                      '❌ BaseListWidget [${widget.collectionName}] displaying error: ${snapshot.error}');
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
                          'Error loading data',
                          style: const TextStyle(
                            color: kRedInactiveTextColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            '${snapshot.error}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Seamless Transition: If we have previous data and the stream is just re-subscribing (waiting),
                // keep showing current items instead of a shimmer or empty state.
                if (snapshot.connectionState == ConnectionState.waiting &&
                    _allItems.isNotEmpty) {
                  // Keep showing current items - fall through
                } else if (snapshot.connectionState ==
                        ConnectionState.waiting &&
                    _allItems.isEmpty &&
                    !snapshot.hasData) {
                  return const ShimmerLoadingList();
                }

                // If we have cached data, show it immediately (prevents white screen on back navigation)
                if (_filteredItems.isNotEmpty ||
                    _searchController.text.isNotEmpty) {
                  if (_filteredItems.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off,
                              color: kPrimaryColor, size: 48),
                          const SizedBox(height: 16),
                          const Text(
                            'No matching data found',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w500),
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
                }

                // Fallback: show empty state
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
