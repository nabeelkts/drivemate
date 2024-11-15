import 'package:flutter/material.dart';
import 'package:mds/screens/authentication/login_page.dart';
import 'package:mds/screens/authentication/signup.dart';

class LoginOrRegisterScreen extends StatefulWidget {
  const LoginOrRegisterScreen({super.key});

  @override
  State<LoginOrRegisterScreen> createState() => _LoginOrRegisterScreenState();
}

class _LoginOrRegisterScreenState extends State<LoginOrRegisterScreen> {
  // Initially show login page
  bool showLogInPage = true;

  // Toggle between login page and register page
  void togglePages() {
    setState(() {
      showLogInPage = !showLogInPage;
    });
  }

  // Navigate to the login page
  void navigateToLoginPage() {
    setState(() {
      showLogInPage = true;
    });
  }

  // Navigate to the SignUp page
  void navigateToSignUpPage() {
    setState(() {
      showLogInPage = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLogInPage) {
      return LoginPage(
        onTap: togglePages,
        navigateToSignUpPage: navigateToSignUpPage,
      );
    } else {
      return SignUpPage(
        onTap: togglePages,
        navigateToLoginPage: navigateToLoginPage,
      );
    }
  }
}
