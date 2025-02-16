import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ikigai_flutter/ikigai/registration/user/registration.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../home/therapist/therapistHome.dart';
import '../home/userhome/userhomepage.dart';
import '../superadmin/superhome.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  // Super admin credentials
  static const adminEmail = 'sreeharisujaraj@admin.com';
  static const adminPassword = 'jabbar2424';


  void _loginUser() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      if (email == adminEmail && password == adminPassword) {
        await prefs.setString('userType', 'admin'); // Store user type
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Superhome()),
        );
        return;
      }

      // Firebase authentication
      final UserCredential userCredential =
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Firestore user check
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (userDoc.docs.isNotEmpty) {
        await prefs.setString('userType', 'user'); // Store user type
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Userhomepage()),
        );
        return;
      }

      final therapistDoc = await FirebaseFirestore.instance
          .collection('therapists')
          .where('email', isEqualTo: email)
          .get();

      if (therapistDoc.docs.isNotEmpty) {
        await prefs.setString('userType', 'therapist'); // Store user type
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Therapisthome()),
        );
        return;
      }

      // Exception if user type is not found
      throw Exception('User type not found in database.');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login failed: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[100],
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth > 600 ? 400 : double.infinity,
                ),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue[200],
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Login',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(emailController, 'Email'),
                      _buildTextField(
                        passwordController,
                        'Password',
                        obscureText: !_isPasswordVisible,
                        isPassword: true,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _loginUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[100],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 50,
                            vertical: 15,
                          ),
                        ),
                        child: Text(
                          'Login',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.blue[500],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ThApp(),
                            ),
                          );
                        },
                        child: Text(
                          "Not A User -- Go and Register",
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.white),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool obscureText = false, bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey[300],
          labelText: label,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
              obscureText ? Icons.visibility_off : Icons.visibility,color: Colors.black38,
            ),
            onPressed: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
          )
              : null,
        ),
      ),
    );
  }
}
