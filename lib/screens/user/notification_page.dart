import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Add intl to your pubspec.yaml if not already

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      {
        "message": "Menu has been changed.",
        "dateTime": DateTime.now().subtract(const Duration(minutes: 10)),
      },
      {
        "message": "Farewell program will be arranged.",
        "dateTime": DateTime.now().subtract(const Duration(hours: 2)),
      },
      {
        "message": "Voting time is almost finished, please vote.",
        "dateTime": DateTime.now().subtract(const Duration(days: 1, hours: 1)),
      },
      {
        "message": "Your bill is due soon.",
        "dateTime": DateTime.now().subtract(const Duration(days: 2, hours: 3)),
      },
      {
        "message": "New menu suggestions are open.",
        "dateTime": DateTime.now().subtract(const Duration(days: 3, hours: 5)),
      },
    ];

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
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final notification = notifications[index];
          final dateTime = notification["dateTime"] as DateTime;
          final formattedDate = DateFormat('MMM d, yyyy – h:mm a').format(dateTime);

          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 3,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: const Icon(Icons.notifications, color: Color(0xFF002B5B)),
              ),
              title: Text(
                notification["message"] as String,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                formattedDate,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          );
        },
      ),
    );
  }
}