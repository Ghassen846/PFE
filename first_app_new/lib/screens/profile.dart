import 'dart:async';
import 'package:first_app_new/services/auth_service.dart';
import 'package:first_app_new/services/image_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

// Add these imports
import 'package:first_app_new/screens/ProfileEditScreen.dart' as profile_edit;

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
  bool _isLoading = false;
  bool _isOnline = true; // User is online by default
  Timer?
  _statusCheckTimer; // Timer to periodically check online status  @override
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
    _checkOnlineStatus();

    // Set up periodic online status check every 30 seconds
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkOnlineStatus();
    });
  }

  // Check if the user is online
  Future<void> _checkOnlineStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _isOnline = prefs.getBool('isOnline') ?? true;
      });
    } catch (e) {
      debugPrint('Error checking online status: $e');
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _statusCheckTimer?.cancel(); // Cancel the timer when disposing
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
                'name':
                    _nameController
                        .text, // Updated to use 'name' instead of 'LastName'
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
        _nameController.text =
            result['name'] ??
            _nameController.text; // Updated to use 'name' instead of 'LastName'
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
                      child: Stack(
                        children: [
                          ImageService.buildAvatar(
                            imageUrl: _imageUrl ?? '',
                            radius: 50,
                            category: 'user',
                          ),
                          // Online indicator
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 15,
                              height: 15,
                              decoration: BoxDecoration(
                                color: _isOnline ? Colors.green : Colors.grey,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
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

                    const SizedBox(height: 30),

                    // Logout button
                    Center(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.logout),
                        label: const Text(
                          'Disconnect',
                          style: TextStyle(fontSize: 16),
                        ),
                        onPressed: _showLogoutConfirmation,
                      ),
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

  // Show logout confirmation dialog
  Future<void> _showLogoutConfirmation() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to disconnect?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop();
                await _handleLogout();
              },
            ),
          ],
        );
      },
    );
  }

  // Handle logout process
  Future<void> _handleLogout() async {
    try {
      // Show loading indicator
      setState(() => _isLoading = true);

      // Cancel status check timer
      _statusCheckTimer?.cancel();

      // Set user as offline on the server
      await AuthServiceImproved.updateOnlineStatusToServer(false);

      // Stop periodic status updates from AuthService
      AuthServiceImproved.stopPeriodicOnlineUpdates();

      // Complete logout to clear all user data
      await AuthServiceImproved.logout();

      // Show success message
      Fluttertoast.showToast(
        msg: "Disconnected successfully",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );

      // Navigate to login screen
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      debugPrint('Error during logout: $e');
      Fluttertoast.showToast(
        msg: "Error disconnecting: $e",
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
