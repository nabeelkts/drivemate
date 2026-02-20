// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:iconly/iconly.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/screens/accounts/accounts_screen.dart';
import 'package:mds/screens/dashboard/dashboard.dart';
import 'package:mds/screens/dashboard/dashboard_layout2.dart';
import 'package:mds/screens/profile/profile_screen.dart';
import 'package:mds/screens/statistics/stats_screen.dart';
import 'package:mds/services/app_lifecycle_service.dart';
import 'package:mds/services/subscription_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mds/controller/workspace_controller.dart';
import 'package:mds/features/tracking/presentation/screens/owner_map_screen.dart';

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
    if (_isOwner) {
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
    final profileIndex = _isOwner ? 4 : 3;

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

    // Block navigation to other tabs if subscription is expired
    if (_isSubscriptionExpired && index != profileIndex) {
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
    final String homeLayout = box.read('homeLayout') ?? 'layout1';
    return homeLayout == 'layout2'
        ? const DashboardLayout2()
        : const Dashboard();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: PopScope(
        canPop: false,
        child: Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: IndexedStack(
                  index: _currentIndex,
                  children: _screens,
                ),
              ),
            ),
            Obx(() {
              if (!_workspaceController.isConnected.value &&
                  _currentIndex != (_isOwner ? 4 : 3)) {
                return Container(
                  color: theme.scaffoldBackgroundColor.withOpacity(0.95),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.link_off, size: 80, color: kPrimaryColor),
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
      bottomNavigationBar:
          _isOwner ? _buildOwnerNavBar(theme) : _buildStaffNavBar(theme),
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
        _buildNavBarItem(0, IconlyLight.home, 'Home'),
        _buildNavBarItem(1, IconlyLight.chart, 'Statistics'),
        _buildNavBarItem(2, Icons.map_outlined, 'Map', useIconData: true),
        _buildNavBarItem(3, IconlyLight.swap, 'Accounts'),
        _buildNavBarItem(4, IconlyLight.profile, 'Profile'),
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
        _buildNavBarItem(0, IconlyLight.home, 'Home'),
        _buildNavBarItem(1, IconlyLight.chart, 'Statistics'),
        _buildNavBarItem(2, IconlyLight.swap, 'Accounts'),
        _buildNavBarItem(3, IconlyLight.profile, 'Profile'),
      ],
    );
  }

  BottomNavigationBarItem _buildNavBarItem(
    int index,
    dynamic icon,
    String label, {
    bool useIconData = false,
  }) {
    final theme = Theme.of(context);
    final profileIndex = _isOwner ? 4 : 3;
    final isStaffUnconnected =
        !_workspaceController.isConnected.value && index != profileIndex;
    final isDisabled =
        (_isSubscriptionExpired || isStaffUnconnected) && index != profileIndex;

    final iconWidget = Opacity(
      opacity: isDisabled ? 0.3 : 1.0,
      child: Icon(
        icon as IconData,
        color: _currentIndex == index
            ? theme.colorScheme.primary
            : (isDisabled ? Colors.grey.shade400 : Colors.grey.shade700),
        size: 32,
      ),
    );

    return BottomNavigationBarItem(
      label: label,
      icon: iconWidget,
    );
  }
}
