import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAllUserActivityLogScreen extends StatefulWidget {
  const AdminAllUserActivityLogScreen({super.key});

  @override
  State<AdminAllUserActivityLogScreen> createState() =>
      _AdminAllUserActivityLogScreenState();
}

class _AdminAllUserActivityLogScreenState
    extends State<AdminAllUserActivityLogScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All User Activity Logs'),
        backgroundColor: const Color(0xFF002B5B),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by BA No, Name, or Email',
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('user_requests')
                  .snapshots(),
              builder: (context, userSnap) {
                if (userSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!userSnap.hasData || userSnap.data!.docs.isEmpty) {
                  return const Center(child: Text('No users found.'));
                }
                final users = userSnap.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final baNo = data['ba_no']?.toString() ?? '';
                  final name = data['name']?.toString() ?? '';
                  final email = data['email']?.toString() ?? '';
                  final q = _searchQuery.toLowerCase();
                  return baNo.toLowerCase().contains(q) ||
                      name.toLowerCase().contains(q) ||
                      email.toLowerCase().contains(q);
                }).toList();
                if (users.isEmpty) {
                  return const Center(
                      child: Text('No users match your search.'));
                }
                return ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final user = users[idx];
                    final data = user.data() as Map<String, dynamic>;
                    final baNo = data['ba_no']?.toString() ?? '';
                    final name = data['name']?.toString() ?? '';
                    final email = data['email']?.toString() ?? '';
                    return ExpansionTile(
                      leading: const Icon(Icons.person, color: Colors.blue),
                      title: Text('$name ($baNo)',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(email),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 16, right: 16, bottom: 8),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              icon: const Icon(Icons.delete_forever,
                                  color: Colors.red),
                              label: const Text('Delete All Logs',
                                  style: TextStyle(color: Colors.red)),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete All Logs'),
                                    content: const Text(
                                        'Are you sure you want to delete all activity logs for this user?'),
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
                                  final logsSnap = await FirebaseFirestore
                                      .instance
                                      .collection('activity_log')
                                      .doc(baNo)
                                      .collection('logs')
                                      .get();
                                  for (var doc in logsSnap.docs) {
                                    await doc.reference.delete();
                                  }
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('All logs deleted.')),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                        ),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('activity_log')
                              .doc(baNo)
                              .collection('logs')
                              .orderBy('timestamp', descending: true)
                              .snapshots(),
                          builder: (context, logSnap) {
                            if (logSnap.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(),
                              ));
                            }
                            if (!logSnap.hasData ||
                                logSnap.data!.docs.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('No activity found.'),
                              );
                            }
                            final logs = logSnap.data!.docs;
                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: logs.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 4),
                              itemBuilder: (context, lidx) {
                                final logDoc = logs[lidx];
                                final log =
                                    logDoc.data() as Map<String, dynamic>;
                                final ts =
                                    (log['timestamp'] as Timestamp?)?.toDate();
                                return Dismissible(
                                  key: ValueKey(logDoc.id),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24),
                                    color: Colors.red.shade100,
                                    child: const Icon(Icons.delete,
                                        color: Colors.red, size: 32),
                                  ),
                                  confirmDismiss: (direction) async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete Log'),
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
                                                style: TextStyle(
                                                    color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );
                                    return confirm == true;
                                  },
                                  onDismissed: (_) async {
                                    await logDoc.reference.delete();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text('Log deleted.')),
                                      );
                                    }
                                  },
                                  child: Card(
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor:
                                            const Color(0xFF002B5B),
                                        child: const Icon(Icons.event_note,
                                            color: Colors.white),
                                      ),
                                      title: Text(
                                        log['action'] ?? 'Unknown',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (ts != null)
                                            Text(
                                              '${ts.year}-${ts.month.toString().padLeft(2, '0')}-${ts.day.toString().padLeft(2, '0')}  ${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}',
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.black54),
                                            ),
                                          if (log['details'] != null &&
                                              (log['details'] as Map)
                                                  .isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 4.0),
                                              child: GestureDetector(
                                                onTap: () {
                                                  showDialog(
                                                    context: context,
                                                    builder: (context) =>
                                                        AlertDialog(
                                                      title:
                                                          const Text('Details'),
                                                      content:
                                                          SingleChildScrollView(
                                                        child: Text(
                                                            log['details']
                                                                .toString()),
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                  context),
                                                          child: const Text(
                                                              'Close'),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                                child: const Text(
                                                  'View Details',
                                                  style: TextStyle(
                                                    color: Color(0xFF002B5B),
                                                    fontWeight: FontWeight.w500,
                                                    decoration: TextDecoration
                                                        .underline,
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
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
