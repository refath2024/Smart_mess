import '../../services/activity_log_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentPasswordFormKey = GlobalKey<FormState>();
  final _newPasswordFormKey = GlobalKey<FormState>();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  // Step management
  int _currentStep = 1; // 1: Current password, 2: New password
  bool _currentPasswordVerified = false;

  // Dynamic password matching
  bool _passwordsMatch = false;
  String _matchMessage = '';

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Listen to confirm password changes for dynamic validation
    _confirmPasswordController.addListener(_checkPasswordMatch);
    _newPasswordController.addListener(_checkPasswordMatch);
  }

  void _checkPasswordMatch() {
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    setState(() {
      if (confirmPassword.isEmpty) {
        _passwordsMatch = false;
        _matchMessage = '';
      } else if (newPassword == confirmPassword) {
        _passwordsMatch = true;
        _matchMessage = 'Passwords match ✓';
      } else {
        _passwordsMatch = false;
        _matchMessage = 'Passwords do not match ✗';
      }
    });
  }

  Future<void> _verifyCurrentPassword() async {
    if (!_currentPasswordFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Re-authenticate with current password to verify it's correct
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text.trim(),
      );

      await user.reauthenticateWithCredential(credential);

      // If successful, move to next step
      setState(() {
        _currentPasswordVerified = true;
        _currentStep = 2;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Current password verified successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      String errorMessage = 'Current password verification failed';

      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'wrong-password':
            errorMessage = 'Current password is incorrect';
            break;
          case 'requires-recent-login':
            errorMessage =
                'Please log out and log in again before changing password';
            break;
          default:
            errorMessage = e.message ?? 'Current password verification failed';
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
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

  Future<void> _changePassword() async {
    if (!_newPasswordFormKey.currentState!.validate()) {
      return;
    }

    if (!_passwordsMatch) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please ensure passwords match before proceeding'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final newPassword = _newPasswordController.text.trim();

    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters long'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Update password (user is already re-authenticated from step 1)
      await user.updatePassword(newPassword);

      await ActivityLogService.log(
        'Password Changed',
        details: {'changed_at': DateTime.now().toIso8601String()},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form and go back
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();

        // Reset state
        setState(() {
          _currentStep = 1;
          _currentPasswordVerified = false;
          _passwordsMatch = false;
          _matchMessage = '';
        });

        // Go back to previous screen
        Navigator.pop(context);
      }
    } catch (e) {
      String errorMessage = 'Failed to change password';

      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'weak-password':
            errorMessage = 'New password is too weak';
            break;
          case 'requires-recent-login':
            errorMessage = 'Session expired. Please start over.';
            // Reset to step 1
            setState(() {
              _currentStep = 1;
              _currentPasswordVerified = false;
            });
            break;
          default:
            errorMessage = e.message ?? 'Failed to change password';
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
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

  void _goBackToStep1() {
    setState(() {
      _currentStep = 1;
      _currentPasswordVerified = false;
      _passwordsMatch = false;
      _matchMessage = '';
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    });
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: onToggleVisibility,
        ),
      ),
    );
  }

  String? _validateCurrentPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your current password';
    }
    return null;
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a new password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    if (value == _currentPasswordController.text) {
      return 'New password must be different from current password';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your new password';
    }
    return null; // Dynamic validation handled by _checkPasswordMatch
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          _currentStep == 1 ? 'Verify Current Password' : 'Set New Password',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF002B5B),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: _currentStep == 2
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _goBackToStep1,
              )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress indicator
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Step 1
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _currentStep >= 1
                            ? const Color(0xFF002B5B)
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: _currentPasswordVerified
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 18)
                            : Text(
                                '1',
                                style: TextStyle(
                                  color: _currentStep >= 1
                                      ? Colors.white
                                      : Colors.grey.shade600,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        color: _currentStep >= 2
                            ? const Color(0xFF002B5B)
                            : Colors.grey.shade300,
                      ),
                    ),
                    // Step 2
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _currentStep >= 2
                            ? const Color(0xFF002B5B)
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          '2',
                          style: TextStyle(
                            color: _currentStep >= 2
                                ? Colors.white
                                : Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Current step content
              if (_currentStep == 1) _buildStep1() else _buildStep2(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      children: [
        // Header Section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(
                Icons.lock_outline,
                size: 60,
                color: Color(0xFF002B5B),
              ),
              const SizedBox(height: 12),
              const Text(
                'Verify Current Password',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF002B5B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please enter your current password to continue',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Current Password Form
        Form(
          key: _currentPasswordFormKey,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Password',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF002B5B),
                  ),
                ),
                const SizedBox(height: 20),
                _buildPasswordField(
                  controller: _currentPasswordController,
                  label: 'Enter your current password',
                  obscureText: _obscureCurrentPassword,
                  onToggleVisibility: () {
                    setState(() {
                      _obscureCurrentPassword = !_obscureCurrentPassword;
                    });
                  },
                  validator: _validateCurrentPassword,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Continue Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _verifyCurrentPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF002B5B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
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
                : const Text(
                    'Verify & Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 16),

        // Cancel Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF002B5B),
              side: const BorderSide(color: Color(0xFF002B5B)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      children: [
        // Header Section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(
                Icons.lock_reset,
                size: 60,
                color: Color(0xFF002B5B),
              ),
              const SizedBox(height: 12),
              const Text(
                'Set New Password',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF002B5B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose a strong new password for your account',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // New Password Form
        Form(
          key: _newPasswordFormKey,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'New Password',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF002B5B),
                  ),
                ),
                const SizedBox(height: 20),

                // New Password
                _buildPasswordField(
                  controller: _newPasswordController,
                  label: 'Enter new password',
                  obscureText: _obscureNewPassword,
                  onToggleVisibility: () {
                    setState(() {
                      _obscureNewPassword = !_obscureNewPassword;
                    });
                  },
                  validator: _validateNewPassword,
                ),

                const SizedBox(height: 20),

                // Confirm New Password
                _buildPasswordField(
                  controller: _confirmPasswordController,
                  label: 'Confirm new password',
                  obscureText: _obscureConfirmPassword,
                  onToggleVisibility: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                  validator: _validateConfirmPassword,
                ),

                // Dynamic password match indicator
                if (_matchMessage.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _passwordsMatch
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _passwordsMatch
                            ? Colors.green.shade200
                            : Colors.red.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _passwordsMatch ? Icons.check_circle : Icons.error,
                          color: _passwordsMatch
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _matchMessage,
                          style: TextStyle(
                            color: _passwordsMatch
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Password Requirements
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Password Requirements',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text('• At least 6 characters long\n'
                  '• Different from your current password\n'
                  '• Both password fields must match'),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Change Password Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: (_isLoading ||
                    !_passwordsMatch ||
                    _confirmPasswordController.text.isEmpty)
                ? null
                : _changePassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF002B5B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
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
                : const Text(
                    'Change Password',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 16),

        // Back Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: _isLoading ? null : _goBackToStep1,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF002B5B),
              side: const BorderSide(color: Color(0xFF002B5B)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Back to Previous Step',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
