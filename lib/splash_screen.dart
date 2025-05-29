import 'package:flutter/material.dart';
import 'main.dart';

class SplashScreen extends StatefulWidget {
  static const routeName = '/splash';
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushNamedAndRemoveUntil(
        context, 
        DomflixHomePage.routeName,
        (route) => false,  // Rimuove tutte le rotte precedenti
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final logoHeight = screenWidth < 400 ? 80.0 : (screenWidth < 600 ? 120.0 : 160.0);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Image.asset(
          'assets/domflix_logo_nobg.png',
          height: logoHeight,
        ),
      ),
    );
  }
}