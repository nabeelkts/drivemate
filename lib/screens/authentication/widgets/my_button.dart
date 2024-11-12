import 'package:flutter/material.dart';
import 'package:mds/constants/colors.dart';

class MyButton extends StatelessWidget {
  final Function()? onTap;
  final String text;
  final bool isLoading;
  final bool isEnabled;

  const MyButton({
    super.key,
    required this.onTap,
    required this.text,
    required this.isLoading,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: 390,
          height: 44,
          decoration: ShapeDecoration(
            color: Color(0xFFFFFBF7),
            shape: RoundedRectangleBorder(
              side: const BorderSide(width: 0.50, color: kOrange),
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: Center(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                    color: kPrimaryColor,
                  ))
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
      ),
    );
  }
}
