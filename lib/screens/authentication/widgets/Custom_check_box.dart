import 'package:flutter/material.dart';

class CustomCheckbox extends StatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color fillColor;

  const CustomCheckbox({
    required this.value,
    required this.onChanged,
    required this.fillColor,
  });

  @override
  _CustomCheckboxState createState() => _CustomCheckboxState();
}

class _CustomCheckboxState extends State<CustomCheckbox> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onChanged?.call(!widget.value);
      },
      child: Container(
        width: 24.0,
        height: 24.0,
        decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.fillColor,
            width: 1.0,
          ),
          color: widget.value ? widget.fillColor : Colors.transparent,
        ),
        child: widget.value
            ? Icon(
                Icons.check,
                size: 18.0,
                color: Colors.white,
              )
            : null,
      ),
    );
  }
}
