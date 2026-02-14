/* lib/screens/authentication/signup.dart */
// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/screens/authentication/google_sign_in.dart';
import 'package:mds/screens/authentication/email_verification.dart';
import 'package:mds/screens/authentication/widgets/custom_check_box.dart';
import 'package:mds/screens/authentication/widgets/email_validator.dart';
import 'package:mds/screens/authentication/widgets/my_button.dart';
import 'package:mds/screens/authentication/widgets/my_form_text_field.dart';
import 'package:mds/screens/authentication/widgets/password_validator.dart';
import 'package:provider/provider.dart';
import 'package:mds/screens/profile/edit_company_profile.dart';
import 'package:mds/screens/authentication/role_selection_page.dart';

class SignUpPage extends StatefulWidget {
  final Function()? onTap;
  final VoidCallback? navigateToLoginPage;
  const SignUpPage({
    super.key,
    this.onTap,
    this.navigateToLoginPage,
  });

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool agreedToTerms = false;
  bool passwordObscured = true;
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final schoolIdController = TextEditingController();
  String selectedRole = 'Owner'; // Default to Owner

  Future addUserDetails(Map<String, dynamic> userDetails, String uid) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set(userDetails, SetOptions(merge: true));
  }

  @override
  void dispose() {
    List<TextEditingController> controllers = [
      nameController,
      emailController,
      passwordController,
      confirmPasswordController,
    ];
    for (var controller in controllers) {
      controller.dispose();
    }
    schoolIdController.dispose();
    super.dispose();
  }

  Future signUp() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    if (passwordConfirmed()) {
      try {
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        User? user = userCredential.user;
        if (user != null) {
          final schoolId = selectedRole == 'Owner'
              ? user.uid
              : schoolIdController.text.trim();

          await addUserDetails({
            'name': nameController.text.trim(),
            'email': emailController.text.trim(),
            'role': selectedRole,
            'schoolId': schoolId,
            'hasRoleSelected': true,
            'registrationDate': DateTime.now().toIso8601String(),
          }, user.uid);

          if (mounted) {
            setState(() {
              isLoading = false;
            });
          }
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const EmailVerification(),
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'weak-password') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("The password provided is too weak."),
            ),
          );
        } else if (e.code == 'email-already-in-use') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("The account already exists for this email."),
            ),
          );
        } else if (e.code == 'operation-not-allowed') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  "Email/password sign-in is not enabled. Please contact support."),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Authentication failed. ${e.message}"),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("An unexpected error occurred."),
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  bool passwordConfirmed() {
    return passwordController.text.trim() ==
        confirmPasswordController.text.trim();
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
                        'Sign Up',
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
                        'Sign up to your workspace!!',
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
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => selectedRole = 'Owner'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selectedRole == 'Owner'
                                ? kPrimaryColor
                                : theme.cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: selectedRole == 'Owner'
                                    ? kPrimaryColor
                                    : Colors.grey.withOpacity(0.3)),
                          ),
                          child: Center(
                            child: Text(
                              'Owner',
                              style: TextStyle(
                                color: selectedRole == 'Owner'
                                    ? Colors.white
                                    : textColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => selectedRole = 'Staff'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selectedRole == 'Staff'
                                ? kPrimaryColor
                                : theme.cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: selectedRole == 'Staff'
                                    ? kPrimaryColor
                                    : Colors.grey.withOpacity(0.3)),
                          ),
                          child: Center(
                            child: Text(
                              'Staff',
                              style: TextStyle(
                                color: selectedRole == 'Staff'
                                    ? Colors.white
                                    : textColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (selectedRole == 'Staff')
                Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: MyFormTextField(
                    controller: schoolIdController,
                    hintText: 'Enter School ID provided by Admin',
                    obscureText: false,
                    labelText: 'School ID',
                    validator: (value) {
                      if (selectedRole == 'Staff' &&
                          (value == null || value.trim().isEmpty)) {
                        return 'Required to link your workspace';
                      }
                      return null;
                    },
                    onTapEyeIcon: togglePasswordVisibility,
                  ),
                ),
              const SizedBox(height: 10),
              Form(
                key: formKey,
                child: Column(
                  children: [
                    MyFormTextField(
                      controller: nameController,
                      hintText: 'Enter your name',
                      obscureText: false,
                      labelText: 'Name',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
                      onTapEyeIcon: togglePasswordVisibility,
                    ),
                    const SizedBox(height: 32),
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
                    const SizedBox(height: 32),
                    MyFormTextField(
                      controller: confirmPasswordController,
                      hintText: 'Enter here',
                      obscureText: true,
                      labelText: 'Confirm Password',
                      validator: PasswordValidator.validate,
                      onTapEyeIcon: togglePasswordVisibility,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomCheckbox(
                      value: agreedToTerms,
                      onChanged: (value) {
                        setState(() {
                          agreedToTerms = value;
                        });
                      },
                      fillColor: kPrimaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Agree & Continue',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                child: MyButton(
                  onTap: () {
                    if (formKey.currentState?.validate() ??
                        true && agreedToTerms) {
                      signUp();
                    }
                  },
                  text: 'Sign up',
                  isLoading: isLoading,
                  isEnabled: agreedToTerms,
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
                      'Already have an account!',
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
                      onTap: widget.navigateToLoginPage,
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
                              'Sign in here',
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
}
