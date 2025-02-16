import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../login/login.dart';

class ThApp extends StatelessWidget {
  const ThApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/register',
      routes: {
        '/register': (context) => const RegistrationPage(),
        '/login': (context) => const LoginPage(),
      },
    );
  }
}

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String userType = 'User';
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
  TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  String? selectedTherapistType;
  bool isLoading = false;

  final List<String> therapistTypes = [
    'Psychologist',
    'Psychiatrist',
    'Counselor',
    'Therapist',
    'Psychotherapist',
    'Occupational Therapist',
    'Music Therapist',
    'Marriage and Family Therapist',
    'Child Psychologist',
    'Neuropsychologist',
    'others'
  ];

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> registerUser() async {
    if (!validateInputs()) return;

    setState(() {
      isLoading = true;
    });

    try {
      final UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = userCredential.user;
      if (user != null) {
        final data = {
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'phone': phoneController.text.trim(),
          'userType': userType,
          'position': 'Member',
          'createdAt': FieldValue.serverTimestamp(),
        };

        if (userType == 'Therapist') {
          data['therapistType'] = selectedTherapistType!;
          await _firestore.collection('therapists').doc(user.uid).set(data);
        } else {
          await _firestore.collection('users').doc(user.uid).set(data);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful!')),
        );

        Navigator.push(
            context, MaterialPageRoute(builder: (context) => const LoginPage()));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  bool validateInputs() {
    if (nameController.text.trim().isEmpty) {
      showError('Name cannot be empty');
      return false;
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(emailController.text.trim())) {
      showError('Enter a valid email');
      return false;
    }
    if (!RegExp(r'^[0-9]{10}$').hasMatch(phoneController.text.trim()))
      {
      showError('Enter a valid 10-digit phone number');
      return false;
    }
    if (passwordController.text.trim().length < 6) {
      showError('Password must be at least 6 characters');
      return false;
    }
    if (passwordController.text.trim() !=
        confirmPasswordController.text.trim()) {
      showError('Passwords do not match');
      return false;
    }
    if (userType == 'Therapist' &&
        (selectedTherapistType == null || selectedTherapistType!.isEmpty)) {
      showError('Please select a therapist type');
      return false;
    }
    return true;
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
                  maxWidth: constraints.maxWidth > 600 ? 400 : constraints.maxWidth * 0.9,
                ),
                child: Container(
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
                        'Register',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildRadioButton('User'),
                          const SizedBox(width: 20),
                          _buildRadioButton('Therapist'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      userType == 'User' ? _buildUserForm() : _buildTherapistForm(),
                      const SizedBox(height: 20),
                      isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                        onPressed: registerUser,
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
                          'Register',
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
                                  builder: (context) => const LoginPage()));
                        },
                        child: Text(
                          'Already a User then LOGIN!',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
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

  Widget _buildUserForm() {
    return Column(
      children: [
        _buildTextField(nameController, 'Name'),
        _buildTextField(emailController, 'Email'),
        _buildTextField(phoneController, 'Phone Number'),
        _buildTextField(passwordController, 'Password', obscureText: true),
        _buildTextField(confirmPasswordController, 'Confirm Password',
            obscureText: true),
      ],
    );
  }

  Widget _buildTherapistForm() {
    return Column(
      children: [
        _buildTextField(nameController, 'Name'),
        _buildTextField(emailController, 'Email'),
        _buildTextField(phoneController, 'Phone Number'),
        _buildTextField(passwordController, 'Password', obscureText: true),
        _buildTextField(confirmPasswordController, 'Confirm Password',
            obscureText: true),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: selectedTherapistType,
          onChanged: (value) {
            setState(() {
              selectedTherapistType = value;
            });
          },
          items: therapistTypes
              .map((type) => DropdownMenuItem(
            value: type,
            child: Text(
              type,
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ))
              .toList(),
          decoration: InputDecoration(
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            filled: true,
            fillColor: Colors.grey[300],
            hintText: "Type of Therapist",
            hintStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool obscureText = false}) {
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
        ),
        autofillHints: const [AutofillHints.email],
      ),
    );
  }

  Widget _buildRadioButton(String value) {
    return Row(
      children: [
        Radio<String>(
          value: value,
          groupValue: userType,
          onChanged: (selectedValue) {
            setState(() {
              userType = selectedValue!;
            });
          },
          activeColor: Colors.teal,
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
