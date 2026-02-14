/* lib/screens/authentication/login_page.dart */
// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/screens/authentication/forgot_password.dart';
import 'package:mds/screens/authentication/google_sign_in.dart';
import 'package:mds/screens/authentication/widgets/email_validator.dart';
import 'package:mds/screens/authentication/widgets/my_button.dart';
import 'package:mds/screens/authentication/widgets/my_form_text_field.dart';
import 'package:mds/screens/authentication/widgets/password_validator.dart';
import 'package:provider/provider.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mds/services/auth_service.dart';
import 'package:mds/screens/profile/edit_company_profile.dart';
import 'package:mds/screens/authentication/role_selection_page.dart';

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
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _authService = AuthService();
  final _box = GetStorage();
  Box? box1;

  @override
  void initState() {
    super.initState();
    createOpenBox();
    getdata();
    _checkBiometricAvailability();
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

  Future<void> _authenticateWithBiometrics() async {
    try {
      final authenticated = await _authService.authenticateWithBiometrics();
      if (authenticated) {
        final storedEmail = _box.read('lastLoginEmail');
        final storedPassword = _box.read('lastLoginPassword');

        if (storedEmail != null && storedPassword != null) {
          emailController.text = storedEmail;
          passwordController.text = storedPassword;
          await signInWithEmailAndPassword(context);
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
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                child: MyButton(
                  onTap: () {
                    if (formKey.currentState!.validate()) {
                      signInWithEmailAndPassword(context);
                      login();
                    }
                  },
                  text: 'Login',
                  isLoading: isLoading,
                  isEnabled: true,
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

  void login() {
    if (isChecked && box1 != null) {
      box1?.put('email', emailController.text);
      box1?.put('pass', passwordController.text);
    }
  }

  signInWithEmailAndPassword(BuildContext context) async {
    try {
      setState(() {
        isLoading = true;
      });
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      // Store credentials for biometric login if enabled
      if (await _authService.isBiometricEnabled()) {
        _box.write('lastLoginEmail', emailController.text);
        _box.write('lastLoginPassword', passwordController.text);
      }

      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text(
              "Authenticated as ${FirebaseAuth.instance.currentUser?.email!}",
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Sync user data to Firestore
      final user = FirebaseAuth.instance.currentUser;
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
      String message;
      if (e.code == 'user-not-found') {
        message = "No user found for this email.";
      } else if (e.code == 'wrong-password') {
        message = "Wrong password provided for this user.";
      } else {
        message = "Authentication failed. ${e.message}";
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("An unexpected error occurred.")),
        );
      }
    }
  }
}
