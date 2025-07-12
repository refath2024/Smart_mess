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

  void _handleApply() {
    if (_formKey.currentState!.validate()) {
      // All fields are valid, proceed
      debugPrint("BA No: ${_noController.text}");
      debugPrint("Rank: ${_rankController.text}");
      debugPrint("Name: ${_nameController.text}");
      debugPrint("Unit: ${_unitController.text}");
      debugPrint("Email: ${_emailController.text}");
      debugPrint("Mobile: ${_mobileController.text}");
      debugPrint("Password: ${_passwordController.text}");

      // TODO: Replace with your backend or Firebase logic

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration submitted successfully!')),
      );
    } else {
      // Validation failed, errors shown by validator functions
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
            image: AssetImage('assets/bg.jpg'), // Keep if you want background
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black26, BlendMode.darken),
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: 450,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [
                  BoxShadow(blurRadius: 12, color: Colors.black26),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Apply for SMART MESS",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff0d47a1),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Fill out the form to register for your officer ID",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                    const SizedBox(height: 24),

                    _buildTextField(
                      "No",
                      _noController,
                      validator: (val) => val == null || val.isEmpty
                          ? 'Please enter your ID number'
                          : null,
                    ),

                    _buildTextField(
                      "Rank",
                      _rankController,
                      validator: (val) => val == null || val.isEmpty
                          ? 'Please enter your rank'
                          : null,
                    ),

                    _buildTextField(
                      "Name",
                      _nameController,
                      validator: (val) => val == null || val.isEmpty
                          ? 'Please enter your name'
                          : null,
                    ),

                    _buildTextField(
                      "Unit",
                      _unitController,
                      validator: (val) => val == null || val.isEmpty
                          ? 'Please enter your unit'
                          : null,
                    ),

                    _buildTextField(
                      "Email",
                      _emailController,
                      type: TextInputType.emailAddress,
                      validator: (val) {
                        if (val == null || val.isEmpty)
                          return 'Please enter your email';
                        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                        if (!emailRegex.hasMatch(val))
                          return 'Enter a valid email';
                        return null;
                      },
                    ),

                    _buildTextField(
                      "Mobile No",
                      _mobileController,
                      type: TextInputType.phone,
                      validator: (val) => val == null || val.isEmpty
                          ? 'Please enter your mobile number'
                          : null,
                    ),

                    _buildPasswordField(
                      "Password",
                      _passwordController,
                      _passwordVisible,
                      () {
                        setState(() {
                          _passwordVisible = !_passwordVisible;
                        });
                      },
                      validator: (val) {
                        if (val == null || val.isEmpty)
                          return 'Please enter a password';
                        if (val.length < 6)
                          return 'Password must be at least 6 characters';
                        return null;
                      },
                    ),

                    _buildPasswordField(
                      "Confirm Password",
                      _confirmPasswordController,
                      _confirmPasswordVisible,
                      () {
                        setState(() {
                          _confirmPasswordVisible = !_confirmPasswordVisible;
                        });
                      },
                      validator: (val) {
                        if (val == null || val.isEmpty)
                          return 'Please confirm your password';
                        if (val != _passwordController.text)
                          return 'Passwords do not match';
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              255,
                              221,
                              52,
                              52,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _handleApply,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              255,
                              41,
                              241,
                              5,
                            ), // Bright contrasting color
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 14,
                            ),
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            shadowColor: const Color.fromARGB(
                              255,
                              80,
                              255,
                              64,
                            ).withOpacity(0.6),
                          ),
                          child: const Text(
                            "Apply",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.white, // White text for visibility
                              letterSpacing: 1.1,
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
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType type = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 5),
          TextFormField(
            controller: controller,
            keyboardType: type,
            validator: validator,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xff0d47a1),
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField(
    String label,
    TextEditingController controller,
    bool visible,
    VoidCallback toggleVisibility, {
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 5),
          TextFormField(
            controller: controller,
            obscureText: !visible,
            validator: validator,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xff0d47a1),
                  width: 2,
                ),
              ),
              suffixIcon: IconButton(
                icon: Icon(visible ? Icons.visibility_off : Icons.visibility),
                onPressed: toggleVisibility,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
