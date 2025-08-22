import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/admin_auth_service.dart';

class AddDiningMemberForm extends StatefulWidget {
  const AddDiningMemberForm({super.key});

  @override
  State<AddDiningMemberForm> createState() => _AddDiningMemberFormState();
}

class _AddDiningMemberFormState extends State<AddDiningMemberForm> {
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
  String? _selectedRank;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _passwordsMatch = false;
  String _confirmPasswordError = '';
  bool _isLoading = false;

  final AdminAuthService _adminAuthService = AdminAuthService();
  Map<String, dynamic>? _currentAdminData;

  // Military ranks organized by service branch
  final List<String> _armyRanks = [
    'General',
    'Lieutenant General',
    'Major General',
    'Brigadier General',
    'Colonel',
    'Lieutenant Colonel',
    'Major',
    'Captain',
    'Lieutenant',
    'Second Lieutenant',
  ];

  final List<String> _navyRanks = [
    'Admiral',
    'Vice Admiral',
    'Rear Admiral',
    'Commodore',
    'Captain (Navy)',
    'Commander',
    'Lieutenant Commander',
    'Lieutenant (Navy)',
    'Sub-Lieutenant',
    'Acting Sub-Lieutenant',
  ];

  final List<String> _airForceRanks = [
    'Air Chief Marshal',
    'Air Marshal',
    'Air Vice Marshal',
    'Air Commodore',
    'Group Captain',
    'Wing Commander',
    'Squadron Leader',
    'Flight Lieutenant',
    'Flying Officer',
    'Pilot Officer',
  ];

  final List<String> _roles = [
    'Dining Member',
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentAdminData();
  }

  Future<void> _loadCurrentAdminData() async {
    try {
      final adminData = await _adminAuthService.getCurrentAdminData();
      if (adminData != null) {
        setState(() {
          _currentAdminData = adminData;
        });
        debugPrint(
            'Admin data loaded successfully: ${adminData['name']} (${adminData['email']})');
      } else {
        debugPrint('Failed to load admin data: adminData is null');
        // Set a fallback admin data
        setState(() {
          _currentAdminData = {
            'name': 'System Admin',
            'email': 'admin@system.com',
          };
        });
        debugPrint('Using fallback admin data');
      }
    } catch (e) {
      debugPrint('Failed to load admin data: $e');
      // Set a default admin data to prevent null errors
      setState(() {
        _currentAdminData = {
          'name': 'System Admin',
          'email': 'admin@system.com',
        };
      });
    }
  }

  Future<bool> _checkEmailExists() async {
    try {
      // Check if email exists in user_requests collection
      final existingUserQuery = await FirebaseFirestore.instance
          .collection('user_requests')
          .where('email', isEqualTo: _emailController.text.trim())
          .get();

      if (existingUserQuery.docs.isNotEmpty) {
        final userData = existingUserQuery.docs.first.data();
        final bool isApproved = userData['approved'] ?? false;
        final bool isRejected = userData['rejected'] ?? false;

        if (isApproved) {
          // User is already approved
          await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Email Already Exists'),
              content: const Text(
                'This email is already registered and approved. Please use a different email address.',
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
        } else if (!isRejected) {
          // User has pending application
          await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Application Pending'),
              content: const Text(
                'This email already has a pending application. Please use a different email address.',
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
      }

      return true; // Email doesn't exist or was rejected, can proceed
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

    // Load and save admin data BEFORE any operations
    await _loadCurrentAdminData();

    // Save the current admin info
    final String approvedByName = _currentAdminData?['name'] ?? 'System Admin';
    final String adminEmail = _currentAdminData?['email'] ?? 'admin@system.com';

    debugPrint('Admin adding member: $approvedByName ($adminEmail)');

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
      // Store current admin's Firebase Auth user info
      final currentAdminUser = FirebaseAuth.instance.currentUser;
      final String? adminAuthEmail = currentAdminUser?.email;
      final String? adminAuthUid = currentAdminUser?.uid;

      debugPrint(
          'Current admin Firebase user: $adminAuthEmail (UID: $adminAuthUid)');

      // Create Firebase Auth user for the dining member
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim());

      String userid = credential.user!.uid;

      debugPrint(
          'Created new dining member Firebase Auth: ${credential.user!.email} (UID: $userid)');
      debugPrint('Using approved_by: $approvedByName');

      // Save dining member info to Firestore
      await FirebaseFirestore.instance
          .collection('user_requests')
          .doc(userid)
          .set({
        'ba_no': _baNoController.text.trim(),
        'rank': _rankController.text.trim(),
        'name': _nameController.text.trim(),
        'unit': _unitController.text.trim(),
        'email': _emailController.text.trim(),
        'mobile': _mobileController.text.trim(),
        'approved': true, // Admin is directly approving
        'rejected': false,
        'status': 'active',
        'created_at': FieldValue.serverTimestamp(),
        'approved_at': FieldValue.serverTimestamp(),
        'user_id': userid,
        'approved_by_admin': true,
        'approved_by': approvedByName, // Use the saved admin name
        'approved_by_email': adminEmail, // Store admin email for reference
        'application_date': DateTime.now().toIso8601String(),
        'firebase_auth_created': true, // Firebase Auth account created
      });

      // Log activity (admin as actor, like add_shopping.dart)
      final adminName = _currentAdminData?['name'] ?? 'Admin';
      final baNo = _currentAdminData?['ba_no'] ?? '';
      if (baNo.isNotEmpty) {
        final details =
            'BA No: ${_baNoController.text.trim()}, Rank: ${_rankController.text.trim()}, Name: ${_nameController.text.trim()}, Unit: ${_unitController.text.trim()}, Email: ${_emailController.text.trim()}, Mobile: ${_mobileController.text.trim()}';
        await FirebaseFirestore.instance
            .collection('staff_activity_log')
            .doc(baNo)
            .collection('logs')
            .add({
          'timestamp': FieldValue.serverTimestamp(),
          'actionType': 'Add Dining Member',
          'message': '$adminName added dining member. Details: $details',
          'name': adminName,
        });
      }

      // Sign out the newly created dining member
      await FirebaseAuth.instance.signOut();

      debugPrint('Signed out dining member, admin session may be affected');

      if (context.mounted) {
        // Success dialog with appropriate message
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success'),
            content: Text(
              '${_nameController.text} has been successfully registered as a dining member.\n\nApproved by: $approvedByName\n\nFirebase Auth account created. They can now log in using their email and password.\n\nNote: You may need to log in again as admin if prompted.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context)
                      .pop(); // Return to dining member state page
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Registration Error'),
          content: Text(e.message ?? 'An unexpected error occurred.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK')),
          ],
        ),
      );
    } catch (e) {
      if (context.mounted) {
        // Handle any other errors
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to add dining member: $e'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK')),
            ],
          ),
        );
      }
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

  Widget _buildRankDropdown() {
    // Combine all ranks with service branch headers
    List<DropdownMenuItem<String>> allRanks = [];

    // Army ranks
    allRanks.add(const DropdownMenuItem<String>(
      enabled: false,
      value: null,
      child: Text(
        'Bangladesh Army',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
      ),
    ));
    allRanks.addAll(_armyRanks.map((rank) => DropdownMenuItem<String>(
          value: rank,
          child: Text('  $rank'),
        )));

    // Navy ranks
    allRanks.add(const DropdownMenuItem<String>(
      enabled: false,
      value: null,
      child: Text(
        'Bangladesh Navy',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
      ),
    ));
    allRanks.addAll(_navyRanks.map((rank) => DropdownMenuItem<String>(
          value: rank,
          child: Text('  $rank'),
        )));

    // Air Force ranks
    allRanks.add(const DropdownMenuItem<String>(
      enabled: false,
      value: null,
      child: Text(
        'Bangladesh Air Force',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
      ),
    ));
    allRanks.addAll(_airForceRanks.map((rank) => DropdownMenuItem<String>(
          value: rank,
          child: Text('  $rank'),
        )));

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: _selectedRank,
        decoration: const InputDecoration(
          labelText: 'Rank *',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        items: allRanks,
        onChanged: (String? newValue) {
          setState(() {
            _selectedRank = newValue;
            _rankController.text = newValue ?? '';
          });
        },
        validator: (value) =>
            value == null || value.isEmpty ? 'Please select rank' : null,
        hint: const Text('Select rank'),
        isExpanded: true,
        menuMaxHeight: 300,
      ),
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
                        'Add New Dining Member',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                      ),
                      const SizedBox(height: 24),
                      buildInputField(
                        _baNoController,
                        'BA No',
                        isRequired: true,
                      ),
                      _buildRankDropdown(),
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
                                            .pop(); // Return to dining member state page
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
