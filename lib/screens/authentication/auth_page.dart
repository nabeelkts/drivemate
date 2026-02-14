// ignore_for_file: library_private_types_in_public_api

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mds/screens/authentication/email_verification.dart';
import 'package:mds/screens/authentication/login_or_register.dart';
import 'package:mds/screens/navigation_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mds/screens/profile/edit_company_profile.dart';
import 'package:mds/screens/authentication/role_selection_page.dart';
import 'package:get/get.dart';
import 'package:mds/controller/workspace_controller.dart';

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
      body: PopScope(
        canPop: false,
        child: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasData) {
              final user = snapshot.data!;
              if (user.emailVerified) {
                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .snapshots(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                      return const RoleSelectionPage();
                    }

                    final userData =
                        userSnapshot.data!.data() as Map<String, dynamic>;
                    final String? role = userData['role'];
                    final bool hasRoleSelected =
                        userData['hasRoleSelected'] ?? false;

                    if (role == null || !hasRoleSelected) {
                      return const RoleSelectionPage();
                    }

                    if (role == 'Owner') {
                      final bool hasCompanyProfile =
                          userData['hasCompanyProfile'] ?? false;
                      if (!hasCompanyProfile) {
                        return const EditCompanyProfile(isRegistration: true);
                      }
                    } else if (role == 'Staff') {
                      final String? schoolId = userData['schoolId'];
                      if (schoolId == null ||
                          schoolId.isEmpty ||
                          schoolId == user.uid) {
                        return const RoleSelectionPage();
                      }
                    }

                    // All checks passed, navigate to the home screen immediately
                    return const BottomNavScreen();
                  },
                );
              } else {
                if (isFirstTime) {
                  isFirstTime = false;
                  return const EmailVerification();
                } else {
                  return const LoginOrRegisterScreen();
                }
              }
            } else {
              return const LoginOrRegisterScreen();
            }
          },
        ),
      ),
    );
  }
}
