// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hive/hive.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/screens/authentication/forgot_password.dart';
import 'package:mds/screens/authentication/google_sign_in.dart';
import 'package:mds/screens/authentication/widgets/email_validator.dart';
import 'package:mds/screens/authentication/widgets/my_button.dart';
import 'package:mds/screens/authentication/widgets/my_form_text_field.dart';
import 'package:mds/screens/authentication/widgets/password_validator.dart';
import 'package:provider/provider.dart';

import '../dashboard/list/students_list.dart';

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
  // final user = FirebaseAuth.instance.currentUser!;
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool isChecked = false;
  bool passwordObscured = true;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  signInWithEmailAndPassword(BuildContext context) async {
    try {
      setState(() {
        isLoading = true;
      });
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      setState(() {
        isLoading = false;
      });
      // Show success message to the user using a SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            "Authenticated as ${user?.email!}",
          ),
          duration:
              Duration(seconds: 2), // You can adjust the duration as needed
        ),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        isLoading = false;
      });
      if (e.code == 'user-not-found') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No user found for this email."),
          ),
        );
      } else if (e.code == 'wrong-password') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Wrong password provided for this user."),
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
      // Handle other generic exceptions if needed
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("An unexpected error occurred."),
        ),
      );
    }
  }

  late Box box1;
  @override
  void initState() {
    super.initState();
    createOpenBox();
  }

  void createOpenBox() async {
    box1 = await Hive.openBox('logindata');
    getdata();
  }

  void getdata() async {
    final storedEmail = box1.get('email');
    final storedPass = box1.get('pass');

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
                          'Log in',
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
                          'Log in to your workspace!!',
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
                  key: formKey,
                  child: Column(children: [
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
                  ]),
                ),
                const SizedBox(height: 8), // Adjust spacing
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
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(
                          color: Color(0xFF3B3B3B),
                          fontSize: 13,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                          decoration: TextDecoration.underline,
                          height: 0,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                MyButton(
                    onTap: () {
                      if (formKey.currentState!.validate()) {
                        signInWithEmailAndPassword(context);
                        login();
                      }
                    },
                    text: 'Login',
                    isLoading: isLoading,
                    isEnabled: true),

                const SizedBox(height: 40),
                Center(
                  child: GestureDetector(
                    onTap: () {
                      final provider = Provider.of<GoogleSignInProvider>(
                          context,
                          listen: false);
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
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
                            'Sign in with Google',
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
                          'Don\'t have an account yet!',
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
                          onTap: widget.navigateToSignUpPage,
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
                                  'Sign up here',
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
              ]),
        )));
  }

  void login() {
    if (isChecked && emailController != null && passwordController != null) {
      box1.put('email', emailController.text);
      box1.put('pass', passwordController.text);
    }
  }
}
