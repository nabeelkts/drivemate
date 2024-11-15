// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/screens/authentication/google_sign_in.dart';
import 'package:mds/screens/authentication/widgets/Custom_check_box.dart';
import 'package:mds/screens/authentication/widgets/email_validator.dart';
import 'package:mds/screens/authentication/widgets/my_button.dart';
import 'package:mds/screens/authentication/widgets/my_form_text_field.dart';
import 'package:mds/screens/authentication/widgets/password_validator.dart';
import 'package:provider/provider.dart';

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
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  Future addUserDetails(Map<String, String> userDetails, String uid) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set(userDetails);
  }

  @override
  void dispose() {
    List<TextEditingController> controllers = [
      emailController,
      passwordController,
    ];
    for (var controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future signUp() async {
    setState(() {
      isLoading = true;
    });

    if (passwordConfirmed()) {
      try {
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        User? user = userCredential.user;
        if (user != null) {
          // String fullName = nameController.text.trim();
          //   await user.updateDisplayName(fullName);

          // Use the user UID as the document ID
          await addUserDetails({
            //'name': nameController.text.trim(),
            'email': emailController.text.trim(),
            'password': passwordController.text.trim(),
          }, user.uid); // Pass the user UID to the function

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.green,
              content: Text('Your registration is successful'),
              duration: Duration(
                seconds: 2,
              ),
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
        } else {
          // Handle other Firebase Authentication exceptions if needed
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

    setState(() {
      isLoading = false;
    });
  }

  bool passwordConfirmed() {
    if (passwordController.text.trim() ==
        confirmPasswordController.text.trim()) {
      return true;
    } else {
      return false;
    }
  }

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
              width: 250,
              height: 71,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sign Up',
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
                      'Sign up to your workspace!!',
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
            Form(
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
                    controller: passwordController, // Fix controller here
                    hintText: 'Enter here',
                    obscureText: true, // Assuming it's a password field
                    labelText: 'Password',
                    validator: PasswordValidator.validate,
                    onTapEyeIcon: togglePasswordVisibility,
                  ),
                  const SizedBox(height: 32),
                  MyFormTextField(
                    controller:
                        confirmPasswordController, // Fix controller here
                    hintText: 'Enter here',
                    obscureText: true, // Assuming it's a password field
                    labelText: 'Confirm Password',
                    validator: ConfirmPasswordValidator.validate,
                    onTapEyeIcon: togglePasswordVisibility,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
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
                    color: Color(0xFF3B3B3B),
                    fontSize: 13,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            MyButton(
              onTap: () {
                if (formKey.currentState?.validate() ?? true && agreedToTerms) {
                  signUp();
                }
              },
              text: 'Sign up',
              isLoading: isLoading,
              isEnabled: agreedToTerms,
            ),
            const SizedBox(height: 40),
            Center(
              child: GestureDetector(
                onTap: () {
                  final provider =
                      Provider.of<GoogleSignInProvider>(context, listen: false);
                  provider.googleLogin(context);
                },
                child: Container(
                  padding: const EdgeInsets.only(left: 8, right: 16),
                  decoration: ShapeDecoration(
                    color: const Color(0xFFFFFBF7),
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
                        padding: const EdgeInsets.all(10),
                        decoration: ShapeDecoration(
                          color: const Color.fromRGBO(250, 249, 247, 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(38),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              padding: const EdgeInsets.only(right: 0.60),
                              clipBehavior: Clip.antiAlias,
                              decoration: const BoxDecoration(),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 29.40,
                                    height: 30,
                                    child: Stack(children: [
                                      SvgPicture.asset(
                                          'assets/icons/google.svg'),
                                    ]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 7),
                      const Text(
                        'Sign up with Google',
                        style: TextStyle(
                          color: Color(0xFF3B3B3B),
                          fontSize: 14,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                          height: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 40,
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Colors.white),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account!',
                      style: TextStyle(
                        color: kBlack,
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
                          color: const Color(0xFFFFFBF7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(34),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sign in here',
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
                  ],
                ),
              ),
            ),
          ]))),
    );
  }
}
