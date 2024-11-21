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
    return Container(
      width: 85.0,
      height: 95.0,
      // padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5.50),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 84,
            height: 74,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: const ShapeDecoration(
                      color: Color(0xFFFFFBF7),
                      shape: OvalBorder(),
                    ),
                  ),
                ),
                Positioned(
                  left: 11.05,
                  top: 1.25,
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: Stack(
                      children: [
                        SvgPicture.asset(
                          imagePath,
                          width: 83,
                          height: 83,
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
              color: Colors.black,
              fontSize: 12,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
