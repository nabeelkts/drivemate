import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/screens/authentication/auth_page.dart';
import 'package:page_transition/page_transition.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      splash: SizedBox(
        height: 200,
        width: 200,
        child: Image.asset(
          'assets/icons/Drivemate.png',
          height: 50,
          width: 180,
        ),
      ),
      nextScreen: const AuthPage(),
      //splashTransition: SplashTransition.fadeTransition,
      backgroundColor: kWhite,
      pageTransitionType:
          PageTransitionType.rightToLeftWithFade, // Use slideUp transition
      duration: 1000,
      //curve: Curves.fastOutSlowIn,
    );
  }
}
