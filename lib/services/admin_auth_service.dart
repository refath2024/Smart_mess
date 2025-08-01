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

        // First, try to sign in to see if Firebase Auth account already exists
        try {
          final UserCredential userCredential =
              await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );

          // Firebase Auth account exists, update the staff_state document
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
            'first_login': false,
          };
        } on FirebaseAuthException catch (signInError) {
          if (signInError.code == 'user-not-found') {
            // No Firebase Auth account exists, create one
            try {
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
            } on FirebaseAuthException catch (createError) {
              if (createError.code == 'email-already-in-use') {
                return {
                  'success': false,
                  'error':
                      'Email already in use with different password. Please use forgot password to reset.',
                };
              } else {
                return {
                  'success': false,
                  'error': 'Failed to create account: ${createError.message}',
                };
              }
            }
          } else if (signInError.code == 'wrong-password' ||
              signInError.code == 'invalid-credential') {
            // Try to fix the password mismatch by sending reset email
            try {
              await _auth.sendPasswordResetEmail(email: email);

              return {
                'success': false,
                'error':
                    'Password sync issue detected. A password reset email has been sent to $email. Please check your email, reset your password to "${data['password']}" (your database password), then try logging in again.',
              };
            } catch (resetError) {
              return {
                'success': false,
                'error':
                    'Firebase Auth password mismatch detected. Please contact system administrator.',
              };
            }
          } else {
            return {
              'success': false,
              'error': 'Authentication error: ${signInError.message}',
            };
          }
        }
      } else {
        // Firebase Auth account already exists
        // First verify against stored password
        if (data['password'] == password) {
          return await _signInExistingUser(email, password, data);
        } else {
          return {
            'success': false,
            'error': 'Incorrect password.',
          };
        }
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
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return {
          'success': false,
          'error':
              'Firebase Auth password mismatch. Please use the forgot password feature to reset your password.',
        };
      }

      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email.';
          break;
        case 'wrong-password':
        case 'invalid-credential':
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
