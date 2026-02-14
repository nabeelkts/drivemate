import 'package:flutter/material.dart';

class CustomText extends StatelessWidget {
  final String text;
  final Color textColor;
  final double fontSize;
  final FontWeight fontWeight;
  final double height;
  final TextAlign textAlign;

  const CustomText({
    super.key,
    required this.text,
    required this.textColor,
    this.fontSize = 21.40,
    this.fontWeight = FontWeight.w600,
    this.height = 0,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: textColor,
        fontSize: fontSize,
        fontFamily: 'Inter',
        fontWeight: fontWeight,
        height: height,
      ),
      textAlign: textAlign,
    );
  }
}