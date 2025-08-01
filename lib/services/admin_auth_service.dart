import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> loginAdmin(
      String email, String password) async {
    try {
      // First, check if user exists in staff_state collection
      final QuerySnapshot staffQuery = await _firestore
          .collection('staff_state')
          .where('email', isEqualTo: email)
          .get();

      if (staffQuery.docs.isEmpty) {
        return {
          'success': false,
          'error': 'No staff member found with this email.',
        };
      }

      final DocumentSnapshot staffDoc = staffQuery.docs.first;
      final data = staffDoc.data() as Map<String, dynamic>;

      // Check if staff member is active
      if (data['status'] != 'Active') {
        return {
          'success': false,
          'error':
              'Your account is inactive. Please contact system administrator.',
        };
      }

      // Check if this is first time login (Firebase Auth not created yet)
      if (data['firebase_auth_created'] != true) {
        // Verify the stored password
        if (data['password'] != password) {
          return {
            'success': false,
            'error': 'Incorrect password.',
          };
        }

        try {
          // Create Firebase Auth account for first-time login
          final UserCredential userCredential =
              await _auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );

          // Update the document ID to match Firebase Auth UID and mark as created
          await _firestore
              .collection('staff_state')
              .doc(userCredential.user!.uid)
              .set({
            ...data,
            'firebase_auth_created': true,
            'first_login_at': FieldValue.serverTimestamp(),
            'user_id': userCredential.user!.uid,
          });

          // Delete the old document if it has a different ID
          if (staffDoc.id != userCredential.user!.uid) {
            await _firestore
                .collection('staff_state')
                .doc(staffDoc.id)
                .delete();
          }

          return {
            'success': true,
            'data': data,
            'uid': userCredential.user!.uid,
            'first_login': true,
          };
        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            // If email already exists in Firebase Auth, try to sign in normally
            return await _signInExistingUser(email, password, data);
          } else {
            return {
              'success': false,
              'error': 'Failed to create account: ${e.message}',
            };
          }
        }
      } else {
        // Firebase Auth account already exists, sign in normally
        return await _signInExistingUser(email, password, data);
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'An unexpected error occurred: $e',
      };
    }
  }

  Future<Map<String, dynamic>?> _signInExistingUser(
      String email, String password, Map<String, dynamic> staffData) async {
    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Verify user still exists in staff_state collection with correct UID
      final DocumentSnapshot staffDoc = await _firestore
          .collection('staff_state')
          .doc(userCredential.user!.uid)
          .get();

      if (staffDoc.exists) {
        final data = staffDoc.data() as Map<String, dynamic>;
        if (data['status'] == 'Active') {
          return {
            'success': true,
            'data': data,
            'uid': userCredential.user!.uid,
          };
        } else {
          await _auth.signOut();
          return {
            'success': false,
            'error':
                'Your account is inactive. Please contact system administrator.',
          };
        }
      } else {
        await _auth.signOut();
        return {
          'success': false,
          'error': 'Staff data not found. Please contact system administrator.',
        };
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password.';
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
