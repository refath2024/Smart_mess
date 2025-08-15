import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  String? _selectedMonth;
  int? _selectedYear;
  bool _paymentSuccess = false;
  bool _isSubmitting = false;

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

  // User data
  Map<String, dynamic>? _userData;
  double _totalDue = 0.0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadCurrentBill();
  }

  @override
  void dispose() {
    _controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('user_requests')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            _userData = userDoc.data();
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _loadCurrentBill() async {
    try {
      final now = DateTime.now();
      final monthYear = "${_getMonthName(now.month)} ${now.year}";

      final billDoc = await FirebaseFirestore.instance
          .collection('Bills')
          .doc(monthYear)
          .get();

      if (billDoc.exists && _userData != null) {
        final billData = billDoc.data() as Map<String, dynamic>;
        final userBill =
            billData[_userData!['ba_no']?.toString()] as Map<String, dynamic>?;

        if (userBill != null) {
          setState(() {
            _totalDue = userBill['total_due']?.toDouble() ?? 0.0;
          });
        }
      }
    } catch (e) {
      print('Error loading current bill: $e');
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

  final List<String> _months = [
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
    'December',
  ];

  final int currentYear = DateTime.now().year;

  void _showPaymentModal(String method) {
    // Clear controllers
    _controllers.forEach((key, controller) => controller.clear());
    _controllers['amount']!.text = _totalDue.toStringAsFixed(2);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Enter $method Payment Details'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              if (method == 'bKash' || method == 'Tap') ...[
                _buildInputField('Phone Number',
                    controller: _controllers['phone']!),
                _buildInputField('Transaction ID',
                    controller: _controllers['transactionId']!),
                _buildInputField('Amount',
                    controller: _controllers['amount']!, isNumber: true),
              ] else if (method == 'Bank') ...[
                _buildInputField('Bank Account No',
                    controller: _controllers['accountNo']!),
                _buildInputField('Bank Name',
                    controller: _controllers['bankName']!),
                _buildInputField('Amount',
                    controller: _controllers['amount']!, isNumber: true),
              ] else if (method == 'Card') ...[
                _buildInputField('Card Number',
                    controller: _controllers['cardNumber']!),
                _buildInputField('Expiry Date',
                    controller: _controllers['expiryDate']!),
                _buildInputField('CVV',
                    controller: _controllers['cvv']!, isNumber: true),
                _buildInputField('Amount',
                    controller: _controllers['amount']!, isNumber: true),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed:
                _isSubmitting ? null : () => _submitPaymentRequest(method),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 7, 125, 21),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('Submit', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Future<void> _submitPaymentRequest(String method) async {
    if (_userData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('User data not found'), backgroundColor: Colors.red),
      );
      return;
    }

    // Validate form
    final amount = double.tryParse(_controllers['amount']!.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a valid amount'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final baNo = _userData!['ba_no']?.toString();
      final timestamp = DateTime.now();

      // Create payment request data
      Map<String, dynamic> paymentData = {
        'amount': amount,
        'payment_method': method,
        'ba_no': baNo,
        'rank': _userData!['rank'],
        'name': _userData!['name'],
        'status': 'pending',
        'request_time': timestamp,
      };

      // Add method-specific details
      if (method == 'bKash' || method == 'Tap') {
        paymentData['phone_number'] = _controllers['phone']!.text;
        paymentData['transaction_id'] = _controllers['transactionId']!.text;
      } else if (method == 'Bank') {
        paymentData['account_no'] = _controllers['accountNo']!.text;
        paymentData['bank_name'] = _controllers['bankName']!.text;
      } else if (method == 'Card') {
        paymentData['card_number'] = _controllers['cardNumber']!.text;
        paymentData['expiry_date'] = _controllers['expiryDate']!.text;
        paymentData['cvv'] = _controllers['cvv']!.text;
      }

      // Get existing payment history
      final paymentHistoryRef =
          FirebaseFirestore.instance.collection('payment_history').doc(baNo);

      final paymentDoc = await paymentHistoryRef.get();

      // Create transaction entry with auto-incrementing number
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

      // Save payment request
      await paymentHistoryRef.set({
        transactionKey: paymentData,
      }, SetOptions(merge: true));

      Navigator.pop(context);
      setState(() {
        _paymentSuccess = true;
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Payment request submitted! Amount: ৳${amount.toStringAsFixed(2)}"),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error submitting payment: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildInputField(String label,
      {bool isNumber = false,
      String? initialValue,
      TextEditingController? controller}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller ??
            (initialValue != null
                ? TextEditingController(text: initialValue)
                : null),
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              if (_paymentSuccess)
                Card(
                  color: Colors.green.shade50,
                  margin: const EdgeInsets.only(bottom: 20),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Payment Request Submitted!",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text(
                                  "Your payment request has been sent to admin for approval."),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Card(
                color: Colors.red.shade50,
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.receipt, color: Colors.red, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Total Due",
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red)),
                            const SizedBox(height: 4),
                            Text("৳ ${_totalDue.toStringAsFixed(2)}",
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.black87)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text("Select Payment Method",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Column(
                children: [
                  _paymentMethodCard("bKash", 'assets/bkash.png'),
                  _paymentMethodCard("Bank", 'assets/bank.png'),
                  _paymentMethodCard("Tap", 'assets/Tap.png'),
                  _paymentMethodCard("Card", 'assets/card.png'),
                ],
              ),
              const SizedBox(height: 30),
              const Text("View Your Mess Bill",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedMonth,
                items: _months
                    .map((month) =>
                        DropdownMenuItem(value: month, child: Text(month)))
                    .toList(),
                decoration: const InputDecoration(
                  labelText: "Select Month",
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _selectedMonth = value),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                value: _selectedYear,
                items: List.generate(6, (i) => currentYear - i)
                    .map((year) => DropdownMenuItem(
                        value: year, child: Text(year.toString())))
                    .toList(),
                decoration: const InputDecoration(
                  labelText: "Select Year",
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _selectedYear = value),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () {
                  if (_selectedMonth != null && _selectedYear != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            "Viewing bill for $_selectedMonth $_selectedYear"),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please select both month and year"),
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(10),
                splashColor: Colors.blue.shade100,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF002B5B),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    "View Bill",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _paymentMethodCard(String method, String? iconPath) {
    return InkWell(
      onTap: () => _showPaymentModal(method),
      borderRadius: BorderRadius.circular(12),
      splashColor: Colors.blue.shade100,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFf0f2f5), Color(0xFFE8EEF5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 6,
              offset: Offset(2, 2),
            ),
          ],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (iconPath != null) ...[
                Image.asset(iconPath, height: 36, width: 36),
                const SizedBox(width: 16),
              ],
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text("Make payment through $method"),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
