import 'package:first_app/SignUp.dart';
import 'package:first_app/home.dart';
import 'package:flutter/material.dart';
import 'login.dart';
import 'spalch.dart';

void main() => runApp(const MyApp());

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
