import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/controller/app_controller.dart';
import 'package:mds/controller/theme_controller.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mds/screens/legal/privacy_policy_screen.dart';
import 'package:mds/screens/legal/terms_of_service_screen.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:mds/utils/loading_utils.dart';
import 'package:mds/screens/profile/widgets/profile_header.dart';
import 'package:mds/screens/profile/widgets/subscription_card.dart';
import 'package:mds/screens/profile/admin/organization_management_page.dart';
import 'package:mds/controller/workspace_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:mds/screens/profile/edit_user_profile.dart';
import 'package:mds/screens/profile/edit_company_profile.dart';
import 'package:mds/screens/profile/home_layout_selector.dart';
import 'package:mds/screens/profile/dialog_box.dart';
import 'package:mds/services/subscription_service.dart';
import 'package:mds/screens/profile/admin/admin_subscription_page.dart';
import 'package:mds/screens/profile/admin/manage_staff_page.dart';
import 'package:mds/screens/authentication/google_sign_in.dart';
import 'package:mds/screens/profile/settings_page.dart';
import 'package:mds/features/tracking/presentation/screens/owner_map_screen.dart';
import 'package:mds/features/tracking/presentation/screens/staff_tracking_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onSubscriptionRenewed;

  const ProfileScreen({super.key, this.onSubscriptionRenewed});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final box = GetStorage();
  final auth = LocalAuthentication();
  final appController = Get.put(AppController());
  late final ThemeController themeController;
  bool isDarkMode = false;
  bool notificationsEnabled = true;
  bool biometricEnabled = false;
  bool canCheckBiometrics = false;
  User? _currentUser;
  String _lastLoginTime = '';
  Color get _selectedThemeColor => themeController.themeColor;
  bool _isInitialized = false;

  final WorkspaceController _workspaceController =
      Get.find<WorkspaceController>();
  Worker? _workspaceWorker;

  @override
  void initState() {
    super.initState();
    _initializeState();
  }

  Future<void> _initializeState() async {
    if (!mounted) return;

    themeController = Get.find<ThemeController>();
    _currentUser = FirebaseAuth.instance.currentUser;
    isDarkMode = box.read('isDarkMode') ??
        (themeController.themeMode.value == ThemeMode.dark);
    notificationsEnabled = box.read('notificationsEnabled') ?? true;
    biometricEnabled = box.read('biometricEnabled') ?? false;
    _lastLoginTime = box.read('lastLoginTime') ??
        DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now());

    _workspaceWorker = ever(_workspaceController.isLoading, (isLoading) {
      if (!isLoading) {
        _workspaceController.refreshAppData();
      }
    });

    if (!_workspaceController.isLoading.value) {
      _workspaceController.refreshAppData();
    }
    _updateLastLoginTime();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyTheme();
    });

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _workspaceWorker?.dispose();
    super.dispose();
  }

  void _applyTheme() {
    Get.changeThemeMode(isDarkMode ? ThemeMode.dark : ThemeMode.light);
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isDarkMode ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: isDarkMode ? Colors.black : Colors.white,
        systemNavigationBarIconBrightness:
            isDarkMode ? Brightness.light : Brightness.dark,
      ),
    );
  }

  void _updateLastLoginTime() {
    final now = DateTime.now();
    final formattedTime = DateFormat('dd/MM/yyyy hh:mm a').format(now);
    box.write('lastLoginTime', formattedTime);
    if (mounted) {
      setState(() {
        _lastLoginTime = formattedTime;
      });
    }
  }

  Future<void> _checkBiometrics() async {
    try {
      canCheckBiometrics = await auth.canCheckBiometrics;
      if (!canCheckBiometrics) {
        biometricEnabled = false;
        box.write('biometricEnabled', false);
      }
    } catch (e) {
      canCheckBiometrics = false;
      biometricEnabled = false;
      box.write('biometricEnabled', false);
    }
  }

  void toggleTheme() {
    if (!mounted) return;
    setState(() {
      isDarkMode = !isDarkMode;
      box.write('isDarkMode', isDarkMode);
      themeController
          .setThemeMode(isDarkMode ? ThemeMode.dark : ThemeMode.light);
      _applyTheme();
    });
  }

  void toggleNotifications() {
    if (!mounted) return;
    setState(() {
      notificationsEnabled = !notificationsEnabled;
      box.write('notificationsEnabled', notificationsEnabled);
    });
  }

  Future<void> toggleBiometric() async {
    if (!mounted) return;

    if (!canCheckBiometrics) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Biometric authentication is not available on this device'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (!biometricEnabled) {
      try {
        final List<BiometricType> availableBiometrics =
            await auth.getAvailableBiometrics();

        if (availableBiometrics.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'No biometrics enrolled on this device. Please set up fingerprint or face recognition in your device settings.'),
                duration: Duration(seconds: 4),
              ),
            );
          }
          return;
        }

        bool authenticated = await auth.authenticate(
          localizedReason: 'Please authenticate to enable biometric login',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: true,
          ),
        );

        if (authenticated && mounted) {
          setState(() {
            biometricEnabled = true;
            box.write('biometricEnabled', true);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric login enabled'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Failed to enable biometric login: ${e.toString()}'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } else if (mounted) {
      setState(() {
        biometricEnabled = false;
        box.write('biometricEnabled', false);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biometric login disabled'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _selectedThemeColor,
            onColorChanged: (color) {
              if (!mounted) return;
              themeController.setThemeColor(color);
              setState(() {});
            },
            pickerAreaHeightPercent: 0.8,
            enableAlpha: false,
            labelTypes: const [],
            displayThumbColor: true,
            paletteType: PaletteType.hsvWithHue,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void showLogoutConfirmationDialog() {
    showCustomConfirmationDialog(
      context,
      'Confirm Logout',
      'Are you sure you want to logout?',
      () async {
        Navigator.pop(context); // Close confirmation dialog
        final provider =
            Provider.of<GoogleSignInProvider>(context, listen: false);
        await provider.signOut(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized && _currentUser == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('No user logged in'),
        ),
      );
    }

    final cardColor = isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100;
    final borderColor =
        isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    return SafeArea(
      child: Scaffold(
        backgroundColor: isDarkMode ? Colors.black : Colors.grey.shade200,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Obx(() {
                final subData = _workspaceController.subscriptionData;
                if (_workspaceController.isAppDataLoading.value &&
                    subData.isEmpty) {
                  return const Center(child: LinearProgressIndicator());
                }

                final isStaff = _workspaceController.userRole.value == 'Staff';
                if (isStaff) return const SizedBox.shrink();

                final shouldWarn = subData['shouldWarn'] ?? false;
                final isInGracePeriod = subData['isInGracePeriod'] ?? false;
                final isGracePeriodExpired =
                    subData['isGracePeriodExpired'] ?? false;
                final daysLeft = subData['daysLeft'] ?? 0;

                return Column(
                  children: [
                    if (shouldWarn)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: kOrange, width: 2),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.timer_outlined,
                                color: kOrange, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Subscription Expiring Soon',
                                    style: TextStyle(
                                      color: kOrange,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Your subscription will expire in $daysLeft days. Please renew to avoid any interruption.',
                                    style: const TextStyle(
                                      color: kOrange,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (isInGracePeriod)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue, width: 2),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline,
                                color: Colors.blue, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Grace Period Active',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Your subscription has expired, but you have ${7 + daysLeft} days left in your grace period.',
                                    style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (isGracePeriodExpired)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red, width: 2),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning,
                                color: Colors.red, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Subscription Expired',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Please renew your subscription to access all features',
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              }),
              ProfileHeader(
                currentUser: _currentUser,
                cardColor: cardColor,
                textColor: textColor,
                lastLoginTime: _lastLoginTime,
              ),
              const SizedBox(height: 20),
              Obx(() {
                final isStaff = _workspaceController.userRole.value == 'Staff';
                if (isStaff) return const SizedBox.shrink();
                return SubscriptionCard(
                  cardColor: cardColor,
                  textColor: textColor,
                  onSubscribeDialog: _showSubscribeDialog,
                );
              }),
              _buildMyOrganizationTile(
                context,
                _workspaceController,
                cardColor,
                borderColor,
                textColor,
              ),
              const SizedBox(height: 12),
              _buildTrackingTile(
                context,
                _workspaceController,
                cardColor,
                borderColor,
                textColor,
              ),
              const SizedBox(height: 20),
              _buildSettingTile(
                cardColor: cardColor,
                textColor: textColor,
                icon: Icons.settings,
                title: 'Settings',
                subtitle: 'Theme, Notifications, and Account',
                trailing: Icon(Icons.chevron_right,
                    color: textColor.withOpacity(0.5)),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SettingsPage(
                        toggleTheme: toggleTheme,
                        isDarkMode: isDarkMode,
                        notificationsEnabled: notificationsEnabled,
                        toggleNotifications: toggleNotifications,
                        biometricEnabled: biometricEnabled,
                        toggleBiometric: toggleBiometric,
                      ),
                    ),
                  );
                  _workspaceController.refreshAppData();
                },
              ),
              const SizedBox(height: 24),
              _buildFooterSingleLine(textColor),
              const SizedBox(height: 24),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Modular UI components have been moved to lib/screens/profile/widgets/

  Widget _buildFooterSingleLine(Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onLongPress: _showAdminLoginDialog,
          child: Text('Version ${appController.currentVersion.value}',
              style:
                  TextStyle(color: textColor.withOpacity(0.8), fontSize: 12)),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const PrivacyPolicyScreen())),
          child: Text('Privacy Policy',
              style: TextStyle(
                  color: textColor.withOpacity(0.9),
                  fontSize: 12,
                  decoration: TextDecoration.underline)),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const TermsOfServiceScreen())),
          child: Text('Terms',
              style: TextStyle(
                  color: textColor.withOpacity(0.9),
                  fontSize: 12,
                  decoration: TextDecoration.underline)),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () {
            appController.checkForUpdate();
          },
          child: Text('App Update',
              style: TextStyle(
                  color: textColor.withOpacity(0.9),
                  fontSize: 12,
                  decoration: TextDecoration.underline)),
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required Color cardColor,
    required Color textColor,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: textColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: kOrange, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: TextStyle(
                          color: textColor.withOpacity(0.5),
                          fontSize: 11,
                          fontWeight: FontWeight.w400),
                    ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildMyOrganizationTile(
    BuildContext context,
    WorkspaceController controller,
    Color cardColor,
    Color borderColor,
    Color textColor,
  ) {
    return Obx(() {
      final isStaff = controller.userRole.value == 'Staff';
      final isConnected = controller.isConnected.value;
      final branchData = controller.currentBranchData;
      SizedBox(
        height: 10,
      );
      String title = 'Organization';
      String name =
          controller.userProfileData['schoolName'] ?? 'My Organization';
      String subtitle = branchData['branchName'] ?? 'Manage Organization';
      IconData icon = Icons.business_center_outlined;
      VoidCallback onTap = () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const OrganizationManagementPage(),
          ),
        );
      };

      if (isStaff) {
        if (!isConnected) {
          // Show Join School option
          name = 'Join School Workspace';
          subtitle = 'Connect with your school owner';
          icon = Icons.add_business_outlined;
          onTap = () => _showJoinSchoolDialog();
        } else {
          // Show current workplace info but navigate to workplace info page
          title = 'My Workplace';
          name = branchData['branchName'] ?? 'Connected School';
          subtitle = 'Working at this branch';
        }
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: textColor.withOpacity(0.5),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor.withOpacity(0.5)),
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: kOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: kOrange, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: textColor.withOpacity(0.6),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        color: textColor.withOpacity(0.3)),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildTrackingTile(
    BuildContext context,
    WorkspaceController controller,
    Color cardColor,
    Color borderColor,
    Color textColor,
  ) {
    return Obx(() {
      final isStaff = controller.userRole.value == 'Staff';
      final isAdmin = controller.userRole.value == 'Owner' ||
          controller.userRole.value == 'Admin';

      if (!isStaff && !isAdmin) return const SizedBox.shrink();

      return Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor.withOpacity(0.5)),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => isStaff
                    ? const StaffTrackingScreen()
                    : const OwnerMapScreen(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isStaff ? Icons.my_location : Icons.map_outlined,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isStaff ? 'My Tracking Status' : 'Live Fleet Tracking',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isStaff
                            ? 'Manage your location sharing'
                            : 'Monitor all drivers in real-time',
                        style: TextStyle(
                          color: textColor.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: textColor.withOpacity(0.3)),
              ],
            ),
          ),
        ),
      );
    });
  }

  void _showJoinSchoolDialog() {
    final TextEditingController idController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isLoading = false;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Join School Workspace',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Enter the School ID provided by your administrator to link your account.',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: idController,
                    enabled: !isLoading,
                    style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Enter School ID',
                      hintStyle: TextStyle(
                          color: isDark
                              ? Colors.white.withOpacity(0.3)
                              : Colors.black.withOpacity(0.3)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      errorText: errorMessage,
                      errorMaxLines: 2,
                    ),
                    onChanged: (value) {
                      if (errorMessage != null) {
                        setState(() {
                          errorMessage = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed:
                              isLoading ? null : () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () async {
                                  final id = idController.text.trim();
                                  if (id.isEmpty) {
                                    setState(() {
                                      errorMessage = 'Please enter a School ID';
                                    });
                                    return;
                                  }

                                  setState(() {
                                    isLoading = true;
                                    errorMessage = null;
                                  });

                                  final result =
                                      await _workspaceController.joinSchool(id);

                                  if (mounted) {
                                    if (result['success'] == true) {
                                      Navigator.pop(context);
                                      Get.snackbar(
                                        "Success",
                                        result['message'] ??
                                            'Joined school workspace successfully',
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor:
                                            Colors.green.withOpacity(0.1),
                                        colorText: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                        duration: const Duration(seconds: 2),
                                      );
                                    } else {
                                      setState(() {
                                        isLoading = false;
                                        errorMessage = result['message'] ??
                                            'Failed to join school';
                                      });
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text('Join',
                                  style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showSubscribeDialog() {
    final TextEditingController codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Activation Code'),
        content: TextField(
          controller: codeController,
          decoration: const InputDecoration(hintText: 'XXXX-XXXX-XXXX-XXXX'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = codeController.text.trim().toUpperCase();
              if (code.isEmpty) return;

              final res = await SubscriptionService().redeemCode(
                _workspaceController.currentSchoolId.value,
                code,
                redeemerUid: _currentUser!.uid,
              );

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(res['message'] ?? 'Status updated')),
                );
                _workspaceController.refreshAppData();
              }
            },
            child: const Text('Activate'),
          ),
        ],
      ),
    );
  }

  void _showAdminLoginDialog() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No user logged in'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('admin_access')
          .doc('config')
          .get();

      if (!doc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Admin access not configured'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final data = doc.data()!;
      final adminEmail = data['email'] as String?;

      if (user.email == adminEmail) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AdminSubscriptionPage(),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Access Denied: Admin privileges required'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
