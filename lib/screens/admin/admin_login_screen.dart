import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../login_screen.dart';
import 'admin_home_screen.dart';
import 'admin_forgot_password_screen.dart';
import '../../services/admin_auth_service.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AdminAuthService _adminAuthService = AdminAuthService();
  String _division = "MIST";
  bool _obscurePassword = true; // 👁️ password visibility toggle
  bool _isLoading = false;

  // Email suggestions
  List<String> _emailSuggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _loadAdminEmailHistory();
    _emailController.addListener(_onEmailChanged);
  }

  Future<void> _loadAdminEmailHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final adminEmailHistory =
          prefs.getStringList('admin_email_history') ?? [];
      setState(() {
        _emailSuggestions = adminEmailHistory;
      });
    } catch (e) {
      print('Error loading admin email history: $e');
    }
  }

  Future<void> _saveAdminEmailToHistory(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> adminEmailHistory =
          prefs.getStringList('admin_email_history') ?? [];

      // Remove email if it already exists to avoid duplicates
      adminEmailHistory.remove(email);

      // Add email to the beginning of the list
      adminEmailHistory.insert(0, email);

      // Keep only the last 5 emails
      if (adminEmailHistory.length > 5) {
        adminEmailHistory = adminEmailHistory.take(5).toList();
      }

      await prefs.setStringList('admin_email_history', adminEmailHistory);

      setState(() {
        _emailSuggestions = adminEmailHistory;
      });
    } catch (e) {
      print('Error saving admin email history: $e');
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
      _showSuggestions = filteredSuggestions.isNotEmpty && query.isNotEmpty;
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
      final result = await _adminAuthService.loginAdmin(email, password);

      if (result != null && result['success'] == true) {
        // Save admin email to history on successful login
        await _saveAdminEmailToHistory(email);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminHomeScreen()),
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
    return Scaffold(
      backgroundColor: Colors.blue.shade900,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Container(
            width: 400,
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
                  "Smart Mess – Admin Login",
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
                    // Admin email suggestions dropdown
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
                              .where((email) => email.toLowerCase().contains(
                                  _emailController.text.toLowerCase()))
                              .length,
                          itemBuilder: (context, index) {
                            final filteredEmails = _emailSuggestions
                                .where((email) => email.toLowerCase().contains(
                                    _emailController.text.toLowerCase()))
                                .toList();
                            final email = filteredEmails[index];

                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.admin_panel_settings,
                                  size: 16, color: Colors.blue),
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
                        (div) => DropdownMenuItem(value: div, child: Text(div)),
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
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade900,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text("Login"),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminForgotPasswordScreen(),
                      ),
                    );
                  },
                  child: const Text("Forgot Password?"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  child: const Text("← Go to Officer Portal"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
