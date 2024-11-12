import 'package:flutter/material.dart';

class SecondImageContainer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 445,
          height: 200,
          child: Image.asset(
            "assets/images/secondimage.jpg",
            fit: BoxFit.fill,
          ),
        ),
      ],
    );
  }
}
