import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/admin_auth_service.dart';

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
  bool _isLoading = false;

  final AdminAuthService _adminAuthService = AdminAuthService();
  Map<String, dynamic>? _currentAdminData;
  List<String> _availableRoles = [];

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

  // Roles that can only have one person assigned
  final List<String> _uniqueRoles = [
    'PMC',
    'G2 (Mess)',
    'Mess Secretary',
    'Asst Mess Secretary',
    'RP NCO',
    'Barrack NCO',
    'Mess Sgt',
    'Asst Mess Sgt',
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentAdminData();
    _loadAvailableRoles();
  }

  Future<void> _loadCurrentAdminData() async {
    try {
      final adminData = await _adminAuthService.getCurrentAdminData();
      setState(() {
        _currentAdminData = adminData;
      });
    } catch (e) {
      debugPrint('Failed to load admin data: $e');
    }
  }

  Future<void> _loadAvailableRoles() async {
    try {
      // Get all existing staff roles
      final existingStaff =
          await FirebaseFirestore.instance.collection('staff_state').get();

      final existingRoles = existingStaff.docs
          .map((doc) => doc.data()['role'] as String?)
          .where((role) => role != null)
          .toSet();

      setState(() {
        // Filter out unique roles that are already assigned
        // But allow multiple assignments for non-unique roles
        _availableRoles = _roles.where((role) {
          if (_uniqueRoles.contains(role)) {
            // For unique roles, only show if not already assigned
            return !existingRoles.contains(role);
          } else {
            // For non-unique roles, always show
            return true;
          }
        }).toList();
      });
    } catch (e) {
      debugPrint('Failed to load available roles: $e');
      // If there's an error, show all roles
      setState(() {
        _availableRoles = _roles;
      });
    }
  }

  bool get _hasAvailableUniqueRoles {
    return _availableRoles.any((role) => _uniqueRoles.contains(role));
  }

  Future<bool> _checkEmailExists() async {
    try {
      // Check if email exists in staff_state collection
      final existingStaffQuery = await FirebaseFirestore.instance
          .collection('staff_state')
          .where('email', isEqualTo: _emailController.text.trim())
          .get();

      if (existingStaffQuery.docs.isNotEmpty) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Email Already Exists'),
            content: const Text(
              'This email is already registered for a staff member. Please use a different email address.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return false;
      }

      return true; // Email doesn't exist, can proceed
    } catch (e) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to check email: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return false;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Check if email already exists
    final canProceed = await _checkEmailExists();
    if (!canProceed) {
      setState(() => _isLoading = false);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Submission'),
        content: Text('Are you sure you want to add ${_nameController.text}?'),
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

    if (confirm != true) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim());
      // Generate a temporary document ID for Firestore
      final String staffId = credential.user!.uid; // Use Firebase Auth user ID

      // Save staff info to Firestore under 'staff_state' collection
      await FirebaseFirestore.instance
          .collection('staff_state')
          .doc(staffId)
          .set({
        'ba_no': _baNoController.text.trim(),
        'rank': _rankController.text.trim(),
        'name': _nameController.text.trim(),
        'unit': _unitController.text.trim(),
        'email': _emailController.text.trim(),
        'mobile': _mobileController.text.trim(),
        'role': _selectedRole,
        'status': 'Active', // Set as active staff member
        'created_at': FieldValue.serverTimestamp(),
        'user_id': staffId,
        'created_by': _currentAdminData?['name'] ?? 'Admin',
      });

      // Success dialog
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Success'),
          content: Text(
            '${_nameController.text} has been successfully registered as a staff member.\n\nCreated by: ${_currentAdminData?['name'] ?? 'Admin'}\n\nThey can now log in using their email and password.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Return to staff state page
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to add staff member: $e'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK')),
          ],
        ),
      );
    } finally {
      setState(() => _isLoading = false);
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

  Widget _buildRankField() {
    return buildInputField(
      _rankController,
      'Rank',
      isRequired: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
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
                      color: Colors.black.withValues(alpha: 0.08),
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
                        'Add New Staff Member',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                      ),
                      if (!_hasAvailableUniqueRoles)
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info, color: Colors.blue.shade800),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'All unique staff roles (PMC, G2, Mess Secretary, etc.) are currently assigned. You can still add general staff members like Clerk, Cook, Butler, Waiter.',
                                  style: TextStyle(
                                    color: Colors.blue.shade800,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),
                      buildInputField(
                        _baNoController,
                        'BA/ID No',
                        isRequired: true,
                      ),
                      _buildRankField(),
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
                        'Mobile No (at least 11 digits)',
                        inputType: TextInputType.phone,
                        isRequired: true,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Please enter mobile number';
                          }
                          if (!RegExp(r'^\d+$').hasMatch(val)) {
                            return 'Mobile number must contain only digits';
                          }
                          if (val.length < 11) {
                            return 'Mobile number must be at least 11 digits';
                          }
                          return null;
                        },
                      ),
                      buildInputField(
                        _emailController,
                        'E-Mail',
                        inputType: TextInputType.emailAddress,
                        isRequired: true,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Please enter email';
                          }
                          final emailRegex =
                              RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                          if (!emailRegex.hasMatch(val)) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      buildInputField(
                        _passwordController,
                        'Password',
                        isRequired: true,
                        obscure: _obscurePassword,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Please enter password';
                          }
                          if (val.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
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
                        items: _availableRoles.map((String role) {
                          return DropdownMenuItem<String>(
                            value: role,
                            child: Text(role),
                          );
                        }).toList(),
                        onChanged: _availableRoles.isEmpty
                            ? null
                            : (value) => setState(() => _selectedRole = value),
                        validator: (value) =>
                            value == null ? 'Please select a role' : null,
                        hint: const Text('Select a role'),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0052CC),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.save),
                              label:
                                  Text(_isLoading ? 'Submitting...' : 'Submit'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoading
                                  ? null
                                  : () async {
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
                                        Navigator.of(context)
                                            .pop(); // Return to staff state page
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
