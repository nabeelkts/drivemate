import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ShortcutIcon extends StatelessWidget {
  // ignore: use_key_in_widget_constructors
  const ShortcutIcon({Key? key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        buildIconContainer('assets/icons/student_icon.svg', 'Students'),
        buildIconContainer('assets/icons/student_icon.svg', 'Students'),
        buildIconContainer('assets/icons/student_icon.svg', 'Students'),
        buildIconContainer('assets/icons/student_icon.svg', 'Students'),
      ],
    );
  }

  Widget buildIconContainer(String imagePath, String text) {
    return Column(
      children: [
        SizedBox(
          width: 80,
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
            fontSize: 12,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
