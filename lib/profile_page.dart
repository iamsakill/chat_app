import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final user = FirebaseAuth.instance.currentUser!;
  final _formKey = GlobalKey<FormState>();
  final picker = ImagePicker();

  File? _profileImage;

  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final addressController = TextEditingController();
  final phoneController = TextEditingController();
  final bloodGroupController = TextEditingController();
  final nidController = TextEditingController();

  String? imageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _profileImage = File(picked.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    String? uploadedImageUrl = imageUrl;

    try {
      if (_profileImage != null) {
        final ref = FirebaseStorage.instance.ref(
          'profile_pics/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg', // Unique filename
        );
        await ref.putFile(_profileImage!);
        uploadedImageUrl = await ref.getDownloadURL();
      }

      final data = {
        'email': user.email,
        'name': nameController.text.trim(),
        'username': usernameController.text.trim(),
        'address': addressController.text.trim(),
        'phone': phoneController.text.trim(),
        'blood_group': bloodGroupController.text.trim(),
        'nid': nidController.text.trim(),
        'profile_pic': uploadedImageUrl ?? '',
        // Update email_search if name/username affects it, or just keep email parts
        'email_search': user.email?.toLowerCase().split(RegExp(r'[\.@]')).where((s) => s.isNotEmpty).toList(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(data, SetOptions(merge: true)); // Use merge to update specific fields
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile saved successfully!')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save profile: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        nameController.text = data['name'] ?? '';
        usernameController.text = data['username'] ?? '';
        addressController.text = data['address'] ?? '';
        phoneController.text = data['phone'] ?? '';
        bloodGroupController.text = data['blood_group'] ?? '';
        nidController.text = data['nid'] ?? '';
        imageUrl = data['profile_pic'];
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load profile: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : (imageUrl != null && imageUrl!.isNotEmpty)
                          ? NetworkImage(imageUrl!) as ImageProvider
                          : const AssetImage('assets/default_avatar.png'),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Theme.of(context).primaryColor,
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildProfileField(
                controller: nameController,
                label: 'Full Name',
                icon: Icons.person,
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              _buildProfileField(
                controller: usernameController,
                label: 'Username',
                icon: Icons.alternate_email,
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              _buildProfileField(
                controller: phoneController,
                label: 'Phone',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              _buildProfileField(
                controller: addressController,
                label: 'Address',
                icon: Icons.location_on,
              ),
              _buildProfileField(
                controller: bloodGroupController,
                label: 'Blood Group',
                icon: Icons.bloodtype,
              ),
              _buildProfileField(
                controller: nidController,
                label: 'NID Number',
                icon: Icons.credit_card,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _saveProfile,
                  icon: const Icon(Icons.save),
                  label: const Text(
                    'Save Profile',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Theme.of(context).primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
        validator: validator,
      ),
    );
  }
}