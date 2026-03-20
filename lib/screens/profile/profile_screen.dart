import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:drivemate/screens/profile/dialog_box.dart';
import 'package:drivemate/utils/loading_utils.dart';
import 'package:get_storage/get_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:drivemate/constants/colors.dart';
import 'package:drivemate/controller/app_controller.dart';
import 'package:drivemate/controller/theme_controller.dart';
import 'package:intl/intl.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:drivemate/screens/profile/widgets/profile_header.dart';
import 'package:drivemate/screens/profile/widgets/subscription_card.dart';
import 'package:drivemate/screens/profile/admin/organization_management_page.dart';
import 'package:drivemate/controller/workspace_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:drivemate/services/subscription_service.dart';
import 'package:drivemate/screens/profile/admin/admin_subscription_page.dart';
import 'package:drivemate/screens/profile/settings_page.dart';
import 'package:drivemate/screens/profile/about_page.dart'; // ← new
import 'package:drivemate/screens/profile/all_services_page.dart'; // ← new
import 'package:drivemate/screens/recycle_bin/recycle_bin_screen.dart'; // Recycle Bin
import 'package:drivemate/screens/chat/contact_support_screen.dart'; // Chat Support

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onSubscriptionRenewed;

  const ProfileScreen({super.key, this.onSubscriptionRenewed});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final box = GetStorage();
  final auth = LocalAuthentication();
  final appController = Get.put(AppController());
  late final ThemeController themeController;
  bool isDarkMode = false;
  // Settings are now reactive via AppController
  bool canCheckBiometrics = false;
  User? _currentUser;
  String _lastLoginTime = '';
  Color get _selectedThemeColor => themeController.themeColor;
  bool _isInitialized = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final WorkspaceController _workspaceController =
      Get.find<WorkspaceController>();
  Worker? _workspaceWorker;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _initializeState();
  }

  Future<void> _initializeState() async {
    if (!mounted) return;

    themeController = Get.find<ThemeController>();
    _currentUser = FirebaseAuth.instance.currentUser;
    isDarkMode = box.read('isDarkMode') ??
        (themeController.themeMode.value == ThemeMode.dark);

    // Settings are now handled by AppController reactive variables
    canCheckBiometrics = await auth.canCheckBiometrics;
    _lastLoginTime = box.read('lastLoginTime') ??
        DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now());

    _workspaceWorker = ever(_workspaceController.isLoading, (isLoading) {
      if (!isLoading) _workspaceController.refreshAppData();
    });

    if (!_workspaceController.isLoading.value) {
      _workspaceController.refreshAppData();
    }
    _updateLastLoginTime();

    WidgetsBinding.instance.addPostFrameCallback((_) => _applyTheme());

    if (mounted) {
      setState(() => _isInitialized = true);
      _animController.forward();
    }
  }

  @override
  void dispose() {
    _workspaceWorker?.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _applyTheme() {
    Get.changeThemeMode(isDarkMode ? ThemeMode.dark : ThemeMode.light);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: isDarkMode ? Colors.black : Colors.white,
      systemNavigationBarIconBrightness:
          isDarkMode ? Brightness.light : Brightness.dark,
    ));
  }

  void _updateLastLoginTime() {
    final now = DateTime.now();
    final formattedTime = DateFormat('dd/MM/yyyy hh:mm a').format(now);
    box.write('lastLoginTime', formattedTime);
    if (mounted) setState(() => _lastLoginTime = formattedTime);
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
    appController.notificationsEnabled.value =
        !appController.notificationsEnabled.value;
    box.write('notificationsEnabled', appController.notificationsEnabled.value);
    setState(() {}); // Keep local if used elsewhere, but reactive handles UI
  }

  Future<void> toggleBiometric() async {
    if (!mounted) return;

    if (!canCheckBiometrics) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:
            Text('Biometric authentication is not available on this device'),
        duration: Duration(seconds: 3),
      ));
      return;
    }

    if (!appController.biometricEnabled.value) {
      try {
        final available = await auth.getAvailableBiometrics();
        if (available.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'No biometrics enrolled. Please set up fingerprint or face recognition in device settings.'),
              duration: Duration(seconds: 4),
            ));
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
          appController.biometricEnabled.value = true;
          box.write('biometricEnabled', true);
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Biometric login enabled'),
            duration: Duration(seconds: 2),
          ));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to enable biometric login: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ));
        }
      }
    } else if (mounted) {
      appController.biometricEnabled.value = false;
      box.write('biometricEnabled', false);
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Biometric login disabled'),
        duration: Duration(seconds: 2),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized && _currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_currentUser == null) {
      return const Scaffold(body: Center(child: Text('No user logged in')));
    }

    final isDark = isDarkMode;
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.06);
    final textColor = isDark ? Colors.white : Colors.black87;
    final bgColor = isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7);
    final subColor = isDark ? Colors.white38 : Colors.black38;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        toolbarHeight: 0,
        elevation: 0,
        backgroundColor: bgColor,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                // ── Subscription warnings ──────────────────────────────
                Obx(() {
                  final subData = _workspaceController.subscriptionData;
                  if (_workspaceController.isAppDataLoading.value &&
                      subData.isEmpty) {
                    return const Center(child: LinearProgressIndicator());
                  }

                  final isStaff =
                      _workspaceController.userRole.value == 'Staff';
                  if (isStaff) return const SizedBox.shrink();

                  final shouldWarn = subData['shouldWarn'] ?? false;
                  final isInGracePeriod = subData['isInGracePeriod'] ?? false;
                  final isGracePeriodExpired =
                      subData['isGracePeriodExpired'] ?? false;
                  final daysLeft = subData['daysLeft'] ?? 0;

                  return Column(children: [
                    if (shouldWarn)
                      _BannerAlert(
                        icon: Icons.timer_outlined,
                        color: kOrange,
                        title: 'Subscription Expiring Soon',
                        message:
                            'Your subscription expires in $daysLeft days. Please renew to avoid interruption.',
                      ),
                    if (isInGracePeriod)
                      _BannerAlert(
                        icon: Icons.info_outline,
                        color: Colors.blue,
                        title: 'Grace Period Active',
                        message:
                            'Subscription expired — ${7 + daysLeft} days left in grace period.',
                      ),
                    if (isGracePeriodExpired)
                      _BannerAlert(
                        icon: Icons.warning_rounded,
                        color: Colors.red,
                        title: 'Subscription Expired',
                        message:
                            'Please renew your subscription to access all features.',
                      ),
                  ]);
                }),

                // ── Profile header ─────────────────────────────────────
                ProfileHeader(
                  currentUser: _currentUser,
                  cardColor: cardColor,
                  textColor: textColor,
                  lastLoginTime: _lastLoginTime,
                ),

                // ✅ FIX: Proper spacing between header and subscription
                const SizedBox(height: 12),

                // ── Subscription card ──────────────────────────────────
                Obx(() {
                  final isStaff =
                      _workspaceController.userRole.value == 'Staff';
                  final isStudent =
                      _workspaceController.userRole.value == 'Student';
                  if (isStaff || isStudent) return const SizedBox.shrink();
                  return SubscriptionCard(
                    cardColor: cardColor,
                    textColor: textColor,
                    onSubscribeDialog: _showSubscribeDialog,
                  );
                }),

                // ✅ FIX: Generous spacing before ORGANIZATION label
                const SizedBox(height: 12),

                // ── Organization ───────────────────────────────────────
                Obx(() {
                  final isStudent =
                      _workspaceController.userRole.value == 'Student';
                  if (isStudent) return const SizedBox.shrink();
                  return _buildMyOrganizationTile(context, _workspaceController,
                      cardColor, borderColor, textColor, subColor);
                }),

                const SizedBox(height: 12),

                // ── All Services ───────────────────────────────────────
                Obx(() {
                  final isStudent =
                      _workspaceController.userRole.value == 'Student';
                  if (isStudent) return const SizedBox.shrink();
                  return _SectionCard(
                    cardColor: cardColor,
                    borderColor: borderColor,
                    children: [
                      _MenuRow(
                        icon: Icons.apps_outlined,
                        iconColor: kPrimaryColor,
                        label: 'All Services',
                        subtitle: 'Access all app services',
                        textColor: textColor,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AllServicesPage()),
                        ),
                      ),
                    ],
                  );
                }),

                const SizedBox(height: 12),

                // ── Settings & About ───────────────────────────────────
                _buildLabel('PREFERENCES', subColor),
                _SectionCard(
                  cardColor: cardColor,
                  borderColor: borderColor,
                  children: [
                    _MenuRow(
                      icon: Icons.support_agent,
                      iconColor: kPrimaryColor,
                      label: 'Contact Support',
                      subtitle: 'Chat with support team',
                      textColor: textColor,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ContactSupportScreen(),
                        ),
                      ),
                    ),
                    _Divider(color: borderColor),
                    _MenuRow(
                      icon: Icons.settings_outlined,
                      iconColor: Colors.grey,
                      label: 'Settings',
                      subtitle: 'Theme, Notifications, Account',
                      textColor: textColor,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => Obx(() => SettingsPage(
                                  toggleTheme: toggleTheme,
                                  isDarkMode: isDarkMode,
                                  notificationsEnabled:
                                      appController.notificationsEnabled.value,
                                  toggleNotifications: toggleNotifications,
                                  biometricEnabled:
                                      appController.biometricEnabled.value,
                                  toggleBiometric: toggleBiometric,
                                )),
                          ),
                        );
                        _workspaceController.refreshAppData();
                      },
                    ),
                    _Divider(color: borderColor),
                    // Hide Recycle Bin for students - they don't manage deleted items
                    Obx(() {
                      final isStudent =
                          _workspaceController.userRole.value == 'Student';
                      if (isStudent) return const SizedBox.shrink();
                      return _MenuRow(
                        icon: Icons.delete_outline,
                        iconColor: Colors.red,
                        label: 'Recycle Bin',
                        subtitle: 'Deleted items (90 days)',
                        textColor: textColor,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RecycleBinScreen()),
                        ),
                      );
                    }),
                    _Divider(color: borderColor),
                    GestureDetector(
                      onLongPress: _showAdminLoginDialog,
                      child: _MenuRow(
                        icon: Icons.info_outline_rounded,
                        iconColor: Colors.teal,
                        label: 'About',
                        subtitle: 'Privacy, Terms & App Version',
                        textColor: textColor,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AboutPage()),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // // ── Footer ─────────────────────────────────────────────
                // Center(
                //   child: Text(
                //     '© ${DateTime.now().year} MDS Management',
                //     style: TextStyle(
                //       color: subColor,
                //       fontSize: 11,
                //     ),
                //   ),
                // ),
                // const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
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
    Color subColor,
  ) {
    return Obx(() {
      final isStaff = controller.userRole.value == 'Staff';
      final isConnected = controller.isConnected.value;
      // Explicitly access reactive observables to ensure Obx tracks them
      final branchId = controller.currentBranchId.value;
      final ownedBranches = controller.ownedBranches;
      final companyData = controller.companyData;
      final staffBranchData = controller.staffBranchData;
      
      // Compute branch data based on role
      String branchName = '';
      String? location;
      String? phone;
      
      if (isStaff && isConnected) {
        // Staff connected to branch
        if (branchId.isNotEmpty) {
          final branch = ownedBranches.firstWhere(
            (b) => b['id'] == branchId,
            orElse: () => staffBranchData.isNotEmpty ? staffBranchData : {},
          );
          branchName = branch['branchName'] ?? 
                       staffBranchData['branchName'] ?? 
                       companyData['companyName'] ?? 
                       'Connected School';
          location = branch['location'] ?? 
                     staffBranchData['location'] ?? 
                     companyData['companyAddress'];
          phone = branch['contactPhone'] ?? 
                  staffBranchData['contactPhone'] ?? 
                  companyData['companyPhone'];
        } else {
          branchName = companyData['companyName'] ?? 'Connected School';
          location = companyData['companyAddress'];
          phone = companyData['companyPhone'];
        }
      }

      String sectionTitle = 'ORGANIZATION';
      String name = controller.userProfileData['schoolName'] ?? 'My Organization';
      String subtitle = branchName.isNotEmpty ? branchName : 'Manage Organization';
      IconData icon = Icons.business_center_outlined;
      Color iconColor = kOrange;
      VoidCallback onTap = () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const OrganizationManagementPage()),
          );

      if (isStaff) {
        sectionTitle = 'WORKPLACE';
        if (!isConnected) {
          name = 'Join School Workspace';
          subtitle = 'Connect with your school owner';
          icon = Icons.add_business_outlined;
          onTap = _showJoinSchoolDialog;
        } else {
          name = branchName.isNotEmpty ? branchName : 'Connected School';
          // Build detailed subtitle with available info
          if (location != null && phone != null) {
            subtitle = '$location\n📞 $phone';
          } else if (location != null) {
            subtitle = location;
          } else if (phone != null) {
            subtitle = '📞 $phone';
          } else {
            subtitle = 'Working at this branch';
          }
        }
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel(sectionTitle, subColor),
          _SectionCard(
            cardColor: cardColor,
            borderColor: borderColor,
            children: [
              _MenuRow(
                icon: icon,
                iconColor: iconColor,
                label: name,
                subtitle: subtitle,
                textColor: textColor,
                onTap: onTap,
              ),
            ],
          ),
        ],
      );
    });
  }

  // ── Dialogs ────────────────────────────────────────────────────────────────

  Future<void> _showJoinSchoolDialog() async {
    final TextEditingController idController = TextEditingController();
    final bool? confirmed = await showCustomStatefulDialogResult<bool>(
      context,
      'Join School Workspace',
      (ctx, setDialogState, choose) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          const Text(
            'Enter the School ID provided by your administrator.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: idController,
            decoration: InputDecoration(
              hintText: 'Enter School ID',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
      confirmText: 'Join',
      cancelText: 'Cancel',
      onConfirmResult: () => true,
    );
    if (confirmed == true) {
      final id = idController.text.trim();
      if (id.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a School ID')));
        return;
      }
      final result = await LoadingUtils.wrapWithLoading(context, () async {
        return await _workspaceController.joinSchool(id);
      }, message: 'Joining workspace...');
      if (!mounted) return;
      if (result['success'] == true) {
        Get.snackbar(
          'Success',
          result['message'] ?? 'Joined school workspace successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.1),
          duration: const Duration(seconds: 2),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to join school')),
        );
      }
    }
  }

  Future<void> _showSubscribeDialog() async {
    final TextEditingController codeController = TextEditingController();

    final bool? confirmed = await showCustomStatefulDialogResult<bool>(
      context,
      'Enter Activation Code',
      (ctx, setDialogState, choose) => TextField(
        controller: codeController,
        decoration: const InputDecoration(hintText: 'XXXX-XXXX-XXXX-XXXX'),
      ),
      confirmText: 'Activate',
      cancelText: 'Cancel',
      onConfirmResult: () => true,
    );
    if (confirmed == true) {
      final code = codeController.text.trim().toUpperCase();
      if (code.isEmpty) return;
      final res = await LoadingUtils.wrapWithLoading(context, () async {
        return await SubscriptionService().redeemCode(
          _workspaceController.currentSchoolId.value,
          code,
          redeemerUid: _currentUser!.uid,
        );
      }, message: 'Activating...');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Status updated')));
      _workspaceController.refreshAppData();
    }
  }

  void _showAdminLoginDialog() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('No user logged in'), backgroundColor: Colors.red));
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
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Admin access not configured'),
              backgroundColor: Colors.red));
        }
        return;
      }

      final adminEmail = doc.data()!['email'] as String?;

      if (user.email == adminEmail) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminSubscriptionPage()),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Access Denied: Admin privileges required'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red));
      }
    }
  }
}

// ── Shared UI Components ──────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  final Color cardColor;
  final Color borderColor;

  const _SectionCard({
    required this.children,
    required this.cardColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String? subtitle;
  final Color textColor;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _MenuRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.textColor,
    this.subtitle,
    this.onTap,
    // ignore: unused_element_parameter
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: TextStyle(
                            color: textColor.withOpacity(0.5), fontSize: 11.5)),
                  ],
                ],
              ),
            ),
            trailing ??
                Icon(Icons.chevron_right_rounded,
                    color: textColor.withOpacity(0.28), size: 20),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final Color color;
  const _Divider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 64),
      child: Divider(height: 1, thickness: 0.5, color: color),
    );
  }
}

class _BannerAlert extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;

  const _BannerAlert({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 3),
                Text(message,
                    style: TextStyle(
                        color: color.withOpacity(0.85), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
