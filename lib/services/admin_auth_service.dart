import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> loginAdmin(
      String email, String password) async {
    try {
      // First, authenticate with Firebase Auth
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if the user exists in staff_state collection
      final DocumentSnapshot staffDoc = await _firestore
          .collection('staff_state')
          .doc(userCredential.user!.uid)
          .get();

      if (staffDoc.exists) {
        final data = staffDoc.data() as Map<String, dynamic>;

        // Check if the staff member is active
        if (data['status'] == 'Active') {
          return {
            'success': true,
            'data': data,
            'uid': userCredential.user!.uid,
          };
        } else {
          // Sign out if inactive
          await _auth.signOut();
          return {
            'success': false,
            'error':
                'Your account is inactive. Please contact system administrator.',
          };
        }
      } else {
        // Sign out if not a staff member
        await _auth.signOut();
        return {
          'success': false,
          'error': 'You are not authorized to access admin panel.',
        };
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Wrong password provided.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address.';
          break;
        case 'user-disabled':
          errorMessage = 'This user account has been disabled.';
          break;
        default:
          errorMessage = 'Login failed: ${e.message}';
      }
      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'An unexpected error occurred: $e',
      };
    }
  }

  Future<bool> isAdminLoggedIn() async {
    final User? user = _auth.currentUser;
    if (user == null) return false;

    try {
      final DocumentSnapshot staffDoc =
          await _firestore.collection('staff_state').doc(user.uid).get();

      if (staffDoc.exists) {
        final data = staffDoc.data() as Map<String, dynamic>;
        return data['status'] == 'Active';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getCurrentAdminData() async {
    final User? user = _auth.currentUser;
    if (user == null) return null;

    try {
      final DocumentSnapshot staffDoc =
          await _firestore.collection('staff_state').doc(user.uid).get();

      if (staffDoc.exists) {
        final data = staffDoc.data() as Map<String, dynamic>;
        data['uid'] = user.uid;
        return data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> logoutAdmin() async {
    await _auth.signOut();
  }
}
