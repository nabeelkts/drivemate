import 'package:flutter/material.dart';

class FirstImageContainer extends StatelessWidget {
  const FirstImageContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 185, 
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5), // Ensure the image respects the container's border radius
        child: Image.asset(
          "assets/images/firstimage.png",
          fit: BoxFit.cover, // Use BoxFit.cover to fill the container while maintaining aspect ratio
          width: double.infinity,
          height: double.infinity, // Use double.infinity to fill the container
          errorBuilder: (context, error, stackTrace) {
            print('Error loading image: $error');
            return Container(
              color: Colors.grey[300],
              child: Center(
                child: Text('Error loading image: $error'),
              ),
            );
          },
        ),
      ),
    );
  }
}
