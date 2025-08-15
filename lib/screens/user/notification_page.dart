import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final notificationsSnapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('user_id', isEqualTo: currentUser.uid)
          .get();

      final notifications = notificationsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? '',
          'message': data['message'] ?? '',
          'type': data['type'] ?? 'General',
          'sender_name': data['sender_name'] ?? 'Admin',
          'created_at': data['created_at'] as Timestamp?,
          'is_read': data['is_read'] ?? false,
        };
      }).toList();

      // Sort notifications by created_at in descending order (newest first)
      notifications.sort((a, b) {
        final aTime =
            (a['created_at'] as Timestamp?)?.toDate() ?? DateTime.now();
        final bTime =
            (b['created_at'] as Timestamp?)?.toDate() ?? DateTime.now();
        return bTime.compareTo(aTime);
      });

      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });

      // Mark all notifications as read
      await _markAllAsRead(
          notificationsSnapshot.docs.map((doc) => doc.id).toList());
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading notifications: $e')),
        );
      }
    }
  }

  Future<void> _markAllAsRead(List<String> notificationIds) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      for (final id in notificationIds) {
        final notificationRef =
            FirebaseFirestore.instance.collection('notifications').doc(id);
        batch.update(notificationRef, {'is_read': true});
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error marking notifications as read: $e');
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'Announcement':
        return Icons.campaign;
      case 'Bill Reminder':
        return Icons.receipt_long;
      case 'Menu Update':
        return Icons.restaurant_menu;
      case 'Event':
        return Icons.event;
      case 'Emergency':
        return Icons.emergency;
      case 'System Update':
        return Icons.system_update;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'Announcement':
        return Colors.blue;
      case 'Bill Reminder':
        return Colors.orange;
      case 'Menu Update':
        return Colors.green;
      case 'Event':
        return Colors.purple;
      case 'Emergency':
        return Colors.red;
      case 'System Update':
        return Colors.teal;
      default:
        return const Color(0xFF002B5B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF002B5B),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Notifications",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 80,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No notifications yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'You\'ll see new notifications here',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      final createdAt =
                          notification['created_at'] as Timestamp?;
                      final dateTime = createdAt?.toDate() ?? DateTime.now();
                      final formattedDate =
                          DateFormat('MMM d, yyyy – h:mm a').format(dateTime);
                      final type = notification['type'] as String;
                      final isRead = notification['is_read'] as bool;

                      return Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: isRead ? 1 : 3,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: isRead
                                ? null
                                : Border.all(
                                    color: _getNotificationColor(type)
                                        .withOpacity(0.3),
                                    width: 1,
                                  ),
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _getNotificationColor(type)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getNotificationIcon(type),
                                color: _getNotificationColor(type),
                                size: 24,
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    notification['title'] as String,
                                    style: TextStyle(
                                      fontWeight: isRead
                                          ? FontWeight.w500
                                          : FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                if (!isRead)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: _getNotificationColor(type),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  notification['message'] as String,
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.schedule,
                                      size: 14,
                                      color: Colors.grey.shade500,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      formattedDate,
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getNotificationColor(type)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        type,
                                        style: TextStyle(
                                          color: _getNotificationColor(type),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
