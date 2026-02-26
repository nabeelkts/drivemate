import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoadingList extends StatelessWidget {
  const ShimmerLoadingList({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.white10,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 8, // Specify the number of shimmering items you want
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.grey,
              ),
              title: Container(
                width: double.infinity,
                height: 15,
                color: Colors.grey,
              ),
              subtitle: Container(
                width: double.infinity,
                height: 10,
                color: Colors.grey,
              ),
            ),
          );
        },
      ),
    );
  }
}
