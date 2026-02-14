import 'package:flutter/material.dart';
import 'package:mds/constants/colors.dart';

class MyButton extends StatelessWidget {
  final Function()? onTap;
  final String text;
  final bool isLoading;
  final bool isEnabled;
  final double width;
  final Color? color;
  final Color? textColor;
  final Color? borderColor;

  const MyButton({
    super.key,
    required this.onTap,
    required this.text,
    required this.isLoading,
    required this.isEnabled,
    this.width = double.infinity,
    this.color,
    this.textColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        width: width,
        height: 44,
        decoration: ShapeDecoration(
          color: color, // Use provided color or default to transparent (null)
          shape: RoundedRectangleBorder(
            side: BorderSide(width: 0.50, color: borderColor ?? kOrange),
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Center(
          child: isLoading
              ? const CircularProgressIndicator(
                  color: kPrimaryColor,
                )
              : Text(
                  text,
                  style: TextStyle(
                    color: textColor ?? kOrange,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
        ),
      ),
    );
  }
}
