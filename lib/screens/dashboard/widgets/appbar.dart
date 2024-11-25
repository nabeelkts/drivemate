import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:mds/screens/notification/notification_screen.dart';

class DashAppBar extends StatelessWidget {
  // ignore: use_key_in_widget_constructors
  const DashAppBar({Key? key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical:10,
          ),
          clipBehavior: Clip.antiAlias,
          decoration: ShapeDecoration(
            gradient: const LinearGradient(
              begin: Alignment(-0.00, -1.00),
              end: Alignment(0, 1),
              colors: [Color(0xFFF46B45), Color(0xFFEEA849)],
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(31),
            ),
          ),
          child: const Icon(
            IconlyLight.profile,
            size: 20,
            //color: kWhite,
          ),
        ),
         Text(
          'Drivemate',
          style: TextStyle(
            color: textColor,
            fontSize: 21.40,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            height: 0,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>  NotificationsScreen(), 
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
            clipBehavior: Clip.antiAlias,
            decoration: ShapeDecoration(
              //color: kWhite,
              shape: RoundedRectangleBorder(
                side: const BorderSide(width: 0.30, color: Color(0xFFF46B45)),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            child: const Icon(
              IconlyLight.notification,
              size: 20,
              color: Color.fromRGBO(255, 111, 97, 1),
            ),
          ),
        ),
      ],
    );
  }
}
