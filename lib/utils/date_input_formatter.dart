import 'package:flutter/services.dart';

/// TextInputFormatter that automatically adds hyphens for DD-MM-YYYY date format
/// User types numbers only, hyphens are inserted automatically
class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text.replaceAll('-', '');

    // Limit to 8 digits (DDMMYYYY)
    if (text.length > 8) {
      text = text.substring(0, 8);
    }

    // Only allow digits
    text = text.replaceAll(RegExp(r'[^0-9]'), '');

    // Add hyphens automatically
    String formatted = '';
    for (int i = 0; i < text.length; i++) {
      if (i == 2 || i == 4) {
        formatted += '-';
      }
      formatted += text[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Validates if the date string is in valid DD-MM-YYYY format
bool isValidDateFormat(String date) {
  if (date.isEmpty) return true; // Empty is valid (optional field)

  final regex = RegExp(r'^\d{2}-\d{2}-\d{4}$');
  if (!regex.hasMatch(date)) return false;

  final parts = date.split('-');
  final day = int.tryParse(parts[0]) ?? 0;
  final month = int.tryParse(parts[1]) ?? 0;
  final year = int.tryParse(parts[2]) ?? 0;

  if (day < 1 || day > 31) return false;
  if (month < 1 || month > 12) return false;
  if (year < 1900 || year > 2100) return false;

  return true;
}
