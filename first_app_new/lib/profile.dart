import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

// Add these imports
import 'screens/ProfileEditScreen.dart' as profile_edit;

class ProfileScreen extends StatefulWidget {
  final String username;
  final String email;
  final String phone;
  final String role;
  final String firstName;
  final String name;
  final String? imageUrl;

  const ProfileScreen({
    super.key,
    required this.username,
    required this.email,
    required this.phone,
    required this.role,
    required this.firstName,
    required this.name,
    this.imageUrl,
  });

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  final bool _isEditing = false;
  late TextEditingController _firstNameController;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _usernameController;
  String? _imageUrl;
  final bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.firstName);
    _nameController = TextEditingController(text: widget.name);
    _emailController = TextEditingController(text: widget.email);
    _phoneController = TextEditingController(text: widget.phone);
    _usernameController = TextEditingController(text: widget.username);
    _imageUrl = widget.imageUrl;
    _loadStoredData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _loadStoredData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _imageUrl = prefs.getString('image') ?? widget.imageUrl;
    });
  }

  Future<void> _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => profile_edit.ProfileEditScreen(
              initialData: {
                'firstName': _firstNameController.text,
                'name': _nameController.text,
                'email': _emailController.text,
                'phone': _phoneController.text,
                'username': _usernameController.text,
                'image': _imageUrl,
              },
            ),
      ),
    );

    // If we have result data back from the edit screen, update the UI
    if (result != null && mounted) {
      setState(() {
        _firstNameController.text =
            result['firstName'] ?? _firstNameController.text;
        _nameController.text = result['name'] ?? _nameController.text;
        _emailController.text = result['email'] ?? _emailController.text;
        _phoneController.text = result['phone'] ?? _phoneController.text;
        _usernameController.text =
            result['username'] ?? _usernameController.text;
        _imageUrl = result['image'] ?? _imageUrl;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _navigateToEditProfile,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage:
                            (_imageUrl != null && _imageUrl!.isNotEmpty)
                                ? NetworkImage(_imageUrl!)
                                : const AssetImage('assets/default_profile.jpg')
                                    as ImageProvider,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildProfileItem('First Name', _firstNameController),
                    _buildProfileItem('last Name', _nameController),
                    _buildProfileItem('Username', _usernameController),
                    _buildProfileItem('Email', _emailController),
                    _buildProfileItem('Phone', _phoneController),
                    _buildProfileItem(
                      'Role',
                      TextEditingController(
                        text:
                            widget.role.isEmpty
                                ? 'livreur'
                                : widget
                                    .role, // Default to 'livreur' if role is empty
                      ),
                      isEditable: false,
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildProfileItem(
    String label,
    TextEditingController controller, {
    bool isEditable = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 4),
          _isEditing && isEditable
              ? TextField(
                controller: controller,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter $label',
                ),
              )
              : Text(
                controller.text.isEmpty ? 'Not set' : controller.text,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
          const Divider(),
        ],
      ),
    );
  }
}
