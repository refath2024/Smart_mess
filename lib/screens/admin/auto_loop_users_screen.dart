import '../../services/admin_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AutoLoopUsersScreen extends StatefulWidget {
  const AutoLoopUsersScreen({super.key});

  @override
  State<AutoLoopUsersScreen> createState() => _AutoLoopUsersScreenState();
}

class _AutoLoopUsersScreenState extends State<AutoLoopUsersScreen> {
  final AdminAuthService _adminAuthService = AdminAuthService();
  Map<String, dynamic>? _currentUserData;

  @override
  void initState() {
    super.initState();
    _fetchCurrentAdminData();
    _fetchAutoLoopUsers();
  }

  void _fetchCurrentAdminData() async {
    final data = await _adminAuthService.getCurrentAdminData();
    if (mounted) {
      setState(() {
        _currentUserData = data;
      });
    }
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> autoLoopUsers = [];
  bool _isLoading = true;

  // Edit controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _rankController = TextEditingController();
  final TextEditingController _baNoController = TextEditingController();
  bool _breakfastEnabled = false;
  bool _lunchEnabled = false;
  bool _dinnerEnabled = false;
  bool _enabled = true;

  // Removed duplicate initState

  @override
  void dispose() {
    _nameController.dispose();
    _rankController.dispose();
    _baNoController.dispose();
    super.dispose();
  }

  Future<void> _fetchAutoLoopUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final QuerySnapshot snapshot =
          await _firestore.collection('user_auto_loop').orderBy('ba_no').get();

      autoLoopUsers = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'ba_no': data['ba_no'] ?? '',
          'name': data['name'] ?? '',
          'rank': data['rank'] ?? '',
          'enabled': data['enabled'] ?? false,
          'meal_pattern': data['meal_pattern'] ??
              {
                'breakfast': false,
                'lunch': false,
                'dinner': false,
              },
        };
      }).toList();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching auto loop users: $e')),
        );
      }
    }
  }

  Future<void> _toggleUserEnabled(String docId, bool currentEnabled) async {
    try {
      await _firestore.collection('user_auto_loop').doc(docId).update({
        'enabled': !currentEnabled,
      });

      // Activity log for toggle
      final adminName = _currentUserData?['name'] ?? 'Admin';
      final adminBaNo = _currentUserData?['ba_no'] ?? '';
      // Find user info for log
      final user =
          autoLoopUsers.firstWhere((u) => u['id'] == docId, orElse: () => {});
      final userName = user['name'] ?? '';
      final userBaNo = user['ba_no'] ?? '';
      final statusMsg = !currentEnabled ? 'Enabled' : 'Disabled';
      if (adminBaNo.isNotEmpty) {
        await _firestore
            .collection('staff_activity_log')
            .doc(adminBaNo)
            .collection('logs')
            .add({
          'timestamp': FieldValue.serverTimestamp(),
          'actionType': 'Toggle Auto Loop User',
          'message':
              '$adminName toggled auto loop user $userName ($userBaNo) to $statusMsg.',
          'name': adminName,
        });
      }

      // Update local data
      setState(() {
        final index = autoLoopUsers.indexWhere((user) => user['id'] == docId);
        if (index != -1) {
          autoLoopUsers[index]['enabled'] = !currentEnabled;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              !currentEnabled
                  ? 'Auto loop enabled for user'
                  : 'Auto loop disabled for user',
            ),
            backgroundColor: !currentEnabled ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating user: $e')),
        );
      }
    }
  }

  void _showEditDialog(Map<String, dynamic> user) {
    _nameController.text = user['name'];
    _rankController.text = user['rank'];
    _baNoController.text = user['ba_no'];
    _enabled = user['enabled'];

    final mealPattern = user['meal_pattern'] as Map<String, dynamic>;
    _breakfastEnabled = mealPattern['breakfast'] ?? false;
    _lunchEnabled = mealPattern['lunch'] ?? false;
    _dinnerEnabled = mealPattern['dinner'] ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Edit Auto Loop User'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _baNoController,
                  decoration: const InputDecoration(
                    labelText: 'BA Number',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _rankController,
                  decoration: const InputDecoration(
                    labelText: 'Rank',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Enabled/Disabled Toggle
                Row(
                  children: [
                    const Text('Auto Loop Status: '),
                    Switch(
                      value: _enabled,
                      onChanged: (value) async {
                        setDialogState(() {
                          _enabled = value;
                        });
                        // Activity log for toggle
                        final adminName = _currentUserData?['name'] ?? 'Admin';
                        final adminBaNo = _currentUserData?['ba_no'] ?? '';
                        final userName = _nameController.text.trim();
                        final userBaNo = _baNoController.text.trim();
                        final statusMsg = value ? 'Enabled' : 'Disabled';
                        if (adminBaNo.isNotEmpty) {
                          await _firestore
                              .collection('staff_activity_log')
                              .doc(adminBaNo)
                              .collection('logs')
                              .add({
                            'timestamp': FieldValue.serverTimestamp(),
                            'actionType': 'Toggle Auto Loop User',
                            'message':
                                '$adminName toggled auto loop user $userName ($userBaNo) to $statusMsg.',
                            'name': adminName,
                          });
                        }
                      },
                    ),
                    Text(_enabled ? 'Enabled' : 'Disabled'),
                  ],
                ),
                const SizedBox(height: 16),

                // Meal Pattern Section
                const Text(
                  'Meal Pattern:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text('Breakfast'),
                  value: _breakfastEnabled,
                  onChanged: (value) {
                    setDialogState(() {
                      _breakfastEnabled = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                CheckboxListTile(
                  title: const Text('Lunch'),
                  value: _lunchEnabled,
                  onChanged: (value) {
                    setDialogState(() {
                      _lunchEnabled = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                CheckboxListTile(
                  title: const Text('Dinner'),
                  value: _dinnerEnabled,
                  onChanged: (value) {
                    setDialogState(() {
                      _dinnerEnabled = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _saveUser(user['id']),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveUser(String docId) async {
    try {
      final oldUser = autoLoopUsers.firstWhere((user) => user['id'] == docId,
          orElse: () => {});
      final oldPattern = oldUser['meal_pattern'] ?? {};
      final oldEnabled = oldUser['enabled'];
      final oldName = oldUser['name'] ?? '';
      final oldRank = oldUser['rank'] ?? '';
      final oldBaNo = oldUser['ba_no'] ?? '';

      await _firestore.collection('user_auto_loop').doc(docId).update({
        'ba_no': _baNoController.text.trim(),
        'name': _nameController.text.trim(),
        'rank': _rankController.text.trim(),
        'enabled': _enabled,
        'meal_pattern': {
          'breakfast': _breakfastEnabled,
          'lunch': _lunchEnabled,
          'dinner': _dinnerEnabled,
        },
      });

      // Activity log for edit
      final adminName = _currentUserData?['name'] ?? 'Admin';
      final adminBaNo = _currentUserData?['ba_no'] ?? '';
      if (adminBaNo.isNotEmpty) {
        List<String> changes = [];
        if (oldName != _nameController.text.trim()) {
          changes.add('Name: $oldName → ${_nameController.text.trim()}');
        }
        if (oldRank != _rankController.text.trim()) {
          changes.add('Rank: $oldRank → ${_rankController.text.trim()}');
        }
        if (oldBaNo != _baNoController.text.trim()) {
          changes.add('BA No: $oldBaNo → ${_baNoController.text.trim()}');
        }
        if (oldEnabled != _enabled) {
          changes.add(
              'Status: ${oldEnabled ? 'Enabled' : 'Disabled'} → ${_enabled ? 'Enabled' : 'Disabled'}');
        }
        if (oldPattern['breakfast'] != _breakfastEnabled) {
          changes.add(
              'Breakfast: ${oldPattern['breakfast'] == true ? 'Yes' : 'No'} → ${_breakfastEnabled ? 'Yes' : 'No'}');
        }
        if (oldPattern['lunch'] != _lunchEnabled) {
          changes.add(
              'Lunch: ${oldPattern['lunch'] == true ? 'Yes' : 'No'} → ${_lunchEnabled ? 'Yes' : 'No'}');
        }
        if (oldPattern['dinner'] != _dinnerEnabled) {
          changes.add(
              'Dinner: ${oldPattern['dinner'] == true ? 'Yes' : 'No'} → ${_dinnerEnabled ? 'Yes' : 'No'}');
        }
        final details =
            'Edited auto loop user ${_nameController.text.trim()} (${_baNoController.text.trim()}). ' +
                (changes.isNotEmpty
                    ? 'Changes: ' + changes.join('; ')
                    : 'No field changed.');
        await _firestore
            .collection('staff_activity_log')
            .doc(adminBaNo)
            .collection('logs')
            .add({
          'timestamp': FieldValue.serverTimestamp(),
          'actionType': 'Edit Auto Loop User',
          'message': '$adminName edited auto loop user. $details',
          'name': adminName,
        });
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchAutoLoopUsers(); // Refresh data
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving user: $e')),
        );
      }
    }
  }

  Future<void> _deleteUser(String docId, String userName) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content:
            Text('Are you sure you want to delete $userName from auto loop?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Get user details before delete
        final user =
            autoLoopUsers.firstWhere((u) => u['id'] == docId, orElse: () => {});
        final baNo = user['ba_no'] ?? '';
        final name = user['name'] ?? '';
        final rank = user['rank'] ?? '';
        final pattern = user['meal_pattern'] ?? {};
        final enabled = user['enabled'] ?? false;

        await _firestore.collection('user_auto_loop').doc(docId).delete();

        // Activity log for delete
        final adminName = _currentUserData?['name'] ?? 'Admin';
        final adminBaNo = _currentUserData?['ba_no'] ?? '';
        if (adminBaNo.isNotEmpty) {
          final details =
              'Deleted auto loop user $name ($baNo), Rank: $rank, Status: ${enabled ? 'Enabled' : 'Disabled'}, '
              'Breakfast: ${pattern['breakfast'] == true ? 'Yes' : 'No'}, '
              'Lunch: ${pattern['lunch'] == true ? 'Yes' : 'No'}, '
              'Dinner: ${pattern['dinner'] == true ? 'Yes' : 'No'}';
          await _firestore
              .collection('staff_activity_log')
              .doc(adminBaNo)
              .collection('logs')
              .add({
            'timestamp': FieldValue.serverTimestamp(),
            'actionType': 'Delete Auto Loop User',
            'message': '$adminName deleted auto loop user. $details',
            'name': adminName,
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _fetchAutoLoopUsers(); // Refresh data
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting user: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF002B5B),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: const Text(
          'Auto Loop Users',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchAutoLoopUsers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : autoLoopUsers.isEmpty
              ? const Center(
                  child: Text(
                    'No auto loop users found',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Auto Loop Users: ${autoLoopUsers.length}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(
                                const Color(0xFF1A4D8F),
                              ),
                              columns: const [
                                DataColumn(
                                  label: Text(
                                    'BA Number',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Name',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Rank',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Status',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Breakfast',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Lunch',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Dinner',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Actions',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                              rows: autoLoopUsers.map((user) {
                                final mealPattern = user['meal_pattern']
                                    as Map<String, dynamic>;
                                final bool isEnabled = user['enabled'] ?? false;

                                return DataRow(
                                  color:
                                      WidgetStateProperty.resolveWith<Color?>(
                                    (Set<WidgetState> states) {
                                      return isEnabled
                                          ? null
                                          : Colors.grey[100];
                                    },
                                  ),
                                  cells: [
                                    DataCell(Text(user['ba_no'])),
                                    DataCell(Text(user['name'])),
                                    DataCell(Text(user['rank'])),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isEnabled
                                              ? Colors.green
                                              : Colors.red,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          isEnabled ? 'Enabled' : 'Disabled',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Icon(
                                        mealPattern['breakfast']
                                            ? Icons.check
                                            : Icons.close,
                                        color: mealPattern['breakfast']
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                    DataCell(
                                      Icon(
                                        mealPattern['lunch']
                                            ? Icons.check
                                            : Icons.close,
                                        color: mealPattern['lunch']
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                    DataCell(
                                      Icon(
                                        mealPattern['dinner']
                                            ? Icons.check
                                            : Icons.close,
                                        color: mealPattern['dinner']
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Edit button
                                          IconButton(
                                            icon: const Icon(Icons.edit,
                                                color: Colors.blue),
                                            onPressed: () =>
                                                _showEditDialog(user),
                                            tooltip: 'Edit',
                                          ),
                                          // Toggle enable/disable
                                          IconButton(
                                            icon: Icon(
                                              isEnabled
                                                  ? Icons.toggle_on
                                                  : Icons.toggle_off,
                                              color: isEnabled
                                                  ? Colors.green
                                                  : Colors.grey,
                                            ),
                                            onPressed: () => _toggleUserEnabled(
                                                user['id'], isEnabled),
                                            tooltip: isEnabled
                                                ? 'Disable'
                                                : 'Enable',
                                          ),
                                          // Delete button
                                          IconButton(
                                            icon: const Icon(Icons.delete,
                                                color: Colors.red),
                                            onPressed: () => _deleteUser(
                                                user['id'], user['name']),
                                            tooltip: 'Delete',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
