import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class EmailLinkService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Your Firebase project domain (from firebase_options.dart)
  static const String projectDomain = 'smart-mess-dfe03.firebaseapp.com';

  /// Send email link for authentication
  /// This uses the new Firebase Hosting domain instead of Dynamic Links
  static Future<void> sendSignInLinkToEmail({
    required String email,
    String? androidPackageName,
    bool androidInstallApp = false,
    String? androidMinimumVersion,
  }) async {
    try {
      final actionCodeSettings = ActionCodeSettings(
        // Use Firebase Hosting domain instead of Dynamic Links
        url: 'https://$projectDomain/__/auth/links',
        handleCodeInApp: true,
        androidPackageName: androidPackageName ?? 'com.example.smart_mess',
        androidInstallApp: androidInstallApp,
        androidMinimumVersion: androidMinimumVersion,
        // Set the Firebase Hosting domain as the custom domain
        dynamicLinkDomain: null, // No longer using Dynamic Links
      );

      await _auth.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: actionCodeSettings,
      );

      debugPrint('Email link sent successfully to $email');
    } catch (e) {
      debugPrint('Error sending email link: $e');
      rethrow;
    }
  }

  /// Check if the incoming link is a sign-in link
  static bool isSignInWithEmailLink(String emailLink) {
    return _auth.isSignInWithEmailLink(emailLink);
  }

  /// Complete sign-in with email link
  static Future<UserCredential> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) async {
    try {
      final credential = await _auth.signInWithEmailLink(
        email: email,
        emailLink: emailLink,
      );

      debugPrint('Successfully signed in with email link');
      return credential;
    } catch (e) {
      debugPrint('Error signing in with email link: $e');
      rethrow;
    }
  }

  /// Send password reset email
  /// This also uses the new Firebase Hosting domain
  static Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      final actionCodeSettings = ActionCodeSettings(
        // Use Firebase Hosting domain
        url: 'https://$projectDomain/__/auth/links',
        handleCodeInApp: false,
      );

      await _auth.sendPasswordResetEmail(
        email: email,
        actionCodeSettings: actionCodeSettings,
      );

      debugPrint('Password reset email sent successfully to $email');
    } catch (e) {
      debugPrint('Error sending password reset email: $e');
      rethrow;
    }
  }
}
