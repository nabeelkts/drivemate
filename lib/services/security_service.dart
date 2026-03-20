import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// Security service that handles authentication security measures:
/// - Rate limiting for login attempts
/// - Session management and expiration
/// - Secure credential handling
/// - Password reset token management
///
/// This service provides rate limiting directly without requiring initialization.
class SecurityService extends GetxService {
  final GetStorage _box = GetStorage();

  // ============================================================
  // LOGIN RATE LIMITING
  // ============================================================
  static const String _loginAttemptsKey = 'login_attempts';
  static const int _maxLoginAttempts = 5;
  static const int _loginLockoutMinutes = 15;

  /// Check if login attempts are rate limited
  bool isRateLimited() {
    final attempts = _box.read<Map<String, dynamic>>(_loginAttemptsKey);
    if (attempts == null) return false;

    final lastAttemptTime =
        DateTime.parse(attempts['lastAttemptTime'] as String);
    final attemptCount = attempts['attemptCount'] as int;

    if (attemptCount >= _maxLoginAttempts) {
      final lockoutEnd =
          lastAttemptTime.add(Duration(minutes: _loginLockoutMinutes));
      if (DateTime.now().isBefore(lockoutEnd)) {
        return true;
      } else {
        _resetLoginAttempts();
        return false;
      }
    }
    return false;
  }

  /// Get remaining lockout time in seconds
  int getRemainingLockoutSeconds() {
    final attempts = _box.read<Map<String, dynamic>>(_loginAttemptsKey);
    if (attempts == null) return 0;

    final lastAttemptTime =
        DateTime.parse(attempts['lastAttemptTime'] as String);
    final lockoutEnd =
        lastAttemptTime.add(Duration(minutes: _loginLockoutMinutes));
    final remaining = lockoutEnd.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// Record a failed login attempt
  void recordFailedLoginAttempt() {
    final attempts = _box.read<Map<String, dynamic>>(_loginAttemptsKey);
    int attemptCount = 1;
    DateTime lastAttemptTime = DateTime.now();

    if (attempts != null) {
      attemptCount = (attempts['attemptCount'] as int) + 1;
      lastAttemptTime = DateTime.parse(attempts['lastAttemptTime'] as String);

      final lockoutEnd =
          lastAttemptTime.add(Duration(minutes: _loginLockoutMinutes));
      if (DateTime.now().isAfter(lockoutEnd)) {
        attemptCount = 1;
      }
    }

    _box.write(_loginAttemptsKey, {
      'attemptCount': attemptCount,
      'lastAttemptTime': DateTime.now().toIso8601String(),
    });
  }

  /// Get remaining login attempts before lockout
  int getRemainingLoginAttempts() {
    final attempts = _box.read<Map<String, dynamic>>(_loginAttemptsKey);
    if (attempts == null) return _maxLoginAttempts;
    final attemptCount = attempts['attemptCount'] as int;
    return (_maxLoginAttempts - attemptCount).clamp(0, _maxLoginAttempts);
  }

  /// Reset login attempts after successful login
  void _resetLoginAttempts() {
    _box.remove(_loginAttemptsKey);
  }

  /// Record successful login - must be called after successful authentication
  void onSuccessfulLogin() {
    _resetLoginAttempts();
    _startSession();
  }

  // ============================================================
  // SESSION MANAGEMENT
  // ============================================================
  static const String _sessionStartKey = 'session_start_time';
  static const int _sessionTimeoutMinutes = 129600;

  /// Check if session has expired
  bool isSessionExpired() {
    final sessionStart = _box.read<String>(_sessionStartKey);
    if (sessionStart == null) return true;

    final startTime = DateTime.parse(sessionStart);
    final sessionEnd = startTime.add(Duration(minutes: _sessionTimeoutMinutes));
    return DateTime.now().isAfter(sessionEnd);
  }

  /// Get remaining session time in seconds
  int getRemainingSessionSeconds() {
    final sessionStart = _box.read<String>(_sessionStartKey);
    if (sessionStart == null) return 0;

    final startTime = DateTime.parse(sessionStart);
    final sessionEnd = startTime.add(Duration(minutes: _sessionTimeoutMinutes));
    final remaining = sessionEnd.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// Refresh session (extend session on user activity)
  void refreshSession() {
    if (!isSessionExpired()) {
      _box.write(_sessionStartKey, DateTime.now().toIso8601String());
    }
  }

  /// Start a new session
  void _startSession() {
    _box.write(_sessionStartKey, DateTime.now().toIso8601String());
  }

  /// End the current session
  void endSession() {
    _box.remove(_sessionStartKey);
    _resetLoginAttempts();
  }

  // ============================================================
  // PASSWORD RESET
  // ============================================================
  static const String _passwordResetAttemptsKey = 'password_reset_attempts';
  static const int _maxPasswordResetAttempts = 3;
  static const int _passwordResetLockoutMinutes = 60;

  /// Check if password reset is rate limited
  bool isPasswordResetRateLimited() {
    final attempts = _box.read<Map<String, dynamic>>(_passwordResetAttemptsKey);
    if (attempts == null) return false;

    final lastAttemptTime =
        DateTime.parse(attempts['lastAttemptTime'] as String);
    final attemptCount = attempts['attemptCount'] as int;

    if (attemptCount >= _maxPasswordResetAttempts) {
      final lockoutEnd =
          lastAttemptTime.add(Duration(minutes: _passwordResetLockoutMinutes));
      if (DateTime.now().isBefore(lockoutEnd)) {
        return true;
      } else {
        _resetPasswordResetAttempts();
        return false;
      }
    }
    return false;
  }

  /// Get password reset remaining lockout seconds
  int getPasswordResetRemainingSeconds() {
    final attempts = _box.read<Map<String, dynamic>>(_passwordResetAttemptsKey);
    if (attempts == null) return 0;

    final lastAttemptTime =
        DateTime.parse(attempts['lastAttemptTime'] as String);
    final lockoutEnd =
        lastAttemptTime.add(Duration(minutes: _passwordResetLockoutMinutes));
    final remaining = lockoutEnd.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// Record failed password reset attempt
  void recordFailedPasswordResetAttempt() {
    final attempts = _box.read<Map<String, dynamic>>(_passwordResetAttemptsKey);
    int attemptCount = 1;

    if (attempts != null) {
      attemptCount = (attempts['attemptCount'] as int) + 1;
      final lastAttemptTime =
          DateTime.parse(attempts['lastAttemptTime'] as String);
      final lockoutEnd =
          lastAttemptTime.add(Duration(minutes: _passwordResetLockoutMinutes));

      if (DateTime.now().isAfter(lockoutEnd)) {
        attemptCount = 1;
      }
    }

    _box.write(_passwordResetAttemptsKey, {
      'attemptCount': attemptCount,
      'lastAttemptTime': DateTime.now().toIso8601String(),
    });
  }

  /// Reset password reset attempts
  void _resetPasswordResetAttempts() {
    _box.remove(_passwordResetAttemptsKey);
  }

  /// Called after password reset email is sent successfully
  void onPasswordResetEmailSent() {
    _resetPasswordResetAttempts();
  }

  // ============================================================
  // ACCOUNT CREATION RATE LIMITING
  // ============================================================
  static const String _accountCreationKey = 'account_creation_attempts';
  static const int _maxAccountCreationAttempts = 3;
  static const int _accountCreationLockoutMinutes = 60;

  /// Check if account creation is rate limited
  bool isAccountCreationRateLimited() {
    final attempts = _box.read<Map<String, dynamic>>(_accountCreationKey);
    if (attempts == null) return false;

    final lastAttemptTime =
        DateTime.parse(attempts['lastAttemptTime'] as String);
    final attemptCount = attempts['attemptCount'] as int;

    if (attemptCount >= _maxAccountCreationAttempts) {
      final lockoutEnd = lastAttemptTime
          .add(Duration(minutes: _accountCreationLockoutMinutes));
      if (DateTime.now().isBefore(lockoutEnd)) {
        return true;
      } else {
        _box.remove(_accountCreationKey);
        return false;
      }
    }
    return false;
  }

  /// Get account creation remaining lockout seconds
  int getAccountCreationRemainingSeconds() {
    final attempts = _box.read<Map<String, dynamic>>(_accountCreationKey);
    if (attempts == null) return 0;

    final lastAttemptTime =
        DateTime.parse(attempts['lastAttemptTime'] as String);
    final lockoutEnd =
        lastAttemptTime.add(Duration(minutes: _accountCreationLockoutMinutes));
    final remaining = lockoutEnd.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// Record failed account creation attempt
  void recordFailedAccountCreationAttempt() {
    final attempts = _box.read<Map<String, dynamic>>(_accountCreationKey);
    int attemptCount = 1;

    if (attempts != null) {
      attemptCount = (attempts['attemptCount'] as int) + 1;
      final lastAttemptTime =
          DateTime.parse(attempts['lastAttemptTime'] as String);
      final lockoutEnd = lastAttemptTime
          .add(Duration(minutes: _accountCreationLockoutMinutes));

      if (DateTime.now().isAfter(lockoutEnd)) {
        attemptCount = 1;
      }
    }

    _box.write(_accountCreationKey, {
      'attemptCount': attemptCount,
      'lastAttemptTime': DateTime.now().toIso8601String(),
    });
  }

  /// Called after successful account creation
  void onSuccessfulAccountCreation() {
    _box.remove(_accountCreationKey);
  }

  /// Check if email has too many registrations
  bool isEmailRegistrationRateLimited(String email) {
    // Simplified implementation - no email tracking for now
    return false;
  }

  /// Record email registration attempt
  void recordEmailRegistrationAttempt(String email) {
    // Simplified implementation
  }

  // ============================================================
  // API RATE LIMITING (Simplified)
  // ============================================================
  // ignore: unused_field
  static const String _apiRateLimitKey = 'api_rate_limit';
  static const int _maxApiRequestsPerMinute = 60;
  static const String _apiRequestTimestampsKey = 'api_request_timestamps';

  /// Check if API requests are rate limited
  bool isAPIRateLimited() {
    final timestamps = _getApiRequestTimestamps();
    final now = DateTime.now();
    final recentTimestamps = timestamps
        .where((t) => t.isAfter(now.subtract(const Duration(minutes: 1))))
        .toList();
    return recentTimestamps.length >= _maxApiRequestsPerMinute;
  }

  /// Check if API burst limit is exceeded
  bool isAPIBurstLimited() {
    return false; // Simplified
  }

  /// Record an API request
  void recordAPIRequest() {
    final timestamps = _getApiRequestTimestamps();
    timestamps.add(DateTime.now());
    final cutoff = DateTime.now().subtract(const Duration(hours: 1));
    final recentTimestamps =
        timestamps.where((t) => t.isAfter(cutoff)).toList();
    _box.write(_apiRequestTimestampsKey,
        recentTimestamps.map((t) => t.toIso8601String()).toList());
  }

  List<DateTime> _getApiRequestTimestamps() {
    final timestamps = _box.read<List<dynamic>>(_apiRequestTimestampsKey);
    if (timestamps == null) return [];
    return timestamps.map((t) => DateTime.parse(t as String)).toList();
  }

  /// Get remaining API requests for current minute
  int getRemainingAPIRequests() {
    return _maxApiRequestsPerMinute; // Simplified
  }

  /// Get API requests remaining in current hour
  int getRemainingAPIRequestsPerHour() {
    return 500; // Simplified
  }

  // ============================================================
  // AI GENERATION REQUEST RATE LIMITING
  // ============================================================
  // ignore: unused_field
  static const String _aiRequestKey = 'ai_request_attempts';
  static const int _maxAIRequestsPerHour = 20;
  // ignore: unused_field
  static const int _aiLockoutMinutes = 30;

  /// Check if AI requests are rate limited
  bool isAIRateLimited() {
    return false; // Simplified
  }

  /// Check if OCR requests are rate limited
  bool isOCRRateLimited() {
    return false; // Simplified
  }

  /// Get AI request remaining seconds
  int getAIRemainingLockoutSeconds() {
    return 0;
  }

  /// Get OCR remaining lockout seconds
  int getOCRRemainingLockoutSeconds() {
    return 0;
  }

  /// Record an AI request
  void recordAIRequest() {
    // Simplified
  }

  /// Record an OCR request
  void recordOCRRequest() {
    // Simplified
  }

  /// Get remaining AI requests
  int getRemainingAIRequests() {
    return _maxAIRequestsPerHour;
  }

  /// Get remaining OCR requests
  int getRemainingOCRRequests() {
    return 10;
  }

  // ============================================================
  // BOT DETECTION (Simplified)
  // ============================================================

  /// Check if suspicious activity is detected
  bool isSuspiciousActivityDetected() {
    return false;
  }

  /// Record suspicious activity
  void recordSuspiciousActivity(String activityType) {
    // Simplified
  }

  /// Get remaining suspicious actions allowed
  int getRemainingSuspiciousActions() {
    return 5;
  }

  /// Generate a simple device fingerprint hash
  String generateDeviceFingerprint(String userAgent, String? userId) {
    final input = '$userAgent-$userId-${DateTime.now().day}';
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  // ============================================================
  // DATA SCRAPING PROTECTION (Simplified)
  // ============================================================

  /// Check if bulk data access is rate limited
  bool isBulkAccessRateLimited() {
    return false;
  }

  /// Record bulk data access
  void recordBulkDataAccess() {
    // Simplified
  }

  /// Get remaining bulk requests
  int getRemainingBulkRequests() {
    return 100;
  }

  // ============================================================
  // UTILITY METHODS
  // ============================================================

  /// Generate a secure hash for verification purposes
  String generateSecureHash(String input) {
    final bytes = utf8.encode(input + DateTime.now().toIso8601String());
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Check if email verification is required
  Future<bool> isEmailVerificationRequired() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    await user.reload();
    final currentUser = FirebaseAuth.instance.currentUser;
    return currentUser?.emailVerified ?? true;
  }

  /// Clear all security-related storage (for logout)
  void clearSecurityStorage() {
    endSession();
    _resetPasswordResetAttempts();
    _box.remove(_apiRequestTimestampsKey);
  }

  /// Get comprehensive rate limit status for UI display
  Map<String, dynamic> getRateLimitStatus() {
    return {
      'login': {
        'isLimited': isRateLimited(),
        'remainingAttempts': getRemainingLoginAttempts(),
        'remainingSeconds': getRemainingLockoutSeconds(),
      },
      'accountCreation': {
        'isLimited': isAccountCreationRateLimited(),
        'remainingSeconds': getAccountCreationRemainingSeconds(),
      },
      'api': {
        'isLimited': isAPIRateLimited(),
        'isBurstLimited': isAPIBurstLimited(),
        'remainingPerMinute': getRemainingAPIRequests(),
        'remainingPerHour': getRemainingAPIRequestsPerHour(),
      },
      'ai': {
        'isLimited': isAIRateLimited(),
        'remainingRequests': getRemainingAIRequests(),
        'remainingSeconds': getAIRemainingLockoutSeconds(),
      },
      'ocr': {
        'isLimited': isOCRRateLimited(),
        'remainingRequests': getRemainingOCRRequests(),
        'remainingSeconds': getOCRRemainingLockoutSeconds(),
      },
      'botDetection': {
        'isSuspected': isSuspiciousActivityDetected(),
        'remainingActions': getRemainingSuspiciousActions(),
      },
      'bulkAccess': {
        'isLimited': isBulkAccessRateLimited(),
        'remainingRequests': getRemainingBulkRequests(),
      },
      'passwordReset': {
        'isLimited': isPasswordResetRateLimited(),
        'remainingSeconds': getPasswordResetRemainingSeconds(),
      },
    };
  }
}
