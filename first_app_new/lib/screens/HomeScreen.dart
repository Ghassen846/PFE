import 'dart:async';
import 'package:first_app_new/services/image_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../customs/info_card.dart';
import 'package:first_app_new/services/api_service.dart';
import '../helpers/footer_navigation_helper.dart';
import 'dart:developer' as developer;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool _isDarkMode = false;
  late AnimationController _animationController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Map<String, dynamic>? _userData;
  bool _isOnline = false;
  Timer? _onlineStatusTimer;
  int _unreadCount = 0;

  int completedDeliveries = 0;
  int pendingDeliveries = 0;
  double totalCollected = 0;
  double totalEarnings = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fetchUserData();
    _setUserOnline();
    _fetchDeliveryStats();
    _fetchUnreadCount();

    _onlineStatusTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      _updateOnlineStatus();
      _fetchUnreadCount();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _onlineStatusTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchDeliveryStats() async {
    setState(() => _isLoading = true);
    try {
      String? userId = await ApiService.getUserId();
      if (userId == null || userId.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        userId = prefs.getString('userId');
        if (userId == null || userId.isEmpty) {
          developer.log(
            'User ID not found, redirecting to login',
            name: 'HomeScreen',
          );
          throw "User ID not found. Please log in again.";
        }
      }
      userId = userId.trim();

      developer.log(
        'Fetching delivery stats for user ID: $userId',
        name: 'HomeScreen',
      );
      final response = await ApiService.get(
        'delivery/stats',
        queryParams: {'userId': userId},
      );

      if (response.containsKey('error')) {
        developer.log(
          'Error fetching delivery stats: ${response['error']}',
          name: 'HomeScreen',
        );
        throw response['error'];
      }
      developer.log('Delivery stats fetched: $response', name: 'HomeScreen');
      if (mounted) {
        setState(() {
          completedDeliveries =
              int.tryParse(response['completed']?.toString() ?? '0') ?? 0;
          pendingDeliveries =
              int.tryParse(response['pending']?.toString() ?? '0') ?? 0;
          totalCollected =
              double.tryParse(response['collected']?.toString() ?? '0') ?? 0.0;
          totalEarnings =
              double.tryParse(response['earnings']?.toString() ?? '0') ?? 0.0;
          _isLoading = false;
        });
      }
    } catch (e) {
      developer.log(
        'Exception fetching delivery stats: $e',
        name: 'HomeScreen',
      );
      if (mounted) {
        setState(() => _isLoading = false);
      }
      Fluttertoast.showToast(
        msg: "Error fetching stats: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  Future<void> _setUserOnline() async {
    try {
      developer.log('Setting user online', name: 'HomeScreen');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isOnline', true);
      if (mounted) {
        setState(() {
          _isOnline = true;
        });
      }
      await ApiService.updateOnlineStatusToServer(true);
    } catch (e) {
      developer.log('Error setting user online: $e', name: 'HomeScreen');
    }
  }

  Future<void> _updateOnlineStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

      if (isLoggedIn) {
        developer.log('Updating online status', name: 'HomeScreen');
        await prefs.setBool('isOnline', true);
        await ApiService.updateOnlineStatusToServer(true);

        if (mounted) {
          setState(() {
            _isOnline = true;
          });
        }
      }
    } catch (e) {
      developer.log('Error updating online status: $e', name: 'HomeScreen');
    }
  }

  Future<void> _fetchUserData() async {
    setState(() => _isLoading = true);

    try {
      final token = await ApiService.getToken();

      if (token == null) {
        developer.log(
          'No token found, redirecting to login',
          name: 'HomeScreen',
        );
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
        return;
      }

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

        if (cachedData.values.whereType<String>().every((v) => v.isNotEmpty)) {
          developer.log(
            'Using cached user data: $cachedData',
            name: 'HomeScreen',
          );
          setState(() {
            _userData = cachedData;
            _isLoading = false;
          });
          return;
        }
      }

      developer.log('Fetching user profile from server', name: 'HomeScreen');
      final response = await ApiService.get('user/me');

      if (response.containsKey('error')) {
        developer.log(
          'Error fetching user profile: ${response['error']}',
          name: 'HomeScreen',
        );
        await ApiService.secureStorage.delete(key: 'token');
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

      final userData = Map<String, dynamic>.from(response);
      developer.log('User profile fetched: $userData', name: 'HomeScreen');

      setState(() {
        _userData = userData;
        _isLoading = false;
      });

      await _saveUserDataToPrefs(userData);
    } catch (e) {
      developer.log('Exception fetching user data: $e', name: 'HomeScreen');
      if (mounted) {
        setState(() => _isLoading = false);
        Fluttertoast.showToast(
          msg: "Failed to load profile data",
          backgroundColor: Colors.orange,
        );
      }
    }
  }

  Future<void> _saveUserDataToPrefs(Map<String, dynamic> userData) async {
    developer.log(
      'Saving user data to preferences: $userData',
      name: 'HomeScreen',
    );
    await ApiService.saveUserData(userData);
  }

  Future<void> _fetchUnreadCount() async {
    try {
      String? userId = await ApiService.getUserId();
      if (userId == null || userId.isEmpty) {
        developer.log(
          'No user ID for fetching unread count',
          name: 'HomeScreen',
        );
        return;
      }

      developer.log(
        'Fetching unread message count for user ID: $userId',
        name: 'HomeScreen',
      );
      final response = await ApiService.get(
        'chat/unread',
        queryParams: {'userId': userId},
      );
      if (response.containsKey('error')) {
        developer.log(
          'Error fetching unread count: ${response['error']}',
          name: 'HomeScreen',
        );
        return;
      }
      if (mounted) {
        setState(() {
          _unreadCount = response['totalUnread'] ?? 0;
        });
      }
    } catch (e) {
      developer.log('Exception fetching unread count: $e', name: 'HomeScreen');
    }
  }

  void _toggleTheme() {
    developer.log(
      'Toggling theme: isDarkMode=$_isDarkMode',
      name: 'HomeScreen',
    );
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  Future<void> _handleLogout() async {
    developer.log('Showing logout confirmation dialog', name: 'HomeScreen');
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
                developer.log('Logout cancelled', name: 'HomeScreen');
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
  }

  Future<void> _performLogout() async {
    setState(() => _isLoading = true);
    try {
      developer.log('Performing logout', name: 'HomeScreen');
      _onlineStatusTimer?.cancel();
      await ApiService.updateOnlineStatusToServer(false);
      ApiService.stopPeriodicOnlineUpdates();
      await ApiService.logout();

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
      developer.log('Error during logout: $e', name: 'HomeScreen');
      Fluttertoast.showToast(
        msg: 'Error logging out',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToDetailsScreen(String category, String title) {
    developer.log(
      'Navigating to DeliveryDetailsScreen using FooterNavigationHelper: category=$category, title=$title',
      name: 'HomeScreen',
    );
    FooterNavigationHelper.navigateToDeliveryDetails(
      context,
      category: category,
      title: title,
    );
  }

  Widget _buildDashboardCards() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(10),
      children: [
        InfoCard(
          title: 'Completed Deliveries',
          value: _isLoading ? '...' : completedDeliveries.toString(),
          color: Colors.green,
          icon: Icons.check_circle,
          onTap:
              () =>
                  _navigateToDetailsScreen('completed', 'Completed Deliveries'),
        ),
        InfoCard(
          title: 'Pending Deliveries',
          value: _isLoading ? '...' : pendingDeliveries.toString(),
          color: Colors.orange,
          icon: Icons.pending_actions,
          onTap:
              () => _navigateToDetailsScreen('pending', 'Pending Deliveries'),
        ),
        InfoCard(
          title: 'Total Collected',
          value: _isLoading ? '...' : '\$${totalCollected.toStringAsFixed(2)}',
          color: Colors.blue,
          icon: Icons.monetization_on,
          onTap:
              () =>
                  _navigateToDetailsScreen('collected', 'Payment Collections'),
        ),
        InfoCard(
          title: 'Earnings',
          value: _isLoading ? '...' : '\$${totalEarnings.toStringAsFixed(2)}',
          color: Colors.purple,
          icon: Icons.account_balance_wallet,
          onTap: () => _navigateToDetailsScreen('earnings', 'Driver Earnings'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            developer.log('Opening drawer', name: 'HomeScreen');
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          IconButton(
            icon: Icon(_isDarkMode ? Icons.wb_sunny : Icons.nightlight_round),
            onPressed: _toggleTheme,
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.chat),
                tooltip: 'Chat with Admin',
                onPressed: () {
                  developer.log(
                    'Navigating to chat screen',
                    name: 'HomeScreen',
                  );
                  Navigator.of(
                    context,
                  ).pushNamed('/chat', arguments: _userData);
                },
              ),
              if (_unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_unreadCount',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () {
                developer.log(
                  'Navigating to profile with userData: $_userData',
                  name: 'HomeScreen',
                );
                Navigator.of(
                  context,
                ).pushNamed('/profile', arguments: _userData);
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ImageService.buildAvatar(
                    imageUrl:
                        _userData != null &&
                                _userData!.containsKey('image') &&
                                _userData!['image'] != null
                            ? _userData!['image'].toString()
                            : '',
                    radius: 15,
                    category: 'user',
                  ),
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
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage:
                        _userData != null &&
                                _userData!['image'] != null &&
                                _userData!['image'].toString().isNotEmpty
                            ? NetworkImage(
                              ImageService.getFullImageUrl(
                                _userData!['image'] as String,
                              ),
                            )
                            : null,
                    child:
                        _userData == null ||
                                _userData!['image'] == null ||
                                _userData!['image'].toString().isEmpty
                            ? const Icon(Icons.person, size: 30)
                            : null,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _userData?['firstName'] ?? 'Loading...',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  Text(
                    _userData?['email'] ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushReplacementNamed('/home');
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Chat with Admin'),
              trailing:
                  _unreadCount > 0
                      ? Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$_unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      )
                      : null,
              onTap: () {
                developer.log(
                  'Navigating to chat screen from drawer',
                  name: 'HomeScreen',
                );
                Navigator.pop(context);
                Navigator.of(context).pushNamed('/chat', arguments: _userData);
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('History'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushReplacementNamed('/history');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                _handleLogout();
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          _buildDashboardCards(),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
