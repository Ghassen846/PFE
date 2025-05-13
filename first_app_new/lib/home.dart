import 'dart:convert';
import 'dart:async'; // For Timer
import 'Help.dart';
import 'History.dart';
import 'Notification.dart';
import 'profile.dart';
import 'Search.dart';
import 'Settings.dart';

import 'side_menu.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'services/ApiService.dart';
import 'services/AuthService.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isLoading = false;
  bool _isSearching = false;
  bool _isDarkMode = false;
  late AnimationController _animationController;
  late PageController _pageController;
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Map<String, dynamic>? _userData; // Cache user data to avoid repeated fetches
  bool _isOnline = false; // Track user's online status
  Timer? _onlineStatusTimer; // Timer to periodically update online status

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
    _setUserOnline(); // Set user as online when app starts

    // Start periodic online status updates every 2 minutes
    _onlineStatusTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      _updateOnlineStatus();
    });
  }

  // Set the user as online
  Future<void> _setUserOnline() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isOnline', true);
      setState(() {
        _isOnline = true;
      });
    } catch (e) {
      debugPrint('Error setting user online: $e');
    }
  }

  // Update online status periodically
  Future<void> _updateOnlineStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if logged in before updating status
      final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      if (isLoggedIn) {
        await prefs.setBool('isOnline', true);
        // Update online status to server
        await AuthService.updateOnlineStatusToServer(true);

        if (mounted) {
          setState(() {
            _isOnline = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error updating online status: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    _searchController.dispose();
    _onlineStatusTimer?.cancel(); // Cancel the timer when disposing

    // Don't cancel the global periodic updates since they're managed by AuthService
    // We only handle our local timer here

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
          'name':
              prefs.getString('name') ??
              '', // Updated to use 'name' instead of 'LastName'
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
      await prefs.setString(
        'name',
        userData['name'] ?? '',
      ); // Updated to use 'name' instead of 'LastName'
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
  // Navigation is now handled directly by PageView onPageChanged
  // This function is kept for reference but may be removed

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
  // Auth buttons are now managed differently
  // This function is kept for reference but may be removed

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
                  name:
                      data['name']?.toString() ??
                      '', // Updated to use 'name' instead of 'LastName'
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
    // Show confirmation dialog
    showDialog<void>(
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
                await _performLogout();
              },
            ),
          ],
        );
      },
    );
  } // Actually perform the logout

  Future<void> _performLogout() async {
    setState(() => _isLoading = true);
    try {
      // Cancel our local timer first
      _onlineStatusTimer?.cancel();

      // Set user as offline on the server
      await AuthService.updateOnlineStatusToServer(false);

      // Stop periodic status updates from AuthService
      AuthService.stopPeriodicOnlineUpdates();

      // Complete logout to clear all user data
      await AuthService.logout();

      Fluttertoast.showToast(
        msg: 'Successfully disconnected',
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
              Stack(
                children: [
                  GestureDetector(
                    onTap: _navigateToProfile,
                    child: CircleAvatar(
                      radius: 15,
                      backgroundImage:
                          _userData != null &&
                                  _userData!['image'] != null &&
                                  _userData!['image'].isNotEmpty
                              ? NetworkImage(_userData!['image'])
                              : const AssetImage('assets/default_profile.jpg')
                                  as ImageProvider,
                    ),
                  ),
                  // Online indicator
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _isOnline ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                    ),
                  ),
                ],
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
