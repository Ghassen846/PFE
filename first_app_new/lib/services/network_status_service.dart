import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'server_config.dart';

class NetworkStatusService {
  // Singleton pattern
  static final NetworkStatusService _instance =
      NetworkStatusService._internal();
  factory NetworkStatusService() => _instance;
  NetworkStatusService._internal();

  // Stream controllers
  final _statusController = StreamController<bool>.broadcast();
  Stream<bool> get statusStream => _statusController.stream;

  // Connectivity monitoring
  Timer? _connectivityTimer;
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // Server information
  String? _connectedServerUrl;
  String? get connectedServerUrl => _connectedServerUrl;

  // Initialize the service
  Future<void> initialize() async {
    developer.log('Initializing NetworkStatusService', name: 'NetworkStatus');

    // First check current connectivity state
    await _checkConnectivity();

    // Start periodic checks
    _connectivityTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkConnectivity(),
    );

    // Subscribe to connectivity changes
    Connectivity().onConnectivityChanged.listen((_) {
      // When connectivity changes, check server availability
      _checkConnectivity();
    });
  }

  // Check connectivity and server availability
  Future<bool> _checkConnectivity() async {
    try {
      // First check if we have any internet connection
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        _updateStatus(false, null);
        return false;
      }

      // Try each server URL
      final urls = [
        ServerConfig.PRIMARY_SERVER_URL,
        ServerConfig.ALTERNATIVE_URL,
        ServerConfig.EMULATOR_URL,
        ServerConfig.LOCALHOST_URL,
        ServerConfig.LOOPBACK_URL,
      ];

      for (final url in urls) {
        try {
          final response = await http
              .get(Uri.parse('$url/health'))
              .timeout(const Duration(seconds: 2));

          if (response.statusCode >= 200 && response.statusCode < 300) {
            // We found a working server
            _updateStatus(true, url);

            // Save this server URL for future use
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('active_server_url', url);

            return true;
          }
        } catch (e) {
          developer.log('Failed to connect to $url: $e', name: 'NetworkStatus');
          // Continue trying other URLs
        }
      }

      // If we reach here, no server is available
      _updateStatus(false, null);
      return false;
    } catch (e) {
      developer.log('Error checking connectivity: $e', name: 'NetworkStatus');
      _updateStatus(false, null);
      return false;
    }
  }

  // Update connection status
  void _updateStatus(bool isConnected, String? serverUrl) {
    if (_isConnected != isConnected || _connectedServerUrl != serverUrl) {
      _isConnected = isConnected;
      _connectedServerUrl = serverUrl;
      _statusController.add(isConnected);

      developer.log(
        isConnected
            ? 'Connected to server: $serverUrl'
            : 'Disconnected from server',
        name: 'NetworkStatus',
      );
    }
  }

  // Force a connectivity check
  Future<bool> checkNow() async {
    return await _checkConnectivity();
  }

  // Show a network status indicator
  static Widget buildNetworkStatusIndicator() {
    return StreamBuilder<bool>(
      stream: NetworkStatusService().statusStream,
      initialData: NetworkStatusService().isConnected,
      builder: (context, snapshot) {
        final isConnected = snapshot.data ?? false;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color:
                isConnected
                    ? Colors.green.withValues(alpha: 0.2)
                    : Colors.red.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isConnected ? Icons.cloud_done : Icons.cloud_off,
                size: 16,
                color: isConnected ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 4),
              Text(
                isConnected ? 'Online' : 'Offline',
                style: TextStyle(
                  fontSize: 12,
                  color: isConnected ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Clean up resources
  void dispose() {
    _connectivityTimer?.cancel();
    _statusController.close();
  }
}
