import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InsertTransactionScreen extends StatefulWidget {
  const InsertTransactionScreen({super.key});

  @override
  State<InsertTransactionScreen> createState() =>
      _InsertTransactionScreenState();
}

class _InsertTransactionScreenState extends State<InsertTransactionScreen> {
  bool _isSubmitting = false;
  bool _isLoadingUsers = true;
  bool _isLoadingBill = false;

  // User selection
  List<Map<String, dynamic>> _users = [];
  Map<String, dynamic>? _selectedUser;
  double _totalDue = 0.0;

  // Controllers for payment forms
  final Map<String, TextEditingController> _controllers = {
    'phone': TextEditingController(),
    'transactionId': TextEditingController(),
    'amount': TextEditingController(),
    'accountNo': TextEditingController(),
    'bankName': TextEditingController(),
    'cardNumber': TextEditingController(),
    'expiryDate': TextEditingController(),
    'cvv': TextEditingController(),
  };

  String _selectedPaymentMethod = 'bKash';
  final List<String> _paymentMethods = ['bKash', 'Tap', 'Bank', 'Card'];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('user_requests')
          .where('approved', isEqualTo: true)
          .where('status', isEqualTo: 'active')
          .get();

      List<Map<String, dynamic>> users = [];
      for (var doc in usersSnapshot.docs) {
        final userData = doc.data();
        users.add({
          'uid': doc.id,
          'ba_no': userData['ba_no'],
          'name': userData['name'],
          'rank': userData['rank'],
        });
      }

      setState(() {
        _users = users;
        _isLoadingUsers = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingUsers = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading users: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadUserBill(String baNo) async {
    setState(() {
      _isLoadingBill = true;
    });

    try {
      final now = DateTime.now();
      final monthYear = "${_getMonthName(now.month)} ${now.year}";

      final billDoc = await FirebaseFirestore.instance
          .collection('Bills')
          .doc(monthYear)
          .get();

      if (billDoc.exists) {
        final billData = billDoc.data() as Map<String, dynamic>;
        final userBill = billData[baNo] as Map<String, dynamic>?;

        if (userBill != null) {
          // Calculate current total due
          final currentBill = userBill['current_bill']?.toDouble() ?? 0.0;
          final arrears = userBill['arrears']?.toDouble() ?? 0.0;
          final paidAmount = userBill['paid_amount']?.toDouble() ?? 0.0;
          final calculatedTotalDue = currentBill + arrears - paidAmount;

          setState(() {
            _totalDue = calculatedTotalDue > 0 ? calculatedTotalDue : 0.0;
            _controllers['amount']!.text = _totalDue.toStringAsFixed(2);
          });
        } else {
          setState(() {
            _totalDue = 0.0;
            _controllers['amount']!.text = '0.00';
          });
        }
      } else {
        setState(() {
          _totalDue = 0.0;
          _controllers['amount']!.text = '0.00';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading bill: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoadingBill = false;
      });
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  Future<void> _submitTransaction() async {
    if (_selectedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a user'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate form based on payment method
    final amount = double.tryParse(_controllers['amount']!.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate method-specific fields
    if (_selectedPaymentMethod == 'bKash' || _selectedPaymentMethod == 'Tap') {
      if (_controllers['phone']!.text.isEmpty ||
          _controllers['transactionId']!.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill in all required fields'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } else if (_selectedPaymentMethod == 'Bank') {
      if (_controllers['accountNo']!.text.isEmpty ||
          _controllers['bankName']!.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill in all required fields'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } else if (_selectedPaymentMethod == 'Card') {
      if (_controllers['cardNumber']!.text.isEmpty ||
          _controllers['expiryDate']!.text.isEmpty ||
          _controllers['cvv']!.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill in all required fields'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final baNo = _selectedUser!['ba_no']?.toString();
      final timestamp = DateTime.now();
      final now = DateTime.now();
      final monthYear = "${_getMonthName(now.month)} ${now.year}";

      // Directly update the bill with paid amount (admin transaction - auto approved)
      final billRef =
          FirebaseFirestore.instance.collection('Bills').doc(monthYear);
      final billDoc = await billRef.get();

      if (billDoc.exists) {
        final billData = billDoc.data() as Map<String, dynamic>;
        final userBill = billData[baNo] as Map<String, dynamic>?;

        if (userBill != null) {
          final currentPaidAmount = userBill['paid_amount']?.toDouble() ?? 0.0;
          final newPaidAmount = currentPaidAmount + amount;

          // Get current bill and arrears for calculation
          final currentBill = userBill['current_bill']?.toDouble() ?? 0.0;
          final arrears = userBill['arrears']?.toDouble() ?? 0.0;

          // Calculate new total due: current_bill + arrears - paid_amount
          final newTotalDue = currentBill + arrears - newPaidAmount;

          // Determine status automatically based on total due
          String newStatus = newTotalDue <= 0 ? 'Paid' : 'Unpaid';

          await billRef.update({
            '$baNo.paid_amount': newPaidAmount,
            '$baNo.total_due': newTotalDue,
            '$baNo.bill_status': newStatus,
          });

          // Also record in payment history as approved transaction
          Map<String, dynamic> paymentData = {
            'amount': amount,
            'payment_method': _selectedPaymentMethod,
            'ba_no': baNo,
            'rank': _selectedUser!['rank'],
            'name': _selectedUser!['name'],
            'status': 'approved', // Admin transactions are auto-approved
            'request_time': timestamp,
            'approved_at': timestamp,
            'admin_created': true, // Flag to indicate admin created this
          };

          // Add method-specific details
          if (_selectedPaymentMethod == 'bKash' ||
              _selectedPaymentMethod == 'Tap') {
            paymentData['phone_number'] = _controllers['phone']!.text;
            paymentData['transaction_id'] = _controllers['transactionId']!.text;
          } else if (_selectedPaymentMethod == 'Bank') {
            paymentData['account_no'] = _controllers['accountNo']!.text;
            paymentData['bank_name'] = _controllers['bankName']!.text;
          } else if (_selectedPaymentMethod == 'Card') {
            paymentData['card_number'] = _controllers['cardNumber']!.text;
            paymentData['expiry_date'] = _controllers['expiryDate']!.text;
            paymentData['cvv'] = _controllers['cvv']!.text;
          }

          // Save to payment history
          final paymentHistoryRef = FirebaseFirestore.instance
              .collection('payment_history')
              .doc(baNo);

          final paymentDoc = await paymentHistoryRef.get();

          String dateKey =
              "${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}";

          Map<String, dynamic> existingData = {};
          if (paymentDoc.exists) {
            existingData = paymentDoc.data() as Map<String, dynamic>;
          }

          // Find next transaction number for this date
          int transactionNumber = 1;
          while (existingData
              .containsKey('${dateKey}_transaction_$transactionNumber')) {
            transactionNumber++;
          }

          String transactionKey = '${dateKey}_transaction_$transactionNumber';

          await paymentHistoryRef.set({
            transactionKey: paymentData,
          }, SetOptions(merge: true));

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    "Transaction created successfully! Amount: ৳${amount.toStringAsFixed(2)}"),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true); // Return true to indicate success
          }
        } else {
          throw Exception('User bill not found for current month');
        }
      } else {
        throw Exception('Bills not found for current month');
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating transaction: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildInputField(String label, TextEditingController controller,
      {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F9),
      appBar: AppBar(
        title: const Text('Add Transaction'),
        backgroundColor: const Color(0xFF002B5B),
        foregroundColor: Colors.white,
      ),
      body: _isLoadingUsers
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              minimum: const EdgeInsets.only(bottom: 12),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Create Transaction',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),

                        // User Selection
                        const Text('Select User',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () async {
                            final selected =
                                await showDialog<Map<String, dynamic>>(
                              context: context,
                              builder: (context) {
                                String search = '';
                                List<Map<String, dynamic>> filtered = _users;
                                return StatefulBuilder(
                                  builder: (context, setState) {
                                    filtered = _users.where((user) {
                                      final s = search.toLowerCase();
                                      return (user['ba_no']
                                                  ?.toString()
                                                  .toLowerCase()
                                                  .contains(s) ??
                                              false) ||
                                          (user['name']
                                                  ?.toString()
                                                  .toLowerCase()
                                                  .contains(s) ??
                                              false) ||
                                          (user['rank']
                                                  ?.toString()
                                                  .toLowerCase()
                                                  .contains(s) ??
                                              false);
                                    }).toList();
                                    return AlertDialog(
                                      title: const Text('Search User'),
                                      content: SingleChildScrollView(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            TextField(
                                              decoration: const InputDecoration(
                                                  hintText:
                                                      'Type to search...'),
                                              onChanged: (val) =>
                                                  setState(() => search = val),
                                            ),
                                            const SizedBox(height: 12),
                                            SizedBox(
                                              width: double.maxFinite,
                                              height: 300,
                                              child: filtered.isEmpty
                                                  ? const Center(
                                                      child: Text(
                                                          'No users found'))
                                                  : ListView.builder(
                                                      itemCount:
                                                          filtered.length,
                                                      itemBuilder:
                                                          (context, idx) {
                                                        final user =
                                                            filtered[idx];
                                                        return ListTile(
                                                          title: Text(
                                                              '${user['ba_no']} - ${user['rank']} ${user['name']}'),
                                                          onTap: () =>
                                                              Navigator.of(
                                                                      context)
                                                                  .pop(user),
                                                        );
                                                      },
                                                    ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                          child: const Text('Cancel'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            );
                            if (selected != null) {
                              setState(() {
                                _selectedUser = selected;
                                _loadUserBill(selected['ba_no'].toString());
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            child: Text(
                              _selectedUser == null
                                  ? 'Choose a user'
                                  : '${_selectedUser!['ba_no']} - ${_selectedUser!['rank']} ${_selectedUser!['name']}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),

                        if (_selectedUser != null) ...[
                          const SizedBox(height: 16),

                          // Total Due Display
                          if (_isLoadingBill)
                            const Center(child: CircularProgressIndicator())
                          else
                            Card(
                              color: _totalDue > 0
                                  ? Colors.red.shade50
                                  : Colors.green.shade50,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.receipt,
                                      color: _totalDue > 0
                                          ? Colors.red
                                          : Colors.green,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text('Current Total Due',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w600)),
                                          Text(
                                            '৳${_totalDue.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: _totalDue > 0
                                                  ? Colors.red
                                                  : Colors.green,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          const SizedBox(height: 16),

                          // Payment Method Selection
                          const Text('Payment Method',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedPaymentMethod,
                            items: _paymentMethods.map((method) {
                              return DropdownMenuItem(
                                  value: method, child: Text(method));
                            }).toList(),
                            onChanged: (method) {
                              setState(() {
                                _selectedPaymentMethod = method!;
                                // Clear controllers when method changes
                                _controllers.forEach((key, controller) {
                                  if (key != 'amount') controller.clear();
                                });
                              });
                            },
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Payment Method Specific Fields
                          if (_selectedPaymentMethod == 'bKash' ||
                              _selectedPaymentMethod == 'Tap') ...[
                            _buildInputField(
                                'Phone Number', _controllers['phone']!),
                            _buildInputField('Transaction ID',
                                _controllers['transactionId']!),
                          ] else if (_selectedPaymentMethod == 'Bank') ...[
                            _buildInputField(
                                'Bank Account No', _controllers['accountNo']!),
                            _buildInputField(
                                'Bank Name', _controllers['bankName']!),
                          ] else if (_selectedPaymentMethod == 'Card') ...[
                            _buildInputField(
                                'Card Number', _controllers['cardNumber']!),
                            _buildInputField(
                                'Expiry Date', _controllers['expiryDate']!),
                            _buildInputField('CVV', _controllers['cvv']!,
                                isNumber: true),
                          ],

                          _buildInputField('Amount', _controllers['amount']!,
                              isNumber: true),

                          const SizedBox(height: 24),

                          // Submit Button
                          ElevatedButton(
                            onPressed:
                                _isSubmitting ? null : _submitTransaction,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Create Transaction',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
