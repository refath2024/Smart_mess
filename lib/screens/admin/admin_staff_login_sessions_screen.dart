import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminStaffLoginSessionsScreen extends StatelessWidget {
  const AdminStaffLoginSessionsScreen({super.key});

  Future<String?> _getBaNo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final staffDoc = await FirebaseFirestore.instance
        .collection('staff_state')
        .where('email', isEqualTo: user.email)
        .limit(1)
        .get();
    if (staffDoc.docs.isEmpty) return null;
    return staffDoc.docs.first.data()['ba_no']?.toString();
  }

  Future<void> _deleteAllSessions(BuildContext context, String baNo) async {
    final sessions = await FirebaseFirestore.instance
        .collection('staff_login_sessions')
        .doc(baNo)
        .collection('sessions')
        .get();
    final batch = FirebaseFirestore.instance.batch();
    for (var doc in sessions.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All login sessions deleted.')),
    );
  }

  Future<void> _deleteSession(
      BuildContext context, String baNo, String sessionId) async {
    await FirebaseFirestore.instance
        .collection('staff_login_sessions')
        .doc(baNo)
        .collection('sessions')
        .doc(sessionId)
        .delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Login session deleted.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _StaffLoginSessionsBody(
      getBaNo: _getBaNo,
      deleteAllSessions: _deleteAllSessions,
      deleteSession: _deleteSession,
    );
  }
}

class _StaffLoginSessionsBody extends StatefulWidget {
  final Future<String?> Function() getBaNo;
  final Future<void> Function(BuildContext, String) deleteAllSessions;
  final Future<void> Function(BuildContext, String, String) deleteSession;
  const _StaffLoginSessionsBody(
      {required this.getBaNo,
      required this.deleteAllSessions,
      required this.deleteSession});

  @override
  State<_StaffLoginSessionsBody> createState() =>
      _StaffLoginSessionsBodyState();
}

class _StaffLoginSessionsBodyState extends State<_StaffLoginSessionsBody> {
  DateTimeRange? _dateRange;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: widget.getBaNo(),
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
            title: const Text('Login Sessions'),
            backgroundColor: const Color(0xFF002B5B),
            foregroundColor: Colors.white,
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDateRangePicker(
                            context: context,
                            initialDateRange: _dateRange,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() {
                              _dateRange = picked;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Filter by Date',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(_dateRange == null
                              ? 'All Dates'
                              : '${_dateRange!.start.year}-${_dateRange!.start.month.toString().padLeft(2, '0')}-${_dateRange!.start.day.toString().padLeft(2, '0')} to ${_dateRange!.end.year}-${_dateRange!.end.month.toString().padLeft(2, '0')}-${_dateRange!.end.day.toString().padLeft(2, '0')}'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('Delete All'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete All Login Sessions?'),
                            content: const Text(
                                'Are you sure you want to delete all login sessions? This action cannot be undone.'),
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
                          await widget.deleteAllSessions(context, baNo);
                        }
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('staff_login_sessions')
                      .doc(baNo)
                      .collection('sessions')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                          child: Text('No login sessions found.'));
                    }
                    var sessions = snapshot.data!.docs;
                    if (_dateRange != null) {
                      sessions = sessions.where((doc) {
                        final ts = (doc['timestamp'] as Timestamp?)?.toDate();
                        if (ts == null) return false;
                        return ts.isAfter(_dateRange!.start
                                .subtract(const Duration(days: 1))) &&
                            ts.isBefore(
                                _dateRange!.end.add(const Duration(days: 1)));
                      }).toList();
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 8),
                      itemCount: sessions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final sessionDoc = sessions[idx];
                        final session =
                            sessionDoc.data() as Map<String, dynamic>;
                        final ts =
                            (session['timestamp'] as Timestamp?)?.toDate();
                        return Dismissible(
                          key: ValueKey(sessionDoc.id),
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
                                title: const Text('Delete Login Session?'),
                                content: const Text(
                                    'Are you sure you want to delete this login session?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            return confirm == true;
                          },
                          onDismissed: (_) => widget.deleteSession(
                              context, baNo, sessionDoc.id),
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading:
                                  const Icon(Icons.login, color: Colors.blue),
                              title: Text(ts != null
                                  ? '${ts.year}-${ts.month.toString().padLeft(2, '0')}-${ts.day.toString().padLeft(2, '0')}  ${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}'
                                  : 'Unknown'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (session['device'] != null)
                                    Text('Device: ${session['device']}',
                                        style: const TextStyle(fontSize: 13)),
                                  if (session['location'] != null)
                                    Text('Location: ${session['location']}',
                                        style: const TextStyle(fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
