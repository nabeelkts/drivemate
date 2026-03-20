// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:iconly/iconly.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drivemate/constants/colors.dart';
import 'package:drivemate/screens/accounts/accounts_screen.dart';
import 'package:drivemate/screens/dashboard/dashboard.dart';
import 'package:drivemate/screens/dashboard/dashboard_layout2.dart';
import 'package:drivemate/screens/dashboard/student/student_dashboard_screen.dart';
import 'package:drivemate/screens/dashboard/list/details/students_details_page.dart';
import 'package:drivemate/screens/profile/profile_screen.dart';
import 'package:drivemate/screens/statistics/stats_screen.dart';
import 'package:drivemate/services/app_lifecycle_service.dart';
import 'package:drivemate/services/subscription_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:drivemate/controller/workspace_controller.dart';
import 'package:drivemate/features/tracking/presentation/screens/owner_map_screen.dart';

class BottomNavScreen extends StatefulWidget {
  const BottomNavScreen({super.key});

  @override
  _BottomNavScreenState createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  final WorkspaceController _workspaceController =
      Get.find<WorkspaceController>();
  final box = GetStorage();
  int _currentIndex = 0;
  late List<Widget> _screens;

  // Subscription state
  final SubscriptionService _subscriptionService = SubscriptionService();
  bool _isSubscriptionExpired = false;

  bool get _isOwner => _workspaceController.userRole.value == 'Owner';
  bool get _isStudent => _workspaceController.userRole.value == 'Student';

  @override
  void initState() {
    super.initState();
    // Listen for layout changes and rebuild immediately
    box.listenKey('homeLayout', (value) {
      if (mounted) {
        setState(() {
          _screens[0] = _getCurrentDashboard();
        });
      }
    });
    // Check subscription status
    _checkSubscription();
    // Check biometric authentication when app first loads
    _checkBiometricOnStart();

    _screens = _buildScreens();
  }

  List<Widget> _buildScreens() {
    if (_isStudent) {
      // Students see their own details page using the existing StudentDetailsPage
      return [
        const StudentDetailsScreenLoader(),
        ProfileScreen(onSubscriptionRenewed: _checkSubscription),
      ];
    } else if (_isOwner) {
      return [
        _getCurrentDashboard(),
        const StatsScreen(),
        const OwnerMapScreen(), // Map tab — owners only
        const AccountsScreen(),
        ProfileScreen(onSubscriptionRenewed: _checkSubscription),
      ];
    } else {
      return [
        _getCurrentDashboard(),
        const StatsScreen(),
        const AccountsScreen(),
        ProfileScreen(onSubscriptionRenewed: _checkSubscription),
      ];
    }
  }

  Future<void> _checkSubscription() async {
    final schoolId = _workspaceController.currentSchoolId.value;
    final user = FirebaseAuth.instance.currentUser;

    if (schoolId.isEmpty && user == null) {
      return;
    }

    try {
      int retryCount = 0;
      while (_workspaceController.isLoading.value && retryCount < 30) {
        await Future.delayed(const Duration(milliseconds: 100));
        retryCount++;
      }

      final schoolId = _workspaceController.currentSchoolId.value;
      final targetId = schoolId.isNotEmpty ? schoolId : (user?.uid ?? '');

      if (targetId.isEmpty) {
        return;
      }

      final result = await _subscriptionService.checkSubscription(targetId);
      final isGracePeriodExpired = result['isGracePeriodExpired'] ?? false;

      if (mounted) {
        final profileIndex = _isOwner ? 4 : 3;
        setState(() {
          _isSubscriptionExpired = isGracePeriodExpired;

          if (isGracePeriodExpired && _currentIndex != profileIndex) {
            _currentIndex = profileIndex;
          }
        });
      }
    } catch (e) {
      print('Error checking subscription: $e');
    }
  }

  Future<void> _checkBiometricOnStart() async {
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final lifecycleService = Get.find<AppLifecycleService>();
      await lifecycleService.checkBiometricOnAppStart();
    } catch (e) {
      print('Error checking biometric on start: $e');
    }
  }

  void _onItemTapped(int index) {
    final profileIndex = _isStudent ? 1 : (_isOwner ? 4 : 3);

    // Block navigation to other tabs if staff is not connected
    if (!_workspaceController.isConnected.value && index != profileIndex) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Workspace connection required. Please enter your School ID in the Profile tab.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: kPrimaryColor,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Block navigation to other tabs if subscription is expired (not for students)
    if (!_isStudent && _isSubscriptionExpired && index != profileIndex) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Subscription and grace period expired. Please renew to access this feature.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Renew',
            textColor: Colors.white,
            onPressed: () {
              setState(() => _currentIndex = profileIndex);
            },
          ),
        ),
      );
      return;
    }

    setState(() => _currentIndex = index);
  }

  Widget _getCurrentDashboard() {
    // Temporarily disabled layout selector at user's request. Only Vertical Layout shown.
    // final String homeLayout = box.read('homeLayout') ?? 'layout1';
    // return homeLayout == 'layout2'
    //     ? const DashboardLayout2() // Vertical Layout
    //     : const Dashboard();       // Classic/Grid Layout
    return const DashboardLayout2();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        ),
      ),
      body: SafeArea(
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;

            // If on home screen (index 0), exit directly
            if (_currentIndex == 0) {
              SystemNavigator.pop();
            } else {
              // Go back to home screen
              setState(() {
                _currentIndex = 0;
              });
            }
          },
          child: Stack(
            children: [
              IndexedStack(
                index: _currentIndex,
                children: _screens,
              ),
              Obx(() {
                // Only show overlay if isConnected is explicitly false AND initializeWorkspace has finished its first check
                if (_workspaceController.isConnectedInitialized.value &&
                    !_workspaceController.isConnected.value &&
                    _currentIndex != (_isOwner ? 4 : 3)) {
                  return Container(
                    color: theme.scaffoldBackgroundColor.withOpacity(0.95),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.link_off,
                                size: 80, color: kPrimaryColor),
                            const SizedBox(height: 24),
                            Text(
                              'Workspace Required',
                              style: theme.textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'You are logged in as a Staff member but not yet connected to a Driving School workspace.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 32),
                            ElevatedButton(
                              onPressed: () => setState(
                                  () => _currentIndex = _isOwner ? 4 : 3),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Go to Profile to Connect',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
              Obx(() {
                final isLoading = _workspaceController.isLoading.value ||
                    _workspaceController.isAppDataLoading.value;
                if (isLoading) {
                  return Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      minHeight: 2,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          kPrimaryColor.withOpacity(0.5)),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _isStudent
          ? _buildStudentNavBar(theme)
          : (_isOwner ? _buildOwnerNavBar(theme) : _buildStaffNavBar(theme)),
    );
  }

  /// 5-tab nav bar for owners: Home | Stats | Map | Accounts | Profile
  Widget _buildOwnerNavBar(ThemeData theme) {
    return BottomNavigationBar(
      backgroundColor:
          theme.brightness == Brightness.dark ? Colors.black : Colors.white,
      currentIndex: _currentIndex,
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      selectedItemColor: theme.colorScheme.primary,
      unselectedItemColor: Colors.grey.shade500,
      elevation: 0.0,
      items: [
        _buildNavBarItem(0, IconlyLight.home, IconlyBold.home, 'Home'),
        _buildNavBarItem(1, IconlyLight.chart, IconlyBold.chart, 'Statistics'),
        _buildNavBarItem(2, Icons.map_outlined, Icons.map, 'Map',
            useIconData: true),
        _buildNavBarItem(3, IconlyLight.swap, IconlyBold.swap, 'Accounts'),
        _buildNavBarItem(4, IconlyLight.profile, IconlyBold.profile, 'Profile'),
      ],
    );
  }

  /// 4-tab nav bar for staff: Home | Stats | Accounts | Profile
  Widget _buildStaffNavBar(ThemeData theme) {
    return BottomNavigationBar(
      backgroundColor:
          theme.brightness == Brightness.dark ? Colors.black : Colors.white,
      currentIndex: _currentIndex,
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      selectedItemColor: theme.colorScheme.primary,
      unselectedItemColor: Colors.grey.shade500,
      elevation: 0.0,
      items: [
        _buildNavBarItem(0, IconlyLight.home, IconlyBold.home, 'Home'),
        _buildNavBarItem(1, IconlyLight.chart, IconlyBold.chart, 'Statistics'),
        _buildNavBarItem(2, IconlyLight.swap, IconlyBold.swap, 'Accounts'),
        _buildNavBarItem(3, IconlyLight.profile, IconlyBold.profile, 'Profile'),
      ],
    );
  }

  /// 2-tab nav bar for students: Dashboard | Profile
  Widget _buildStudentNavBar(ThemeData theme) {
    return BottomNavigationBar(
      backgroundColor:
          theme.brightness == Brightness.dark ? Colors.black : Colors.white,
      currentIndex: _currentIndex,
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      selectedItemColor: theme.colorScheme.primary,
      unselectedItemColor: Colors.grey.shade500,
      elevation: 0.0,
      items: [
        _buildNavBarItem(0, IconlyLight.home, IconlyBold.home, 'Dashboard'),
        _buildNavBarItem(1, IconlyLight.profile, IconlyBold.profile, 'Profile'),
      ],
    );
  }

  BottomNavigationBarItem _buildNavBarItem(
    int index,
    dynamic icon,
    dynamic selectedIcon,
    String label, {
    bool useIconData = false,
  }) {
    final theme = Theme.of(context);
    final profileIndex = _isOwner ? 4 : 3;
    final isStaffUnconnected =
        !_workspaceController.isConnected.value && index != profileIndex;
    final isDisabled =
        (_isSubscriptionExpired || isStaffUnconnected) && index != profileIndex;

    final isSelected = _currentIndex == index;

    final iconWidget = Opacity(
      opacity: isDisabled ? 0.3 : 1.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: Icon(
          isSelected ? (selectedIcon as IconData) : (icon as IconData),
          color: isSelected
              ? theme.colorScheme.primary
              : (isDisabled ? Colors.grey.shade400 : Colors.grey.shade700),
          size: isSelected
              ? 30
              : 28, // Slightly smaller base size, larger selected
        ),
      ),
    );

    return BottomNavigationBarItem(
      label: label,
      icon: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: iconWidget,
      ),
      activeIcon: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: iconWidget,
      ),
    );
  }
}

/// Helper widget to load and display StudentDetailsPage for the current student
class StudentDetailsScreenLoader extends StatefulWidget {
  const StudentDetailsScreenLoader({super.key});

  @override
  State<StudentDetailsScreenLoader> createState() =>
      _StudentDetailsScreenLoaderState();
}

class _StudentDetailsScreenLoaderState
    extends State<StudentDetailsScreenLoader> {
  final WorkspaceController _workspaceController =
      Get.find<WorkspaceController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _studentData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    try {
      final schoolId = _workspaceController.currentSchoolId.value;
      final studentDocId = _workspaceController.studentDocId.value;

      if (schoolId.isEmpty || studentDocId.isEmpty) {
        setState(() {
          _error = 'Student data not found';
          _isLoading = false;
        });
        return;
      }

      final doc = await _firestore
          .collection('users')
          .doc(schoolId)
          .collection('students')
          .doc(studentDocId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = Map<String, dynamic>.from(doc.data()!);
        data['id'] = doc.id;
        setState(() {
          _studentData = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Student record not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _loadStudentData();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return StudentDetailsPage(
      studentDetails: _studentData!,
      isStudentView: true,
    );
  }
}
