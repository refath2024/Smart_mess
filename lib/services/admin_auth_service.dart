import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> loginAdmin(
      String email, String password) async {
    try {
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

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        return {'success': false, 'error': 'Invalid email or password'};
      }

      // First, check if user exists in staff_state collection
      final DocumentSnapshot staffDoc = await _firestore
          .collection('staff_state')
          .doc(credential.user!.uid)
          .get();

      if (!staffDoc.exists) {
        return {
          'success': false,
          'error': 'No staff member found with this email.',
        };
      }

      final data = staffDoc.data() as Map<String, dynamic>;

      // Check if staff member is active
      if (data['status'] != 'Active') {
        return {
          'success': false,
          'error':
              'Your account is inactive. Please contact system administrator.',
        };
      }

      return {
        'success': true,
        'message': 'Login successful',
        'data': data, // Return staff data if needed
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
