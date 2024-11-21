import 'package:flutter/material.dart';

class SecondImageContainer extends StatelessWidget {
  const SecondImageContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 445,
          height: 202,
          child: Image.asset(
            "assets/images/secondimage.jpg",
            fit: BoxFit.fill,
          ),
        ),
      ],
    );
  }
}
