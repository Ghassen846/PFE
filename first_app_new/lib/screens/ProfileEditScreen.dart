import 'dart:io';
import 'package:first_app_new/services/profile_update_service.dart';
import 'package:first_app_new/services/image_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileEditScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  const ProfileEditScreen({super.key, this.initialData});

  @override
  _ProfileEditScreenState createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _usernameController;

  // Add controllers for password fields
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  String? _imageUrl;
  File? _selectedImage;
  bool _isLoading = false;
  bool _dataLoaded = false;
  bool _showPasswordFields = false; // To toggle password change UI

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _usernameController = TextEditingController();

    // Initialize password controllers
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    if (widget.initialData != null) {
      _loadInitialData(widget.initialData!);
    } else {
      _loadUserData();
    }
  }

  void _loadInitialData(Map<String, dynamic> data) {
    _firstNameController.text = data['firstName'] ?? '';
    _nameController.text =
        data['name'] ??
        ''; // Changed from 'LastName' to 'name' to match backend
    _emailController.text = data['email'] ?? '';
    _phoneController.text = data['phone'] ?? '';
    _usernameController.text = data['username'] ?? '';
    _imageUrl = data['image'];
    setState(() => _dataLoaded = true);
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      // First try to get from SharedPreferences for faster loading
      final prefs = await SharedPreferences.getInstance();
      _firstNameController.text = prefs.getString('firstName') ?? '';
      _nameController.text = prefs.getString('LastName') ?? '';
      _emailController.text = prefs.getString('email') ?? '';
      _phoneController.text = prefs.getString('phone') ?? '';
      _usernameController.text = prefs.getString('username') ?? '';
      _imageUrl = prefs.getString('image');

      // Then try to get fresh data from API
      try {
        final userData = await ProfileUpdateService.getUserProfile();
        setState(() {
          _firstNameController.text =
              userData['firstName'] ?? _firstNameController.text;
          _nameController.text = userData['LastName'] ?? _nameController.text;
          _emailController.text = userData['email'] ?? _emailController.text;
          _phoneController.text = userData['phone'] ?? _phoneController.text;
          _usernameController.text =
              userData['username'] ?? _usernameController.text;
          _imageUrl = userData['image'] ?? _imageUrl;
        });
        // Update local storage with fresh data
        ProfileUpdateService.updateLocalUserData(userData);
      } catch (e) {
        // If API call fails, we already loaded from SharedPreferences
        ProfileUpdateService.showToast(
          message: "Using cached profile data: $e",
          isError: true,
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
        _dataLoaded = true;
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // First upload image if selected
      if (_selectedImage != null) {
        final imageUrl = await ProfileUpdateService.uploadProfileImage(
          _selectedImage!,
        );
        setState(() => _imageUrl = imageUrl);
      }

      // Then update profile data
      final userData = await ProfileUpdateService.updateProfile(
        firstName: _firstNameController.text.trim(),
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        username: _usernameController.text.trim(),
      );

      // Update local storage
      await ProfileUpdateService.updateLocalUserData(userData);

      ProfileUpdateService.showToast(message: 'Profile updated successfully');

      Navigator.pop(context, userData);
    } catch (e) {
      ProfileUpdateService.showToast(
        message: 'Error updating profile: $e',
        isError: true,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Change password method
  Future<void> _changePassword() async {
    // Validate only password fields
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ProfileUpdateService.showToast(
        message: 'Please fill all password fields',
        isError: true,
      );
      return;
    }

    if (_newPasswordController.text.length < 6) {
      ProfileUpdateService.showToast(
        message: 'New password must be at least 6 characters',
        isError: true,
      );
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ProfileUpdateService.showToast(
        message: 'New passwords do not match',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await ProfileUpdateService.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (success) {
        ProfileUpdateService.showToast(
          message: 'Password changed successfully!',
        );
        // Clear fields and hide the password section
        setState(() {
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
          _showPasswordFields = false;
        });
      }
    } catch (e) {
      ProfileUpdateService.showToast(
        message: 'Failed to change password: ${e.toString()}',
        isError: true,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();

    // Dispose password controllers
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          if (_dataLoaded)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isLoading ? null : _saveProfile,
              tooltip: 'Save Changes',
            ),
        ],
      ),
      body:
          _isLoading && !_dataLoaded
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Profile Image
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          _selectedImage != null
                              ? CircleAvatar(
                                radius: 60,
                                backgroundImage: FileImage(_selectedImage!),
                              )
                              : ImageService.buildAvatar(
                                imageUrl: _imageUrl ?? '',
                                radius: 60,
                                category: 'user',
                              ),
                          InkWell(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Form fields
                      _buildTextField(
                        label: 'First Name',
                        controller: _firstNameController,
                        validator:
                            (val) =>
                                val!.isEmpty
                                    ? 'Please enter your first name'
                                    : null,
                      ),
                      _buildTextField(
                        label: 'Last Name',
                        controller: _nameController,
                        validator:
                            (val) =>
                                val!.isEmpty
                                    ? 'Please enter your full name'
                                    : null,
                      ),
                      _buildTextField(
                        label: 'Username',
                        controller: _usernameController,
                        validator:
                            (val) =>
                                val!.isEmpty ? 'Please enter a username' : null,
                        prefixIcon: Icons.person,
                      ),
                      _buildTextField(
                        label: 'Email',
                        controller: _emailController,
                        validator: (val) {
                          if (val!.isEmpty) return 'Please enter your email';
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(val)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email,
                      ),
                      _buildTextField(
                        label: 'Phone',
                        controller: _phoneController,
                        validator: (val) {
                          if (val!.isEmpty) {
                            return 'Please enter your phone number';
                          }
                          if (!RegExp(
                            r'^(\+216)?[2459][0-9]{7}$',
                          ).hasMatch(val)) {
                            return 'Please enter a valid Tunisian phone number';
                          }
                          return null;
                        },
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone,
                      ),

                      const SizedBox(height: 20),

                      // Change Password Button
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _showPasswordFields = !_showPasswordFields;
                            if (!_showPasswordFields) {
                              // Clear password fields when hiding
                              _currentPasswordController.clear();
                              _newPasswordController.clear();
                              _confirmPasswordController.clear();
                            }
                          });
                        },
                        icon: Icon(
                          _showPasswordFields
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        label: Text(
                          _showPasswordFields
                              ? 'Hide Password Fields'
                              : 'Change Password',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(200, 45),
                        ),
                      ),

                      // Password change fields
                      if (_showPasswordFields) ...[
                        const SizedBox(height: 20),
                        _buildTextField(
                          label: 'Current Password',
                          controller: _currentPasswordController,
                          validator:
                              (val) =>
                                  val!.isEmpty
                                      ? 'Please enter your current password'
                                      : null,
                          obscureText: true,
                          prefixIcon: Icons.lock_outline,
                        ),
                        _buildTextField(
                          label: 'New Password',
                          controller: _newPasswordController,
                          validator: (val) {
                            if (val!.isEmpty) {
                              return 'Please enter a new password';
                            }
                            if (val.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                          obscureText: true,
                          prefixIcon: Icons.lock,
                        ),
                        _buildTextField(
                          label: 'Confirm New Password',
                          controller: _confirmPasswordController,
                          validator: (val) {
                            if (val!.isEmpty) {
                              return 'Please confirm your new password';
                            }
                            if (val != _newPasswordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                          obscureText: true,
                          prefixIcon: Icons.lock,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _changePassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Save New Password'),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String? Function(String?)? validator,
    TextInputType? keyboardType,
    IconData? prefixIcon,
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        ),
        validator: validator,
        keyboardType: keyboardType,
        enabled: !_isLoading,
        obscureText: obscureText,
      ),
    );
  }
}
