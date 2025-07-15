import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'admin_staff_state_screen.dart' as staff_screen;

class AddNewUserForm extends StatefulWidget {
  const AddNewUserForm({super.key});

  @override
  State<AddNewUserForm> createState() => _AddNewUserFormState();
}

class _AddNewUserFormState extends State<AddNewUserForm> {
  final _formKey = GlobalKey<FormState>();
  final _baNoController = TextEditingController();
  final _rankController = TextEditingController();
  final _nameController = TextEditingController();
  final _unitController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedRole;

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Confirm Submission'),
          content: Text('Are you sure you want to add ${_nameController.text}?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
          ],
        ),
      );

      if (confirm != true) return;

      final response = await http.post(
        Uri.parse('https://your-domain.com/add_staffs.php'),
        body: {
          'ba_no': _baNoController.text,
          'rank': _rankController.text,
          'name': _nameController.text,
          'unit': _unitController.text,
          'mobile_no': _mobileController.text,
          'email': _emailController.text,
          'password': _passwordController.text,
          'role': _selectedRole,
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User added successfully!')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const staff_screen.AdminStaffStateScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add user.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _baNoController.dispose();
    _rankController.dispose();
    _nameController.dispose();
    _unitController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Add New User',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 24),
                  buildInputField(_baNoController, 'BA No'),
                  buildInputField(_rankController, 'Rank'),
                  buildInputField(_nameController, 'Name'),
                  buildInputField(_unitController, 'Unit'),
                  buildInputField(_mobileController, 'Mobile No'),
                  buildInputField(_emailController, 'E-Mail', inputType: TextInputType.emailAddress),
                  buildInputField(_passwordController, 'Password', obscure: true),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedRole,
                    items: const [
                      DropdownMenuItem(value: 'user', child: Text('Dining Member')),
                    ],
                    onChanged: (value) => setState(() => _selectedRole = value),
                    validator: (value) => value == null ? 'Please select a role' : null,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                        child: const Text('Submit'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const staff_screen.AdminStaffStateScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildInputField(TextEditingController controller, String label,
      {bool obscure = false, TextInputType inputType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: inputType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        validator: (value) => (value == null || value.isEmpty) ? 'Please enter $label' : null,
      ),
    );
  }
}