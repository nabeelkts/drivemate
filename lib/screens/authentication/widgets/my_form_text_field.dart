import 'package:flutter/material.dart';
import 'package:mds/constants/colors.dart';

class MyFormTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final String labelText;
  final bool obscureText;
  final void Function()? onTapEyeIcon;
  final String? Function(String?)? validator;

  const MyFormTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.labelText,
    required this.obscureText,
    required this.onTapEyeIcon,
    required this.validator,
  });

  @override
  // ignore: library_private_types_in_public_api
  _MyFormTextFieldState createState() => _MyFormTextFieldState();
}

class _MyFormTextFieldState extends State<MyFormTextField> {
  bool passwordObscured = true;

  @override
  void initState() {
    super.initState();
    passwordObscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Material(
        borderRadius: BorderRadius.circular(10),
        child: TextFormField(
          validator: widget.validator,
          controller: widget.controller,
          obscureText: passwordObscured,
          decoration: InputDecoration(
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: kOrange),
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: kOrange),
              borderRadius: BorderRadius.circular(10),
            ),
            labelText: widget.labelText,
            labelStyle: const TextStyle(
              fontSize: 12,
              fontFamily: 'Inter',
              fontWeight: FontWeight.normal,
              height: 0,
            ),
            hintText: widget.hintText,
            hintStyle: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w300,
              height: 0,
              fontSize: 10,
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 10, // Adjust the vertical padding as needed
              horizontal: 16, // Adjust the horizontal padding as needed
            ),
            suffixIcon: widget.obscureText
                ? GestureDetector(
                    onTap: () {
                      widget.onTapEyeIcon?.call();
                      togglePasswordVisibility();
                    },
                    child: Icon(
                      passwordObscured
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  void togglePasswordVisibility() {
    setState(() {
      passwordObscured = !passwordObscured;
    });
  }
}
