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

    String? uploadedImageUrl = imageUrl;

    if (_profileImage != null) {
      final ref = FirebaseStorage.instance.ref(
        'profile_pics/${user.uid}_${DateTime.now().millisecondsSinceEpoch}',
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
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set(data);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile saved')));
  }

  Future<void> _loadProfile() async {
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
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _profileImage != null
                      ? FileImage(_profileImage!)
                      : (imageUrl != null && imageUrl!.isNotEmpty)
                      ? NetworkImage(imageUrl!) as ImageProvider
                      : const AssetImage('assets/default_avatar.png'),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username (unique)',
                ),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              TextFormField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              TextFormField(
                controller: bloodGroupController,
                decoration: const InputDecoration(labelText: 'Blood Group'),
              ),
              TextFormField(
                controller: nidController,
                decoration: const InputDecoration(labelText: 'NID Number'),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _saveProfile,
                icon: const Icon(Icons.save),
                label: const Text('Save Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
