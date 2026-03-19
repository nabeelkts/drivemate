/* lib/screens/authentication/login_page.dart */
// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:drivemate/constants/colors.dart';
import 'package:drivemate/screens/authentication/forgot_password.dart';
import 'package:drivemate/screens/authentication/google_sign_in.dart';
import 'package:drivemate/screens/authentication/widgets/email_validator.dart';
import 'package:drivemate/screens/authentication/widgets/my_button.dart';
import 'package:drivemate/screens/authentication/widgets/my_form_text_field.dart';
import 'package:drivemate/screens/authentication/widgets/password_validator.dart';
import 'package:provider/provider.dart';
import 'package:get_storage/get_storage.dart';
import 'package:drivemate/services/auth_service.dart';
import 'package:drivemate/services/security_service.dart';
import 'package:drivemate/screens/profile/edit_company_profile.dart';
import 'package:drivemate/screens/authentication/role_selection_page.dart';

class LoginPage extends StatefulWidget {
  final Function()? onTap;
  final VoidCallback? navigateToSignUpPage;
  const LoginPage({
    super.key,
    this.onTap,
    this.navigateToSignUpPage,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool isChecked = false;
  bool passwordObscured = true;
  bool isRateLimited = false;
  int remainingLockoutSeconds = 0;
  int remainingAttempts = 5; // New: show remaining attempts
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _authService = AuthService();
  late SecurityService _securityService;
  final _box = GetStorage();
  Box? box1;

  @override
  void initState() {
    super.initState();
    // Use injected SecurityService
    _securityService = Get.find<SecurityService>();
    _checkRateLimitStatus();
    createOpenBox();
    getdata();
    _checkBiometricAvailability();
  }

  void _checkRateLimitStatus() {
    isRateLimited = _securityService.isRateLimited();
    remainingAttempts = _securityService.getRemainingLoginAttempts();
    if (isRateLimited) {
      remainingLockoutSeconds = _securityService.getRemainingLockoutSeconds();
      _startLockoutCountdown();
    }
  }

  void _startLockoutCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        if (remainingLockoutSeconds > 0) {
          remainingLockoutSeconds--;
        } else {
          isRateLimited = false;
          _checkRateLimitStatus();
        }
      });
      return isRateLimited && mounted;
    });
  }

  void createOpenBox() async {
    box1 = await Hive.openBox('logindata');
    getdata();
  }

  void getdata() async {
    if (box1 == null) return;

    final storedEmail = box1?.get('email');
    final storedPass = box1?.get('pass');

    if (storedEmail != null) {
      emailController.text = storedEmail;
      isChecked = true;
      setState(() {});
    }
    if (storedPass != null) {
      passwordController.text = storedPass;
      isChecked = true;
      setState(() {});
    }
  }

  Future<void> _checkBiometricAvailability() async {
    if (await _authService.isBiometricEnabled()) {
      _authenticateWithBiometrics();
    }
  }

  /// Biometric authentication - for enhanced security, users must have previously
  /// logged in with email/password and enabled biometric login.
  /// This uses the device's biometric verification to unlock the stored session.
  Future<void> _authenticateWithBiometrics() async {
    try {
      // First verify biometric is available and enabled
      if (!await _authService.isBiometricEnabled()) {
        return;
      }

      // Authenticate with device biometrics/PIN
      final authenticated = await _authService.authenticateWithBiometrics();
      if (authenticated) {
        // Get stored email for session restoration
        // Note: We do NOT store or retrieve passwords - biometric unlocks the session
        // The session is managed by Firebase Auth's currentUser
        final storedEmail = _box.read('lastLoginEmail');

        if (storedEmail != null) {
          emailController.text = storedEmail;
          // For biometric login, we check if Firebase session is still valid
          // If valid, we don't need the password
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null && currentUser.email == storedEmail) {
            // Session is valid, proceed to home
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/home');
            }
          } else {
            // Session expired, require password login
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Session expired. Please log in with your password.'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      print('Error during biometric authentication: $e');
    }
  }

  void togglePasswordVisibility() {
    setState(() {
      passwordObscured = !passwordObscured;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? kBlack;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        toolbarHeight: 0,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: theme.brightness == Brightness.dark
              ? Brightness.light
              : Brightness.dark,
          statusBarBrightness: theme.brightness == Brightness.dark
              ? Brightness.dark
              : Brightness.light,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 50),
              Center(
                child: SizedBox(
                  height: 50,
                  width: 180,
                  child: Image.asset('assets/icons/Drivemate.png'),
                ),
              ),
              const SizedBox(height: 98),
              SizedBox(
                width: 250,
                height: 71,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Log in',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 36,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          height: 0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Log in to your workspace!!',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w300,
                          height: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 37),
              Form(
                key: formKey,
                child: Column(
                  children: [
                    MyFormTextField(
                      controller: emailController,
                      hintText: 'Enter here',
                      obscureText: false,
                      labelText: 'Email Address',
                      validator: EmailValidator.validate,
                      onTapEyeIcon: togglePasswordVisibility,
                    ),
                    const SizedBox(height: 32),
                    MyFormTextField(
                      controller: passwordController,
                      hintText: 'Enter here',
                      obscureText: true,
                      labelText: 'Password',
                      validator: PasswordValidator.validate,
                      onTapEyeIcon: togglePasswordVisibility,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Forgot password?',
                      style: TextStyle(
                        color: textColor.withOpacity(0.7),
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        //decoration: TextDecoration.underline,
                        height: 0,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Show rate limit warning if applicable
              if (isRateLimited)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lock_clock, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Too many failed attempts. Try again in ${remainingLockoutSeconds ~/ 60}:${(remainingLockoutSeconds % 60).toString().padLeft(2, '0')}',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (!isRateLimited && remainingAttempts < 5)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Warning: $remainingAttempts login attempts remaining before lockout',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                child: MyButton(
                  onTap: () {
                    if (isRateLimited) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Please wait ${remainingLockoutSeconds ~/ 60}:${(remainingLockoutSeconds % 60).toString().padLeft(2, '0')} before trying again'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    if (formKey.currentState!.validate()) {
                      signInWithEmailAndPassword(context);
                      _saveEmailForBiometric();
                    }
                  },
                  text: 'Login',
                  isLoading: isLoading,
                  isEnabled: !isRateLimited,
                  width: double.infinity,
                ),
              ),
              const SizedBox(height: 40),
              Center(
                child: Consumer<GoogleSignInProvider>(
                  builder: (_, provider, __) {
                    final isSigningIn = provider.isSigningIn;
                    return GestureDetector(
                      onTap: isSigningIn
                          ? null
                          : () async {
                              final userCredential =
                                  await provider.signInWithGoogle(context);
                              if (userCredential != null && context.mounted) {
                                if (userCredential
                                        .additionalUserInfo?.isNewUser ??
                                    false) {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const RoleSelectionPage()),
                                  );
                                } else {
                                  Navigator.pushReplacementNamed(
                                      context, '/home');
                                }
                              }
                            },
                      child: Container(
                        padding: const EdgeInsets.only(left: 8, right: 16),
                        decoration: ShapeDecoration(
                          color: theme.cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(72),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: ShapeDecoration(
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: isSigningIn
                                  ? const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : Image.network(
                                      'https://www.google.com/images/branding/googleg/1x/googleg_standard_color_128dp.png',
                                      width: 24,
                                      height: 24,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.g_mobiledata,
                                          size: 24,
                                          color: Colors.red,
                                        );
                                      },
                                    ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isSigningIn
                                  ? 'Signing in...'
                                  : 'Continue with Google',
                              style: TextStyle(
                                color: theme.textTheme.bodyLarge?.color,
                                fontSize: 16,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 40),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Don\'t have an account yet!',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 24,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        height: 0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: widget.navigateToSignUpPage,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: ShapeDecoration(
                          color: theme.cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(34),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sign up here',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 16,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w300,
                                height: 0,
                              ),
                            ),
                          ],
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
    );
  }

  /// Save email for biometric login - NEVER save passwords in plain text
  /// Only the email is stored to help users, biometric verifies device ownership
  void _saveEmailForBiometric() {
    if (isChecked && box1 != null) {
      // Only save email, never save password
      box1?.put('email', emailController.text);
      // Delete password storage for security - we no longer store passwords
      box1?.delete('pass');

      // Also save to GetStorage for biometric authentication
      _box.write('lastLoginEmail', emailController.text);
      // Remove password storage from GetStorage too
      _box.remove('lastLoginPassword');
    }
  }

  /// Legacy login method - kept for compatibility but no longer stores passwords
  @Deprecated('Use _saveEmailForBiometric instead')
  void login() {
    _saveEmailForBiometric();
  }

  signInWithEmailAndPassword(BuildContext context) async {
    // Check rate limiting before attempting login
    if (_securityService.isRateLimited()) {
      final remainingSeconds = _securityService.getRemainingLockoutSeconds();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Too many failed attempts. Please wait ${remainingSeconds ~/ 60}:${(remainingSeconds % 60).toString().padLeft(2, '0')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      // Attempt login
      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      // SECURITY: Record successful login to reset rate limiting and start session
      _securityService.onSuccessfulLogin();

      // Store ONLY email for biometric login if enabled - NEVER store password
      if (await _authService.isBiometricEnabled()) {
        _box.write('lastLoginEmail', emailController.text);
        // SECURITY: Do NOT store password - biometric uses device verification only
        _box.remove(
            'lastLoginPassword'); // Ensure any old passwords are removed
      }

      // Check email verification before allowing access
      final user = userCredential.user;
      if (user != null && !user.emailVerified) {
        // User exists but email not verified
        await FirebaseAuth.instance.signOut();
        setState(() {
          isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Please verify your email before logging in. Check your inbox for the verification link.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text(
              "Authenticated as ${user?.email}",
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Sync user data to Firestore
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        final userData = <String, dynamic>{};
        final currentData = userDoc.data();

        if (currentData == null || currentData['email'] == null) {
          userData['email'] = user.email;
        }
        if (currentData == null ||
            (currentData['name'] == null ||
                currentData['name'].toString().isEmpty)) {
          userData['name'] = user.displayName ?? '';
        }

        if (userData.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set(userData, SetOptions(merge: true));
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        isLoading = false;
      });

      // SECURITY: Record failed login attempt for rate limiting
      _securityService.recordFailedLoginAttempt();

      // Check if account is now locked after this attempt
      if (_securityService.isRateLimited()) {
        final remainingSeconds = _securityService.getRemainingLockoutSeconds();
        if (mounted) {
          setState(() {
            isRateLimited = true;
            remainingLockoutSeconds = remainingSeconds;
          });
          _startLockoutCountdown();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Too many failed attempts. Account locked for ${remainingSeconds ~/ 60} minutes.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      String message;
      if (e.code == 'user-not-found') {
        message = "No user found for this email.";
      } else if (e.code == 'wrong-password') {
        message = "Wrong password provided for this user.";
      } else if (e.code == 'too-many-requests') {
        message =
            "Too many login attempts. Please try again later or reset your password.";
      } else {
        message = "Authentication failed. ${e.message}";
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("An unexpected error occurred.")),
        );
      }
    }
  }
}
