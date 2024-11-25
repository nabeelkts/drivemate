// ignore_for_file: use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class RegistrationIcon extends StatelessWidget {
  const RegistrationIcon({Key? key});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (BuildContext context) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            buildIconContainer('assets/icons/student_icon.svg', 'Students',
                '/students', context),
            buildIconContainer('assets/icons/license_icon.svg', 'License',
                '/license', context),
            buildIconContainer('assets/icons/endorse_icon.svg', 'Endorse to DL',
                '/endorse', context),
            buildIconContainer(
                'assets/icons/rc_icon.svg', 'RC', '/rc', context),
          ],
        );
      },
    );
  }

  Widget buildIconContainer(
      String imagePath, String text, String routeName, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, routeName);
      },
      child: SizedBox(
        width: 80,
        height: 95,
        child: Column(
          //mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 84,
              height: 74,
              child: Stack(
                children: [

                  Positioned(
                    left: 11.05,
                    top: 1.25,
                    child: SizedBox(
                      // width: 64,
                      // height: 64,
                      child: Stack(
                        children: [
                          SvgPicture.asset(
                            imagePath,
                            // width: 83,
                            // height: 83,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              text,
              style: const TextStyle(
                //color: Colors.black,
                fontSize: 12,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
