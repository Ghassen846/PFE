import 'dart:convert';
import 'package:first_app/Help.dart';
import 'package:first_app/History.dart';
import 'package:first_app/Notification.dart';
import 'package:first_app/Profile.dart';
import 'package:first_app/Search.dart';
import 'package:first_app/Settings.dart';

import 'package:first_app/side_menu.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'services/ApiService.dart'; // Add this import

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isLoading = false;
  bool _areAuthButtonsVisible = false;
  bool _isSearching = false;
  bool _isDarkMode = false;
  late AnimationController _animationController;
  late PageController _pageController;
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Map<String, dynamic>? _userData; // Cache user data to avoid repeated fetches

  final List<Widget> _screens = [
    const Center(child: Text('Home Screen', style: TextStyle(fontSize: 24))),
    const SearchScreen(),
    const HistoryScreen(),
    const SettingsScreen(),
    const NotificationScreen(),
    const HelpScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _pageController = PageController(initialPage: _selectedIndex);
    _fetchUserData(); // Fetch user data once during initialization
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    setState(() => _isLoading = true);

    try {
      // First check if we have a token
      final token = await ApiService.getToken();

      if (token == null) {
        debugPrint('No token found, redirecting to login');
        // Make sure we only redirect once
        if (mounted) {
          await Future.delayed(Duration.zero); // Ensure context is valid
          Navigator.of(context).pushReplacementNamed('/login');
        }
        return;
      }

      // Try to get user data from shared preferences first
      final prefs = await SharedPreferences.getInstance();
      final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

      if (isLoggedIn) {
        final cachedData = {
          'username': prefs.getString('username') ?? '',
          'email': prefs.getString('email') ?? '',
          'phone': prefs.getString('phone') ?? '',
          'role': prefs.getString('role') ?? 'livreur',
          'firstName': prefs.getString('firstName') ?? '',
          'name': prefs.getString('name') ?? '',
          'image': prefs.getString('image') ?? '',
        };

        // Check if we have all the required data
        if (cachedData.values.every((v) => v.isNotEmpty)) {
          setState(() {
            _userData = cachedData;
            _isLoading = false;
          });
          return;
        }
      } // If no cached data or incomplete, fetch from server
      final response = await ApiService.get('user/profile');

      if (response.containsKey('error')) {
        // Token might be invalid or expired
        debugPrint('API Error: ${response['error']}');

        // Clear token and preferences
        await ApiService.secureStorage.delete(key: 'token');
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        if (mounted) {
          Fluttertoast.showToast(
            msg: "Session expired. Please login again.",
            backgroundColor: Colors.red,
          );
          Navigator.of(context).pushReplacementNamed('/login');
        }
        return;
      }

      // Successfully got user data - convert to Map<String, dynamic>
      final userData = Map<String, dynamic>.from(response);

      // Update in state
      setState(() {
        _userData = userData;
        _isLoading = false;
      });

      // Save to preferences for next time
      await _saveUserDataToPrefs(userData);
    } catch (e) {
      debugPrint('Error fetching user data: $e');

      // Handle error gracefully
      if (mounted) {
        setState(() => _isLoading = false);
        Fluttertoast.showToast(
          msg: "Failed to load profile data",
          backgroundColor: Colors.orange,
        );
      }
    }
  }

  // Helper method to save user data to preferences
  Future<void> _saveUserDataToPrefs(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('username', userData['username'] ?? '');
      await prefs.setString('firstName', userData['firstName'] ?? '');
      await prefs.setString('name', userData['name'] ?? '');
      await prefs.setString('email', userData['email'] ?? '');
      await prefs.setString('phone', userData['phone'] ?? '');
      await prefs.setString('role', userData['role'] ?? 'livreur');

      if (userData['image'] != null) {
        await prefs.setString('image', userData['image']);
      }

      await prefs.setBool('isLoggedIn', true);
    } catch (e) {
      debugPrint('Error saving user data to prefs: $e');
    }
  }

  void _onItemTapped(int index) {
    if (index >= _screens.length) {
      debugPrint('Invalid bottom nav index: $index');
      return;
    }
    debugPrint('Bottom nav tapped: $index');
    setState(() {
      _isLoading = true;
      _selectedIndex = index;
      if (_isSearching) {
        _stopSearching();
      }
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  void _handleMenuSelection(int index) {
    if (index >= _screens.length) {
      debugPrint('Invalid menu index: $index');
      return;
    }
    debugPrint('Menu selected: $index');
    setState(() {
      _isLoading = true;
      _selectedIndex = index;
      if (_isSearching) {
        _stopSearching();
      }
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  void _toggleAuthButtons() {
    setState(() {
      _areAuthButtonsVisible = !_areAuthButtonsVisible;
      if (_areAuthButtonsVisible) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearching() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      SearchScreen.searchQuery = '';
      FocusScope.of(context).unfocus();
    });
  }

  Future<void> _navigateToProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      Fluttertoast.showToast(
        msg: 'Please log in to view your profile',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      Navigator.pushNamed(context, '/login');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Use ApiService instead of direct http call
      final response = await ApiService.get('user/me');

      if (!response.containsKey('error')) {
        // Get user data directly from response
        final data = Map<String, dynamic>.from(response);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ProfileScreen(
                  username: data['username']?.toString() ?? '',
                  email: data['email']?.toString() ?? '',
                  phone: data['phone']?.toString() ?? '',
                  role: data['role']?.toString() ?? '',
                  firstName: data['firstName']?.toString() ?? '',
                  name: data['name']?.toString() ?? '',
                  imageUrl: data['image']?.toString() ?? '',
                ),
          ),
        );
      } else {
        Fluttertoast.showToast(
          msg: 'Failed to load profile data: ${response['error']}',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error loading profile: $e',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleLogout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Clear all session data
      await prefs.clear();

      Fluttertoast.showToast(
        msg: 'Successfully logged out',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      debugPrint('Error during logout: $e');
      Fluttertoast.showToast(
        msg: 'Error logging out',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme:
          _isDarkMode
              ? ThemeData.dark().copyWith(
                primaryColor: Colors.blueGrey[800],
                appBarTheme: AppBarTheme(backgroundColor: Colors.blueGrey[900]),
                scaffoldBackgroundColor: Colors.blueGrey[900],
                floatingActionButtonTheme: FloatingActionButtonThemeData(
                  backgroundColor: Colors.blueGrey[800],
                ),
              )
              : ThemeData.light().copyWith(
                primaryColor: Colors.orange,
                appBarTheme: const AppBarTheme(backgroundColor: Colors.orange),
                scaffoldBackgroundColor: Colors.white,
                floatingActionButtonTheme: FloatingActionButtonThemeData(
                  backgroundColor: Colors.orange[800],
                ),
              ),
      home: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title:
              _isSearching
                  ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        color: _isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          Icons.close,
                          color: _isDarkMode ? Colors.white : Colors.black,
                        ),
                        onPressed: _stopSearching,
                      ),
                    ),
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white : Colors.black,
                    ),
                    onSubmitted: (value) {
                      SearchScreen.searchQuery = value;
                      setState(() {});
                    },
                  )
                  : Text(_getAppBarTitle()),
          leading:
              _isSearching
                  ? null
                  : IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                  ),
          actions: [
            if (!_isSearching) ...[
              if (_selectedIndex == 1)
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _startSearch,
                ),
              IconButton(
                icon: Icon(
                  _isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
                ),
                onPressed: _toggleTheme,
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white, size: 26),
                tooltip: 'Logout',
                onPressed: _handleLogout,
              ),
              CircleAvatar(
                radius: 15,
                backgroundImage:
                    _userData != null &&
                            _userData!['image'] != null &&
                            _userData!['image'].isNotEmpty
                        ? NetworkImage(_userData!['image'])
                        : const AssetImage('assets/default_profile.jpg')
                            as ImageProvider,
                child: GestureDetector(onTap: _navigateToProfile),
              ),
            ],
          ],
        ),
        drawer: SideMenu(onMenuSelected: _handleMenuSelection),
        body: Stack(
          children: [
            PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _selectedIndex = index;
                  if (_isSearching) {
                    _stopSearching();
                  }
                });
              },
              children: _screens,
            ),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Home';
      case 1:
        return 'Search';
      case 2:
        return 'History';
      case 3:
        return 'Settings';
      case 4:
        return 'Notifications';
      case 5:
        return 'Help';
      default:
        return 'Home';
    }
  }
}
