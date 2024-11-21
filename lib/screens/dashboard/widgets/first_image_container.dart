import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class FirstImageContainer extends StatelessWidget {
  const FirstImageContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CachedNetworkImage(
          imageUrl:
              "https://drive.google.com/uc?export=view&id=1fQYERzzIVinc4bif_5SF7cJQT9mFN9om",
          fit: BoxFit.cover,
          width: 445,
          height: 200,
        ),
      ],
    );
  }
}
