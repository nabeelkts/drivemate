// ignore_for_file: library_private_types_in_public_api

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mds/screens/authentication/email_verification.dart';
import 'package:mds/screens/authentication/login_or_register.dart';
import 'package:mds/screens/navigation_screen.dart';

class AuthPage extends StatefulWidget {
  // ignore: use_key_in_widget_constructors
  const AuthPage({Key? key});

  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isFirstTime = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show a loading indicator while checking the authentication state
            return const CircularProgressIndicator();
          } else {
            if (snapshot.hasData) {
              // User is logged in
              final user = snapshot.data!;
              if (user.emailVerified) {
                // Email is verified, navigate to the home page
                return const BottomNavScreen();
              } else {
                // Email is not verified, show the email verification screen only once
                if (isFirstTime) {
                  isFirstTime = false;
                  return const EmailVerification();
                } else {
                  // Email verification already shown, show the login screen
                  return const LoginOrRegisterScreen();
                }
              }
            } else {
              // User is not logged in, navigate to the login page
              return const LoginOrRegisterScreen();
            }
          }
        },
      ),
    );
  }
}
