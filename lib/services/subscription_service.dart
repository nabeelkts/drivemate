import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check subscription status and return remaining days
  Future<Map<String, dynamic>> checkSubscription(String schoolId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(schoolId).get();

      if (!userDoc.exists) {
        return {
          'status': 'Trial',
          'daysLeft': 0,
          'expiry': null,
          'error': 'User not found'
        };
      }

      final data = userDoc.data()!;
      final status = data['subscriptionStatus'] as String?;
      final expiryTimestamp = data['subscriptionExpiry'] as Timestamp?;

      // If no subscription data, initialize trial
      if (status == null || expiryTimestamp == null) {
        return await initializeTrial(schoolId);
      }

      final expiry = expiryTimestamp.toDate();
      final now = DateTime.now();
      final difference = expiry.difference(now);
      final daysLeft = difference.inDays;

      // Grace period is 7 days after expiry
      final bool isExpired = daysLeft < 0; // Negative means it PASSED expiry
      final bool isInGracePeriod = isExpired && daysLeft >= -7;
      final bool isGracePeriodExpired = daysLeft < -7;
      final bool shouldWarn = !isExpired && daysLeft <= 7;

      return {
        'status': status,
        'daysLeft': daysLeft, // Can be negative now
        'expiry': expiry,
        'isExpired': isExpired,
        'isInGracePeriod': isInGracePeriod,
        'isGracePeriodExpired': isGracePeriodExpired,
        'shouldWarn': shouldWarn,
      };
    } catch (e) {
      print('Error checking subscription: $e');
      return {
        'status': 'Trial',
        'daysLeft': 0,
        'expiry': null,
        'error': e.toString()
      };
    }
  }

  /// Initialize 3-month trial for a workspace
  Future<Map<String, dynamic>> initializeTrial(String schoolId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(schoolId).get();

      if (!userDoc.exists) {
        return {
          'status': 'Trial',
          'daysLeft': 0,
          'expiry': null,
          'error': 'User not found'
        };
      }

      final data = userDoc.data()!;
      final registrationDate = data['registrationDate'] as String?;

      DateTime trialStart;
      if (registrationDate != null) {
        trialStart = DateTime.tryParse(registrationDate) ?? DateTime.now();
      } else {
        trialStart = DateTime.now();
      }

      final trialExpiry = trialStart.add(const Duration(days: 90)); // 3 months

      final updateData = {
        'subscriptionStatus': 'Trial',
        'subscriptionExpiry': Timestamp.fromDate(trialExpiry),
      };

      if (registrationDate == null) {
        updateData['registrationDate'] = DateTime.now().toIso8601String();
      }

      await _firestore.collection('users').doc(schoolId).update(updateData);

      final daysLeft = trialExpiry.difference(DateTime.now()).inDays;

      return {
        'status': 'Trial',
        'daysLeft': daysLeft > 0 ? daysLeft : 0,
        'expiry': trialExpiry,
        'isExpired': daysLeft <= 0,
      };
    } catch (e) {
      print('Error initializing trial: $e');
      return {
        'status': 'Trial',
        'daysLeft': 0,
        'expiry': null,
        'error': e.toString()
      };
    }
  }

  /// Redeem a subscription code for a workspace
  Future<Map<String, dynamic>> redeemCode(String schoolId, String code,
      {String? redeemerUid}) async {
    try {
      // Validate code format (16 alphanumeric characters)
      if (code.length != 16 ||
          !RegExp(r'^[A-Z0-9]+$').hasMatch(code.toUpperCase())) {
        return {
          'success': false,
          'message':
              'Invalid code format. Code must be 16 alphanumeric characters.'
        };
      }

      final codeDoc = await _firestore
          .collection('subscription_codes')
          .doc(code.toUpperCase())
          .get();

      if (!codeDoc.exists) {
        return {
          'success': false,
          'message': 'Invalid code. This code does not exist.'
        };
      }

      final codeData = codeDoc.data()!;
      final isUsed = codeData['isUsed'] as bool? ?? false;

      if (isUsed) {
        return {
          'success': false,
          'message': 'This code has already been used.'
        };
      }

      final durationDays = codeData['durationDays'] as int? ?? 365;
      final newExpiry = DateTime.now().add(Duration(days: durationDays));

      // Update workspace subscription
      await _firestore.collection('users').doc(schoolId).update({
        'subscriptionStatus': 'Premium',
        'subscriptionExpiry': Timestamp.fromDate(newExpiry),
        'usedSubscriptionCode': code, // Store the code used
        'lastRedeemedBy': redeemerUid,
      });

      // Mark code as used
      await _firestore
          .collection('subscription_codes')
          .doc(code.toUpperCase())
          .update({
        'isUsed': true,
        'usedBy': redeemerUid ?? schoolId,
        'schoolId': schoolId, // Record which school used it
        'usedAt': Timestamp.now(),
      });

      return {
        'success': true,
        'message': 'Premium subscription activated successfully!',
        'expiry': newExpiry,
        'daysAdded': durationDays,
      };
    } catch (e) {
      print('Error redeeming code: $e');
      return {
        'success': false,
        'message': 'An error occurred while redeeming the code: ${e.toString()}'
      };
    }
  }

  /// Generate a random 16-character alphanumeric code
  String generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(16, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  /// Create a new subscription code in Firestore
  Future<Map<String, dynamic>> createCode({int durationDays = 365}) async {
    try {
      String code;
      bool codeExists = true;

      // Generate unique code
      while (codeExists) {
        code = generateCode();
        final doc =
            await _firestore.collection('subscription_codes').doc(code).get();
        codeExists = doc.exists;
      }

      final newCode = generateCode();

      await _firestore.collection('subscription_codes').doc(newCode).set({
        'code': newCode,
        'durationDays': durationDays,
        'isUsed': false,
        'createdAt': Timestamp.now(),
      });

      return {
        'success': true,
        'code': newCode,
        'durationDays': durationDays,
      };
    } catch (e) {
      print('Error creating code: $e');
      return {
        'success': false,
        'message': 'Failed to create code: ${e.toString()}'
      };
    }
  }

  /// Get all subscription codes (for admin view)
  Stream<List<Map<String, dynamic>>> getAllCodes() {
    return _firestore
        .collection('subscription_codes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'code': data['code'] ?? doc.id,
          'durationDays': data['durationDays'] ?? 365,
          'isUsed': data['isUsed'] ?? false,
          'usedBy': data['usedBy'],
          'usedAt': data['usedAt'],
          'createdAt': data['createdAt'],
        };
      }).toList();
    });
  }

  /// Get all users with subscription details (for admin view)
  Stream<List<Map<String, dynamic>>> getAllUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      final users = snapshot.docs.map((doc) {
        final data = doc.data();
        final expiryTimestamp = data['subscriptionExpiry'] as Timestamp?;
        final expiry = expiryTimestamp?.toDate();
        final daysLeft =
            expiry != null ? expiry.difference(DateTime.now()).inDays : 0;

        // Robust name fetching: name > displayName > companyName > email
        String displayName = data['name'] ?? data['displayName'] ?? '';
        if (displayName.isEmpty &&
            data['companyName'] != null &&
            data['companyName'] != 'N/A') {
          displayName = data['companyName'];
        }
        if (displayName.isEmpty) {
          displayName = data['email'] ?? 'User';
        }

        // Robust email fetching: email > userEmail > docID as fallback
        String userEmail = data['email'] ?? data['userEmail'] ?? 'N/A';

        return {
          'uid': doc.id,
          'schoolId': data['schoolId'] ?? doc.id,
          'role': data['role'] ?? 'Owner',
          'name': displayName,
          'photoURL': data['photoURL'] ??
              data['photoUrl'] ??
              data['userPhoto'] ??
              data['photoURL'] ?? // Repeated for safety
              '',
          'companyLogo': data['companyLogo'] ?? '',
          'companyName':
              (data['companyName'] != null && data['companyName'] != 'N/A')
                  ? data['companyName']
                  : 'N/A',
          'companyPhone': data['companyPhone'] ?? 'N/A',
          'companyAddress': data['companyAddress'] ?? 'N/A',
          'email': userEmail,
          'subscriptionStatus': data['subscriptionStatus'] ?? 'Trial',
          'subscriptionExpiry': expiry,
          'daysLeft': daysLeft,
          'isExpired': daysLeft <= 0,
          'registrationDate': data['registrationDate'],
          'usedCode': data['usedSubscriptionCode'] ?? 'N/A',
        };
      }).toList();

      // Sort by registration date if available, otherwise by company name
      users.sort((a, b) {
        final aDate = a['registrationDate'];
        final bDate = b['registrationDate'];
        if (aDate != null && bDate != null) {
          return bDate.toString().compareTo(aDate.toString());
        }
        return (a['companyName'] as String)
            .compareTo(b['companyName'] as String);
      });

      return users;
    });
  }

  /// Update workspace's trial period (add days to current expiry)
  Future<Map<String, dynamic>> updateTrialPeriod(
      String schoolId, int daysToAdd) async {
    try {
      final userDoc = await _firestore.collection('users').doc(schoolId).get();

      if (!userDoc.exists) {
        return {'success': false, 'message': 'User not found'};
      }

      final data = userDoc.data()!;
      final currentExpiry =
          (data['subscriptionExpiry'] as Timestamp?)?.toDate() ??
              DateTime.now();
      final newExpiry = currentExpiry.add(Duration(days: daysToAdd));

      await _firestore.collection('users').doc(schoolId).update({
        'subscriptionExpiry': Timestamp.fromDate(newExpiry),
      });

      return {
        'success': true,
        'message': 'Trial period extended by $daysToAdd days',
        'newExpiry': newExpiry,
      };
    } catch (e) {
      print('Error updating trial period: $e');
      return {
        'success': false,
        'message': 'Failed to update trial: ${e.toString()}'
      };
    }
  }

  /// Grant Premium subscription to a workspace
  Future<Map<String, dynamic>> grantPremium(
      String schoolId, int durationDays) async {
    try {
      final newExpiry = DateTime.now().add(Duration(days: durationDays));

      await _firestore.collection('users').doc(schoolId).update({
        'subscriptionStatus': 'Premium',
        'subscriptionExpiry': Timestamp.fromDate(newExpiry),
      });

      return {
        'success': true,
        'message': 'Premium subscription granted for $durationDays days',
        'newExpiry': newExpiry,
      };
    } catch (e) {
      print('Error granting premium: $e');
      return {
        'success': false,
        'message': 'Failed to grant premium: ${e.toString()}'
      };
    }
  }

  /// Revoke workspace's subscription (set to expired)
  Future<Map<String, dynamic>> revokeSubscription(String schoolId) async {
    try {
      final pastDate = DateTime.now().subtract(const Duration(days: 1));

      await _firestore.collection('users').doc(schoolId).update({
        'subscriptionStatus': 'Trial',
        'subscriptionExpiry': Timestamp.fromDate(pastDate),
      });

      return {
        'success': true,
        'message': 'Subscription revoked successfully',
      };
    } catch (e) {
      print('Error revoking subscription: $e');
      return {
        'success': false,
        'message': 'Failed to revoke subscription: ${e.toString()}'
      };
    }
  }

  // / Update user metadata (name, email)
  Future<Map<String, dynamic>> updateUserDetails(
      String uid, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .set(data, SetOptions(merge: true));
      return {'success': true, 'message': 'User profile updated successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to update user: $e'};
    }
  }

  /// Delete a subscription code
  Future<Map<String, dynamic>> deleteCode(String code) async {
    try {
      // Find the document with this code
      final querySnapshot = await _firestore
          .collection('subscription_codes')
          .where('code', isEqualTo: code)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return {'success': false, 'message': 'Code not found'};
      }

      // Delete the document
      await querySnapshot.docs.first.reference.delete();

      return {
        'success': true,
        'message': 'Code deleted successfully',
      };
    } catch (e) {
      print('Error deleting code: $e');
      return {
        'success': false,
        'message': 'Failed to delete code: ${e.toString()}'
      };
    }
  }
}
