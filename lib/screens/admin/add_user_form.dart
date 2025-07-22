import 'package:flutter/material.dart';

class AddUserFormPage extends StatefulWidget {
  const AddUserFormPage({super.key});

  @override
  State<AddUserFormPage> createState() => _AddUserFormPageState();
}

class _AddUserFormPageState extends State<AddUserFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _baController = TextEditingController();
  final _rankController = TextEditingController();
  final _nameController = TextEditingController();
  final _unitController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedRole;

  @override
  void dispose() {
    _baController.dispose();
    _rankController.dispose();
    _nameController.dispose();
    _unitController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User successfully added')),
      );
      Navigator.pop(context);
    }
  }

  void _cancelForm() {
    Navigator.pop(context);
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscure,
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'This field is required' : null,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF1FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF002B5B),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text("Add New User", style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
              ],
            ),
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text("Add New User",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(label: 'BA No:', controller: _baController),
                  _buildTextField(label: 'Rank:', controller: _rankController),
                  _buildTextField(label: 'Name:', controller: _nameController),
                  _buildTextField(label: 'Unit:', controller: _unitController),
                  _buildTextField(
                    label: 'Mobile No:',
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                  ),
                  _buildTextField(
                    label: 'E-Mail:',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  _buildTextField(
                    label: 'Password:',
                    controller: _passwordController,
                    obscure: true,
                  ),
                  const SizedBox(height: 12),
                  const Text("Role:", style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    items: const [
                      DropdownMenuItem(value: null, child: Text('None')),
                      DropdownMenuItem(value: 'Dining Member', child: Text('Dining Member')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value;
                      });
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Please select a role' : null,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text("Save", style: TextStyle(color: Colors.white)),
                      ),
                      ElevatedButton(
                        onPressed: _cancelForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text("Cancel", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
