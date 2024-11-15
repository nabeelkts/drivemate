import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:mds/constants/colors.dart';

class DashAppBar extends StatelessWidget {
  const DashAppBar({Key? key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
            clipBehavior: Clip.antiAlias,
            decoration: ShapeDecoration(
              gradient: const LinearGradient(
                begin: Alignment(-0.00, -1.00),
                end: Alignment(0, 1),
                colors: [Color(0xFFF46B45), Color(0xFFEEA849)],
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(41),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  IconlyLight.profile,
                  size: 20,
                  color: kWhite,
                ),
              ],
            ),
          ),
          const Text(
            'Drivemate',
            style: TextStyle(
              color: kBlack,
              fontSize: 21.40,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              height: 0,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
            clipBehavior: Clip.antiAlias,
            decoration: ShapeDecoration(
              color: kWhite,
              shape: RoundedRectangleBorder(
                side: const BorderSide(width: 0.30, color: Color(0xFFF46B45)),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  IconlyLight.notification,
                  size: 20,
                  color: Color.fromRGBO(255, 111, 97, 1),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
