import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'admin/admin_login_screen.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import 'user/user_home_screen.dart';
import '../services/user_auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final UserAuthService _userAuthService = UserAuthService();
  String _division = "MIST";
  bool _obscurePassword = true;
  bool _isLoading = false;
  
  // Email suggestions
  List<String> _emailSuggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    _loadEmailHistory();
    _emailController.addListener(_onEmailChanged);
  }

  Future<void> _loadEmailHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final emailHistory = prefs.getStringList('email_history') ?? [];
      setState(() {
        _emailSuggestions = emailHistory;
      });
    } catch (e) {
      print('Error loading email history: $e');
    }
  }

  Future<void> _saveEmailToHistory(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> emailHistory = prefs.getStringList('email_history') ?? [];
      
      // Remove email if it already exists to avoid duplicates
      emailHistory.remove(email);
      
      // Add email to the beginning of the list
      emailHistory.insert(0, email);
      
      // Keep only the last 5 emails
      if (emailHistory.length > 5) {
        emailHistory = emailHistory.take(5).toList();
      }
      
      await prefs.setStringList('email_history', emailHistory);
      
      setState(() {
        _emailSuggestions = emailHistory;
      });
    } catch (e) {
      print('Error saving email history: $e');
    }
  }

  void _onEmailChanged() {
    final query = _emailController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _showSuggestions = false;
      });
      return;
    }

    final filteredSuggestions = _emailSuggestions
        .where((email) => email.toLowerCase().contains(query))
        .toList();

    setState(() {
      _showSuggestions = filteredSuggestions.isNotEmpty && query.length > 0;
    });
  }

  void _selectEmailSuggestion(String email) {
    _emailController.text = email;
    setState(() {
      _showSuggestions = false;
    });
  }

  @override
  void dispose() {
    _emailController.removeListener(_onEmailChanged);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter both email and password")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _userAuthService.loginUser(email, password);

      if (result != null && result['success'] == true) {
        // Save email to history on successful login
        await _saveEmailToHistory(email);
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const UserHomeScreen()),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result?['error'] ?? 'Login failed')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.blue.shade900,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 10),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/army.png', height: 60),
                    const SizedBox(height: 12),
                    const Text(
                      "Smart Mess – Officer Login",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Email field with suggestions
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            suffixIcon: _emailController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _emailController.clear();
                                      setState(() {
                                        _showSuggestions = false;
                                      });
                                    },
                                  )
                                : null,
                          ),
                        ),
                        // Email suggestions dropdown
                        if (_showSuggestions && _emailSuggestions.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _emailSuggestions
                                  .where((email) => email
                                      .toLowerCase()
                                      .contains(_emailController.text.toLowerCase()))
                                  .length,
                              itemBuilder: (context, index) {
                                final filteredEmails = _emailSuggestions
                                    .where((email) => email
                                        .toLowerCase()
                                        .contains(_emailController.text.toLowerCase()))
                                    .toList();
                                final email = filteredEmails[index];
                                
                                return ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.history, size: 16),
                                  title: Text(
                                    email,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  onTap: () => _selectEmailSuggestion(email),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _division,
                      items: ['MIST', 'Other']
                          .map(
                            (div) =>
                                DropdownMenuItem(value: div, child: Text(div)),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _division = val!),
                      decoration: InputDecoration(
                        labelText: 'Division',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade900,
                                foregroundColor: Colors.white,
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text("Login"),
                            ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const ForgotPasswordScreen()),
                        );
                      },
                      child: const Text("Forgot Password?"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AdminLoginScreen()),
                        );
                      },
                      child: const Text("← Go to Admin Portal"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const RegisterScreen()),
                        );
                      },
                      child: const Text("Don't have an account? Register here"),
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
}
