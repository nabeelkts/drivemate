import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class InviteSection extends StatelessWidget {
  const InviteSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 230,
      child: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              "assets/images/minivan.png", // Replace with your image path
              fit: BoxFit.fill,
            ),
          ),

          // Content
          Container(
            decoration: const BoxDecoration(
              color: Colors
                  .transparent, // Set to transparent to let the image show through
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 25, top: 30),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        "Invite your Friends",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.black.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          // Replace the URL with your app's download link
                          const String appLink =
                              "https://drive.google.com/file/d/1BagYtUjK-liVuTeuyFO8Y5xswENU-OQk/view?usp=sharing";

                          // Share the app link
                          Share.share("Check out this awesome app: $appLink");
                        },
                        child: Container(
                          height: 36,
                          width: 140,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            border: Border.all(
                              width: 1,
                              color: Colors.grey.shade400,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              "Invite",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black.withOpacity(0.8),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
