import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _isLoading = false;

  String? _validateConfirmPassword(String? val) {
    if (val == null || val.isEmpty) return 'Please confirm your password';
    if (val != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _handleApply() async {
    if (!_formKey.currentState!.validate()) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Application'),
        content: const Text('Are you sure you want to submit your application?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final String userid = userCredential.user!.uid;

      // Save user info to Firestore under 'user_requests' collection
      await FirebaseFirestore.instance.collection('user_requests').doc(userid).set({
        'no': _noController.text.trim(),
        'rank': _rankController.text.trim(),
        'name': _nameController.text.trim(),
        'unit': _unitController.text.trim(),
        'email': _emailController.text.trim(),
        'mobile': _mobileController.text.trim(),
        'approved': false,
        'rejected': false,
        'status': 'pending',
        'created_at': FieldValue.serverTimestamp(),
        'user_id': userid,
      });

      // Success dialog
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Application Submitted'),
          content: const Text(
            'Your ID has been sent for approval. You will be notified via email once approved.\n'
            'You may also check your application status by logging in with your credentials.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Registration Error'),
          content: Text(e.message ?? 'An unexpected error occurred.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
          ],
        ),
      );
    } catch (e) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text(e.toString()),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
          ],
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
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

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType type = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
                  boxShadow: const [BoxShadow(blurRadius: 12, color: Colors.black26)],
                ),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
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
                        validator: (val) => val == null || val.trim().isEmpty ? 'Please enter your ID number' : null,
                      ),
                      _buildTextField("Rank *", _rankController),
                      _buildTextField(
                        "Name *",
                        _nameController,
                        validator: (val) => val == null || val.trim().isEmpty ? 'Please enter your name' : null,
                      ),
                      _buildTextField("Unit *", _unitController),
                      _buildTextField(
                        "Email *",
                        _emailController,
                        type: TextInputType.emailAddress,
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Please enter your email';
                          final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                          if (!emailRegex.hasMatch(val)) return 'Enter a valid email address';
                          return null;
                        },
                      ),
                      _buildTextField(
                        "Mobile No (at least 11 digits) *",
                        _mobileController,
                        type: TextInputType.phone,
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Please enter your mobile number';
                          if (!RegExp(r'^\d+$').hasMatch(val)) return 'Mobile number must contain only digits';
                          if (val.length < 11) return 'Mobile number must be at least 11 digits';
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_passwordVisible,
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Please enter a password';
                          if (val.length < 6) return 'Password must be at least 6 characters';
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Password *',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xff0d47a1), width: 2),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(_passwordVisible ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                            color: Colors.grey.shade700,
                          ),
                        ),
                        onChanged: (_) {
                          if (_confirmPasswordController.text.isNotEmpty) {
                            _formKey.currentState?.validate();
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_confirmPasswordController.text.isNotEmpty)
                                Icon(
                                  _confirmPasswordController.text == _passwordController.text
                                      ? Icons.check_circle
                                      : Icons.error,
                                  color: _confirmPasswordController.text == _passwordController.text
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              IconButton(
                                icon: Icon(_confirmPasswordVisible ? Icons.visibility_off : Icons.visibility),
                                onPressed: () =>
                                    setState(() => _confirmPasswordVisible = !_confirmPasswordVisible),
                                color: Colors.grey.shade700,
                              ),
                            ],
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: _confirmPasswordController.text.isEmpty
                                  ? const Color(0xff0d47a1)
                                  : _confirmPasswordController.text == _passwordController.text
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
                                  : _confirmPasswordController.text == _passwordController.text
                                      ? Colors.green
                                      : Colors.red,
                            ),
                          ),
                        ),
                        onChanged: (_) => _formKey.currentState?.validate(),
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
                                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade100,
                              foregroundColor: Colors.black87,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 1,
                            ),
                            child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                          ),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleApply,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff0d47a1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 1,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text("Apply", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
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
