import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _noController = TextEditingController();
  final TextEditingController _rankController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _isLoading = false;
  bool _hasAttemptedSubmit = false;

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

  String? _selectedRank;

  // Helper method to get service branch from rank
  String _getServiceBranch(String rank) {
    if (_armyRanks.contains(rank)) {
      return 'Army';
    } else if (_navyRanks.contains(rank)) {
      return 'Navy';
    } else if (_airForceRanks.contains(rank)) {
      return 'Air Force';
    }
    return '';
  }

  // Helper method to get prefix based on service branch
  String _getPrefix(String serviceBranch) {
    switch (serviceBranch) {
      case 'Army':
        return 'BA-';
      case 'Navy':
        return 'BN-';
      case 'Air Force':
        return 'BAF-';
      default:
        return '';
    }
  }

  // Helper method to extract only numbers from BA number field
  String _extractNumbers(String input) {
    return input.replaceAll(RegExp(r'[^0-9]'), '');
  }

  // Method to update BA number based on selected rank
  void _updateBANumber() {
    if (_selectedRank != null) {
      final serviceBranch = _getServiceBranch(_selectedRank!);
      final prefix = _getPrefix(serviceBranch);

      // Extract only numbers from current BA number
      final numbersOnly = _extractNumbers(_noController.text);

      // Update the BA number with correct prefix
      if (numbersOnly.isNotEmpty) {
        _noController.text = '$prefix$numbersOnly';
        // Move cursor to end
        _noController.selection = TextSelection.fromPosition(
          TextPosition(offset: _noController.text.length),
        );
      } else if (prefix.isNotEmpty) {
        // If no numbers, just set the prefix
        _noController.text = prefix;
        _noController.selection = TextSelection.fromPosition(
          TextPosition(offset: _noController.text.length),
        );
      }
    }
  }

  String? _validateConfirmPassword(String? val) {
    if (val == null || val.isEmpty) return 'Please confirm your password';
    if (val != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  Future<bool> _checkEmailExists() async {
    try {
      // Show loading indicator for email check
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Checking email...'),
            ],
          ),
        ),
      );

      // Check if email exists in user_requests collection
      final existingUserQuery = await FirebaseFirestore.instance
          .collection('user_requests')
          .where('email', isEqualTo: _emailController.text.trim())
          .get();

      // Close loading dialog
      Navigator.of(context).pop();

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
                'This email is already registered and approved. Please use a different email address or contact admin if you need assistance.',
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
        } else if (isRejected) {
          // User was rejected, allow to reapply
          final reapply = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Previous Application Rejected'),
              content: const Text(
                'Your previous application was rejected. Would you like to submit a new application with updated information?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Reapply'),
                ),
              ],
            ),
          );
          return reapply ?? false;
        } else {
          // User has pending application
          await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Application Pending'),
              content: const Text(
                'You already have a pending application with this email. Please wait for admin approval or contact admin for status updates.',
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

      return true; // Email doesn't exist, can proceed
    } catch (e) {
      // Close loading dialog if still open
      Navigator.of(context).pop();

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

  Future<void> _handleApply() async {
    setState(() => _hasAttemptedSubmit = true);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    // Check if email already exists
    final canProceed = await _checkEmailExists();
    if (!canProceed) {
      setState(() => _isLoading = false);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Application'),
        content:
            const Text('Are you sure you want to submit your application?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes')),
        ],
      ),
    );

    if (confirm != true) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Check if this is a reapplication (rejected user)
      final existingUserQuery = await FirebaseFirestore.instance
          .collection('user_requests')
          .where('email', isEqualTo: _emailController.text.trim())
          .get();

      String userid;
      bool isReapplication = false;

      if (existingUserQuery.docs.isNotEmpty) {
        // This is a reapplication, use existing document ID
        final existingDoc = existingUserQuery.docs.first;
        userid = existingDoc.id;
        isReapplication = true;
      } else {
        // Create Firebase Auth user first to get UID
        final userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        userid = userCredential.user!.uid;

        // Update the user's display name
        await userCredential.user
            ?.updateDisplayName(_nameController.text.trim());
      }

      // Save/Update user info to Firestore under 'user_requests' collection
      await FirebaseFirestore.instance
          .collection('user_requests')
          .doc(userid)
          .set({
        'ba_no': _noController.text.trim(),
        'rank': _rankController.text.trim(),
        'name': _nameController.text.trim(),
        'unit': _unitController.text.trim(),
        'email': _emailController.text.trim(),
        'mobile': _mobileController.text.trim(),
        'approved': false, // User registration needs approval
        'rejected': false,
        'status': 'pending', // Status is pending for user registrations
        'created_at': FieldValue.serverTimestamp(),
        'user_id': userid,
        'approved_by_admin': false, // This is user self-registration
        'application_date': DateTime.now().toIso8601String(),
        'reapplication': isReapplication,
        'updated_at': isReapplication ? FieldValue.serverTimestamp() : null,
      });

      // Success dialog
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(isReapplication
              ? 'Application Updated'
              : 'Application Submitted'),
          content: Text(
            isReapplication
                ? 'Your application has been updated and sent for approval. You will be notified via email once approved.\nYou may also check your application status by logging in with your credentials.'
                : 'Your ID has been sent for approval. You will be notified via email once approved.\nYou may also check your application status by logging in with your credentials.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()));
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
          content: Text('Failed to submit application: $e'),
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

  @override
  void initState() {
    super.initState();
    // Add listener to BA number field to maintain proper format
    _noController.addListener(_onBANumberChanged);
  }

  void _onBANumberChanged() {
    if (_selectedRank != null) {
      final serviceBranch = _getServiceBranch(_selectedRank!);
      final expectedPrefix = _getPrefix(serviceBranch);

      if (expectedPrefix.isNotEmpty &&
          !_noController.text.startsWith(expectedPrefix)) {
        // If user types something that doesn't start with expected prefix, fix it
        final numbersOnly = _extractNumbers(_noController.text);
        if (numbersOnly.isNotEmpty) {
          final newText = '$expectedPrefix$numbersOnly';
          if (newText != _noController.text) {
            _noController.text = newText;
            _noController.selection = TextSelection.fromPosition(
              TextPosition(offset: _noController.text.length),
            );
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _noController.removeListener(_onBANumberChanged);
    _noController.dispose();
    _rankController.dispose();
    _nameController.dispose();
    _unitController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
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
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        value: _selectedRank,
        decoration: InputDecoration(
          labelText: 'Rank *',
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xff0d47a1), width: 2),
          ),
        ),
        items: allRanks,
        onChanged: (String? newValue) {
          setState(() {
            _selectedRank = newValue;
            _rankController.text = newValue ?? '';
            // Update BA number with appropriate prefix
            _updateBANumber();
          });
        },
        validator: (value) =>
            value == null || value.isEmpty ? 'Please select your rank' : null,
        hint: const Text('Select your rank'),
        isExpanded: true,
        menuMaxHeight: 300,
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType type = TextInputType.text,
    String? Function(String?)? validator,
    String? hintText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xff0d47a1), width: 2),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.shade900.withOpacity(0.9),
                Colors.blue.shade600.withOpacity(0.9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            image: const DecorationImage(
              image: AssetImage('assets/bg.jpg'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(Colors.black26, BlendMode.darken),
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
              child: Container(
                width: 450,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [
                    BoxShadow(blurRadius: 12, color: Colors.black26)
                  ],
                ),
                child: Form(
                  key: _formKey,
                  autovalidateMode: _hasAttemptedSubmit
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        "SMART MESS",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff0d47a1),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Fill out the form to apply for your officer ID",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                      const SizedBox(height: 24),
                      _buildTextField(
                        "BA No *",
                        _noController,
                        hintText: _selectedRank != null
                            ? '${_getPrefix(_getServiceBranch(_selectedRank!))}12345'
                            : 'Select rank first, then enter your number',
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter your BA number';
                          }

                          // Check if rank is selected first
                          if (_selectedRank == null) {
                            return 'Please select your rank first';
                          }

                          final serviceBranch =
                              _getServiceBranch(_selectedRank!);
                          final expectedPrefix = _getPrefix(serviceBranch);

                          if (expectedPrefix.isNotEmpty) {
                            if (!val.startsWith(expectedPrefix)) {
                              return 'BA number should start with $expectedPrefix for your selected rank';
                            }

                            // Check if there are numbers after the prefix
                            final numbersOnly = _extractNumbers(val);
                            if (numbersOnly.isEmpty) {
                              return 'Please enter your BA number after the prefix';
                            }
                          }

                          return null;
                        },
                      ),
                      _buildRankDropdown(),
                      _buildTextField(
                        "Name *",
                        _nameController,
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Please enter your name'
                            : null,
                      ),
                      _buildTextField(
                        "Unit *",
                        _unitController,
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Please enter your unit'
                            : null,
                      ),
                      _buildTextField(
                        "Email *",
                        _emailController,
                        type: TextInputType.emailAddress,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Please enter your email';
                          }
                          final emailRegex =
                              RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                          if (!emailRegex.hasMatch(val)) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      _buildTextField(
                        "Mobile No (at least 11 digits) *",
                        _mobileController,
                        type: TextInputType.phone,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Please enter your mobile number';
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
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_passwordVisible,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (val.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Password *',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: Color(0xff0d47a1), width: 2),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(_passwordVisible
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () => setState(
                                () => _passwordVisible = !_passwordVisible),
                            color: Colors.grey.shade700,
                          ),
                        ),
                        onChanged: (_) {
                          // Only validate if form has been submitted once
                          if (_formKey.currentState?.validate() == false) {
                            // Form has validation errors, so we can auto-validate
                          }
                        },
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: !_confirmPasswordVisible,
                        validator: _validateConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password *',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_confirmPasswordController.text.isNotEmpty)
                                Icon(
                                  _confirmPasswordController.text ==
                                          _passwordController.text
                                      ? Icons.check_circle
                                      : Icons.error,
                                  color: _confirmPasswordController.text ==
                                          _passwordController.text
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              IconButton(
                                icon: Icon(_confirmPasswordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                                onPressed: () => setState(() =>
                                    _confirmPasswordVisible =
                                        !_confirmPasswordVisible),
                                color: Colors.grey.shade700,
                              ),
                            ],
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: _confirmPasswordController.text.isEmpty
                                  ? const Color(0xff0d47a1)
                                  : _confirmPasswordController.text ==
                                          _passwordController.text
                                      ? Colors.green
                                      : Colors.red,
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: _confirmPasswordController.text.isEmpty
                                  ? Colors.grey
                                  : _confirmPasswordController.text ==
                                          _passwordController.text
                                      ? Colors.green
                                      : Colors.red,
                            ),
                          ),
                        ),
                        onChanged: (_) {
                          // Update the visual indicator without triggering validation
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const LoginScreen()),
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade100,
                              foregroundColor: Colors.black87,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              elevation: 1,
                            ),
                            child: const Text("Cancel",
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 16)),
                          ),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleApply,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff0d47a1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              elevation: 1,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text("Apply",
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16)),
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
}
