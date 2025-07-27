library default_connector;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DefaultConnector {
  // Private constructor
  DefaultConnector._internal();

  static final DefaultConnector _instance = DefaultConnector._internal();

  // Singleton getter
  static DefaultConnector get instance => _instance;

  // Lazy initialize Firebase (optional), call this once at app start
  static Future<void> initialize() async {
    await Firebase.initializeApp();
  }

  // Firebase Auth instance
  FirebaseAuth get auth => FirebaseAuth.instance;

  // Firestore instance
  FirebaseFirestore get firestore => FirebaseFirestore.instance;

  // Example: sign-in with email and password
  Future<User?> signIn(String email, String password) async {
    try {
      final credentials = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credentials.user;
    } on FirebaseAuthException catch (e) {
      // Handle errors as needed, here we rethrow
      throw e;
    }
  }

  // Example: sign out
  Future<void> signOut() => auth.signOut();

  // You can add more Firebase service wrappers here as needed
}
