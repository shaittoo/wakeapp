import 'package:flutter/material.dart';
import 'package:wakeapp/main.dart';
import 'map_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToMapScreen();
  }

  Future<void> _navigateToMapScreen() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainNavigation()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'lib/assets/splashscreen_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.2,
            left: 0,
            right: 0,
            child: Image.asset(
              'lib/assets/wakeapp_logo.png',
              width: 200,
              height: 200,
            ),
          ),
        ],
      ),
    );
  }
}
