import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../services/server_config.dart';
import '../helpers/shared.dart';

class LendingScreen extends StatefulWidget {
  const LendingScreen({Key? key}) : super(key: key);
  static late WebSocketChannel channel;

  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LendingScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isConnected = false;
  String? userId;
  int navigatorIndex = 0;

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
    if (!mounted) return;

    // Close any existing connection and mark offline
    try {
      LendingScreen.channel.sink.close();
    } catch (_) {}
    setState(() => isConnected = false);

    try {
      // Retrieve stored user ID
      final id = await getIdFromSharedPrefs();
      if (id.isEmpty) {
        log(
          'Invalid or missing user ID, cannot establish WebSocket connection',
        );
        return;
      }
      // Build WS URL
      final wsBase = ServerConfig.activeServerUrl
          .replaceFirst('http', 'ws')
          .replaceFirst('/api', '');
      final wsUrl = '$wsBase?userID=$id';
      log('Connecting to WebSocket: $wsUrl');

      LendingScreen.channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      LendingScreen.channel.stream.listen(
        (msg) {
          if (!mounted) return;
          processMessage(msg);
        },
        onError: (err) {
          log('WebSocket Error: $err');
          setState(() => isConnected = false);
          _scheduleReconnection();
        },
        onDone: () {
          log('WebSocket closed');
          setState(() => isConnected = false);
          _scheduleReconnection();
        },
        cancelOnError: false,
      );
      setState(() {
        isConnected = true;
        userId = id;
      });
    } catch (e) {
      log('Error establishing WebSocket connection: $e');
      setState(() => isConnected = false);
      _scheduleReconnection();
    }
  }

  void _scheduleReconnection() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !isConnected) {
        log('Reconnecting WebSocket...');
        initializeWebSocketConnection();
      }
    });
  }

  void processMessage(dynamic message) {
    try {
      log('Received WS message: $message');
      final data = jsonDecode(message) as Map<String, dynamic>;
      switch (data['type']) {
        case 'NEW_ORDER':
          _showCustomBottomSheet(
            title: 'New Order!',
            message: 'You have received a new order.',
            isSuccess: true,
          );
          break;
        case 'ORDER_CANCELED':
          _showCustomBottomSheet(
            title: 'Order Canceled',
            message: 'An order has been canceled.',
            isSuccess: false,
          );
          break;
        case 'CONNECTION_SUCCESS':
          setState(() => isConnected = true);
          break;
      }
    } catch (e) {
      log('Error processing message: $e');
    }
  }

  void _showCustomBottomSheet({
    required String title,
    required String message,
    required bool isSuccess,
  }) {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      builder:
          (_) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: isSuccess ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 10),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSuccess ? Colors.green : Colors.red,
                  ),
                  child: const Text('OK'),
                ),
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
          Row(
            children: [
              const Text('Online:'),
              Switch(
                value: isConnected,
                onChanged: (val) {
                  if (val)
                    initializeWebSocketConnection();
                  else
                    setState(() => isConnected = false);
                },
                activeColor: Colors.green,
                inactiveThumbColor: Colors.red,
              ),
            ],
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
              onTap: () => setState(() => navigatorIndex = 0),
            ),
            ListTile(
              leading: const Icon(Icons.delivery_dining),
              title: const Text('Orders'),
              onTap: () => setState(() => navigatorIndex = 1),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('History'),
              onTap: () => setState(() => navigatorIndex = 2),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () => setState(() => navigatorIndex = 3),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
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
                      ? 'Connected - receiving updates'
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
      bottomNavigationBar: SafeArea(
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
          onTabChange: (idx) => setState(() => navigatorIndex = idx),
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
              setState(() => isConnected = false);
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
