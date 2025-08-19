import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StaffOwnActivityLogScreen extends StatelessWidget {
  const StaffOwnActivityLogScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in.')),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('staff_state')
          .doc(currentUser.uid)
          .get(),
      builder: (context, staffSnap) {
        if (staffSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (!staffSnap.hasData || !staffSnap.data!.exists) {
          return const Scaffold(
              body: Center(child: Text('Staff info not found.')));
        }
        final staffData = staffSnap.data!.data() as Map<String, dynamic>;
        final baNo = staffData['ba_no'] ?? '';
        if (baNo.isEmpty) {
          return const Scaffold(body: Center(child: Text('BA No not found.')));
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('My Activity Log'),
            backgroundColor: Color(0xFF002B5B),
            foregroundColor: Colors.white,
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('staff_activity_log')
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
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Tooltip(
                        message: 'Delete All Logs',
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(8),
                          ),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete All Activity Logs'),
                                content: const Text(
                                    'Are you sure you want to delete all activity logs? This cannot be undone.'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Delete All',
                                        style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              final batch = FirebaseFirestore.instance.batch();
                              for (final doc in logs) {
                                batch.delete(doc.reference);
                              }
                              await batch.commit();
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('All activity logs deleted.')));
                            }
                          },
                          child: const Icon(Icons.delete_forever,
                              color: Colors.red, size: 22),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(0),
                      itemCount: logs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final log = logs[idx].data() as Map<String, dynamic>;
                        final ts = (log['timestamp'] as Timestamp?)?.toDate();
                        String activityTitle = '';
                        final senderName = log['name'] ?? '';
                        if (log['actionType'] == 'Send Notification') {
                          if (log['receiver'] == 'All Officers') {
                            activityTitle =
                                '$senderName sent notification to All Officers.';
                          } else if (log['receiver_name'] != null &&
                              log['receiver_name'] != '') {
                            activityTitle =
                                '$senderName sent notification to ${log['receiver_name']}.';
                          } else {
                            activityTitle = '$senderName sent notification.';
                          }
                        } else {
                          activityTitle = log['actionType'] ?? 'Activity';
                        }
                        return Dismissible(
                          key: ValueKey(logs[idx].id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            color: Colors.red,
                            child: const Icon(Icons.delete,
                                color: Colors.white, size: 32),
                          ),
                          confirmDismiss: (direction) async {
                            return await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Activity Log'),
                                content: const Text(
                                    'Are you sure you want to delete this activity log?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Delete',
                                        style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                          },
                          onDismissed: (direction) async {
                            await logs[idx].reference.delete();
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Activity log deleted.')));
                          },
                          child: ListTile(
                            leading: const Icon(Icons.event_note,
                                color: Color(0xFF002B5B)),
                            title: Text(
                              activityTitle,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF002B5B),
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.info_outline,
                                  color: Color(0xFF0052CC)),
                              tooltip: 'Show Details',
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Activity Details'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            'Type: ${log['actionType'] ?? ''}'),
                                        if (log['message'] != null &&
                                            log['message'] != '')
                                          Text('Message: ${log['message']}'),
                                        if (log['receiver'] == 'All Officers')
                                          const Text('Receiver: All Officers'),
                                        if (log['receiver_ba_no'] != null &&
                                            log['receiver_ba_no'] != '') ...[
                                          Text(
                                              'Receiver BA No: ${log['receiver_ba_no']}'),
                                          Text(
                                              'Receiver Rank: ${log['receiver_rank'] ?? ''}'),
                                          Text(
                                              'Receiver Name: ${log['receiver_name'] ?? ''}'),
                                          Text(
                                              'Receiver Email: ${log['receiver_email'] ?? ''}'),
                                        ],
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Close'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            subtitle: ts != null
                                ? Text(
                                    '${ts.year}-${ts.month.toString().padLeft(2, '0')}-${ts.day.toString().padLeft(2, '0')}  ${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}',
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.black54),
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
