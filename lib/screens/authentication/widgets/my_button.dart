import 'package:flutter/material.dart';
import 'package:mds/constants/colors.dart';

class MyButton extends StatelessWidget {
  final Function()? onTap;
  final String text;
  final bool isLoading;
  final bool isEnabled;
  final double width;

  const MyButton({
    super.key,
    required this.onTap,
    required this.text,
    required this.isLoading,
    required this.isEnabled,
    this.width = double.infinity, // Default to full width
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        width: width, // Use the width parameter
        height: 44,
        decoration: ShapeDecoration(
          //color: isEnabled ? Color(0xFFFFFBF7) : Colors.grey[300],
          shape: RoundedRectangleBorder(
            side: const BorderSide(width: 0.50, color: kOrange),
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
                  style: const TextStyle(
                    color: kOrange,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
        ),
      ),
    );
  }
}
