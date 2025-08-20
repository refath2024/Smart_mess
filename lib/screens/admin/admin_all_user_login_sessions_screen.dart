import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAllUserLoginSessionsScreen extends StatefulWidget {
  const AdminAllUserLoginSessionsScreen({super.key});

  @override
  State<AdminAllUserLoginSessionsScreen> createState() =>
      _AdminAllUserLoginSessionsScreenState();
}

class _AdminAllUserLoginSessionsScreenState
    extends State<AdminAllUserLoginSessionsScreen> {
  String? _selectedUser;
  DateTimeRange? _dateRange;
  String _searchQuery = '';
  List<Map<String, dynamic>> _allSessions = [];
  List<Map<String, dynamic>> _filteredSessions = [];
  List<Map<String, String>> _userList = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsersAndSessions();
  }

  Future<void> _loadUsersAndSessions() async {
    setState(() {
      _loading = true;
    });
    final userSnap = await FirebaseFirestore.instance
        .collection('user_requests')
        .where('approved', isEqualTo: true)
        .where('rejected', isEqualTo: false)
        .get();
    _userList = userSnap.docs
        .map((doc) => {
              'ba_no': doc.data()['ba_no']?.toString() ?? '',
              'name': doc.data()['name']?.toString() ?? '',
            })
        .where((user) => (user['ba_no'] ?? '').isNotEmpty)
        .toList();
    List<Map<String, dynamic>> sessions = [];
    for (final user in _userList) {
      final baNo = user['ba_no']!;
      final name = user['name']!;
      final sessionSnap = await FirebaseFirestore.instance
          .collection('login_sessions')
          .doc(baNo)
          .collection('sessions')
          .get();
      for (final doc in sessionSnap.docs) {
        final data = doc.data();
        sessions.add({
          ...data,
          'ba_no': baNo,
          'user_name': name,
          'session_id': doc.id,
        });
      }
    }
    // Sort sessions by descending timestamp (nulls last)
    sessions.sort((a, b) {
      final ta = a['timestamp'];
      final tb = b['timestamp'];
      if (ta == null && tb == null) return 0;
      if (ta == null) return 1;
      if (tb == null) return -1;
      return (tb as Timestamp).compareTo(ta as Timestamp);
    });
    _allSessions = sessions;
    _filteredSessions = List.from(_allSessions);
    setState(() {
      _loading = false;
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredSessions = _allSessions.where((session) {
        final matchesUser =
            _selectedUser == null || session['ba_no'] == _selectedUser;
        final matchesDate = _dateRange == null ||
            (session['timestamp'] != null &&
                session['timestamp'] is Timestamp &&
                (session['timestamp'] as Timestamp).toDate().isAfter(
                    _dateRange!.start.subtract(const Duration(days: 1))) &&
                (session['timestamp'] as Timestamp)
                    .toDate()
                    .isBefore(_dateRange!.end.add(const Duration(days: 1))));
        final q = _searchQuery.toLowerCase();
        final baNo = (session['ba_no'] ?? '').toString().toLowerCase();
        final name = (session['user_name'] ?? '').toString().toLowerCase();
        return matchesUser &&
            matchesDate &&
            (baNo.contains(q) || name.contains(q));
      }).toList();
    });
  }

  Future<void> _deleteSession(
      BuildContext context, String baNo, String sessionId) async {
    await FirebaseFirestore.instance
        .collection('login_sessions')
        .doc(baNo)
        .collection('sessions')
        .doc(sessionId)
        .delete();
    setState(() {
      _allSessions.removeWhere(
          (s) => s['ba_no'] == baNo && s['session_id'] == sessionId);
      _filteredSessions.removeWhere(
          (s) => s['ba_no'] == baNo && s['session_id'] == sessionId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Login session deleted.')),
    );
  }

  Future<void> _deleteAllFilteredSessions(BuildContext context) async {
    final batch = FirebaseFirestore.instance.batch();
    for (final session in _filteredSessions) {
      final baNo = session['ba_no'];
      final sessionId = session['session_id'];
      final ref = FirebaseFirestore.instance
          .collection('login_sessions')
          .doc(baNo)
          .collection('sessions')
          .doc(sessionId);
      batch.delete(ref);
    }
    await batch.commit();
    setState(() {
      _allSessions.removeWhere((s) => _filteredSessions.contains(s));
      _filteredSessions.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All filtered login sessions deleted.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All User Login Sessions'),
        backgroundColor: const Color(0xFF002B5B),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedUser,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Filter by User',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('All Users'),
                            ),
                            ..._userList.map((user) => DropdownMenuItem<String>(
                                  value: user['ba_no'],
                                  child: Text(
                                      '${user['name']} (${user['ba_no']})'),
                                )),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _selectedUser = val;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
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
                        icon: const Icon(Icons.search),
                        label: const Text('Search'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _applyFilters,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search by BA No or Name',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) => setState(() {
                      _searchQuery = val.trim().toLowerCase();
                    }),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('Delete All Filtered'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _filteredSessions.isEmpty
                          ? null
                          : () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text(
                                      'Delete All Filtered Login Sessions?'),
                                  content: const Text(
                                      'Are you sure you want to delete all filtered login sessions? This action cannot be undone.'),
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
                                      child: const Text('Delete All'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await _deleteAllFilteredSessions(context);
                              }
                            },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _filteredSessions.isEmpty
                      ? const Center(child: Text('No login sessions found.'))
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 8),
                          itemCount: _filteredSessions.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, idx) {
                            final session = _filteredSessions[idx];
                            final ts =
                                (session['timestamp'] as Timestamp?)?.toDate();
                            return Dismissible(
                              key: ValueKey(
                                  session['ba_no'] + session['session_id']),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 24),
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
                              onDismissed: (_) => _deleteSession(context,
                                  session['ba_no'], session['session_id']),
                              child: Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
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
                                      Text(
                                          'User: ${session['user_name']} (${session['ba_no']})',
                                          style: const TextStyle(fontSize: 13)),
                                      if (session['device'] != null)
                                        Text('Device: ${session['device']}',
                                            style:
                                                const TextStyle(fontSize: 13)),
                                      if (session['location'] != null)
                                        Text('Location: ${session['location']}',
                                            style:
                                                const TextStyle(fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
