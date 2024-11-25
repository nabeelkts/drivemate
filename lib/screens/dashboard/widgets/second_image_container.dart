import 'package:flutter/material.dart';

class SecondImageContainer extends StatelessWidget {
  const SecondImageContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 180, 
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25), // Ensure the image respects the container's border radius
        child: Image.asset("assets/images/secondimage.jpg",
        fit: BoxFit.cover, // Use BoxFit.cover to fill the container while maintaining aspect ratio
          width: double.infinity,
          height: double.infinity, // Use double.infinity to fill the container
        ),
      ),
    );
  }
}