import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    try {
      print('UserAuthService: Attempting login for email: $email');

      // First, check if user exists in user_requests collection
      final QuerySnapshot userQuery = await _firestore
          .collection('user_requests')
          .where('email', isEqualTo: email)
          .get();

      print(
          'UserAuthService: Found ${userQuery.docs.length} documents with email: $email');

      if (userQuery.docs.isEmpty) {
        print('UserAuthService: No user found with email: $email');
        return {
          'success': false,
          'error': 'No user found with this email.',
        };
      }

      final DocumentSnapshot userDoc = userQuery.docs.first;
      final data = userDoc.data() as Map<String, dynamic>;
      final status = data['status']! as String;

      if (status == 'pending') {
        print('UserAuthService: User registration is pending approval');
        return {
          'success': false,
          'error':
              'Your application is pending approval. Please wait for admin approval.',
        };
      } else if (status == 'rejected') {
        print('UserAuthService: User registration has been rejected');
        return {
          'success': false,
          'error': 'Your registration has been rejected. Please contact admin.',
        };
      } else {
        print('UserAuthService: User registration is active');
        final UserCredential userCredential =
            await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        return {
          'success': true,
          'data': data,
          'uid': userCredential.user!.uid,
          'first_login': true,
        };
      }
    } catch (e) {
      print('UserAuthService: Unexpected error: $e');
      return {
        'success': false,
        'error': 'An unexpected error occurred: $e',
      };
    }
  }

  Future<bool> isUserLoggedIn() async {
    final User? user = _auth.currentUser;
    if (user == null) return false;

    try {
      final DocumentSnapshot userDoc =
          await _firestore.collection('user_requests').doc(user.uid).get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        return data['approved'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getCurrentUserData() async {
    final User? user = _auth.currentUser;
    if (user == null) return null;

    try {
      final DocumentSnapshot userDoc =
          await _firestore.collection('user_requests').doc(user.uid).get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        data['uid'] = user.uid;
        return data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> logoutUser() async {
    await _auth.signOut();
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }
}
