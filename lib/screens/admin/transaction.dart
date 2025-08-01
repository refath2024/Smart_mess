import 'package:flutter/material.dart';

// This should match the model used in payments_dashboard.dart
class PaymentData {
  final double amount;
  final DateTime paymentTime;
  final String paymentMethod;
  final String baNo;
  final String rank;
  final String name;

  PaymentData({
    required this.amount,
    required this.paymentTime,
    required this.paymentMethod,
    required this.baNo,
    required this.rank,
    required this.name,
  });
}

class InsertTransactionScreen extends StatefulWidget {
  const InsertTransactionScreen({super.key});

  @override
  _InsertTransactionScreenState createState() => _InsertTransactionScreenState();
}

class _InsertTransactionScreenState extends State<InsertTransactionScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController baNoController = TextEditingController();
  final TextEditingController rankController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController transactionNoController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  String selectedMethod = 'bKash';
  final List<String> paymentMethods = ['bKash', 'Tap', 'Card', 'Nagad', 'Cash'];

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Confirm Transaction"),
          content: Text(
              "Are you sure you want to submit the following transaction?\n\n"
              "BA No: ${baNoController.text}\n"
              "Name: ${nameController.text}\n"
              "Amount: ${amountController.text}"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog

                final newTxn = PaymentData(
                  amount: double.parse(amountController.text),
                  paymentTime: DateTime.now(),
                  paymentMethod: selectedMethod,
                  baNo: baNoController.text,
                  rank: rankController.text,
                  name: nameController.text,
                );

                Navigator.pop(context, newTxn); // ✅ Return to dashboard with data
              },
              child: const Text("Confirm"),
            ),
          ],
        ),
      );
    }
  }

  void _cancelForm() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Cancel Confirmation"),
        content: const Text("Are you sure you want to cancel? All data will be lost."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back without result
            },
            child: const Text("Yes, Cancel"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F9),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.all(16),
          width: 500,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                blurRadius: 10,
                color: Colors.black12,
                offset: Offset(0, 4),
              )
            ],
          ),
          child: Form(
            key: _formKey,
            child: ListView(shrinkWrap: true, children: [
              const Center(
                child: Text(
                  "Transaction Insertion Form",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField("BA No", baNoController),
              _buildTextField("Rank", rankController),
              _buildTextField("Name", nameController),
              _buildTextField("Transaction No", transactionNoController),
              _buildDropdown(),
              _buildTextField("Amount", amountController, isNumber: true),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text("Insert Transaction"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _cancelForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text("Cancel"),
                    ),
                  ),
                ],
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontSize: 14, color: Colors.grey[700])),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            validator: (value) =>
                value!.isEmpty ? "Please enter $label" : null,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Payment Method",
              style: TextStyle(fontSize: 14, color: Colors.grey[700])),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            value: selectedMethod,
            items: paymentMethods
                .map((method) =>
                    DropdownMenuItem(value: method, child: Text(method)))
                .toList(),
            onChanged: (value) => setState(() => selectedMethod = value!),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            ),
          ),
        ],
      ),
    );
  }
}
