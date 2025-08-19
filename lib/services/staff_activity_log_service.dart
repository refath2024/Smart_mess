import 'package:cloud_firestore/cloud_firestore.dart';

class StaffActivityLogService {
  final CollectionReference _activityLogCollection =
      FirebaseFirestore.instance.collection('staff_activity_log');

  Future<void> logActivity({
    required String baNo,
    required String rank,
    required String name,
    required String email,
    required String actionType,
    required String message,
    Map<String, dynamic>? extraData,
  }) async {
    await _activityLogCollection.doc(baNo).collection('logs').add({
      'ba_no': baNo,
      'rank': rank,
      'name': name,
      'email': email,
      'actionType': actionType,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      if (extraData != null) ...extraData,
    });
  }

  Stream<QuerySnapshot> getLogsForStaff(String baNo) {
    return _activityLogCollection
        .doc(baNo)
        .collection('logs')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getAllLogs() {
    return _activityLogCollection.snapshots();
  }
}
