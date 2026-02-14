import 'package:flutter/material.dart';
import 'package:mds/constants/colors.dart';

class SearchWidget extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final ValueChanged<String> onChanged;

  const SearchWidget({super.key, 
    required this.controller,
    required this.onChanged,
    required this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            vertical: 5,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: kPrimaryColor,
          ),
          hintText: placeholder,
          hintStyle: TextStyle(
           // color: Colors.grey[400],
          ),
          //filled: true,
         //fillColor: kWhite,
          // Adjust the vertical padding here
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: const BorderSide(
              color: kPrimaryColor,
              width: 0.8,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: const BorderSide(
              color: kPrimaryColor,
              width: 1.0, // Increase the width for a more prominent border
            ),
          ),
        ),
      ),
    );
  }
}
