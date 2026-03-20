import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// Abuse Protection Service that handles comprehensive security measures:
/// - Rate limiting for login attempts (existing)
/// - Rate limiting for account creation
/// - Rate limiting for API endpoints
/// - Rate limiting for AI generation requests (OCR/document scanning)
/// - Bot detection and prevention
/// - Data scraping protection
/// - Session management and expiration
class AbuseProtectionService extends GetxService {
  final GetStorage _box = GetStorage();

  // ============================================================
  // LOGIN RATE LIMITING (Existing - Enhanced)
  // ============================================================
  static const String _loginAttemptsKey = 'login_attempts';
  static const int _maxLoginAttempts = 5;
  static const int _loginLockoutMinutes = 15;

  // Progressive lockout: increase lockout time with repeated failures
  static const int _progressiveLockoutMultiplier =
      2; // Double lockout each time

  // ============================================================
  // ACCOUNT CREATION RATE LIMITING (NEW)
  // ============================================================
  static const String _accountCreationKey = 'account_creation_attempts';
  static const int _maxAccountCreationAttempts = 3;
  static const int _accountCreationLockoutMinutes = 60;

  // Email-based rate limiting to prevent mass account creation
  static const String _emailRegistrationKey = 'email_registration_';
  static const int _maxRegistrationsPerEmail = 2;
  static const int _emailRegistrationWindowHours = 24;

  // ============================================================
  // API ENDPOINT RATE LIMITING (NEW)
  // ============================================================
  // ignore: unused_field
  static const String _apiRateLimitKey = 'api_rate_limit';
  static const int _maxApiRequestsPerMinute = 60;
  static const int _maxApiRequestsPerHour = 500;
  static const int _apiBurstLimit = 10; // Max requests allowed in burst window

  // Track API requests with timestamps
  static const String _apiRequestTimestampsKey = 'api_request_timestamps';

  // ============================================================
  // AI GENERATION REQUEST RATE LIMITING (NEW)
  // ============================================================
  static const String _aiRequestKey = 'ai_request_attempts';
  static const int _maxAIRequestsPerHour = 20;
  static const int _maxAIRequestsPerDay = 50;
  static const int _aiLockoutMinutes = 30;

  // OCR/Document scan specific limits
  static const String _ocrRequestKey = 'ocr_request_attempts';
  static const int _maxOCRRequestsPerHour = 10;
  static const int _maxOCRRequestsPerDay = 30;

  // ============================================================
  // BOT DETECTION (NEW)
  // ============================================================
  static const String _botDetectionKey = 'bot_detection';
  static const int _maxSuspiciousActions = 5;
  static const int _botSuspicionWindowMinutes = 10;

  // Device fingerprint tracking (reserved for future use)
  // ignore: unused_field
  static const String _deviceFingerprintKey = 'device_fingerprint';
  // ignore: unused_field
  static const int _maxDevicesPerAccount = 5;

  // ============================================================
  // DATA SCRAPING PROTECTION (NEW)
  // ============================================================
  // ignore: unused_field
  static const String _scrapingDetectionKey = 'scraping_detection';
  static const int _maxBulkRequests = 100;
  static const int _bulkRequestWindowMinutes = 5;

  // Track bulk data access patterns
  static const String _bulkAccessTimestampsKey = 'bulk_access_timestamps';

  // ============================================================
  // SESSION MANAGEMENT (Existing)
  // ============================================================
  static const String _sessionStartKey = 'session_start_time';
  static const int _sessionTimeoutMinutes = 30;

  // ============================================================
  // PASSWORD RESET (Existing)
  // ============================================================
  static const String _passwordResetAttemptsKey = 'password_reset_attempts';
  static const int _maxPasswordResetAttempts = 3;
  static const int _passwordResetLockoutMinutes = 60;

  // ============================================================
  // LOGIN RATE LIMITING METHODS
  // ============================================================

  /// Check if login attempts are rate limited
  bool isLoginRateLimited() {
    final attempts = _box.read<Map<String, dynamic>>(_loginAttemptsKey);
    if (attempts == null) return false;

    final lastAttemptTime =
        DateTime.parse(attempts['lastAttemptTime'] as String);
    final attemptCount = attempts['attemptCount'] as int;
    final lockoutCount = attempts['lockoutCount'] as int? ?? 0;

    // If account is locked
    if (attemptCount >= _maxLoginAttempts) {
      // Calculate progressive lockout duration
      final effectiveLockoutMinutes = _loginLockoutMinutes *
          (lockoutCount > 0 ? _progressiveLockoutMultiplier.clamp(1, 8) : 1);
      final lockoutEnd =
          lastAttemptTime.add(Duration(minutes: effectiveLockoutMinutes));
      if (DateTime.now().isBefore(lockoutEnd)) {
        return true;
      } else {
        // Lockout period expired, reset attempts
        _resetLoginAttempts();
        return false;
      }
    }
    return false;
  }

  /// Get remaining login lockout time in seconds
  int getLoginRemainingLockoutSeconds() {
    final attempts = _box.read<Map<String, dynamic>>(_loginAttemptsKey);
    if (attempts == null) return 0;

    final lastAttemptTime =
        DateTime.parse(attempts['lastAttemptTime'] as String);
    final lockoutCount = attempts['lockoutCount'] as int? ?? 0;
    final effectiveLockoutMinutes = _loginLockoutMinutes *
        (lockoutCount > 0 ? _progressiveLockoutMultiplier.clamp(1, 8) : 1);
    final lockoutEnd =
        lastAttemptTime.add(Duration(minutes: effectiveLockoutMinutes));
    final remaining = lockoutEnd.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// Record a failed login attempt
  void recordFailedLoginAttempt() {
    final attempts = _box.read<Map<String, dynamic>>(_loginAttemptsKey);
    int attemptCount = 1;
    int lockoutCount = 0;
    DateTime lastAttemptTime = DateTime.now();

    if (attempts != null) {
      attemptCount = (attempts['attemptCount'] as int) + 1;
      lockoutCount = attempts['lockoutCount'] as int? ?? 0;
      lastAttemptTime = DateTime.parse(attempts['lastAttemptTime'] as String);

      // Check if lockout period has expired
      final effectiveLockoutMinutes = _loginLockoutMinutes *
          (lockoutCount > 0 ? _progressiveLockoutMultiplier.clamp(1, 8) : 1);
      final lockoutEnd =
          lastAttemptTime.add(Duration(minutes: effectiveLockoutMinutes));
      if (DateTime.now().isAfter(lockoutEnd)) {
        attemptCount = 1;
        lockoutCount = 0;
      }
    }

    // Increment lockout count if max attempts reached
    if (attemptCount >= _maxLoginAttempts) {
      lockoutCount++;
    }

    _box.write(_loginAttemptsKey, {
      'attemptCount': attemptCount,
      'lockoutCount': lockoutCount,
      'lastAttemptTime': DateTime.now().toIso8601String(),
    });
  }

  /// Get current failed attempt count
  int getLoginAttemptCount() {
    final attempts = _box.read<Map<String, dynamic>>(_loginAttemptsKey);
    if (attempts == null) return 0;
    return attempts['attemptCount'] as int;
  }

  /// Get remaining login attempts before lockout
  int getRemainingLoginAttempts() {
    return (_maxLoginAttempts - getLoginAttemptCount())
        .clamp(0, _maxLoginAttempts);
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
  // ACCOUNT CREATION RATE LIMITING METHODS
  // ============================================================

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
        _resetAccountCreationAttempts();
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

  /// Reset account creation attempts
  void _resetAccountCreationAttempts() {
    _box.remove(_accountCreationKey);
  }

  /// Called after successful account creation
  void onSuccessfulAccountCreation() {
    _resetAccountCreationAttempts();
  }

  /// Check if email has too many registrations
  bool isEmailRegistrationRateLimited(String email) {
    final key = _emailRegistrationKey + _hashEmail(email);
    final attempts = _box.read<Map<String, dynamic>>(key);
    if (attempts == null) return false;

    final lastAttemptTime =
        DateTime.parse(attempts['lastAttemptTime'] as String);
    final attemptCount = attempts['attemptCount'] as int;

    // Check if within window period
    final windowEnd =
        lastAttemptTime.add(Duration(hours: _emailRegistrationWindowHours));
    if (DateTime.now().isAfter(windowEnd)) {
      _box.remove(key);
      return false;
    }

    return attemptCount >= _maxRegistrationsPerEmail;
  }

  /// Record email registration attempt
  void recordEmailRegistrationAttempt(String email) {
    final key = _emailRegistrationKey + _hashEmail(email);
    final attempts = _box.read<Map<String, dynamic>>(key);
    int attemptCount = 1;

    if (attempts != null) {
      attemptCount = (attempts['attemptCount'] as int) + 1;
    }

    _box.write(key, {
      'attemptCount': attemptCount,
      'lastAttemptTime': DateTime.now().toIso8601String(),
    });
  }

  String _hashEmail(String email) {
    final bytes = utf8.encode(email.toLowerCase());
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  // ============================================================
  // API RATE LIMITING METHODS
  // ============================================================

  /// Check if API requests are rate limited
  bool isAPIRateLimited() {
    final timestamps = _getApiRequestTimestamps();
    final now = DateTime.now();

    // Clean old timestamps
    final recentTimestamps = timestamps
        .where((t) => t.isAfter(now.subtract(const Duration(minutes: 1))))
        .toList();

    return recentTimestamps.length >= _maxApiRequestsPerMinute;
  }

  /// Check if API burst limit is exceeded
  bool isAPIBurstLimited() {
    final timestamps = _getApiRequestTimestamps();
    final now = DateTime.now();

    // Check burst window (last 5 seconds)
    final burstTimestamps = timestamps
        .where((t) => t.isAfter(now.subtract(const Duration(seconds: 5))))
        .toList();

    return burstTimestamps.length >= _apiBurstLimit;
  }

  /// Record an API request
  void recordAPIRequest() {
    final timestamps = _getApiRequestTimestamps();
    timestamps.add(DateTime.now());

    // Keep only last hour of timestamps
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
    final timestamps = _getApiRequestTimestamps();
    final now = DateTime.now();

    final recentTimestamps = timestamps
        .where((t) => t.isAfter(now.subtract(const Duration(minutes: 1))))
        .toList();

    return (_maxApiRequestsPerMinute - recentTimestamps.length)
        .clamp(0, _maxApiRequestsPerMinute);
  }

  /// Get API requests remaining in current hour
  int getRemainingAPIRequestsPerHour() {
    final timestamps = _getApiRequestTimestamps();
    final now = DateTime.now();

    final recentTimestamps = timestamps
        .where((t) => t.isAfter(now.subtract(const Duration(hours: 1))))
        .toList();

    return (_maxApiRequestsPerHour - recentTimestamps.length)
        .clamp(0, _maxApiRequestsPerHour);
  }

  /// Check hourly API limit
  bool isAPIHourlyRateLimited() {
    final timestamps = _getApiRequestTimestamps();
    final now = DateTime.now();

    final recentTimestamps = timestamps
        .where((t) => t.isAfter(now.subtract(const Duration(hours: 1))))
        .toList();

    return recentTimestamps.length >= _maxApiRequestsPerHour;
  }

  // ============================================================
  // AI GENERATION REQUEST RATE LIMITING METHODS
  // ============================================================

  /// Check if AI requests are rate limited
  bool isAIRateLimited() {
    final attempts = _box.read<Map<String, dynamic>>(_aiRequestKey);
    if (attempts == null) return false;

    final lastAttemptTime =
        DateTime.parse(attempts['lastAttemptTime'] as String);
    final hourlyCount = attempts['hourlyCount'] as int;

    // Check hourly limit
    if (hourlyCount >= _maxAIRequestsPerHour) {
      final lockoutEnd =
          lastAttemptTime.add(const Duration(minutes: _aiLockoutMinutes));
      if (DateTime.now().isBefore(lockoutEnd)) {
        return true;
      } else {
        // Reset hourly count if lockout expired
        _resetAIHourlyCount();
        return false;
      }
    }

    return false;
  }

  /// Check if OCR requests are rate limited
  bool isOCRRateLimited() {
    final attempts = _box.read<Map<String, dynamic>>(_ocrRequestKey);
    if (attempts == null) return false;

    final lastAttemptTime =
        DateTime.parse(attempts['lastAttemptTime'] as String);
    final hourlyCount = attempts['hourlyCount'] as int;

    // Check hourly limit
    if (hourlyCount >= _maxOCRRequestsPerHour) {
      final lockoutEnd =
          lastAttemptTime.add(const Duration(minutes: _aiLockoutMinutes));
      if (DateTime.now().isBefore(lockoutEnd)) {
        return true;
      } else {
        _resetOCRHourlyCount();
        return false;
      }
    }

    return false;
  }

  /// Get AI request remaining seconds
  int getAIRemainingLockoutSeconds() {
    final attempts = _box.read<Map<String, dynamic>>(_aiRequestKey);
    if (attempts == null) return 0;

    final lastAttemptTime =
        DateTime.parse(attempts['lastAttemptTime'] as String);
    final lockoutEnd =
        lastAttemptTime.add(const Duration(minutes: _aiLockoutMinutes));
    final remaining = lockoutEnd.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// Get OCR remaining lockout seconds
  int getOCRRemainingLockoutSeconds() {
    final attempts = _box.read<Map<String, dynamic>>(_ocrRequestKey);
    if (attempts == null) return 0;

    final lastAttemptTime =
        DateTime.parse(attempts['lastAttemptTime'] as String);
    final lockoutEnd =
        lastAttemptTime.add(const Duration(minutes: _aiLockoutMinutes));
    final remaining = lockoutEnd.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// Record an AI request
  void recordAIRequest() {
    _recordAIOrOCRRequest(
        _aiRequestKey, _maxAIRequestsPerHour, _maxAIRequestsPerDay);
  }

  /// Record an OCR request
  void recordOCRRequest() {
    _recordAIOrOCRRequest(
        _ocrRequestKey, _maxOCRRequestsPerHour, _maxOCRRequestsPerDay);
  }

  void _recordAIOrOCRRequest(String key, int maxHourly, int maxDaily) {
    final attempts = _box.read<Map<String, dynamic>>(key);
    int hourlyCount = 1;
    int dailyCount = 1;
    DateTime? hourlyResetTime;
    DateTime? dailyResetTime;

    if (attempts != null) {
      hourlyCount = (attempts['hourlyCount'] as int) + 1;
      dailyCount = (attempts['dailyCount'] as int) + 1;
      hourlyResetTime = attempts['hourlyResetTime'] != null
          ? DateTime.parse(attempts['hourlyResetTime'] as String)
          : null;
      dailyResetTime = attempts['dailyResetTime'] != null
          ? DateTime.parse(attempts['dailyResetTime'] as String)
          : null;
    }

    final now = DateTime.now();

    // Reset hourly count if hour has passed
    if (hourlyResetTime == null || now.isAfter(hourlyResetTime)) {
      hourlyCount = 1;
      hourlyResetTime = now.add(const Duration(hours: 1));
    }

    // Reset daily count if day has passed
    if (dailyResetTime == null || now.isAfter(dailyResetTime)) {
      dailyCount = 1;
      dailyResetTime = now.add(const Duration(days: 1));
    }

    _box.write(key, {
      'hourlyCount': hourlyCount,
      'dailyCount': dailyCount,
      'lastAttemptTime': now.toIso8601String(),
      'hourlyResetTime': hourlyResetTime.toIso8601String(),
      'dailyResetTime': dailyResetTime.toIso8601String(),
    });
  }

  void _resetAIHourlyCount() {
    final attempts = _box.read<Map<String, dynamic>>(_aiRequestKey);
    if (attempts != null) {
      _box.write(_aiRequestKey, {
        'hourlyCount': 0,
        'dailyCount': attempts['dailyCount'] ?? 0,
        'lastAttemptTime': DateTime.now().toIso8601String(),
        'hourlyResetTime':
            DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
        'dailyResetTime': attempts['dailyResetTime'],
      });
    }
  }

  void _resetOCRHourlyCount() {
    final attempts = _box.read<Map<String, dynamic>>(_ocrRequestKey);
    if (attempts != null) {
      _box.write(_ocrRequestKey, {
        'hourlyCount': 0,
        'dailyCount': attempts['dailyCount'] ?? 0,
        'lastAttemptTime': DateTime.now().toIso8601String(),
        'hourlyResetTime':
            DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
        'dailyResetTime': attempts['dailyResetTime'],
      });
    }
  }

  /// Get remaining AI requests
  int getRemainingAIRequests() {
    final attempts = _box.read<Map<String, dynamic>>(_aiRequestKey);
    if (attempts == null) return _maxAIRequestsPerHour;

    final hourlyCount = attempts['hourlyCount'] as int;
    return (_maxAIRequestsPerHour - hourlyCount)
        .clamp(0, _maxAIRequestsPerHour);
  }

  /// Get remaining OCR requests
  int getRemainingOCRRequests() {
    final attempts = _box.read<Map<String, dynamic>>(_ocrRequestKey);
    if (attempts == null) return _maxOCRRequestsPerHour;

    final hourlyCount = attempts['hourlyCount'] as int;
    return (_maxOCRRequestsPerHour - hourlyCount)
        .clamp(0, _maxOCRRequestsPerHour);
  }

  // ============================================================
  // BOT DETECTION METHODS
  // ============================================================

  /// Check if suspicious activity is detected
  bool isSuspiciousActivityDetected() {
    final detection = _box.read<Map<String, dynamic>>(_botDetectionKey);
    if (detection == null) return false;

    final lastActivityTime =
        DateTime.parse(detection['lastActivityTime'] as String);
    final suspiciousCount = detection['suspiciousCount'] as int;

    // Check if within suspicion window
    final windowEnd =
        lastActivityTime.add(Duration(minutes: _botSuspicionWindowMinutes));
    if (DateTime.now().isAfter(windowEnd)) {
      _resetBotDetection();
      return false;
    }

    return suspiciousCount >= _maxSuspiciousActions;
  }

  /// Record suspicious activity
  void recordSuspiciousActivity(String activityType) {
    final detection = _box.read<Map<String, dynamic>>(_botDetectionKey);
    int suspiciousCount = 1;
    DateTime lastActivityTime = DateTime.now();

    if (detection != null) {
      final lastActivityTimeParsed =
          DateTime.parse(detection['lastActivityTime'] as String);
      final windowEnd = lastActivityTimeParsed
          .add(Duration(minutes: _botSuspicionWindowMinutes));

      if (DateTime.now().isBefore(windowEnd)) {
        suspiciousCount = (detection['suspiciousCount'] as int) + 1;
      }
      lastActivityTime = lastActivityTimeParsed;
    }

    _box.write(_botDetectionKey, {
      'suspiciousCount': suspiciousCount,
      'lastActivityTime': lastActivityTime.toIso8601String(),
      'lastActivityType': activityType,
    });
  }

  /// Get remaining suspicious actions allowed
  int getRemainingSuspiciousActions() {
    final detection = _box.read<Map<String, dynamic>>(_botDetectionKey);
    if (detection == null) return _maxSuspiciousActions;

    final lastActivityTime =
        DateTime.parse(detection['lastActivityTime'] as String);
    final windowEnd =
        lastActivityTime.add(Duration(minutes: _botSuspicionWindowMinutes));

    if (DateTime.now().isAfter(windowEnd)) {
      return _maxSuspiciousActions;
    }

    final suspiciousCount = detection['suspiciousCount'] as int;
    return (_maxSuspiciousActions - suspiciousCount)
        .clamp(0, _maxSuspiciousActions);
  }

  void _resetBotDetection() {
    _box.remove(_botDetectionKey);
  }

  /// Generate a simple device fingerprint hash
  String generateDeviceFingerprint(String userAgent, String? userId) {
    final input = '$userAgent-$userId-${DateTime.now().day}';
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  // ============================================================
  // DATA SCRAPING PROTECTION METHODS
  // ============================================================

  /// Check if bulk data access is rate limited
  bool isBulkAccessRateLimited() {
    final timestamps = _getBulkAccessTimestamps();
    final now = DateTime.now();

    final recentTimestamps = timestamps
        .where((t) => t.isAfter(
            now.subtract(const Duration(minutes: _bulkRequestWindowMinutes))))
        .toList();

    return recentTimestamps.length >= _maxBulkRequests;
  }

  /// Record bulk data access
  void recordBulkDataAccess() {
    final timestamps = _getBulkAccessTimestamps();
    timestamps.add(DateTime.now());

    // Keep only recent timestamps
    final cutoff = DateTime.now()
        .subtract(const Duration(minutes: _bulkRequestWindowMinutes * 2));
    final recentTimestamps =
        timestamps.where((t) => t.isAfter(cutoff)).toList();

    _box.write(_bulkAccessTimestampsKey,
        recentTimestamps.map((t) => t.toIso8601String()).toList());
  }

  List<DateTime> _getBulkAccessTimestamps() {
    final timestamps = _box.read<List<dynamic>>(_bulkAccessTimestampsKey);
    if (timestamps == null) return [];
    return timestamps.map((t) => DateTime.parse(t as String)).toList();
  }

  /// Get remaining bulk requests
  int getRemainingBulkRequests() {
    final timestamps = _getBulkAccessTimestamps();
    final now = DateTime.now();

    final recentTimestamps = timestamps
        .where((t) => t.isAfter(
            now.subtract(const Duration(minutes: _bulkRequestWindowMinutes))))
        .toList();

    return (_maxBulkRequests - recentTimestamps.length)
        .clamp(0, _maxBulkRequests);
  }

  // ============================================================
  // SESSION MANAGEMENT METHODS
  // ============================================================

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
  // PASSWORD RESET METHODS
  // ============================================================

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
  // UTILITY METHODS
  // ============================================================

  /// Generate a secure hash for verification purposes
  /// This is used for secure token generation, NOT for password hashing
  /// Password hashing is handled by Firebase Auth
  String generateSecureHash(String input) {
    final bytes = utf8.encode(input + DateTime.now().toIso8601String());
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Check if email verification is required
  /// Returns true if user needs to verify email
  Future<bool> isEmailVerificationRequired() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    // Reload user to get latest verification status
    await user.reload();
    final currentUser = FirebaseAuth.instance.currentUser;

    // Return true if email is not verified
    return currentUser?.emailVerified ?? true;
  }

  /// Clear all security-related storage (for logout)
  void clearSecurityStorage() {
    endSession();
    _resetPasswordResetAttempts();
    _resetBotDetection();
    _box.remove(_apiRequestTimestampsKey);
    _box.remove(_bulkAccessTimestampsKey);
  }

  /// Get comprehensive rate limit status for UI display
  Map<String, dynamic> getRateLimitStatus() {
    return {
      'login': {
        'isLimited': isLoginRateLimited(),
        'remainingAttempts': getRemainingLoginAttempts(),
        'remainingSeconds': getLoginRemainingLockoutSeconds(),
      },
      'accountCreation': {
        'isLimited': isAccountCreationRateLimited(),
        'remainingSeconds': getAccountCreationRemainingSeconds(),
      },
      'api': {
        'isLimited': isAPIRateLimited(),
        'isBurstLimited': isAPIBurstLimited(),
        'isHourlyLimited': isAPIHourlyRateLimited(),
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
