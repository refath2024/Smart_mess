import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserActivityLogScreen extends StatelessWidget {
  const UserActivityLogScreen({super.key});

  Future<String?> _getBaNo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final userDoc = await FirebaseFirestore.instance
        .collection('user_requests')
        .doc(user.uid)
        .get();
    if (!userDoc.exists) return null;
    return userDoc.data()!['ba_no']?.toString();
  }

  Future<void> _deleteAllLogs(BuildContext context, String baNo) async {
    final logs = await FirebaseFirestore.instance
        .collection('activity_log')
        .doc(baNo)
        .collection('logs')
        .get();
    final batch = FirebaseFirestore.instance.batch();
    for (var doc in logs.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All activity logs deleted.')),
    );
  }

  Future<void> _deleteLog(
      BuildContext context, String baNo, String logId) async {
    await FirebaseFirestore.instance
        .collection('activity_log')
        .doc(baNo)
        .collection('logs')
        .doc(logId)
        .delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Activity log deleted.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getBaNo(),
      builder: (context, baNoSnap) {
        if (baNoSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final baNo = baNoSnap.data;
        if (baNo == null) {
          return const Scaffold(
              body: Center(child: Text('BA number not found.')));
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('Activity Log'),
            backgroundColor: const Color(0xFF002B5B),
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_forever),
                tooltip: 'Delete All Logs',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete All Activity Logs?'),
                      content: const Text(
                          'Are you sure you want to delete all activity logs? This action cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red),
                          child: const Text('Delete All'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await _deleteAllLogs(context, baNo);
                  }
                },
              ),
            ],
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('activity_log')
                .doc(baNo)
                .collection('logs')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No activity found.'));
              }
              final logs = snapshot.data!.docs;
              return ListView.separated(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                itemCount: logs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, idx) {
                  final logDoc = logs[idx];
                  final log = logDoc.data() as Map<String, dynamic>;
                  final ts = (log['timestamp'] as Timestamp?)?.toDate();
                  return Dismissible(
                    key: ValueKey(logDoc.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      color: Colors.red.shade400,
                      child: const Icon(Icons.delete,
                          color: Colors.white, size: 32),
                    ),
                    confirmDismiss: (_) async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Activity Log?'),
                          content: const Text(
                              'Are you sure you want to delete this activity log?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      return confirm == true;
                    },
                    onDismissed: (_) => _deleteLog(context, baNo, logDoc.id),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF002B5B),
                          child:
                              const Icon(Icons.event_note, color: Colors.white),
                        ),
                        title: Text(
                          log['action'] ?? 'Unknown',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (ts != null)
                              Text(
                                '${ts.year}-${ts.month.toString().padLeft(2, '0')}-${ts.day.toString().padLeft(2, '0')}  ${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                    fontSize: 13, color: Color.fromARGB(218, 47, 46, 46)),
                              ),
                            if (log['details'] != null &&
                                (log['details'] as Map).isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Details'),
                                        content: SingleChildScrollView(
                                          child:
                                              Text(log['details'].toString()),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text('Close'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'View Details',
                                    style: TextStyle(
                                      color: Color.fromARGB(255, 68, 68, 68),
                                      fontWeight: FontWeight.w500,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
