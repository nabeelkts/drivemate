import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

/// Audit logging service for security events
/// Tracks login attempts, suspicious activities, and API errors
class AuditLogService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Event types for audit logging
  static const String eventLoginSuccess = 'LOGIN_SUCCESS';
  static const String eventLoginFailed = 'LOGIN_FAILED';
  static const String eventPasswordReset = 'PASSWORD_RESET';
  static const String eventPasswordResetFailed = 'PASSWORD_RESET_FAILED';
  static const String eventLogout = 'LOGOUT';
  static const String eventSessionExpired = 'SESSION_EXPIRED';
  static const String eventRateLimited = 'RATE_LIMITED';
  static const String eventEmailVerified = 'EMAIL_VERIFIED';
  static const String eventUnauthorizedAccess = 'UNAUTHORIZED_ACCESS';
  static const String eventDataAccess = 'DATA_ACCESS';
  static const String eventDataModification = 'DATA_MODIFICATION';
  static const String eventApiError = 'API_ERROR';
  static const String eventSuspiciousActivity = 'SUSPICIOUS_ACTIVITY';

  /// Log an authentication event
  Future<void> logAuthEvent({
    required String eventType,
    String? userId,
    String? email,
    String? ipAddress,
    String? userAgent,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _firestore.collection('audit_logs').add({
        'eventType': eventType,
        'userId': userId,
        'email': email,
        'ipAddress': ipAddress,
        'userAgent': userAgent,
        'metadata': metadata ?? {},
        'timestamp': FieldValue.serverTimestamp(),
        'severity': _getSeverityForEvent(eventType),
      });
    } catch (e) {
      print('Failed to log auth event: $e');
    }
  }

  /// Log a failed login attempt with details
  Future<void> logFailedLogin({
    required String email,
    required String reason,
    String? ipAddress,
  }) async {
    await logAuthEvent(
      eventType: eventLoginFailed,
      email: email,
      ipAddress: ipAddress,
      metadata: {
        'reason': reason,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Log a successful login
  Future<void> logSuccessfulLogin({
    String? userId,
    required String email,
    String? ipAddress,
  }) async {
    await logAuthEvent(
      eventType: eventLoginSuccess,
      userId: userId,
      email: email,
      ipAddress: ipAddress,
      metadata: {
        'loginTime': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Log a password reset request
  Future<void> logPasswordReset({
    required String email,
    bool success = true,
    String? ipAddress,
  }) async {
    await logAuthEvent(
      eventType: success ? eventPasswordReset : eventPasswordResetFailed,
      email: email,
      ipAddress: ipAddress,
      metadata: {
        'success': success,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Log a rate limiting event
  Future<void> logRateLimited({
    String? userId,
    required String email,
    required String action,
    int attemptCount = 0,
  }) async {
    await logAuthEvent(
      eventType: eventRateLimited,
      userId: userId,
      email: email,
      metadata: {
        'action': action,
        'attemptCount': attemptCount,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Log unauthorized access attempt
  Future<void> logUnauthorizedAccess({
    String? userId,
    required String resource,
    String? details,
  }) async {
    await logAuthEvent(
      eventType: eventUnauthorizedAccess,
      userId: userId,
      metadata: {
        'resource': resource,
        'details': details,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Log API errors
  Future<void> logApiError({
    required String endpoint,
    required String error,
    String? userId,
  }) async {
    await logAuthEvent(
      eventType: eventApiError,
      userId: userId,
      metadata: {
        'endpoint': endpoint,
        'error': error,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Log suspicious activity
  Future<void> logSuspiciousActivity({
    String? userId,
    required String description,
    Map<String, dynamic>? details,
  }) async {
    await logAuthEvent(
      eventType: eventSuspiciousActivity,
      userId: userId,
      metadata: {
        'description': description,
        'details': details ?? {},
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Get severity level for event type
  String _getSeverityForEvent(String eventType) {
    switch (eventType) {
      case eventLoginSuccess:
      case eventLogout:
      case eventEmailVerified:
        return 'INFO';
      case eventLoginFailed:
      case eventRateLimited:
        return 'WARNING';
      case eventUnauthorizedAccess:
      case eventSuspiciousActivity:
      case eventApiError:
        return 'ERROR';
      default:
        return 'INFO';
    }
  }

  /// Query recent audit logs (admin function)
  Future<List<Map<String, dynamic>>> getRecentLogs({
    int limit = 50,
    String? eventType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore
          .collection('audit_logs')
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (eventType != null) {
        query = query.where('eventType', isEqualTo: eventType);
      }

      if (startDate != null) {
        query = query.where('timestamp',
            isGreaterThan: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query =
            query.where('timestamp', isLessThan: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Error fetching audit logs: $e');
      return [];
    }
  }

  /// Get failed login attempts for a specific user (for monitoring)
  Future<int> getFailedLoginCount(String userId,
      {Duration duration = const Duration(hours: 24)}) async {
    try {
      final startTime = DateTime.now().subtract(duration);
      final snapshot = await _firestore
          .collection('audit_logs')
          .where('eventType', isEqualTo: eventLoginFailed)
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(startTime))
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }
}
