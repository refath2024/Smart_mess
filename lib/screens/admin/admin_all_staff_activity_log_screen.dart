import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAllStaffActivityLogScreen extends StatefulWidget {
  const AdminAllStaffActivityLogScreen({Key? key}) : super(key: key);

  @override
  State<AdminAllStaffActivityLogScreen> createState() =>
      _AdminAllStaffActivityLogScreenState();
}

class _AdminAllStaffActivityLogScreenState
    extends State<AdminAllStaffActivityLogScreen> {
  String _searchQuery = '';
  String? _selectedUser;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Staff Activity Logs',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF002B5B),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by Name',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (val) =>
                        setState(() => _searchQuery = val.trim().toLowerCase()),
                  ),
                ),
                const SizedBox(width: 12),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('staff_state')
                      .snapshots(),
                  builder: (context, userSnap) {
                    if (!userSnap.hasData) return const SizedBox();
                    final users = userSnap.data!.docs;
                    return DropdownButton<String?>(
                      value: _selectedUser,
                      hint: const Text('Filter by User'),
                      items: [
                        const DropdownMenuItem<String?>(
                            value: null, child: Text('All Users')),
                        ...users.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final baNo = data['ba_no']?.toString() ?? '';
                          final name = data['name']?.toString() ?? '';
                          return DropdownMenuItem<String?>(
                            value: baNo,
                            child: Text('$name ($baNo)'),
                          );
                        }).toList(),
                      ],
                      onChanged: (val) => setState(() => _selectedUser = val),
                    );
                  },
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.date_range),
                  label: const Text('Filter Date'),
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2023, 1, 1),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                      initialDateRange: _startDate != null && _endDate != null
                          ? DateTimeRange(start: _startDate!, end: _endDate!)
                          : null,
                    );
                    if (picked != null) {
                      setState(() {
                        _startDate = picked.start;
                        _endDate = picked.end;
                      });
                    }
                  },
                ),
                if (_startDate != null && _endDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: 'Clear Date Filter',
                    onPressed: () {
                      setState(() {
                        _startDate = null;
                        _endDate = null;
                      });
                    },
                  ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('staff_state')
                  .snapshots(),
              builder: (context, userSnap) {
                if (!userSnap.hasData)
                  return const Center(child: CircularProgressIndicator());
                final users = userSnap.data!.docs;
                final baNos = users
                    .map((doc) =>
                        (doc.data() as Map<String, dynamic>)['ba_no']
                            ?.toString() ??
                        '')
                    .where((baNo) => baNo.isNotEmpty)
                    .toList();
                return FutureBuilder<List<Map<String, dynamic>>>(
                  future: _fetchAllLogs(baNos),
                  builder: (context, logSnap) {
                    if (!logSnap.hasData)
                      return const Center(child: CircularProgressIndicator());
                    var logs = logSnap.data!;
                    // Filter by user
                    if (_selectedUser != null) {
                      logs = logs
                          .where((log) => log['ba_no'] == _selectedUser)
                          .toList();
                    }
                    // Filter by search
                    if (_searchQuery.isNotEmpty) {
                      logs = logs.where((log) {
                        final name =
                            (log['name'] ?? '').toString().toLowerCase();
                        return name.contains(_searchQuery);
                      }).toList();
                    }
                    // Filter by date
                    if (_startDate != null && _endDate != null) {
                      logs = logs.where((log) {
                        final ts = (log['timestamp'] as Timestamp?)?.toDate();
                        if (ts == null) return false;
                        return !ts.isBefore(_startDate!) &&
                            !ts.isAfter(_endDate!);
                      }).toList();
                    }
                    // Sort by timestamp descending
                    logs.sort((a, b) {
                      final aTs = a['timestamp'] as Timestamp?;
                      final bTs = b['timestamp'] as Timestamp?;
                      if (aTs == null || bTs == null) return 0;
                      return bTs.compareTo(aTs);
                    });
                    if (logs.isEmpty) {
                      return const Center(
                          child: Text('No activity logs found.'));
                    }
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
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
                                        'Are you sure you want to delete all logs in the current filter? This cannot be undone.'),
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
                                  // Group logs by ba_no for efficient batch delete
                                  final Map<String, List<Map<String, dynamic>>>
                                      logsByBaNo = {};
                                  for (final log in logs) {
                                    final baNo = log['ba_no'] as String?;
                                    if (baNo == null) continue;
                                    logsByBaNo
                                        .putIfAbsent(baNo, () => [])
                                        .add(log);
                                  }
                                  final batch =
                                      FirebaseFirestore.instance.batch();
                                  for (final entry in logsByBaNo.entries) {
                                    final baNo = entry.key;
                                    for (final log in entry.value) {
                                      final ts = log['timestamp'];
                                      final logQuery = await FirebaseFirestore
                                          .instance
                                          .collection('staff_activity_log')
                                          .doc(baNo)
                                          .collection('logs')
                                          .where('timestamp', isEqualTo: ts)
                                          .get();
                                      for (final doc in logQuery.docs) {
                                        batch.delete(doc.reference);
                                      }
                                    }
                                  }
                                  await batch.commit();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'All logs in filter deleted.')),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                            itemCount: logs.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, idx) {
                              final log = logs[idx];
                              final ts =
                                  (log['timestamp'] as Timestamp?)?.toDate();
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
                                  activityTitle =
                                      '$senderName sent notification.';
                                }
                              } else {
                                activityTitle = log['actionType'] ?? 'Activity';
                              }
                              return Dismissible(
                                key: ValueKey(
                                    '${log['ba_no']}_${log['timestamp']}'),
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
                                              style:
                                                  TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                  return confirm == true;
                                },
                                onDismissed: (_) async {
                                  final baNo = log['ba_no'] as String?;
                                  final ts = log['timestamp'];
                                  if (baNo != null && ts != null) {
                                    final logQuery = await FirebaseFirestore
                                        .instance
                                        .collection('staff_activity_log')
                                        .doc(baNo)
                                        .collection('logs')
                                        .where('timestamp', isEqualTo: ts)
                                        .get();
                                    for (final doc in logQuery.docs) {
                                      await doc.reference.delete();
                                    }
                                  }
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Log deleted.')),
                                    );
                                  }
                                },
                                child: ListTile(
                                  leading: const Icon(Icons.event_note,
                                      color: Color(0xFF002B5B)),
                                  title: Text(
                                    activityTitle,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Color(0xFF002B5B)),
                                  ),
                                  subtitle: ts != null
                                      ? Text(
                                          '${ts.year}-${ts.month.toString().padLeft(2, '0')}-${ts.day.toString().padLeft(2, '0')}  ${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}',
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.black54),
                                        )
                                      : null,
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
                                                Text(
                                                    'Message: ${log['message']}'),
                                              if (log['receiver'] ==
                                                  'All Officers')
                                                const Text(
                                                    'Receiver: All Officers'),
                                              if (log['receiver_ba_no'] !=
                                                      null &&
                                                  log['receiver_ba_no'] !=
                                                      '') ...[
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
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text('Close'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
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

  // Helper to fetch all logs from all users
  Future<List<Map<String, dynamic>>> _fetchAllLogs(List<String> baNos) async {
    List<Map<String, dynamic>> allLogs = [];
    for (final baNo in baNos) {
      final snap = await FirebaseFirestore.instance
          .collection('staff_activity_log')
          .doc(baNo)
          .collection('logs')
          .get();
      for (final doc in snap.docs) {
        final log = Map<String, dynamic>.from(doc.data());
        log['ba_no'] = baNo;
        allLogs.add(log);
      }
    }
    return allLogs;
  }
}
