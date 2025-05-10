import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'services/AuthService.dart';
import 'signup.dart';
import 'Home.dart'; // Assuming this is your home screen

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
    final isLoggedIn = await AuthService.isLoggedIn();
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
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  } // Handle login process

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // Clear any existing tokens first
        await AuthService.logout();

        // Attempt login
        final response = await AuthService.loginUser(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (response.containsKey('error')) {
          Fluttertoast.showToast(
            msg: "Login failed: ${response['error']}",
            backgroundColor: Colors.red,
            toastLength: Toast.LENGTH_LONG,
          );
          setState(() => _isLoading = false);
          return;
        }

        // Double check that we got a token
        final token = await AuthService.getToken();
        if (token == null) {
          debugPrint("No token received from login response");
          Fluttertoast.showToast(
            msg: "Login failed: Authentication error",
            backgroundColor: Colors.red,
            toastLength: Toast.LENGTH_LONG,
          );
          setState(() => _isLoading = false);
          return;
        }

        debugPrint("Token successfully received and stored");

        // Save user session data
        await AuthService.saveUserSession(response);

        // Show success message
        Fluttertoast.showToast(
          msg: "Login successful!",
          backgroundColor: Colors.green,
        );

        // Navigate to home page
        _navigateToHome();
      } catch (e) {
        debugPrint("Login exception: ${e.toString()}");
        Fluttertoast.showToast(
          msg: "Login failed: ${e.toString()}",
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
                            // TODO: Implement forgot password
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
                            foregroundColor: Colors.white,
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
