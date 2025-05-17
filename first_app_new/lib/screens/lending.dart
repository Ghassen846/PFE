import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class LendingScreen extends StatefulWidget {
  const LendingScreen({super.key});
  static late WebSocketChannel channel;

  @override
  State<LendingScreen> createState() => _LandingPageState();
}

class _LandingPageState extends State<LendingScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isConnected = false;
  String? userId;
  int navigatorIndex = 0;
  // Base WebSocket URL - updated with current PC IP address
  final String baseUrlWS = 'ws://192.168.100.41:5000/ws';

  @override
  void initState() {
    super.initState();
    initializeWebSocketConnection();
  }

  @override
  void dispose() {
    try {
      LendingScreen.channel.sink.close();
    } catch (e) {
      log('Error closing WebSocket: $e');
    }
    super.dispose();
  }

  Future<void> initializeWebSocketConnection() async {
    try {
      String id = await getIdFromSharedPrefs();
      LendingScreen.channel = WebSocketChannel.connect(
        Uri.parse('$baseUrlWS?userID=$id'),
      );

      LendingScreen.channel.stream.listen(
        (message) {
          processMessage(message);
        },
        onError: (error) {
          log('WebSocket Error: $error');
          setState(() {
            isConnected = false;
          });
        },
        onDone: () {
          log('WebSocket connection closed');
          setState(() {
            isConnected = false;
          });
          // Reconnect after a delay
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted) {
              initializeWebSocketConnection();
            }
          });
        },
      );

      setState(() {
        isConnected = true;
        userId = id;
      });
    } catch (e) {
      log('Error establishing WebSocket connection: $e');
      setState(() {
        isConnected = false;
      });
    }
  }

  Future<String> getIdFromSharedPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId') ?? 'unknown';
  }

  void processMessage(dynamic message) {
    try {
      log('Received WebSocket message: $message');
      Map<String, dynamic> jsonResponse = jsonDecode(message);

      if (jsonResponse.containsKey('type')) {
        switch (jsonResponse['type']) {
          case 'NEW_ORDER':
            showCustomBottomSheet(
              title: 'New Order!',
              message: 'You have received a new order. Check your orders page.',
              isSuccess: true,
            );
            break;
          case 'ORDER_CANCELED':
            showCustomBottomSheet(
              title: 'Order Canceled',
              message: 'An order has been canceled by the customer.',
              isSuccess: false,
            );
            break;
          case 'CONNECTION_SUCCESS':
            setState(() {
              isConnected = true;
            });
            break;
          default:
            log('Unknown message type: ${jsonResponse['type']}');
        }
      }
    } catch (e) {
      log('Error processing WebSocket message: $e');
    }
  }

  void showCustomBottomSheet({
    required String title,
    required String message,
    required bool isSuccess,
  }) {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  color: isSuccess ? Colors.green : Colors.red,
                  size: 50,
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSuccess ? Colors.green : Colors.red,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Got it',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Delivery Status'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Text('Online:'),
                const SizedBox(width: 10),
                // Online/Offline toggle switch
                Switch(
                  value: isConnected,
                  onChanged: (value) {
                    if (value) {
                      initializeWebSocketConnection();
                    } else {
                      LendingScreen.channel.sink.close();
                      setState(() {
                        isConnected = false;
                      });
                    }
                  },
                  activeColor: Colors.green,
                  activeTrackColor: Colors.green.withOpacity(0.5),
                  inactiveThumbColor: Colors.red,
                  inactiveTrackColor: Colors.red.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.blue),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage('assets/default_profile.jpg'),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'User ID: ${userId ?? 'Unknown'}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Status: ${isConnected ? 'Online' : 'Offline'}',
                    style: TextStyle(
                      color: isConnected ? Colors.green[100] : Colors.red[100],
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
                setState(() => navigatorIndex = 0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delivery_dining),
              title: const Text('Orders'),
              onTap: () {
                Navigator.pop(context);
                setState(() => navigatorIndex = 1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('History'),
              onTap: () {
                Navigator.pop(context);
                setState(() => navigatorIndex = 2);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                setState(() => navigatorIndex = 3);
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Connection status indicator
          Container(
            color:
                isConnected
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Row(
              children: [
                Icon(
                  isConnected ? Icons.wifi : Icons.wifi_off,
                  color: isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 10),
                Text(
                  isConnected
                      ? 'Connected to server - receiving order updates'
                      : 'Disconnected - reconnecting...',
                  style: TextStyle(
                    color: isConnected ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: Center(child: _getBody())),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(blurRadius: 20, color: Colors.black.withOpacity(.1)),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
            child: GNav(
              rippleColor: Colors.grey[300]!,
              hoverColor: Colors.grey[100]!,
              gap: 8,
              activeColor: Colors.white,
              iconSize: 24,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: Colors.blue,
              color: Colors.black,
              tabs: const [
                GButton(icon: Icons.home, text: 'Home'),
                GButton(icon: Icons.delivery_dining, text: 'Orders'),
                GButton(icon: Icons.history, text: 'History'),
                GButton(icon: Icons.settings, text: 'Settings'),
              ],
              selectedIndex: navigatorIndex,
              onTabChange: (index) {
                setState(() {
                  navigatorIndex = index;
                });
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _getBody() {
    switch (navigatorIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return const Center(child: Text('Orders'));
      case 2:
        return const Center(child: Text('History'));
      case 3:
        return const Center(child: Text('Settings'));
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.delivery_dining, size: 100, color: Colors.blue),
        const SizedBox(height: 20),
        Text(
          'Welcome to Delivery App',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 10),
        Text(
          isConnected
              ? 'You are online and ready to receive orders!'
              : 'You are currently offline. Go online to receive orders.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: isConnected ? Colors.green : Colors.red,
          ),
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: () {
            if (isConnected) {
              LendingScreen.channel.sink.close();
              setState(() {
                isConnected = false;
              });
            } else {
              initializeWebSocketConnection();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isConnected ? Colors.red : Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          ),
          child: Text(isConnected ? 'Go Offline' : 'Go Online'),
        ),
      ],
    );
  }
}
