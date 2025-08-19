import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminNotificationHistoryScreen extends StatelessWidget {
  const AdminNotificationHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _AdminNotificationHistoryScreenBody();
  }
}

class _AdminNotificationHistoryScreenBody extends StatefulWidget {
  @override
  State<_AdminNotificationHistoryScreenBody> createState() =>
      _AdminNotificationHistoryScreenBodyState();
}

class _AdminNotificationHistoryScreenBodyState
    extends State<_AdminNotificationHistoryScreenBody> {
  bool _isDeletingAll = false;
  Set<String> _deletingIds = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification History'),
        backgroundColor: const Color(0xFF002B5B),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No notifications sent yet.'));
          }
          final allDocs = snapshot.data!.docs;
          final List<QueryDocumentSnapshot> filtered = [];
          final Set<String> allUsersKeys = {};
          for (final doc in allDocs) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['target_type'] == 'all') {
              final key =
                  '${data['title']}|${data['message']}|${data['type']}|${(data['created_at'] as Timestamp?)?.millisecondsSinceEpoch ?? ''}';
              if (!allUsersKeys.contains(key)) {
                allUsersKeys.add(key);
                filtered.add(doc);
              }
            } else {
              filtered.add(doc);
            }
          }
          return Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  label: const Text('Delete All',
                      style: TextStyle(color: Colors.red)),
                  onPressed: _isDeletingAll
                      ? null
                      : () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete All Notifications'),
                              content: const Text(
                                  'Are you sure you want to delete all notifications? This cannot be undone.'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete All',
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            setState(() => _isDeletingAll = true);
                            final allDocsSnapshot = await FirebaseFirestore
                                .instance
                                .collection('notifications')
                                .get();
                            for (final doc in allDocsSnapshot.docs) {
                              await doc.reference.delete();
                            }
                            setState(() => _isDeletingAll = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('All notifications deleted.')));
                          }
                        },
                ),
              ),
              if (_isDeletingAll)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (!_isDeletingAll) const SizedBox(height: 8),
              if (!_isDeletingAll)
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(0),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, idx) {
                      final notif =
                          filtered[idx].data() as Map<String, dynamic>;
                      final ts = (notif['created_at'] as Timestamp?)?.toDate();
                      String trailingText = '';
                      final isDeleting =
                          _deletingIds.contains(filtered[idx].id);
                      if (notif['target_type'] == 'all') {
                        trailingText = 'All Officers';
                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('staff_state')
                              .doc(notif['sender_id'])
                              .get(),
                          builder: (context, staffSnap) {
                            String senderDetails = '';
                            if (staffSnap.hasData && staffSnap.data!.exists) {
                              final staff = staffSnap.data!.data()
                                  as Map<String, dynamic>;
                              final sBaNo = staff['ba_no'] ?? '';
                              final sRank = staff['rank'] ?? '';
                              final sName = staff['name'] ?? '';
                              senderDetails = [
                                if (sBaNo != '') 'Sender BA: $sBaNo',
                                if (sRank != '') sRank,
                                if (sName != '') sName
                              ].join(' | ');
                            }
                            if (isDeleting) {
                              return const ListTile(
                                title: Text('Deleting...',
                                    style: TextStyle(color: Colors.red)),
                                trailing: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator()),
                              );
                            }
                            return Dismissible(
                              key: ValueKey(filtered[idx].id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 24),
                                color: Colors.red,
                                child: const Icon(Icons.delete,
                                    color: Colors.white, size: 32),
                              ),
                              confirmDismiss: (direction) async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Notification'),
                                    content: const Text(
                                        'Are you sure you want to delete this notification for all officers?'),
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
                                            style:
                                                TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  setState(
                                      () => _deletingIds.add(filtered[idx].id));
                                  final allDocsSnapshot =
                                      await FirebaseFirestore.instance
                                          .collection('notifications')
                                          .where('title',
                                              isEqualTo: notif['title'])
                                          .where('message',
                                              isEqualTo: notif['message'])
                                          .where('type',
                                              isEqualTo: notif['type'])
                                          .where('target_type',
                                              isEqualTo: 'all')
                                          .get();
                                  for (final doc in allDocsSnapshot.docs) {
                                    await doc.reference.delete();
                                  }
                                  setState(() =>
                                      _deletingIds.remove(filtered[idx].id));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Notification deleted for all officers.')));
                                  return true;
                                }
                                return false;
                              },
                              onDismissed: (direction) async {},
                              child: ListTile(
                                leading: const Icon(Icons.notifications,
                                    color: Color(0xFF002B5B)),
                                title: Text(notif['title'] ?? 'No Title',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Type: ${notif['type'] ?? ''}'),
                                    if (notif['message'] != null &&
                                        notif['message'] != '')
                                      Text('Message: ${notif['message']}'),
                                    if (ts != null)
                                      Text(
                                          'Time: ${ts.year}-${ts.month.toString().padLeft(2, '0')}-${ts.day.toString().padLeft(2, '0')}  ${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}'),
                                    if (senderDetails.isNotEmpty)
                                      Text(senderDetails,
                                          style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12)),
                                  ],
                                ),
                                trailing: Text(trailingText,
                                    style: TextStyle(
                                        color: notif['target_type'] == 'all'
                                            ? Colors.green
                                            : Colors.blue,
                                        fontWeight: FontWeight.bold)),
                              ),
                            );
                          },
                        );
                      } else if (notif['target_type'] == 'specific') {
                        final baNo = notif['receiver_ba_no'] ?? '';
                        final rank = notif['receiver_rank'] ?? '';
                        final name = notif['receiver_name'] ?? '';
                        if (baNo != '' || rank != '' || name != '') {
                          trailingText = [
                            if (baNo != '') 'BA: $baNo',
                            if (rank != '') rank,
                            if (name != '') name
                          ].join(' | ');
                        } else if (notif['user_id'] != null) {
                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('user_requests')
                                .doc(notif['user_id'])
                                .get(),
                            builder: (context, userSnap) {
                              String trailing = 'User not found';
                              if (userSnap.connectionState ==
                                  ConnectionState.waiting) {
                                trailing = 'Loading...';
                              } else if (userSnap.hasData &&
                                  userSnap.data!.exists) {
                                final user = userSnap.data!.data()
                                    as Map<String, dynamic>;
                                final baNo2 = user['ba_no'] ?? '';
                                final rank2 = user['rank'] ?? '';
                                final name2 = user['name'] ?? '';
                                trailing = [
                                  if (baNo2 != '') 'BA: $baNo2',
                                  if (rank2 != '') rank2,
                                  if (name2 != '') name2
                                ].join(' | ');
                              }
                              return _buildSpecificNotificationTileWithLoading(
                                context: context,
                                doc: filtered[idx],
                                notif: notif,
                                ts: ts,
                                trailingText: trailing,
                                isDeleting: isDeleting,
                                onDeleteStart: () => setState(
                                    () => _deletingIds.add(filtered[idx].id)),
                                onDeleteEnd: () => setState(() =>
                                    _deletingIds.remove(filtered[idx].id)),
                              );
                            },
                          );
                        }
                        return _buildSpecificNotificationTileWithLoading(
                          context: context,
                          doc: filtered[idx],
                          notif: notif,
                          ts: ts,
                          trailingText: trailingText,
                          isDeleting: isDeleting,
                          onDeleteStart: () => setState(
                              () => _deletingIds.add(filtered[idx].id)),
                          onDeleteEnd: () => setState(
                              () => _deletingIds.remove(filtered[idx].id)),
                        );
                      }
                      // fallback if no user_id
                      trailingText = 'User not found';
                      return _buildSpecificNotificationTileWithLoading(
                        context: context,
                        doc: filtered[idx],
                        notif: notif,
                        ts: ts,
                        trailingText: trailingText,
                        isDeleting: isDeleting,
                        onDeleteStart: () =>
                            setState(() => _deletingIds.add(filtered[idx].id)),
                        onDeleteEnd: () => setState(
                            () => _deletingIds.remove(filtered[idx].id)),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

Widget _buildSpecificNotificationTileWithLoading({
  required BuildContext context,
  required QueryDocumentSnapshot doc,
  required Map<String, dynamic> notif,
  required DateTime? ts,
  required String trailingText,
  required bool isDeleting,
  required VoidCallback onDeleteStart,
  required VoidCallback onDeleteEnd,
}) {
  if (isDeleting) {
    return const ListTile(
      title: Text('Deleting...', style: TextStyle(color: Colors.red)),
      trailing:
          SizedBox(width: 24, height: 24, child: CircularProgressIndicator()),
    );
  }
  return FutureBuilder<DocumentSnapshot>(
    future: FirebaseFirestore.instance
        .collection('staff_state')
        .doc(notif['sender_id'])
        .get(),
    builder: (context, staffSnap) {
      String senderDetails = '';
      if (staffSnap.hasData && staffSnap.data!.exists) {
        final staff = staffSnap.data!.data() as Map<String, dynamic>;
        final sBaNo = staff['ba_no'] ?? '';
        final sRank = staff['rank'] ?? '';
        final sName = staff['name'] ?? '';
        senderDetails = [
          if (sBaNo != '') 'Sender BA: $sBaNo',
          if (sRank != '') sRank,
          if (sName != '') sName
        ].join(' | ');
      }
      return Dismissible(
        key: ValueKey(doc.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          color: Colors.red,
          child: const Icon(Icons.delete, color: Colors.white, size: 32),
        ),
        confirmDismiss: (direction) async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Notification'),
              content: const Text(
                  'Are you sure you want to delete this notification?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child:
                      const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
          if (confirm == true) {
            onDeleteStart();
            await doc.reference.delete();
            onDeleteEnd();
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notification deleted.')));
            return true;
          }
          return false;
        },
        onDismissed: (direction) async {},
        child: ListTile(
          leading: const Icon(Icons.notifications, color: Color(0xFF002B5B)),
          title: Text(notif['title'] ?? 'No Title',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Type: ${notif['type'] ?? ''}'),
              if (notif['message'] != null && notif['message'] != '')
                Text('Message: ${notif['message']}'),
              if (ts != null)
                Text(
                    'Time: ${ts.year}-${ts.month.toString().padLeft(2, '0')}-${ts.day.toString().padLeft(2, '0')}  ${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}'),
              if (senderDetails.isNotEmpty)
                Text(senderDetails,
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          trailing: Text(trailingText,
              style: TextStyle(
                  color: notif['target_type'] == 'all'
                      ? Colors.green
                      : Colors.blue,
                  fontWeight: FontWeight.bold)),
        ),
      );
    },
  );
}
// ...existing code...
// Show BA No, Rank, and Name if available, otherwise fetch from user_requests
