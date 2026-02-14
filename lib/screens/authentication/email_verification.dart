/* lib/screens/authentication/email_verification.dart */
// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/screens/authentication/login_page.dart';
import 'package:mds/screens/authentication/widgets/my_button.dart';
import 'package:mds/screens/navigation_screen.dart';
import 'package:mds/screens/profile/edit_company_profile.dart';

class EmailVerification extends StatefulWidget {
  const EmailVerification({super.key});

  @override
  State<EmailVerification> createState() => _EmailVerificationState();
}

class _EmailVerificationState extends State<EmailVerification> {
  bool isLoading = false;
  final auth = FirebaseAuth.instance;
  late User user;
  Timer? countdownTimer;
  Timer? verifyTimer;
  int secondsRemaining = 30;

  @override
  void initState() {
    user = auth.currentUser!;
    _sendVerificationEmail();
    _startCountdown();
    verifyTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      checkEmailVerified();
    });
    super.initState();
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    verifyTimer?.cancel();
    super.dispose();
  }

  Future<void> _sendVerificationEmail() async {
    try {
      await user.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification email sent')),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send email. ${e.message}')),
        );
      }
    } catch (_) {}
  }

  void _startCountdown() {
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (secondsRemaining > 0) {
          secondsRemaining--;
        } else {
          countdownTimer?.cancel();
        }
      });
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
                width: 400,
                height: 120,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Email Verification',
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
                        'An email has been sent to ${user.email}, please verify.',
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
              MyButton(
                onTap: () async {
                  if (secondsRemaining == 0 && !isLoading) {
                    setState(() {
                      isLoading = true;
                      secondsRemaining = 30; // Reset the timer
                    });

                    try {
                      await user.sendEmailVerification();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Verification link resent'),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Error resending verification link'),
                        ),
                      );
                    } finally {
                      setState(() {
                        isLoading = false;
                      });
                      _startCountdown();
                    }
                  }
                },
                text: 'Resend Link ($secondsRemaining)',
                isLoading: isLoading,
                isEnabled: true,
              ),
              const SizedBox(height: 37),
              MyButton(
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
            ],
          ),
        ),
      ),
    );
  }

  Future<void> checkEmailVerified() async {
    user = auth.currentUser!;
    await user.reload();
    if (user.emailVerified) {
      countdownTimer?.cancel();
      verifyTimer?.cancel();
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) =>
              const EditCompanyProfile(isRegistration: true)));
    }
  }
}
