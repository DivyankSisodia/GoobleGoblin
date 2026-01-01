import 'package:flutter/material.dart';

import '../home/home_screen.dart';

class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({super.key});

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // Adjust duration as needed
    );

    _slideAnimation = Tween<double>(
      begin: 1.0,  // Start from bottom (off-screen)
      end: 0.0,    // End at center
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();

    // Navigate to home after animation + delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Match your native splash background
      body: AnimatedBuilder(
        animation: _slideAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(
              0,
              MediaQuery.of(context).size.height * _slideAnimation.value,
            ),
            child: Center(
              child: Image.asset(
                'assets/splash_logo.png',
                width: 300, // Adjust size as needed
                height: 300,
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}