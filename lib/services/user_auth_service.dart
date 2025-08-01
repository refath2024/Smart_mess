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

      print('UserAuthService: User data found: ${data.keys}');
      print('UserAuthService: Complete user data: $data');
      print(
          'UserAuthService: approved=${data['approved']}, rejected=${data['rejected']}, firebase_auth_created=${data['firebase_auth_created']}');
      print(
          'UserAuthService: stored password="${data['password']}", provided password="$password"');

      // Check if user is approved (following same pattern as admin auth)
      final approved = data['approved'] ?? false;
      final rejected = data['rejected'] ?? false;

      if (rejected == true) {
        print('UserAuthService: User is rejected');
        return {
          'success': false,
          'error': 'Your registration has been rejected. Please contact admin.',
        };
      }

      if (approved != true) {
        print('UserAuthService: User is not approved');
        return {
          'success': false,
          'error':
              'Your application is pending approval. Please wait for admin approval.',
        };
      }

      print('UserAuthService: User is approved, checking auth status');

      // Check if this is first time login (Firebase Auth not created yet)
      if (data['firebase_auth_created'] != true) {
        print('UserAuthService: First time login - verifying stored password');

        // Verify the stored password
        print('UserAuthService: Detailed password comparison:');
        print(
            '  - Stored: "${data['password']}" (type: ${data['password'].runtimeType})');
        print('  - Provided: "$password" (type: ${password.runtimeType})');
        print('  - Are they equal? ${data['password'] == password}');
        print('  - Stored length: ${data['password']?.toString().length}');
        print('  - Provided length: ${password.length}');

        if (data['password'] != password) {
          print('UserAuthService: Password mismatch!');
          return {
            'success': false,
            'error': 'Incorrect password.',
          };
        }

        print(
            'UserAuthService: Password verified, creating Firebase Auth account');

        try {
          // Create Firebase Auth account for first-time login
          final UserCredential userCredential =
              await _auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );

          print(
              'UserAuthService: Firebase Auth account created with UID: ${userCredential.user!.uid}');

          // Update the document ID to match Firebase Auth UID and mark as created
          await _firestore
              .collection('user_requests')
              .doc(userCredential.user!.uid)
              .set({
            ...data,
            'firebase_auth_created': true,
            'first_login_at': FieldValue.serverTimestamp(),
            'user_id': userCredential.user!.uid,
          });

          print('UserAuthService: Updated document with Firebase Auth UID');

          // Delete the old document if it has a different ID
          if (userDoc.id != userCredential.user!.uid) {
            await _firestore
                .collection('user_requests')
                .doc(userDoc.id)
                .delete();
            print(
                'UserAuthService: Deleted old document with ID: ${userDoc.id}');
          }

          return {
            'success': true,
            'data': data,
            'uid': userCredential.user!.uid,
            'first_login': true,
          };
        } on FirebaseAuthException catch (e) {
          print(
              'UserAuthService: Firebase Auth error: ${e.code} - ${e.message}');
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
        print(
            'UserAuthService: Firebase Auth already exists, signing in normally');
        // Firebase Auth account already exists, sign in normally
        return await _signInExistingUser(email, password, data);
      }
    } catch (e) {
      print('UserAuthService: Unexpected error: $e');
      return {
        'success': false,
        'error': 'An unexpected error occurred: $e',
      };
    }
  }

  Future<Map<String, dynamic>?> _signInExistingUser(
      String email, String password, Map<String, dynamic> userData) async {
    try {
      print(
          'UserAuthService: Trying to sign in with existing Firebase Auth account');
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print(
          'UserAuthService: Successfully signed in with UID: ${userCredential.user!.uid}');

      // Check if user document exists with correct UID
      final DocumentSnapshot userDoc = await _firestore
          .collection('user_requests')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists) {
        print('UserAuthService: User document found with matching UID');
        final data = userDoc.data() as Map<String, dynamic>;

        final approved = data['approved'] ?? false;
        final rejected = data['rejected'] ?? false;

        if (rejected == true) {
          await _auth.signOut();
          return {
            'success': false,
            'error':
                'Your registration has been rejected. Please contact admin.',
          };
        }

        if (approved == true) {
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
                'Your application is pending approval. Please wait for admin approval.',
          };
        }
      } else {
        print(
            'UserAuthService: No document found with Firebase Auth UID, need to update document');
        // Document doesn't exist with Firebase Auth UID, we need to create it
        // and remove the old one (this happens when admin created user but Firebase Auth already existed)

        // Find the original document by email to get the data
        final QuerySnapshot userQuery = await _firestore
            .collection('user_requests')
            .where('email', isEqualTo: email)
            .get();

        if (userQuery.docs.isNotEmpty) {
          final DocumentSnapshot originalDoc = userQuery.docs.first;
          final originalData = originalDoc.data() as Map<String, dynamic>;

          print(
              'UserAuthService: Found original document with ID: ${originalDoc.id}');

          // Create new document with Firebase Auth UID
          await _firestore
              .collection('user_requests')
              .doc(userCredential.user!.uid)
              .set({
            ...originalData,
            'firebase_auth_created': true,
            'first_login_at': FieldValue.serverTimestamp(),
            'user_id': userCredential.user!.uid,
          });

          print('UserAuthService: Created new document with Firebase Auth UID');

          // Delete the old document if it has a different ID
          if (originalDoc.id != userCredential.user!.uid) {
            await _firestore
                .collection('user_requests')
                .doc(originalDoc.id)
                .delete();
            print(
                'UserAuthService: Deleted old document with ID: ${originalDoc.id}');
          }

          final approved = originalData['approved'] ?? false;
          final rejected = originalData['rejected'] ?? false;

          if (rejected == true) {
            await _auth.signOut();
            return {
              'success': false,
              'error':
                  'Your registration has been rejected. Please contact admin.',
            };
          }

          if (approved == true) {
            return {
              'success': true,
              'data': originalData,
              'uid': userCredential.user!.uid,
            };
          } else {
            await _auth.signOut();
            return {
              'success': false,
              'error':
                  'Your application is pending approval. Please wait for admin approval.',
            };
          }
        } else {
          await _auth.signOut();
          return {
            'success': false,
            'error':
                'User data not found. Please contact system administrator.',
          };
        }
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
      print('UserAuthService: Firebase Auth sign in error: $errorMessage');
      return {
        'success': false,
        'error': errorMessage,
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
