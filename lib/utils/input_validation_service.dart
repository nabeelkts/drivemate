/// Input Validation Service
/// Provides strict validation and sanitization for all user inputs
/// Prevents SQL injection, XSS, command injection, and unsafe file uploads
library;

import 'dart:typed_data';

/// Validation result class
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult.valid()
      : isValid = true,
        errorMessage = null;
  const ValidationResult.invalid(this.errorMessage) : isValid = false;

  @override
  String toString() => isValid ? 'Valid' : 'Invalid: $errorMessage';
}

/// Input sanitization and validation utility
class InputValidationService {
  // ============================================================
  // BLOCKED PATTERNS FOR SECURITY
  // ============================================================

  // HTML/Script injection patterns
  static final RegExp _htmlPattern = RegExp(r'<[^>]*>', caseSensitive: false);
  static final RegExp _scriptPattern = RegExp(
    r'(javascript:|vbscript:|data:text/html|on\w+\s*=)',
    caseSensitive: false,
  );

  // Command injection patterns
  static final RegExp _commandPattern = RegExp(
    r'[;&|`$]',
    multiLine: false,
  );

  // Path traversal patterns
  static final RegExp _pathTraversalPattern = RegExp(
    r'(\.\.[/\\])|([/\\]\.\.)|(~[/\\])',
    caseSensitive: false,
  );

  // SQL injection patterns (for potential SQL-backended systems)
  static final RegExp _sqlInjectionPattern = RegExp(
    r"(union\s+select|select\s+\*\s+from|insert\s+into|delete\s+from|drop\s+table|truncate\s+table|exec\s*\(|execute\s*\(|xp_)",
    caseSensitive: false,
  );

  // ============================================================
  // GENERAL SANITIZATION
  // ============================================================

  /// Sanitize string input - remove dangerous characters
  static String sanitizeString(String input) {
    if (input.isEmpty) return input;

    String sanitized = input.trim();

    // Remove null bytes
    sanitized = sanitized.replaceAll('\x00', '');

    // Remove common injection patterns
    sanitized = sanitized.replaceAll(_htmlPattern, '');
    sanitized = sanitized.replaceAll(_scriptPattern, '');
    sanitized = sanitized.replaceAll(_commandPattern, '');

    return sanitized;
  }

  /// Check if string contains dangerous patterns
  static ValidationResult checkForInjection(String input) {
    if (input.isEmpty) {
      return const ValidationResult.valid();
    }

    // Check for HTML/script injection
    if (_htmlPattern.hasMatch(input)) {
      return const ValidationResult.invalid(
        'Input contains HTML tags which are not allowed',
      );
    }

    // Check for script injection
    if (_scriptPattern.hasMatch(input)) {
      return const ValidationResult.invalid(
        'Input contains potentially dangerous script patterns',
      );
    }

    // Check for command injection
    if (_commandPattern.hasMatch(input)) {
      return const ValidationResult.invalid(
        'Input contains command characters that are not allowed',
      );
    }

    // Check for path traversal
    if (_pathTraversalPattern.hasMatch(input)) {
      return const ValidationResult.invalid(
        'Input contains path traversal patterns',
      );
    }

    // Check for SQL injection
    if (_sqlInjectionPattern.hasMatch(input)) {
      return const ValidationResult.invalid(
        'Input contains SQL patterns that are not allowed',
      );
    }

    return const ValidationResult.valid();
  }

  // ============================================================
  // STRING VALIDATION
  // ============================================================

  /// Validate string length
  static ValidationResult validateLength(
    String input, {
    int minLength = 0,
    int maxLength = 1000,
  }) {
    if (input.length < minLength) {
      return ValidationResult.invalid(
        'Input must be at least $minLength characters',
      );
    }
    if (input.length > maxLength) {
      return ValidationResult.invalid(
        'Input must be at most $maxLength characters',
      );
    }
    return const ValidationResult.valid();
  }

  /// Validate name (letters, spaces, and common punctuation only)
  static ValidationResult validateName(String input) {
    if (input.isEmpty) {
      return const ValidationResult.invalid('Name is required');
    }

    final sanitized = sanitizeString(input);

    // Only allow letters, spaces, hyphens, apostrophes, and periods
    final namePattern = RegExp(r"^[a-zA-Z\s\-\'\.]+$");
    if (!namePattern.hasMatch(sanitized)) {
      return const ValidationResult.invalid(
        'Name can only contain letters, spaces, hyphens, and apostrophes',
      );
    }

    return validateLength(sanitized, minLength: 1, maxLength: 100);
  }

  /// Validate email address
  static ValidationResult validateEmail(String input) {
    if (input.isEmpty) {
      return const ValidationResult.invalid('Email is required');
    }

    final sanitized = sanitizeString(input);

    // Standard email pattern
    final emailPattern = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailPattern.hasMatch(sanitized)) {
      return const ValidationResult.invalid('Invalid email format');
    }

    return validateLength(sanitized, maxLength: 254);
  }

  /// Validate phone number (India format)
  static ValidationResult validatePhoneNumber(String input) {
    if (input.isEmpty) {
      return const ValidationResult.invalid('Phone number is required');
    }

    // Remove all non-digit characters for validation
    final digitsOnly = input.replaceAll(RegExp(r'\D'), '');

    // Allow 10-digit Indian mobile or landline with STD
    if (digitsOnly.length < 10 || digitsOnly.length > 12) {
      return const ValidationResult.invalid(
        'Phone number must be 10-12 digits',
      );
    }

    // Check for valid Indian mobile starts with 6-9
    if (digitsOnly.length == 10) {
      if (!RegExp(r'^[6-9]').hasMatch(digitsOnly)) {
        return const ValidationResult.invalid(
          'Mobile number must start with 6, 7, 8, or 9',
        );
      }
    }

    return const ValidationResult.valid();
  }

  /// Validate vehicle number (Indian format)
  static ValidationResult validateVehicleNumber(String input) {
    if (input.isEmpty) {
      return const ValidationResult.invalid('Vehicle number is required');
    }

    final sanitized = sanitizeString(input).toUpperCase();

    // Indian vehicle registration format: XX00XX0000
    final vehiclePattern = RegExp(r'^[A-Z]{2}[0-9]{2}[A-Z]{1,2}[0-9]{4}$');
    if (!vehiclePattern.hasMatch(sanitized)) {
      return const ValidationResult.invalid(
        'Invalid vehicle number format (e.g., KL01AB1234)',
      );
    }

    return const ValidationResult.valid();
  }

  /// Validate license number
  static ValidationResult validateLicenseNumber(String input) {
    if (input.isEmpty) {
      return const ValidationResult.invalid('License number is required');
    }

    final sanitized = sanitizeString(input).toUpperCase();

    // Indian driving license format
    final licensePattern =
        RegExp(r'^[A-Z]{2}[0-9]{13}$|^[A-Z]{2}[0-9]{2}[A-Z]{1,3}[0-9]{6,8}$');
    if (!licensePattern.hasMatch(sanitized)) {
      return const ValidationResult.invalid('Invalid license number format');
    }

    return const ValidationResult.valid();
  }

  /// Validate PIN code (India)
  static ValidationResult validatePinCode(String input) {
    if (input.isEmpty) {
      return const ValidationResult.valid(); // PIN is optional
    }

    final digitsOnly = input.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.length != 6) {
      return const ValidationResult.invalid('PIN code must be 6 digits');
    }

    return const ValidationResult.valid();
  }

  // ============================================================
  // NUMERIC VALIDATION
  // ============================================================

  /// Validate numeric input (amounts, etc)
  static ValidationResult validateNumeric(
    String input, {
    bool allowDecimal = true,
    double? minValue,
    double? maxValue,
  }) {
    if (input.isEmpty) {
      return const ValidationResult.invalid('Number is required');
    }

    final pattern = allowDecimal ? r'^\d+\.?\d*$' : r'^\d+$';
    if (!RegExp(pattern).hasMatch(input)) {
      return ValidationResult.invalid(
        allowDecimal ? 'Invalid number format' : 'Invalid integer format',
      );
    }

    final value = double.tryParse(input);
    if (value == null) {
      return const ValidationResult.invalid('Invalid number');
    }

    if (minValue != null && value < minValue) {
      return ValidationResult.invalid('Value must be at least $minValue');
    }

    if (maxValue != null && value > maxValue) {
      return ValidationResult.invalid('Value must be at most $maxValue');
    }

    return const ValidationResult.valid();
  }

  /// Validate amount (positive number with 2 decimal places)
  static ValidationResult validateAmount(String input) {
    if (input.isEmpty) {
      return const ValidationResult.invalid('Amount is required');
    }

    // Allow common formats: 100, 100.00, 1,234.56
    final cleaned = input.replaceAll(RegExp(r'[, ]'), '');
    final amountPattern = RegExp(r'^\d+\.?\d{0,2}$');

    if (!amountPattern.hasMatch(cleaned)) {
      return const ValidationResult.invalid('Invalid amount format');
    }

    final value = double.tryParse(cleaned);
    if (value == null || value < 0) {
      return const ValidationResult.invalid('Amount must be positive');
    }

    if (value > 999999999) {
      return const ValidationResult.invalid('Amount exceeds maximum limit');
    }

    return const ValidationResult.valid();
  }

  // ============================================================
  // DATE VALIDATION
  // ============================================================

  /// Validate date string
  static ValidationResult validateDate(
    String input, {
    DateTime? minDate,
    DateTime? maxDate,
  }) {
    if (input.isEmpty) {
      return const ValidationResult.invalid('Date is required');
    }

    // Try common date formats
    DateTime? date;

    if (input.contains('-')) {
      final parts = input.split('-');
      if (parts[0].length == 4) {
        // YYYY-MM-DD
        date = DateTime.tryParse(input);
      } else if (parts.length == 3) {
        // DD-MM-YYYY
        date = DateTime.tryParse('${parts[2]}-${parts[1]}-${parts[0]}');
      }
    } else if (input.contains('/')) {
      final parts = input.split('/');
      if (parts.length == 3) {
        date = DateTime.tryParse('${parts[2]}-${parts[1]}-${parts[0]}');
      }
    }

    if (date == null) {
      return const ValidationResult.invalid('Invalid date format');
    }

    if (minDate != null && date.isBefore(minDate)) {
      return ValidationResult.invalid(
        'Date must be after ${_formatDate(minDate)}',
      );
    }

    if (maxDate != null && date.isAfter(maxDate)) {
      return ValidationResult.invalid(
        'Date must be before ${_formatDate(maxDate)}',
      );
    }

    return const ValidationResult.valid();
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  // ============================================================
  // FILE UPLOAD VALIDATION
  // ============================================================

  /// Validate uploaded file
  static ValidationResult validateFile(
    String fileName,
    Uint8List? fileBytes,
  ) {
    if (fileName.isEmpty) {
      return const ValidationResult.invalid('File name is required');
    }

    // Check for path traversal in filename
    if (_pathTraversalPattern.hasMatch(fileName)) {
      return const ValidationResult.invalid(
        'File name contains invalid characters',
      );
    }

    // Get file extension
    final extension = fileName.split('.').last.toLowerCase();

    // Allowed image extensions
    const allowedImageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
    const allowedDocumentExtensions = ['pdf', 'doc', 'docx', 'xls', 'xlsx'];
    const allowedExtensions = [
      ...allowedImageExtensions,
      ...allowedDocumentExtensions,
    ];

    if (!allowedExtensions.contains(extension)) {
      return ValidationResult.invalid(
        'File type not allowed. Allowed: ${allowedExtensions.join(", ")}',
      );
    }

    // Validate file size (max 10MB for images, 25MB for documents)
    final maxSize = allowedImageExtensions.contains(extension)
        ? 10 * 1024 * 1024 // 10MB
        : 25 * 1024 * 1024; // 25MB

    if (fileBytes != null && fileBytes.length > maxSize) {
      final maxSizeMB = (maxSize / (1024 * 1024)).round();
      return ValidationResult.invalid(
        'File size exceeds ${maxSizeMB}MB limit',
      );
    }

    // Validate magic bytes for images
    if (fileBytes != null && allowedImageExtensions.contains(extension)) {
      if (!_isValidImageMagicBytes(fileBytes, extension)) {
        return const ValidationResult.invalid(
          'File content does not match its extension',
        );
      }
    }

    // Check for dangerous file names
    final dangerousPatterns = [
      '..',
      '.exe',
      '.bat',
      '.cmd',
      '.sh',
      '.ps1',
      '.vbs',
      '.js',
      '.jar',
      '.scr',
      '.pif',
    ];

    for (final pattern in dangerousPatterns) {
      if (fileName.toLowerCase().contains(pattern)) {
        return const ValidationResult.invalid(
          'File type not allowed for security reasons',
        );
      }
    }

    return const ValidationResult.valid();
  }

  /// Validate image magic bytes
  static bool _isValidImageMagicBytes(Uint8List bytes, String extension) {
    if (bytes.length < 4) return false;

    // Check magic bytes for common image formats
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        // JPEG: FF D8 FF
        return bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF;
      case 'png':
        // PNG: 89 50 4E 47
        return bytes[0] == 0x89 &&
            bytes[1] == 0x50 &&
            bytes[2] == 0x4E &&
            bytes[3] == 0x47;
      case 'gif':
        // GIF: 47 49 46 38
        return bytes[0] == 0x47 &&
            bytes[1] == 0x49 &&
            bytes[2] == 0x46 &&
            bytes[3] == 0x38;
      case 'webp':
        // WebP: 52 49 46 46 (RIFF) + 57 45 42 50 (WEBP)
        return bytes[0] == 0x52 &&
            bytes[1] == 0x49 &&
            bytes[2] == 0x46 &&
            bytes[3] == 0x46 &&
            bytes[8] == 0x57 &&
            bytes[9] == 0x45 &&
            bytes[10] == 0x42 &&
            bytes[11] == 0x50;
      default:
        return true;
    }
  }

  // ============================================================
  // FIRESTORE QUERY VALIDATION
  // ============================================================

  /// Validate field name for Firestore queries
  static ValidationResult validateFieldName(String fieldName) {
    if (fieldName.isEmpty) {
      return const ValidationResult.invalid('Field name is required');
    }

    // Firestore field names must start with letter and contain only
    // letters, digits, underscores, and not start with underscore
    final fieldPattern = RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$');
    if (!fieldPattern.hasMatch(fieldName)) {
      return const ValidationResult.invalid(
        'Invalid field name format',
      );
    }

    // Block dangerous field names
    const blockedFields = [
      '__name__',
      '__streamId__',
      '__documentId__',
    ];

    if (blockedFields.contains(fieldName)) {
      return const ValidationResult.invalid(
        'Field name not allowed',
      );
    }

    return const ValidationResult.valid();
  }

  /// Validate collection name for Firestore
  static ValidationResult validateCollectionName(String collectionName) {
    if (collectionName.isEmpty) {
      return const ValidationResult.invalid('Collection name is required');
    }

    // Firestore collection names
    final collectionPattern = RegExp(r'^[a-zA-Z][a-zA-Z0-9_-]*$');
    if (!collectionPattern.hasMatch(collectionName)) {
      return const ValidationResult.invalid(
        'Invalid collection name format',
      );
    }

    // Block access to sensitive collections
    const blockedCollections = [
      'users',
      'audit_logs',
      'admin',
      'system',
      'config',
    ];

    if (blockedCollections.contains(collectionName)) {
      return const ValidationResult.invalid(
        'Collection access not allowed',
      );
    }

    return const ValidationResult.valid();
  }

  // ============================================================
  // COMBINED VALIDATORS
  // ============================================================

  /// Validate form field based on field type
  static ValidationResult validateField(String value, String fieldType) {
    switch (fieldType.toLowerCase()) {
      case 'name':
        return validateName(value);
      case 'email':
        return validateEmail(value);
      case 'phone':
      case 'mobile':
        return validatePhoneNumber(value);
      case 'vehicle':
      case 'vehicle_number':
        return validateVehicleNumber(value);
      case 'license':
      case 'license_number':
        return validateLicenseNumber(value);
      case 'pin':
      case 'pincode':
        return validatePinCode(value);
      case 'amount':
      case 'fee':
      case 'price':
        return validateAmount(value);
      case 'number':
      case 'numeric':
        return validateNumeric(value);
      case 'date':
        return validateDate(value);
      case 'text':
      case 'string':
        return validateLength(sanitizeString(value), maxLength: 5000);
      default:
        // For unknown types, do basic sanitization and length check
        return checkForInjection(value).isValid
            ? validateLength(sanitizeString(value), maxLength: 1000)
            : const ValidationResult.invalid('Invalid characters in input');
    }
  }

  /// Validate entire form data map
  static Map<String, ValidationResult> validateFormData(
    Map<String, String> data,
    Map<String, String> fieldTypes,
  ) {
    final results = <String, ValidationResult>{};

    for (final entry in data.entries) {
      final fieldType = fieldTypes[entry.key] ?? 'text';
      results[entry.key] = validateField(entry.value, fieldType);
    }

    return results;
  }

  /// Check if all form validations pass
  static bool isFormValid(Map<String, ValidationResult> results) {
    return results.values.every((result) => result.isValid);
  }

  /// Get list of field errors
  static List<String> getFormErrors(Map<String, ValidationResult> results) {
    return results.entries
        .where((e) => !e.value.isValid)
        .map((e) => '${e.key}: ${e.value.errorMessage}')
        .toList();
  }
}
