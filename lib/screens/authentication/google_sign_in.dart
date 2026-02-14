import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mds/utils/loading_utils.dart';
import 'package:mds/screens/authentication/auth_page.dart';
import 'package:get/get.dart';

class GoogleSignInProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
    signInOption: SignInOption.standard,
  );

  bool _isSigningIn = false;
  User? _currentUser;
  String? _errorMessage;

  GoogleSignInProvider() {
    _init();
  }

  bool get isSigningIn => _isSigningIn;
  User? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;

  Future<void> _init() async {
    _auth.authStateChanges().listen((User? user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  Future<UserCredential?> signInWithGoogle(BuildContext context) async {
    if (_isSigningIn) return null;

    _isSigningIn = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Force account selection
      await _googleSignIn.signOut();

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        _errorMessage = 'Sign in was cancelled';
        if (context.mounted) {
          _showSnackBar(context, _errorMessage!, Colors.orange);
        }
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      final User? user = userCredential.user;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        // Initialize or update user data in Firestore
        final userData = {
          'name': user.displayName ?? '',
          'email': user.email ?? '',
          'photoURL': user.photoURL ?? '',
        };

        if (userDoc.exists) {
          // We don't auto-set schoolId here anymore to ensure role-based logic in AuthPage/RoleSelection
        }

        if (!userDoc.exists || userDoc.data()?['registrationDate'] == null) {
          userData['registrationDate'] = DateTime.now().toIso8601String();
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(userData, SetOptions(merge: true));
      }

      if (context.mounted) {
        _showSnackBar(
          context,
          'Successfully signed in as ${userCredential.user?.email}',
          Colors.green,
        );
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getErrorMessage(e);
      if (context.mounted) {
        _showSnackBar(context, _errorMessage!, Colors.red);
      }
      return null;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      if (context.mounted) {
        _showSnackBar(context, _errorMessage!, Colors.red);
      }
      return null;
    } finally {
      _isSigningIn = false;
      notifyListeners();
    }
  }

  Future<void> signOut(BuildContext context) async {
    try {
      // Use LoadingUtils to show a non-dismissible dialog
      await LoadingUtils.wrapWithLoading(
        context,
        () async {
          await Future.wait([
            _auth.signOut(),
            _googleSignIn.signOut(),
          ]);
          _currentUser = null;
          notifyListeners();

          // Clear navigation stack and go to AuthPage
          Get.offAll(() => const AuthPage());
        },
        message: 'Logging out...',
      );
    } catch (e) {
      _errorMessage = 'Error signing out';
      notifyListeners();
      if (context.mounted) {
        _showSnackBar(context, _errorMessage!, Colors.red);
      }
    }
  }

  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email address but different sign-in credentials.';
      case 'invalid-credential':
        return 'The credential is invalid or has expired.';
      case 'operation-not-allowed':
        return 'Google sign in is not enabled. Please contact support.';
      case 'user-disabled':
        return 'This user has been disabled. Please contact support.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-verification-code':
        return 'The verification code is invalid.';
      case 'invalid-verification-id':
        return 'The verification ID is invalid.';
      case 'network-request-failed':
        return 'A network error occurred. Please check your connection.';
      default:
        return e.message ?? 'An error occurred during sign in.';
    }
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
