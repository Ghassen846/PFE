import 'package:flutter/material.dart';
import 'SignUp.dart';
import 'home.dart';
import 'login.dart';
import 'spalch.dart';
import 'services/AuthService.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Start periodic online status updates when app starts
  AuthService.startPeriodicOnlineUpdates();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gestion de livreurs',
      theme: ThemeData(primarySwatch: Colors.orange),
      initialRoute: '/spalch',
      routes: {
        '/spalch': (context) => const SplashScreen(),
        '/login': (context) => LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}
