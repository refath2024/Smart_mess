import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../services/activity_log_service.dart';

class MyProfilePage extends StatefulWidget {
  const MyProfilePage({super.key});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  bool _isLoading = true;
  bool _isSaving = false;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _noController;
  late TextEditingController _rankController;
  late TextEditingController _unitController;

  String? _imageUrl;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _noController = TextEditingController();
    _rankController = TextEditingController();
    _unitController = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _noController.dispose();
    _rankController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('user_requests')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        _nameController.text = data['name'] ?? '';
        _emailController.text = data['email'] ?? '';
        _phoneController.text = data['mobile'] ?? '';
        _noController.text = data['ba_no'] ??
            data['no'] ??
            ''; // Check both field names for backward compatibility
        _rankController.text = data['rank'] ?? '';
        _unitController.text = data['unit'] ?? '';
        _imageUrl = data['image_url'];
      }
    } catch (e) {
      debugPrint('Failed to load profile: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to load profile: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final bytes = await file.length();
        const maxSizeInBytes = 5 * 1024 * 1024; // 5 MB limit
        if (bytes > maxSizeInBytes) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    "Image size exceeds 5 MB, please select smaller one.")),
          );
          return;
        }
        setState(() {
          _imageFile = file;
        });
      }
    } catch (e) {
      debugPrint('Image picking failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final ext = imageFile.path.split('.').last;
      final ref = FirebaseStorage.instance
          .ref()
          .child('user_profile_images')
          .child('${user.uid}.$ext');

      await ref.putFile(imageFile);
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      debugPrint('Image upload failed: $e');
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String? uploadedImageUrl = _imageUrl;

    if (_imageFile != null) {
      final url = await _uploadImage(_imageFile!);
      if (url != null) {
        uploadedImageUrl = url;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload profile image')),
        );
        setState(() {
          _isSaving = false;
        });
        return;
      }
    }

    try {
      await FirebaseFirestore.instance
          .collection('user_requests')
          .doc(user.uid)
          .update({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'mobile': _phoneController.text.trim(),
        'ba_no': _noController.text.trim(), // Use the correct field name
        'rank': _rankController.text.trim(),
        'unit': _unitController.text.trim(),
        if (uploadedImageUrl != null) 'image_url': uploadedImageUrl,
      });

      setState(() {
        _imageUrl = uploadedImageUrl;
        _imageFile = null;
        _isEditing = false;
      });

      // Log activity for profile update
      await ActivityLogService.log(
        'Profile Updated',
        details: {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'mobile': _phoneController.text.trim(),
          'ba_no': _noController.text.trim(),
          'rank': _rankController.text.trim(),
          'unit': _unitController.text.trim(),
          if (uploadedImageUrl != null) 'image_url': uploadedImageUrl,
          'date': DateTime.now().toIso8601String(),
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      debugPrint('Profile update failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        validator: validator,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey.shade200,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF002B5B),
        title: const Text('My Profile'),
        centerTitle: true,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : Icon(_isEditing ? Icons.check : Icons.edit,
                    color: Colors.white),
            onPressed: _isSaving
                ? null
                : () {
                    if (_isEditing) {
                      _saveProfile();
                    } else {
                      setState(() {
                        _isEditing = true;
                      });
                    }
                  },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : (_imageUrl != null && _imageUrl!.isNotEmpty)
                              ? NetworkImage(_imageUrl!)
                              : const AssetImage('assets/pro.png')
                                  as ImageProvider,
                      backgroundColor: Colors.grey.shade300,
                    ),
                    if (_isEditing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white,
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, size: 20),
                            onPressed: _pickImage,
                            tooltip: 'Change Profile Picture',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildTextField(
                label: "Name *",
                controller: _nameController,
                enabled: _isEditing,
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Please enter your name'
                    : null,
              ),
              _buildTextField(
                label: "Email *",
                controller: _emailController,
                enabled: _isEditing,
                keyboardType: TextInputType.emailAddress,
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Please enter your email';
                  }
                  final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                  if (!regex.hasMatch(val)) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              _buildTextField(
                label: "Mobile No *",
                controller: _phoneController,
                enabled: _isEditing,
                keyboardType: TextInputType.phone,
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
              _buildTextField(
                label: "BA No *",
                controller: _noController,
                enabled: _isEditing,
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Please enter your BA No'
                    : null,
              ),
              _buildTextField(
                label: "Rank *",
                controller: _rankController,
                enabled: _isEditing,
              ),
              _buildTextField(
                label: "Unit *",
                controller: _unitController,
                enabled: _isEditing,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
