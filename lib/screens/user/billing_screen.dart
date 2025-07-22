import 'package:flutter/material.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  String? _selectedMonth;
  int? _selectedYear;
  String? _selectedMethod;
  bool _paymentSuccess = false;

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
    setState(() => _selectedMethod = method);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Enter $method Payment Details'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              if (method == 'bKash' || method == 'Tap') ...[
                _buildInputField('Phone Number'),
                _buildInputField('Transaction ID'),
                _buildInputField('Amount',
                    isNumber: true, initialValue: '1000'),
              ] else if (method == 'Bank') ...[
                _buildInputField('Bank Account No'),
                _buildInputField('Bank Name'),
                _buildInputField('Amount',
                    isNumber: true, initialValue: '1000'),
              ] else if (method == 'Card') ...[
                _buildInputField('Card Number'),
                _buildInputField('Expiry Date'),
                _buildInputField('CVV', isNumber: true),
                _buildInputField('Amount',
                    isNumber: true, initialValue: '1000'),
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
            onPressed: () {
              Navigator.pop(context);
              setState(() => _paymentSuccess = true);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text("Payment successful!"),
                  backgroundColor: Colors.green.shade700,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 7, 125, 21),
            ),
            child: const Text('Submit', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Widget _buildInputField(String label,
      {bool isNumber = false, String? initialValue}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        controller: initialValue != null
            ? TextEditingController(text: initialValue)
            : null,
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
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text("Payment Successful!",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text("Your payment of ৳1000 has been processed."),
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
                child: const Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.receipt, color: Colors.red, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text("Total Due",
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red)),
                            SizedBox(height: 4),
                            Text("৳ 1000",
                                style: TextStyle(
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
