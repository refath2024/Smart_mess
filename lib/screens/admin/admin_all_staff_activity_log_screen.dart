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
                if (userSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!userSnap.hasData || userSnap.data!.docs.isEmpty) {
                  return const Center(child: Text('No staff found.'));
                }
                final users = userSnap.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data['name']?.toString() ?? '';
                  final q = _searchQuery;
                  return name.toLowerCase().contains(q);
                }).toList();
                if (users.isEmpty) {
                  return const Center(
                      child: Text('No staff match your search.'));
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
                    final rank = data['rank']?.toString() ?? '';
                    final name = data['name']?.toString() ?? '';
                    final email = data['email']?.toString() ?? '';
                    final staffId = user.id;
                    return ExpansionTile(
                      leading: const Icon(Icons.person, color: Colors.blue),
                      title: Text('$name ($baNo)',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF002B5B))),
                      subtitle: Text('$rank | $email',
                          style: const TextStyle(color: Colors.black87)),
                      children: [
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('staff_activity_logs')
                              .where('staffId', isEqualTo: staffId)
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
                            final logs = logSnap.data!.docs.where((logDoc) {
                              final log = logDoc.data() as Map<String, dynamic>;
                              final ts =
                                  (log['timestamp'] as Timestamp?)?.toDate();
                              bool matchesDate = true;
                              if (_startDate != null &&
                                  _endDate != null &&
                                  ts != null) {
                                matchesDate = !ts.isBefore(_startDate!) &&
                                    !ts.isAfter(_endDate!);
                              }
                              return matchesDate;
                            }).toList();
                            if (logs.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                    'No activity found for selected date.'),
                              );
                            }
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
                                return ListTile(
                                  leading: IconButton(
                                    icon: const Icon(Icons.info_outline,
                                        color: Color(0xFF0052CC)),
                                    tooltip: 'Show Activity',
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
                                                  'Activity: ${log['message'] ?? ''}'),
                                              Text(
                                                  'Type: ${log['actionType'] ?? ''}'),
                                              if (ts != null)
                                                Text(
                                                    'Time: ${ts.year}-${ts.month.toString().padLeft(2, '0')}-${ts.day.toString().padLeft(2, '0')}  ${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}'),
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
                                  title: Text(
                                    log['message'] ?? 'Unknown',
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
