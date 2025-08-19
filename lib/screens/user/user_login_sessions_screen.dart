import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserLoginSessionsScreen extends StatelessWidget {
  const UserLoginSessionsScreen({super.key});

  Future<String?> _getBaNo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final userDoc = await FirebaseFirestore.instance
        .collection('user_requests')
        .doc(user.uid)
        .get();
    if (!userDoc.exists) return null;
    return userDoc.data()!['ba_no']?.toString();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getBaNo(),
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
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('login_sessions')
                .doc(baNo)
                .collection('sessions')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No login sessions found.'));
              }
              final sessions = snapshot.data!.docs;
              return ListView.separated(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                itemCount: sessions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, idx) {
                  final session = sessions[idx].data() as Map<String, dynamic>;
                  final ts = (session['timestamp'] as Timestamp?)?.toDate();
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const Icon(Icons.login, color: Colors.blue),
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
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
