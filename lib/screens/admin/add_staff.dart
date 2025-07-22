import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'admin_staff_state_screen.dart';

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
  final _confirmPasswordController = TextEditingController();
  String? _selectedRole;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _passwordsMatch = false;
  String _confirmPasswordError = '';

  final List<String> _roles = [
    'PMC',
    'G2 (Mess)',
    'Mess Secretary',
    'Asst Mess Secretary',
    'RP NCO',
    'Barrack NCO',
    'Mess Sgt',
    'Asst Mess Sgt',
    'Clerk',
    'Cook',
    'Butler',
    'Waiter',
    'NC(E)',
  ];

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Confirm Submission'),
          content:
              Text('Are you sure you want to add ${_nameController.text}?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirm')),
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
          MaterialPageRoute(
              builder: (context) => const AdminStaffStateScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add user.')),
        );
      }
    }
  }

  Future<bool> _onWillPop() async {
    bool hasChanges = _baNoController.text.isNotEmpty ||
        _rankController.text.isNotEmpty ||
        _nameController.text.isNotEmpty ||
        _unitController.text.isNotEmpty ||
        _mobileController.text.isNotEmpty ||
        _emailController.text.isNotEmpty ||
        _passwordController.text.isNotEmpty ||
        _confirmPasswordController.text.isNotEmpty ||
        _selectedRole != null;

    if (hasChanges) {
      return await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Discard Changes?'),
              content: const Text('Do you want to discard the changes?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('No'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Yes'),
                ),
              ],
            ),
          ) ??
          false;
    }
    return true;
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
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: const Color(0xFFF4F4F4),
          appBar: AppBar(
            backgroundColor: const Color(0xFF002B5B),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () async {
                if (await _onWillPop()) {
                  Navigator.of(context).pop();
                }
              },
              color: Colors.white,
            ),
            title: const Text(
              'Registration form',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
          ),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
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
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                      ),
                      const SizedBox(height: 24),
                      buildInputField(
                        _baNoController,
                        'BA/ID No',
                        isRequired: true,
                      ),
                      buildInputField(
                        _rankController,
                        'Rank',
                        isRequired: true,
                      ),
                      buildInputField(
                        _nameController,
                        'Name',
                        isRequired: true,
                      ),
                      buildInputField(
                        _unitController,
                        'Unit',
                        isRequired: true,
                      ),
                      buildInputField(
                        _mobileController,
                        'Mobile No',
                        inputType: TextInputType.phone,
                        isRequired: true,
                      ),
                      buildInputField(
                        _emailController,
                        'E-Mail',
                        inputType: TextInputType.emailAddress,
                        isRequired: true,
                      ),
                      buildInputField(
                        _passwordController,
                        'Password',
                        isRequired: true,
                        obscure: _obscurePassword,
                        onChanged: (value) {
                          if (_confirmPasswordController.text.isNotEmpty) {
                            setState(() {
                              _passwordsMatch =
                                  value == _confirmPasswordController.text;
                              _confirmPasswordError =
                                  _confirmPasswordController.text != value
                                      ? 'Passwords do not match'
                                      : '';
                            });
                          }
                        },
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          onChanged: (value) {
                            setState(() {
                              _passwordsMatch =
                                  value == _passwordController.text;
                              _confirmPasswordError = value.isEmpty
                                  ? 'Please enter confirm password'
                                  : value != _passwordController.text
                                      ? 'Passwords do not match'
                                      : '';
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'Confirm Password *',
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_confirmPasswordController.text.isNotEmpty)
                                  Icon(
                                    _passwordsMatch
                                        ? Icons.check_circle
                                        : Icons.error,
                                    color: _passwordsMatch
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                IconButton(
                                  icon: Icon(_obscureConfirmPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword =
                                          !_obscureConfirmPassword;
                                    });
                                  },
                                ),
                              ],
                            ),
                            errorText: _confirmPasswordError.isNotEmpty
                                ? _confirmPasswordError
                                : null,
                            errorStyle: const TextStyle(
                              color: Colors.red,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: _confirmPasswordController.text.isEmpty
                                    ? Colors.blue
                                    : _passwordsMatch
                                        ? Colors.green
                                        : Colors.red,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: _confirmPasswordController.text.isEmpty
                                    ? Colors.grey
                                    : _passwordsMatch
                                        ? Colors.green
                                        : Colors.red,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter confirm password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Role *',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                        ),
                        value: _selectedRole,
                        items: _roles.map((String role) {
                          return DropdownMenuItem<String>(
                            value: role,
                            child: Text(role),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => _selectedRole = value),
                        validator: (value) =>
                            value == null ? 'Please select a role' : null,
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0052CC),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(Icons.save),
                              label: const Text('Submit'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Confirm Cancel'),
                                    content: const Text(
                                        'Are you sure you want to cancel? All changes will be lost.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('No'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        style: TextButton.styleFrom(
                                            foregroundColor: Colors.red),
                                        child: const Text('Yes'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const AdminStaffStateScreen(),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(Icons.cancel),
                              label: const Text('Cancel'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildInputField(
    TextEditingController controller,
    String label, {
    bool obscure = false,
    TextInputType inputType = TextInputType.text,
    Widget? suffixIcon,
    bool isRequired = true,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: inputType,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          suffixIcon: suffixIcon,
        ),
        validator: validator ??
            (value) {
              if (isRequired && (value == null || value.isEmpty)) {
                return 'Please enter $label';
              }
              return null;
            },
      ),
    );
  }
}
