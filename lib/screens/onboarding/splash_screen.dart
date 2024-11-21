import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/screens/authentication/auth_page.dart';
import 'package:mds/screens/onboarding/onboard.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;

    await Future.delayed(const Duration(seconds: 1));

    if (isFirstLaunch) {
      Get.off(() => const OnboardingScreen(), transition: Transition.fadeIn, duration: const Duration(milliseconds: 800));
    } else {
      Get.off(() => const AuthPage(), transition: Transition.fadeIn, duration: const Duration(milliseconds: 800));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,
      body: Center(
        child: SizedBox(
          height: 200,
          width: 200,
          child: Image.asset(
            'assets/icons/Drivemate.png',
            height: 50,
            width: 180,
          ),
        ),
      ),
    );
  }
}
