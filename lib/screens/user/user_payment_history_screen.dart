import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserPaymentHistoryScreen extends StatefulWidget {
  const UserPaymentHistoryScreen({Key? key}) : super(key: key);

  @override
  State<UserPaymentHistoryScreen> createState() =>
      _UserPaymentHistoryScreenState();
}

class _UserPaymentHistoryScreenState extends State<UserPaymentHistoryScreen> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in.')),
      );
    }

    Future<String?> getBaNo() async {
      final userDoc = await FirebaseFirestore.instance
          .collection('user_requests')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        return data['ba_no']?.toString();
      }
      return null;
    }

    return FutureBuilder<String?>(
      future: getBaNo(),
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
            title: const Text('My Payment History'),
            backgroundColor: const Color(0xFF002B5B),
            foregroundColor: Colors.white,
          ),
          body: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.date_range),
                        label: Text(_startDate == null
                            ? 'Start Date'
                            : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _startDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null)
                            setState(() => _startDate = picked);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_startDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: 'Clear',
                        onPressed: () => setState(() => _startDate = null),
                      ),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.date_range),
                        label: Text(_endDate == null
                            ? 'End Date'
                            : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _endDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) setState(() => _endDate = picked);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_endDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: 'Clear',
                        onPressed: () => setState(() => _endDate = null),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('payment_history')
                      .doc(baNo)
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return const Center(
                          child: Text('No payment history found.'));
                    }
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    var transactions = data.entries
                        .where((e) => e.key.contains('_transaction_'))
                        .map((e) => e.value as Map<String, dynamic>)
                        .toList();
                    if (transactions.isEmpty) {
                      return const Center(
                          child: Text('No payment history found.'));
                    }
                    transactions.sort((a, b) {
                      final aTime = a['request_time']?.toDate();
                      final bTime = b['request_time']?.toDate();
                      if (aTime == null && bTime == null) return 0;
                      if (aTime == null) return 1;
                      if (bTime == null) return -1;
                      return bTime.compareTo(aTime);
                    });
                    // Filter by date
                    if (_startDate != null) {
                      transactions = transactions.where((tx) {
                        final t = tx['request_time']?.toDate();
                        return t != null && !t.isBefore(_startDate!);
                      }).toList();
                    }
                    if (_endDate != null) {
                      transactions = transactions.where((tx) {
                        final t = tx['request_time']?.toDate();
                        return t != null && !t.isAfter(_endDate!);
                      }).toList();
                    }
                    if (transactions.isEmpty) {
                      return const Center(
                          child: Text(
                              'No payment history found for selected date.'));
                    }
                    return ListView.separated(
                      itemCount: transactions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, idx) {
                        final tx = transactions[idx];
                        final ts = (tx['request_time'] as Timestamp?)?.toDate();
                        return ListTile(
                          leading: const Icon(Icons.payments),
                          title: Text(
                              '৳${tx['amount']?.toStringAsFixed(2) ?? '0.00'}'),
                          subtitle: Text(
                              'Time: ${ts != null ? ts.toString() : 'Unknown'}\nMethod: ${tx['payment_method'] ?? ''}'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: tx['status'] == 'pending'
                                  ? Colors.orange
                                  : tx['status'] == 'approved'
                                      ? Colors.green
                                      : Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              tx['status']?.toUpperCase() ?? 'UNKNOWN',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                            ),
                          ),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Payment Details'),
                                content: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                          'Amount: ৳${tx['amount']?.toStringAsFixed(2) ?? '0.00'}'),
                                      Text(
                                          'Method: ${tx['payment_method'] ?? ''}'),
                                      Text('Status: ${tx['status'] ?? ''}'),
                                      if (tx['transaction_id']?.isNotEmpty ==
                                          true)
                                        Text(
                                            'Transaction ID: ${tx['transaction_id']}'),
                                      if (tx['phone_number']?.isNotEmpty ==
                                          true)
                                        Text('Phone: ${tx['phone_number']}'),
                                      if (tx['account_no']?.isNotEmpty == true)
                                        Text('Account No: ${tx['account_no']}'),
                                      if (tx['bank_name']?.isNotEmpty == true)
                                        Text('Bank: ${tx['bank_name']}'),
                                      if (tx['card_number']?.isNotEmpty == true)
                                        Text('Card: ${tx['card_number']}'),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          },
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
