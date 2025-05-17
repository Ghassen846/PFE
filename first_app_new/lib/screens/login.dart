import 'package:first_app_new/screens/SignUp.dart';
import 'package:first_app_new/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:developer' as developer;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // State variables
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Check if user is already logged in
  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await ApiService.isLoggedIn();
    developer.log(
      'Checking login status: isLoggedIn=$isLoggedIn',
      name: 'LoginPage',
    );
    if (isLoggedIn) {
      _navigateToHome();
    }
  }

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  void _navigateToHome() {
    developer.log('Navigating to HomeScreen', name: 'LoginPage');
    // Start periodic online status updates
    ApiService.startPeriodicOnlineUpdates();

    // Set user as online
    ApiService.setOnlineStatus(true);
    ApiService.updateOnlineStatusToServer(true);

    // Use the named route that includes the footer navigation
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
  }

  // Enhanced login method with proper online status handling
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // Get login fields
        final String email = _emailController.text.trim();
        final String password = _passwordController.text;
        developer.log('Attempting login with email: $email', name: 'LoginPage');

        // Attempt login
        final Map<String, dynamic> response = await ApiService.loginUser(
          email: email,
          password: password,
        );

        // Check for error in response
        if (response.containsKey('error')) {
          developer.log('Login error: ${response['error']}', name: 'LoginPage');
          Fluttertoast.showToast(
            msg: "Login failed: ${response['error']}",
            backgroundColor: Colors.red,
            toastLength: Toast.LENGTH_LONG,
          );
          setState(() => _isLoading = false);
          return;
        }

        // Check for token
        if (!response.containsKey('token')) {
          developer.log(
            'Login failed: No token in response: $response',
            name: 'LoginPage',
          );
          Fluttertoast.showToast(
            msg: "Login failed: Invalid response",
            backgroundColor: Colors.red,
            toastLength: Toast.LENGTH_LONG,
          );
          setState(() => _isLoading = false);
          return;
        }

        // Save session data
        developer.log('Login successful, saving session', name: 'LoginPage');
        await ApiService.saveUserSession(response);

        // Update online status
        await ApiService.setOnlineStatus(true);
        await ApiService.updateOnlineStatusToServer(true);

        // Start periodic status updates
        ApiService.startPeriodicOnlineUpdates();

        // Show success message
        Fluttertoast.showToast(
          msg: "Login successful!",
          backgroundColor: Colors.green,
        );

        // Navigate to home page
        _navigateToHome();
      } catch (e) {
        developer.log('Login exception: $e', name: 'LoginPage');
        Fluttertoast.showToast(
          msg: "Login failed: $e",
          backgroundColor: Colors.red,
          toastLength: Toast.LENGTH_LONG,
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // App logo
                      Image.asset('assets/images/logoBw.png', height: 120),

                      const SizedBox(height: 32),

                      // Email field
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

                      const SizedBox(height: 16),

                      // Password field
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
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 8),

                      // Forgot password link
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            developer.log(
                              'Forgot password clicked',
                              name: 'LoginPage',
                            );
                            Fluttertoast.showToast(
                              msg:
                                  "Forgot password functionality not implemented yet",
                              backgroundColor: Colors.orange,
                            );
                          },
                          child: const Text('Forgot Password?'),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Login button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.orange,
                          ),
                          child: Text(
                            'LOGIN',
                            style: Theme.of(context).textTheme.labelLarge!
                                .copyWith(color: Colors.white),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Signup link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account?"),
                          TextButton(
                            onPressed: () {
                              developer.log(
                                'Navigating to SignUpPage',
                                name: 'LoginPage',
                              );
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignUpPage(),
                                ),
                              );
                            },
                            child: const Text('Sign Up'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
