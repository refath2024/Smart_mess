import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ActivityLogService {
  static Future<void> log(String action,
      {Map<String, dynamic>? details}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userDoc = await FirebaseFirestore.instance
        .collection('user_requests')
        .doc(user.uid)
        .get();
    if (!userDoc.exists) return;
    final baNo = userDoc.data()!['ba_no']?.toString();
    if (baNo == null) return;
    final logRef = FirebaseFirestore.instance
        .collection('activity_log')
        .doc(baNo)
        .collection('logs');
    await logRef.add({
      'action': action,
      'details': details ?? {},
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
