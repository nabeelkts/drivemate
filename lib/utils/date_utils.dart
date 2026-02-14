import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// Utility class for date formatting and parsing operations
class AppDateUtils {
  // Date format constants
  static const String displayFormat = 'dd-MM-yyyy';
  static const String storageFormat = 'yyyy-MM-dd';

  /// Date picker constraints
  static final DateTime firstDate = DateTime(1900);
  static final DateTime lastDate = DateTime(2100);

  /// Gets the latest allowed date of birth (18 years ago from today)
  static DateTime get dobLastDate {
    final now = DateTime.now();
    return DateTime(now.year - 18, now.month, now.day);
  }

  /// Formats a date string from storage format (yyyy-MM-dd) to display format (dd-MM-yyyy)
  /// Returns empty string if date is null or invalid
  static String formatDateForDisplay(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return '';
    }

    try {
      final date = DateTime.parse(dateString);
      return DateFormat(displayFormat).format(date);
    } catch (e) {
      return dateString;
    }
  }

  /// Formats a date string from display format (dd-MM-yyyy) to storage format (yyyy-MM-dd)
  /// Returns null if date is null, empty, or invalid
  static String? formatDateForStorage(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return null;
    }

    try {
      final date = DateFormat(displayFormat).parse(dateString);
      return DateFormat(storageFormat).format(date);
    } catch (e) {
      if (kDebugMode) {
        print('Error formatting date for storage: $e');
      }
      return null;
    }
  }

  /// Parses a date string in display format and returns DateTime
  /// Returns current date if parsing fails
  static DateTime parseDisplayDate(String dateString, {DateTime? fallback}) {
    if (dateString.isEmpty) {
      return fallback ?? DateTime.now();
    }

    try {
      return DateFormat(displayFormat).parse(dateString);
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing display date: $e');
      }
      return fallback ?? DateTime.now();
    }
  }
}
