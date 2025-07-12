import 'package:flutter/material.dart';

class AdminAddShoppingScreen extends StatefulWidget {
  const AdminAddShoppingScreen({super.key});

  @override
  State<AdminAddShoppingScreen> createState() => _AdminAddShoppingScreenState();
}

class _AdminAddShoppingScreenState extends State<AdminAddShoppingScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _productController = TextEditingController();
  final TextEditingController _unitPriceController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _totalPriceController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _buyerController = TextEditingController();
  final TextEditingController _voucherIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _unitPriceController.addListener(_calculateTotal);
    _amountController.addListener(_calculateTotal);
  }

  void _calculateTotal() {
    final unit = double.tryParse(_unitPriceController.text) ?? 0;
    final amount = double.tryParse(_amountController.text) ?? 0;
    final total = unit * amount;
    _totalPriceController.text = total.toStringAsFixed(2);
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final name = _productController.text;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("$name added successfully.")));

      Navigator.pop(context); // Go back to history page
    }
  }

  void _cancel() {
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _unitPriceController.dispose();
    _amountController.dispose();
    _productController.dispose();
    _totalPriceController.dispose();
    _dateController.dispose();
    _buyerController.dispose();
    _voucherIdController.dispose();
    super.dispose();
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType type = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: type,
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Shopping Entry"),
        backgroundColor: const Color(0xFF002B5B),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildTextField("Product Name", _productController),
                _buildTextField(
                  "Unit Price (kg/qty)",
                  _unitPriceController,
                  type: TextInputType.number,
                ),
                _buildTextField(
                  "Amount (kg/qty)",
                  _amountController,
                  type: TextInputType.number,
                ),
                _buildTextField(
                  "Total Price",
                  _totalPriceController,
                  type: TextInputType.number,
                  readOnly: true,
                ),
                _buildTextField(
                  "Date",
                  _dateController,
                  readOnly: true,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      builder: (context, child) {
                        return Theme(
                          data: ThemeData.light().copyWith(
                            primaryColor: const Color(0xFF002B5B),
                            colorScheme: const ColorScheme.light(
                              primary: Color(0xFF002B5B),
                            ),
                            buttonTheme: const ButtonThemeData(
                              textTheme: ButtonTextTheme.primary,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );

                    if (picked != null) {
                      setState(() {
                        _dateController.text =
                            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                      });
                    }
                  },
                ),

                _buildTextField("Buyer", _buyerController),
                _buildTextField("Voucher ID", _voucherIdController),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A4D8F),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          "Save",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _cancel,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
