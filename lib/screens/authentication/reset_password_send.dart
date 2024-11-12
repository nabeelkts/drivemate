import 'package:flutter/material.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/screens/authentication/login_page.dart';
import 'package:mds/screens/authentication/widgets/my_button.dart';

class ResetPasswordSuccess extends StatefulWidget {
  const ResetPasswordSuccess({super.key});

  @override
  State<ResetPasswordSuccess> createState() => _ResetPasswordSuccessState();
}

class _ResetPasswordSuccessState extends State<ResetPasswordSuccess> {
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;
  final emailController = TextEditingController();
  bool passwordObscured = true;
  void togglePasswordVisibility() {
    setState(() {
      passwordObscured = !passwordObscured;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,
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
            const SizedBox(
              width: 400,
              height: 90,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reset Password',
                      style: TextStyle(
                        color: kBlack,
                        fontSize: 36,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        height: 0,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Check your mail, click on the link to  reset your password',
                      style: TextStyle(
                        color: kBlack,
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
      )),
    );
  }
}
