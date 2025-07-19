import 'package:flutter/material.dart';
import 'user_home_screen.dart';
import 'meal_in_out_screen.dart';
import 'messing.dart';
import '../login_screen.dart';
import 'menu_set_screen.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  String? _selectedMonth;
  int? _selectedYear;
  String? _selectedMethod;

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
                _buildInputField('Transaction ID'),
                _buildInputField('Amount', isNumber: true),
              ] else if (method == 'Bank') ...[
                _buildInputField('Bank Account No'),
                _buildInputField('Bank Name'),
                _buildInputField('Amount', isNumber: true),
              ] else if (method == 'Card') ...[
                _buildInputField('Bank Name'),
                _buildInputField('Amount', isNumber: true),
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Payment details successfully sent."),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 7, 125, 21),
            ),
            child: const Text('Submit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildSidebarTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool selected = false,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.blue.shade100,
      child: ListTile(
        selected: selected,
        selectedTileColor: Colors.blue.shade100,
        leading: Icon(
          icon,
          color: color ?? (selected ? Colors.blue : Colors.black),
        ),
        title: Text(title, style: TextStyle(color: color ?? Colors.black)),
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
              const Text(
                "Select Payment Method",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
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
              const Text(
                "View Your Mess Bill",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedMonth,
                items: _months
                    .map(
                      (month) =>
                          DropdownMenuItem(value: month, child: Text(month)),
                    )
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
                    .map(
                      (year) => DropdownMenuItem(
                        value: year,
                        child: Text(year.toString()),
                      ),
                    )
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
                          "Viewing bill for $_selectedMonth $_selectedYear",
                        ),
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
