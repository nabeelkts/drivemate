import 'package:flutter/material.dart';




class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
          width: 430,
          height: 932,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            children: [
             
              const SizedBox(height: 40),
              Text(
                'Drivemate',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 36,
                  foreground: Paint()
                    ..shader = const LinearGradient(
                      colors: <Color>[
                        Color(0xFFF46B45),
                        Color(0xFFEEA849),
                      ],
                    ).createShader(Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
            Expanded(
                child: PageView(
                  children: [
                   Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child:Image.asset(
                      'assets/images/onboard1.png',
                      width: 350,
                      height: 306,
                    ),),
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child:  Image.asset(
                      'assets/images/onboard2.png',
                      width: 350,
                      height: 306,
                    ),),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child:Image.asset(
                      'assets/images/onboard3.png',
                      width: 350,
                      height: 306,
                    ),),
                  ],
                ),
              ),
              const SizedBox(height: 40),
          Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Effortless student management. Simplify enrollment, track progress, and nurture relationships with Drivemate’s comprehensive database',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: Colors.black,
                    height: 1.21,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Financial clarity at your fingertips. Manage fees, generate reports, and stay ahead of outstanding payments with Drivemate’s intuitive accounting tools',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: Colors.black,
                    height: 1.21,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 40),
              Container(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 146),
                decoration: BoxDecoration(
                  color: Color(0xFFFFFBF7),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Text(
                  'Get Started',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Color(0xFFF46B45),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

