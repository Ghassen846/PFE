import 'package:first_app_new/screens/History.dart';
import 'package:first_app_new/screens/HomeScreen.dart';
import 'package:first_app_new/screens/chat_screen.dart';
import 'package:first_app_new/screens/notification_screen.dart';
import 'package:first_app_new/screens/debug_screen.dart';
import 'package:first_app_new/screens/testing_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'screens/SignUp.dart';
import 'screens/login.dart';
import 'screens/spalch.dart';
import 'screens/order_screen.dart';
import 'screens/lending.dart';
import 'screens/ProfileEditScreen.dart';
import 'helpers/responsive/sizer_util.dart';
import 'helpers/bloc/home_bloc.dart';
import 'generated/app_localizations.dart';
import 'helpers/shared.dart';
import 'services/server_config.dart';

// For storing SharedPreferences instance globally
late SharedPreferences prefs;

Future<void> _initializeNetworking() async {
  try {
    // Check connectivity before initializing
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      log('No internet connection during initialization');
      return;
    }

    // Initialize ServerConfig first
    await ServerConfig.initialize();
    log('Selected server IP: ${ServerConfig.SERVER_IP}');

    // Initialize ApiService if needed
    log('Server URL: ${ServerConfig.activeServerUrl}');

    // Test connection to server
    try {
      final testResult = await http
          .get(Uri.parse('${ServerConfig.activeServerUrl}/health'))
          .timeout(const Duration(seconds: 5));

      log(
        'Server connection test: ${testResult.statusCode == 200 ? "Success" : "Failed"}',
      );
    } catch (e) {
      log('Server connection test failed: $e');
    }
  } catch (e) {
    log('Network initialization error: $e', stackTrace: StackTrace.current);
  }
}

Future<void> _clearStorage() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    final secureStorage = FlutterSecureStorage();
    await secureStorage.deleteAll();
    log('Storage cleared successfully');
  } catch (e) {
    log('Error clearing storage: $e', stackTrace: StackTrace.current);
  }
}

Future<void> _initializeApp() async {
  try {
    // Initialize SharedPreferences first, before anything else
    prefs = await SharedPreferences.getInstance();
    log("SharedPreferences initialized successfully");

    // Also initialize shared preferences in the helper module
    await initPrefs();
  } catch (e) {
    log("Error initializing SharedPreferences: $e");
    rethrow;
  }
}

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize SharedPreferences and other core services first
    await _initializeApp();

    // Load .env file (optional)
    try {
      await dotenv.load(fileName: ".env");
      log("Loaded .env file successfully");
    } catch (e) {
      log("Error loading .env file: $e");
    }

    // Clear stale session data
    await _clearStorage();

    // Initialize networking
    await _initializeNetworking();

    // Check if there's a logged in user
    try {
      // Check for token in secure storage
      final secureStorage = FlutterSecureStorage();
      final token = await secureStorage.read(key: 'token');
      if (token != null) {
        log("Found logged-in user");
      } else {
        log("No logged-in user found");
      }
    } catch (e) {
      log("Error checking login status: $e");
    }

    runApp(const MyApp());
  } catch (e) {
    log("Fatal error during app initialization: $e");
    // You may want to show an error screen here instead of crashing
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Failed to initialize app. Please restart.'),
          ),
        ),
      ),
    );
  }
}

// Add this class before the MyApp class
class MainAppWithFooter extends StatefulWidget {
  final int initialIndex;
  final int notificationCount;

  const MainAppWithFooter({
    super.key,
    this.initialIndex = 0,
    this.notificationCount = 0,
  });

  @override
  State<MainAppWithFooter> createState() => _MainAppWithFooterState();
}

class _MainAppWithFooterState extends State<MainAppWithFooter> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const HomeScreen(),
    const OrderScreen(),
    const NotificationScreen(),
    const HistoryScreen(),
    const ChatScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.orange,
          unselectedItemColor: Colors.grey,
          currentIndex: _currentIndex,
          elevation: 20,
          selectedFontSize: 12,
          unselectedFontSize: 10,
          showUnselectedLabels: true,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_outlined),
              activeIcon: Icon(Icons.receipt),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_outlined),
              activeIcon: Icon(Icons.notifications),
              label: 'Notifications',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Chat',
            ),
          ],
        ),
      ),
    );
  }
}

// Global key for navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Main App Widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => HomeBloc()..add(HomeInitialEvent())),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'), // English
          Locale('ar'), // Arabic
          Locale('fr'), // French
        ],
        title: 'Gestion de livreurs',
        theme: ThemeData(primarySwatch: Colors.orange),
        initialRoute: '/spalch',
        builder: (context, child) {
          SizerUtil.init(context);
          return child ?? const SizedBox.shrink();
        },
        routes: {
          '/spalch': (context) => const SplashScreen(),
          '/login': (context) => const LoginPage(),
          '/signup': (context) => const SignUpPage(),
          '/home': (context) => const MainAppWithFooter(initialIndex: 0),
          '/order': (context) => const MainAppWithFooter(initialIndex: 1),
          '/notification':
              (context) => const MainAppWithFooter(initialIndex: 2),
          '/history': (context) => const MainAppWithFooter(initialIndex: 3),
          '/chat-home': (context) => const MainAppWithFooter(initialIndex: 4),

          '/debug': (context) => const DebugScreen(),
          '/lending': (context) => const LendingScreen(),
          '/editProfile': (context) => const ProfileEditScreen(),
          '/profile': (context) {
            final args =
                ModalRoute.of(context)?.settings.arguments
                    as Map<String, dynamic>?;
            return ProfileEditScreen(initialData: args);
          },
          '/testing': (context) => const TestScreen(),
          '/chat': (context) => const ChatScreen(),

          // Fallback if no args provided
        },
      ),
    );
  }
}
