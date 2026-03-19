/* lib/screens/authentication/forgot_password.dart */
// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:drivemate/constants/colors.dart';
import 'package:drivemate/screens/authentication/login_page.dart';
import 'package:drivemate/screens/authentication/reset_password_send.dart';
import 'package:drivemate/screens/authentication/widgets/email_validator.dart';
import 'package:drivemate/screens/authentication/widgets/my_button.dart';
import 'package:drivemate/screens/authentication/widgets/my_form_text_field.dart';
import 'package:drivemate/services/security_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool isRateLimited = false;
  int remainingLockoutSeconds = 0;
  final emailController = TextEditingController();
  late String email;
  bool passwordObscured = true;
  late SecurityService _securityService;

  @override
  void initState() {
    super.initState();
    _securityService = Get.find<SecurityService>();
    _checkRateLimitStatus();
  }

  void _checkRateLimitStatus() {
    isRateLimited = _securityService.isPasswordResetRateLimited();
    if (isRateLimited) {
      remainingLockoutSeconds =
          _securityService.getPasswordResetRemainingSeconds();
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

  void togglePasswordVisibility() {
    setState(() {
      passwordObscured = !passwordObscured;
    });
  }

  // SECURITY: Reset password with rate limiting
  void resetPass() async {
    // Check rate limiting before attempting
    if (_securityService.isPasswordResetRateLimited()) {
      final remainingSeconds =
          _securityService.getPasswordResetRemainingSeconds();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Too many password reset attempts. Please wait ${remainingSeconds ~/ 60} minutes.'),
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
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      // SECURITY: Record successful password reset email sent
      _securityService.onPasswordResetEmailSent();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email has been sent'),
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ResetPasswordSuccess(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      // SECURITY: Record failed password reset attempt for rate limiting
      _securityService.recordFailedPasswordResetAttempt();

      // Check if account is now locked
      if (_securityService.isPasswordResetRateLimited()) {
        final remainingSeconds =
            _securityService.getPasswordResetRemainingSeconds();
        if (mounted) {
          setState(() {
            isRateLimited = true;
            remainingLockoutSeconds = remainingSeconds;
          });
          _startLockoutCountdown();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Too many attempts. Password reset locked for ${remainingSeconds ~/ 60} minutes.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else if (e.code == 'user-not-found') {
        // SECURITY: Don't reveal if email exists or not for security
        // Show generic message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'If an account exists with this email, a reset link has been sent.'),
          ));
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ResetPasswordSuccess(),
            ),
          );
        }
      } else if (e.code == 'operation-not-allowed') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Email/password sign-in is not enabled. Please contact support.'),
          ));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send email. ${e.message}'),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
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
                width: 350,
                height: 71,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reset Password',
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
                        'Reset password with your email!',
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
              // Show rate limit warning
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
                            'Too many attempts. Try again in ${remainingLockoutSeconds ~/ 60}:${(remainingLockoutSeconds % 60).toString().padLeft(2, '0')}',
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
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                child: MyButton(
                  onTap: isRateLimited
                      ? null
                      : () {
                          if (formKey.currentState!.validate()) {
                            setState(() {
                              email = emailController.text;
                              resetPass();
                            });
                          }
                        },
                  text: 'Reset Password',
                  isLoading: isLoading,
                  isEnabled: !isRateLimited,
                  width: double.infinity,
                ),
              ),
              const SizedBox(height: 32),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                child: MyButton(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginPage(),
                      ),
                    );
                  },
                  text: 'Back to Login',
                  isLoading: isLoading,
                  isEnabled: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
