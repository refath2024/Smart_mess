import 'dart:math';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AdminAddShoppingScreen extends StatefulWidget {
  const AdminAddShoppingScreen({super.key});

  @override
  State<AdminAddShoppingScreen> createState() => _AdminAddShoppingScreenState();
}

class _AdminAddShoppingScreenState extends State<AdminAddShoppingScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _buyerController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _voucherIdController = TextEditingController();

  List<XFile> _images = [];

  @override
  void initState() {
    super.initState();
    _voucherIdController.text = _generateVoucherId();
  }

  String _generateVoucherId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return 'VCH-${List.generate(6, (index) => chars[rnd.nextInt(chars.length)]).join()}';
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final List<XFile> pickedImages = await picker.pickMultiImage();

    if (pickedImages.isNotEmpty) {
      setState(() {
        _images = pickedImages;
      });
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Voucher added successfully")),
      );
      Navigator.pop(context);
    }
  }

  void _cancel() {
    Navigator.pop(context);
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
        title: const Text("Add Shopping Voucher"),
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
                _buildTextField("Buyer Name", _buyerController),
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
                _buildTextField(
                  "Voucher ID",
                  _voucherIdController,
                  readOnly: true,
                ),

                // Image picker section
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Upload Images",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (var img in _images)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(img.path),
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                    GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.add_a_photo),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Save/Cancel buttons
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
