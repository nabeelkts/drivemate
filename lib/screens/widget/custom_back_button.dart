import 'package:flutter/material.dart';
import 'package:mds/constants/colors.dart';

class CustomBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? iconColor;

  const CustomBackButton({
    super.key,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onPressed ?? () => Navigator.maybePop(context),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: backgroundColor ?? Theme.of(context).colorScheme.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: kPrimaryColor,
              width: 1,
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(
                  left: 6.0),
              child: Icon(
                Icons.arrow_back_ios,
                color: iconColor ?? kPrimaryColor,
                size: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}