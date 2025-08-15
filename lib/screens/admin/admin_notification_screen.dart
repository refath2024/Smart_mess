import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminNotificationScreen extends StatefulWidget {
  const AdminNotificationScreen({super.key});

  @override
  State<AdminNotificationScreen> createState() =>
      _AdminNotificationScreenState();
}

class _AdminNotificationScreenState extends State<AdminNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  String _selectedNotificationType = 'General';
  String _selectedTargetType = 'All Users';
  String? _selectedUserId;
  List<Map<String, dynamic>> _allUsers = [];
  bool _isLoading = false;
  bool _isLoadingUsers = false;

  final List<String> _notificationTypes = [
    'General',
    'Announcement',
    'Bill Reminder',
    'Menu Update',
    'Event',
    'Emergency',
    'System Update',
  ];

  final List<String> _targetTypes = [
    'All Users',
    'Specific User',
  ];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('user_requests')
          .where('approved', isEqualTo: true)
          .get();

      final users = usersSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': data['user_id'] ??
              doc.id, // Use user_id field instead of document id
          'name': data['name'] ?? 'Unknown',
          'email': data['email'] ?? '',
          'ba_no': data['ba_no'] ?? '',
          'rank': data['rank'] ?? '',
          'unit': data['unit'] ?? '',
        };
      }).toList();

      // Sort the users by name in the app instead of in the query
      users
          .sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

      setState(() {
        _allUsers = users;
        _isLoadingUsers = false;
      });
    } catch (e) {
      setState(() => _isLoadingUsers = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e')),
        );
      }
    }
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedTargetType == 'Specific User' && _selectedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a user')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentAdmin = FirebaseAuth.instance.currentUser;
      final adminData = await FirebaseFirestore.instance
          .collection('admin_users')
          .doc(currentAdmin!.uid)
          .get();

      final senderName = adminData.data()?['name'] ?? 'Admin';

      final notificationData = {
        'title': _titleController.text.trim(),
        'message': _messageController.text.trim(),
        'type': _selectedNotificationType,
        'sender_id': currentAdmin.uid,
        'sender_name': senderName,
        'created_at': FieldValue.serverTimestamp(),
        'is_read': false,
      };

      if (_selectedTargetType == 'All Users') {
        // Send to all approved users
        final batch = FirebaseFirestore.instance.batch();

        for (final user in _allUsers) {
          final notificationRef =
              FirebaseFirestore.instance.collection('notifications').doc();

          batch.set(notificationRef, {
            ...notificationData,
            'user_id': user['id'],
            'target_type': 'all',
          });
        }

        await batch.commit();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Notification sent to ${_allUsers.length} users')),
          );
        }
      } else {
        // Send to specific user
        await FirebaseFirestore.instance.collection('notifications').add({
          ...notificationData,
          'user_id': _selectedUserId,
          'target_type': 'specific',
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notification sent to selected user')),
          );
        }
      }

      // Clear form
      _titleController.clear();
      _messageController.clear();
      setState(() {
        _selectedNotificationType = 'General';
        _selectedTargetType = 'All Users';
        _selectedUserId = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending notification: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF002B5B),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Send Notification',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification Type Selection
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Notification Type',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedNotificationType,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: _notificationTypes.map((type) {
                          IconData icon;
                          Color color;
                          switch (type) {
                            case 'Announcement':
                              icon = Icons.campaign;
                              color = Colors.blue;
                              break;
                            case 'Bill Reminder':
                              icon = Icons.receipt_long;
                              color = Colors.orange;
                              break;
                            case 'Menu Update':
                              icon = Icons.restaurant_menu;
                              color = Colors.green;
                              break;
                            case 'Event':
                              icon = Icons.event;
                              color = Colors.purple;
                              break;
                            case 'Emergency':
                              icon = Icons.emergency;
                              color = Colors.red;
                              break;
                            case 'System Update':
                              icon = Icons.system_update;
                              color = Colors.teal;
                              break;
                            default:
                              icon = Icons.notifications;
                              color = Colors.grey;
                          }
                          return DropdownMenuItem(
                            value: type,
                            child: Row(
                              children: [
                                Icon(icon, color: color, size: 20),
                                const SizedBox(width: 8),
                                Text(type),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedNotificationType = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Target Selection
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.people, color: Color(0xFF002B5B)),
                          SizedBox(width: 8),
                          Text(
                            'Send To',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedTargetType,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.people),
                        ),
                        items: _targetTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedTargetType = value!;
                            _selectedUserId = null;
                          });
                        },
                      ),
                      if (_selectedTargetType == 'Specific User') ...[
                        const SizedBox(height: 16),
                        if (_isLoadingUsers)
                          const Center(child: CircularProgressIndicator())
                        else
                          DropdownButtonFormField<String>(
                            value: _selectedUserId,
                            isExpanded: true,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.person),
                              hintText: 'Select a user',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            items: _allUsers.map((user) {
                              return DropdownMenuItem<String>(
                                value: user['id'] as String,
                                child: SizedBox(
                                  width: double.infinity,
                                  child: Text(
                                    '${user['rank']} ${user['name']}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedUserId = value;
                              });
                            },
                          ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Notification Content
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.edit, color: Color(0xFF002B5B)),
                          SizedBox(width: 8),
                          Text(
                            'Notification Content',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Title Field
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.title),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                        maxLength: 100,
                      ),

                      const SizedBox(height: 16),

                      // Message Field
                      TextFormField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          labelText: 'Message',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.message),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a message';
                          }
                          return null;
                        },
                        maxLength: 500,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Send Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendNotification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF002B5B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.send, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              _selectedTargetType == 'All Users'
                                  ? 'Send to All Users (${_allUsers.length})'
                                  : 'Send Notification',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
