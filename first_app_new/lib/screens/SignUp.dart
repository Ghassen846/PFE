/*
 * Note: Ensure the backend supports the following endpoints:
 * - POST /api/users/register: For user registration data (JSON)
 * - POST /api/users/register/image: For profile image upload
 * - POST /api/users/register/documents: For vehicle document uploads
 * Update ServerConfig.activeServerUrl in server_config.dart to match your server (e.g., http://192.168.100.41:5000).
 */

import 'dart:io';
import 'package:first_app_new/services/api_service.dart';
import 'package:first_app_new/services/image_service.dart';
import 'package:first_app_new/services/server_config.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'login.dart';
import 'dart:async';
import 'dart:developer' as developer;

class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({required this.delay});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void cancel() {
    _timer?.cancel();
  }
}

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // State variables
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isConnected = true;
  String _selectedRole = 'livreur';
  File? _profileImage;
  LocationData? _currentLocation;
  String _selectedVehicleType = 'scooter';
  final List<File> _vehicleDocuments = [];
  final Connectivity _connectivity = Connectivity();
  // Initialize with an empty subscription that will be properly set in initState
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  String? _lastErrorServerUrl;
  final Debouncer _debouncer = Debouncer(
    delay: const Duration(milliseconds: 500),
  );

  @override
  void initState() {
    super.initState();
    _initializeConnectivity();
    _requestLocationPermission();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _firstNameController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _connectivitySubscription?.cancel();
    _debouncer.cancel();
    super.dispose();
  }

  // Initialize connectivity monitoring
  Future<void> _initializeConnectivity() async {
    try {
      var connectivityResult = await _connectivity.checkConnectivity();
      bool hasInternet = connectivityResult != ConnectivityResult.none;

      if (mounted) {
        setState(() {
          _isConnected = hasInternet;
        });
      }

      _connectivitySubscription =
          _connectivity.onConnectivityChanged.listen((result) {
                bool hasConnection = result != ConnectivityResult.none;

                if (mounted) {
                  setState(() {
                    _isConnected = hasConnection;
                  });
                  developer.log(
                    'Connectivity changed: ${_isConnected ? 'Connected' : 'Disconnected'}',
                    name: 'SignUpPage',
                  );
                }
              })
              as StreamSubscription<ConnectivityResult>;
    } catch (e) {
      developer.log(
        'Connectivity initialization error: $e',
        name: 'SignUpPage',
      );
      if (mounted) {
        setState(() => _isConnected = false);
      }
    }
  }

  // Request location permission and get current location
  Future<void> _requestLocationPermission() async {
    final location = Location();
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    try {
      _currentLocation = await location.getLocation();
      developer.log(
        'Location retrieved: lat=${_currentLocation?.latitude}, lon=${_currentLocation?.longitude}',
        name: 'SignUpPage',
      );
    } catch (e) {
      developer.log('Error getting location: $e', name: 'SignUpPage');
    }
  }

  // Pick image from gallery
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
        _profileImage = File(image.path);
      });
      developer.log(
        'Profile image selected: ${image.path}',
        name: 'SignUpPage',
      );
    }
  }

  // Pick vehicle documents
  Future<void> _pickVehicleDocuments() async {
    final ImagePicker picker = ImagePicker();
    final XFile? document = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 90,
    );

    if (document != null) {
      setState(() {
        _vehicleDocuments.add(File(document.path));
      });
      developer.log(
        'Vehicle document added: ${document.path}',
        name: 'SignUpPage',
      );
    }
  }

  // Handle signup process
  Future<void> _signUp() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      Fluttertoast.showToast(
        msg: "Passwords do not match",
        backgroundColor: Colors.red,
      );
      return;
    }

    try {
      var connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        _showNetworkErrorDialog("No internet connection detected.");
        return;
      }
    } catch (e) {
      if (!_isConnected) {
        _showNetworkErrorDialog("No internet connection detected.");
        return;
      }
    }
    setState(() => _isLoading = true);

    try {
      // Check if profile image exists
      if (_profileImage == null) {
        setState(() => _isLoading = false);
        Fluttertoast.showToast(
          msg: "Please select a profile image",
          toastLength: Toast.LENGTH_LONG,
          backgroundColor: Colors.red,
        );
        return;
      }

      final userData = {
        'username': _usernameController.text.trim(),
        'firstName': _firstNameController.text.trim(),
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'phone': _phoneController.text.trim(),
        'role': _selectedRole,
        if (_currentLocation?.latitude != null)
          'latitude': _currentLocation!.latitude,
        if (_currentLocation?.longitude != null)
          'longitude': _currentLocation!.longitude,
        if (_selectedRole == 'livreur' && _selectedVehicleType.isNotEmpty)
          'vehiculetype': _selectedVehicleType,
      };
      developer.log(
        'Attempting to register user with data: $userData, profileImage: ${_profileImage?.path}, documents: ${_vehicleDocuments.length}',
        name: 'SignUpPage',
      );
      final response = await ApiService.registerUser(
        username: _usernameController.text.trim(),
        firstName: _firstNameController.text.trim(),
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: _phoneController.text.trim(),
        role: _selectedRole,
        latitude: _currentLocation?.latitude,
        longitude: _currentLocation?.longitude,
        vehiculetype: _selectedRole == 'livreur' ? _selectedVehicleType : null,
        profileImage: _profileImage,
        vehicleDocuments: _selectedRole == 'livreur' ? _vehicleDocuments : [],
      );

      developer.log('Registration response: $response', name: 'SignUpPage');

      if (response['error'] != null) {
        String errorMsg = response['error'].toString();
        developer.log('Registration failed: $errorMsg', name: 'SignUpPage');
        if (response['statusCode'] == 404 || errorMsg.contains('404')) {
          _showNetworkErrorDialog(
            'Server endpoint not found. Please check if the server is running at ${ServerConfig.activeServerUrl}/api/users/register.',
          );
        } else {
          Fluttertoast.showToast(msg: errorMsg, backgroundColor: Colors.red);
        }
        return;
      }
      Fluttertoast.showToast(
        msg: "Registration successful! Please login.",
        backgroundColor: Colors.green,
        toastLength: Toast.LENGTH_LONG,
      );

      // Clear any automatic navigation logic that might be happening
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        // Force navigation to login page
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false, // This clears the navigation stack
        );
      }
    } catch (e) {
      String errorMessage;
      _lastErrorServerUrl = ServerConfig.activeServerUrl;
      if (e.toString().contains('SocketException')) {
        errorMessage =
            "Network error: Cannot connect to server at $_lastErrorServerUrl.";
        _showNetworkErrorDialog(errorMessage);
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage =
            "Connection timed out. Server may be down at $_lastErrorServerUrl.";
        _showNetworkErrorDialog(errorMessage);
      } else {
        errorMessage = "Registration error: $e";
        Fluttertoast.showToast(
          msg: errorMessage,
          backgroundColor: Colors.red,
          toastLength: Toast.LENGTH_LONG,
        );
      }
      developer.log('Registration error: $e', name: 'SignUpPage');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Show network error dialog
  void _showNetworkErrorDialog(String message) {
    developer.log('Showing network error dialog: $message', name: 'SignUpPage');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Network Connection Error'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Text(message),
                if (_lastErrorServerUrl != null) ...[
                  const SizedBox(height: 10),
                  Text('Server URL: $_lastErrorServerUrl'),
                ],
                const SizedBox(height: 10),
                const Text('Possible causes:'),
                const Text('• Device not on the same Wi-Fi as the server'),
                const Text('• Server is down or port 5000 is blocked'),
                const Text('• Incorrect server IP or endpoint'),
                const SizedBox(height: 10),
                const Text('Ensure the server is running and try again.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Retry'),
              onPressed: () async {
                Navigator.of(context).pop();
                await Future.delayed(const Duration(milliseconds: 500));
                _debouncer.run(_signUp);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Column(
        children: [
          if (!_isConnected)
            Container(
              width: double.infinity,
              color: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.signal_wifi_off, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No internet connection. Registration may not work.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: _initializeConnectivity,
                    tooltip: 'Check connectivity',
                  ),
                ],
              ),
            ),
          Expanded(
            child:
                _isLoading
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
                                alignment: Alignment.bottomRight,
                                children: [
                                  ImageService.buildAvatar(
                                    imageUrl: _profileImage?.path ?? '',
                                    radius: 50,
                                    category: 'user',
                                    isLocalFile: _profileImage != null,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(4),
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
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _usernameController,
                              decoration: const InputDecoration(
                                labelText: 'Username',
                                prefixIcon: Icon(Icons.person),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a username';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _firstNameController,
                              decoration: const InputDecoration(
                                labelText: 'First Name',
                                prefixIcon: Icon(Icons.person_outline),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your first name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Last Name',
                                prefixIcon: Icon(Icons.person_outline),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your last name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!RegExp(
                                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                ).hasMatch(value)) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock),
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed:
                                      () => setState(
                                        () =>
                                            _obscurePassword =
                                                !_obscurePassword,
                                      ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              decoration: InputDecoration(
                                labelText: 'Confirm Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed:
                                      () => setState(
                                        () =>
                                            _obscureConfirmPassword =
                                                !_obscureConfirmPassword,
                                      ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please confirm your password';
                                }
                                if (value != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Phone Number',
                                prefixIcon: Icon(Icons.phone),
                                border: OutlineInputBorder(),
                                hintText: '(+216) xx xxx xxx',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your phone number';
                                }
                                if (!RegExp(
                                  r'^(\+216)?[2459][0-9]{7}$',
                                ).hasMatch(value)) {
                                  return 'Please enter a valid Tunisian phone number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedRole,
                              decoration: const InputDecoration(
                                labelText: 'Select Role',
                                prefixIcon: Icon(Icons.badge),
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'livreur',
                                  child: Text('Livreur'),
                                ),
                                DropdownMenuItem(
                                  value: 'client',
                                  child: Text('Client'),
                                ),
                              ],
                              onChanged:
                                  (value) =>
                                      setState(() => _selectedRole = value!),
                            ),
                            const SizedBox(height: 16),
                            if (_selectedRole == 'livreur')
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  DropdownButtonFormField<String>(
                                    value: _selectedVehicleType,
                                    decoration: const InputDecoration(
                                      labelText: 'Vehicle Type',
                                      prefixIcon: Icon(Icons.directions_car),
                                      border: OutlineInputBorder(),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'scooter',
                                        child: Text('Scooter'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'motorcycle',
                                        child: Text('Motorcycle'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'car',
                                        child: Text('Car'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'bicycle',
                                        child: Text('Bicycle'),
                                      ),
                                    ],
                                    onChanged:
                                        (value) => setState(
                                          () => _selectedVehicleType = value!,
                                        ),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Vehicle Documents (Optional)',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        if (_vehicleDocuments.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 8.0,
                                            ),
                                            child: Text(
                                              '${_vehicleDocuments.length} document(s) selected',
                                              style: TextStyle(
                                                color:
                                                    Theme.of(
                                                      context,
                                                    ).primaryColor,
                                              ),
                                            ),
                                          ),
                                        SizedBox(
                                          width: double.infinity,
                                          child: OutlinedButton.icon(
                                            onPressed: _pickVehicleDocuments,
                                            icon: const Icon(Icons.upload_file),
                                            label: const Text(
                                              'Upload Vehicle Documents',
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 12,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 24),
                            if (_currentLocation != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Row(
                                  children: const [
                                    Icon(
                                      Icons.location_on,
                                      color: Colors.green,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Location detected',
                                      style: TextStyle(color: Colors.green),
                                    ),
                                  ],
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                children: [
                                  Icon(
                                    _isConnected ? Icons.wifi : Icons.wifi_off,
                                    color:
                                        _isConnected
                                            ? Colors.green
                                            : Colors.red,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isConnected
                                        ? 'Connected to the internet'
                                        : 'No internet connection',
                                    style: TextStyle(
                                      color:
                                          _isConnected
                                              ? Colors.green
                                              : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () => _debouncer.run(_signUp),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text(
                                  'SIGN UP',
                                  style: Theme.of(context).textTheme.labelLarge!
                                      .copyWith(color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("Already have an account?"),
                                TextButton(
                                  onPressed: () {
                                    developer.log(
                                      'Navigating to LoginPage',
                                      name: 'SignUpPage',
                                    );
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const LoginPage(),
                                      ),
                                    );
                                  },
                                  child: const Text('Login'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
