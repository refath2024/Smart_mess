import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class MyProfilePage extends StatefulWidget {
  const MyProfilePage({super.key});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  String name = "Lt John Snow";
  String email = "johnsnow@gmail.com";
  String phone = "0123456789";
  String room = "A-101";
  String baNo = "BA123456";
  String rank = "Lieutenant";
  String unit = "Alpha Company";
  String maritalStatus = "Single";
  File? _imageFile;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF002B5B),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "My Profile",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit, color: Colors.white),
            onPressed: () {
              if (_isEditing && _formKey.currentState!.validate()) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Profile updated!")),
                );
              }
              setState(() {
                _isEditing = !_isEditing;
              });
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
                      radius: 55,
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : const AssetImage('assets/pro.png') as ImageProvider,
                    ),
                    if (_isEditing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white,
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, size: 18),
                            onPressed: _pickImage,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              TextFormField(
                enabled: _isEditing,
                initialValue: name,
                decoration: const InputDecoration(
                  labelText: "Name",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                onChanged: (val) => name = val,
                validator: (val) => val == null || val.isEmpty ? "Enter your name" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                enabled: _isEditing,
                initialValue: baNo,
                decoration: const InputDecoration(
                  labelText: "BA No",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge),
                ),
                onChanged: (val) => baNo = val,
                validator: (val) => val == null || val.isEmpty ? "Enter your BA No" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                enabled: _isEditing,
                initialValue: rank,
                decoration: const InputDecoration(
                  labelText: "Rank",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.military_tech),
                ),
                onChanged: (val) => rank = val,
                validator: (val) => val == null || val.isEmpty ? "Enter your rank" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                enabled: _isEditing,
                initialValue: unit,
                decoration: const InputDecoration(
                  labelText: "Unit",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_balance),
                ),
                onChanged: (val) => unit = val,
                validator: (val) => val == null || val.isEmpty ? "Enter your unit" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                enabled: _isEditing,
                initialValue: maritalStatus,
                decoration: const InputDecoration(
                  labelText: "Marital Status",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.family_restroom),
                ),
                onChanged: (val) => maritalStatus = val,
                validator: (val) => val == null || val.isEmpty ? "Enter your marital status" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                enabled: _isEditing,
                initialValue: email,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                onChanged: (val) => email = val,
                validator: (val) => val == null || val.isEmpty ? "Enter your email" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                enabled: _isEditing,
                initialValue: phone,
                decoration: const InputDecoration(
                  labelText: "Phone",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                onChanged: (val) => phone = val,
                validator: (val) => val == null || val.isEmpty ? "Enter your phone" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                enabled: _isEditing,
                initialValue: room,
                decoration: const InputDecoration(
                  labelText: "Room",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.meeting_room),
                ),
                onChanged: (val) => room = val,
                validator: (val) => val == null || val.isEmpty ? "Enter your room" : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}