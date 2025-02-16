import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ikigai_flutter/ikigai/superadmin/superhome.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import 'package:ikigai_flutter/ikigai/registration/user/registration.dart';
import 'dart:math';

import '../main.dart';
import 'home/therapist/therapistHome.dart';
import 'home/userhome/userhomepage.dart';
import 'login/login.dart';



class IkigaiApp extends StatelessWidget {
  const IkigaiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 7),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.6, curve: Curves.easeIn),
      ),
    );

    _controller.repeat();
    _navigateToHome();
  }

  void _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 7)); // Keep the delay for animation

    final user = FirebaseAuth.instance.currentUser; // Get currently logged-in user

    if (user != null) {
      // User is already logged in, navigate to the appropriate home screen
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userType = prefs.getString('userType');

      if (userType == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) =>  Superhome()),
        );
      } else if (userType == 'user') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) =>  Userhomepage()),
        );
      } else if (userType == 'therapist') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Therapisthome()),
        );
      } else {
        // Default to login if userType is unknown
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      }
    } else {
      // No user logged in, navigate to login page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[100],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _controller.value * 4 * pi,
                  child: child,
                );
              },
              child: Image.asset(
                'asset/image/yin yang.png',
                height: 100,
                width: 100,
              ),
            ),
            const SizedBox(height: 20),
            // Animated Title
            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                'IKIGAI',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2.0,
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Subtitle
            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                'FEEL THE LIFE',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  letterSpacing: 3.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
