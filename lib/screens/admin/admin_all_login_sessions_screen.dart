import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAllLoginSessionsScreen extends StatefulWidget {
  const AdminAllLoginSessionsScreen({super.key});

  @override
  State<AdminAllLoginSessionsScreen> createState() =>
      _AdminAllLoginSessionsScreenState();
}

class _AdminAllLoginSessionsScreenState
    extends State<AdminAllLoginSessionsScreen> {
  String _searchQuery = '';
  DateTimeRange? _dateRange;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All User Login Sessions'),
        backgroundColor: const Color(0xFF002B5B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: 'Filter by Date',
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2023, 1, 1),
                lastDate: DateTime.now().add(const Duration(days: 1)),
                initialDateRange: _dateRange,
              );
              if (picked != null) {
                setState(() => _dateRange = picked);
              }
            },
          ),
        ],
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
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('login_sessions')
                              .doc(baNo)
                              .collection('sessions')
                              .orderBy('timestamp', descending: true)
                              .snapshots(),
                          builder: (context, sessionSnap) {
                            if (sessionSnap.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(),
                              ));
                            }
                            if (!sessionSnap.hasData ||
                                sessionSnap.data!.docs.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('No login sessions.'),
                              );
                            }
                            final sessions =
                                sessionSnap.data!.docs.where((doc) {
                              if (_dateRange == null) return true;
                              final ts =
                                  (doc['timestamp'] as Timestamp?)?.toDate();
                              if (ts == null) return false;
                              return ts.isAfter(_dateRange!.start
                                      .subtract(const Duration(days: 1))) &&
                                  ts.isBefore(_dateRange!.end
                                      .add(const Duration(days: 1)));
                            }).toList();
                            if (sessions.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                    'No login sessions in selected date range.'),
                              );
                            }
                            // --- Delete All Button ---
                            return Column(
                              children: [
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    icon: const Icon(Icons.delete_forever,
                                        color: Colors.red),
                                    label: const Text('Delete All',
                                        style: TextStyle(color: Colors.red)),
                                    onPressed: () async {
                                      final confirm = await showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text(
                                              'Delete All Sessions?'),
                                          content: const Text(
                                              'Are you sure you want to delete all login sessions for this user?'),
                                          actions: [
                                            TextButton(
                                                onPressed: () =>
                                                    Navigator.of(ctx)
                                                        .pop(false),
                                                child: const Text('Cancel')),
                                            TextButton(
                                                onPressed: () =>
                                                    Navigator.of(ctx).pop(true),
                                                child: const Text('Delete',
                                                    style: TextStyle(
                                                        color: Colors.red))),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        final batch =
                                            FirebaseFirestore.instance.batch();
                                        for (var doc in sessions) {
                                          batch.delete(
                                            FirebaseFirestore.instance
                                                .collection('login_sessions')
                                                .doc(baNo)
                                                .collection('sessions')
                                                .doc(doc.id),
                                          );
                                        }
                                        await batch.commit();
                                      }
                                    },
                                  ),
                                ),
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: sessions.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 4),
                                  itemBuilder: (context, sidx) {
                                    final session = sessions[sidx].data()
                                        as Map<String, dynamic>;
                                    final ts =
                                        (session['timestamp'] as Timestamp?)
                                            ?.toDate();
                                    return Dismissible(
                                      key: ValueKey(sessions[sidx].id),
                                      direction: DismissDirection.endToStart,
                                      background: Container(
                                        color: Colors.red,
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20),
                                        child: const Icon(Icons.delete,
                                            color: Colors.white),
                                      ),
                                      confirmDismiss: (direction) async {
                                        return await showDialog(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title:
                                                const Text('Delete Session?'),
                                            content: const Text(
                                                'Are you sure you want to delete this login session?'),
                                            actions: [
                                              TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(ctx)
                                                          .pop(false),
                                                  child: const Text('Cancel')),
                                              TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(ctx)
                                                          .pop(true),
                                                  child: const Text('Delete',
                                                      style: TextStyle(
                                                          color: Colors.red))),
                                            ],
                                          ),
                                        );
                                      },
                                      onDismissed: (_) async {
                                        await FirebaseFirestore.instance
                                            .collection('login_sessions')
                                            .doc(baNo)
                                            .collection('sessions')
                                            .doc(sessions[sidx].id)
                                            .delete();
                                      },
                                      child: Card(
                                        elevation: 1,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                        child: ListTile(
                                          leading: const Icon(Icons.login,
                                              color: Colors.blue),
                                          title: Text(ts != null
                                              ? '${ts.year}-${ts.month.toString().padLeft(2, '0')}-${ts.day.toString().padLeft(2, '0')}  ${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}'
                                              : 'Unknown'),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (session['device'] != null)
                                                Text(
                                                    'Device: ${session['device']}',
                                                    style: const TextStyle(
                                                        fontSize: 13)),
                                              if (session['location'] != null)
                                                Text(
                                                    'Location: ${session['location']}',
                                                    style: const TextStyle(
                                                        fontSize: 13)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
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
