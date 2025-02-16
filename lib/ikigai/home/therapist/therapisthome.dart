import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../communityforum/home.dart';
import '../../login/login.dart';
import '../../therapyfinder/therapist/AppointmentRequestsPage.dart';
import '../../therapyfinder/therapist/confirmedAppointments.dart';
import '../../therapyfinder/therapist/profile.dart';
import '../responsive.dart';

class Therapisthome extends StatefulWidget {
  const Therapisthome({super.key});

  @override
  State<Therapisthome> createState() => _TherapisthomeState();
}

class _TherapisthomeState extends State<Therapisthome> {
  int _currentIndex = 0;

  String? therapistName;
  String? therapistEmail;
  String? therapistType;
  String? therapistDocId;

  List<Widget> _pages = []; // Initialize with an empty list

  @override
  void initState() {
    super.initState();
    fetchTherapistDetails();
  }

  Future<void> fetchTherapistDetails() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        QuerySnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('therapists')
            .where('email', isEqualTo: currentUser.email)
            .get();

        if (userSnapshot.docs.isNotEmpty) {
          final userDoc = userSnapshot.docs.first;
          setState(() {
            therapistName = userDoc['name'];
            therapistEmail = userDoc['email'];
            therapistType = userDoc['therapistType'];
            therapistDocId = userDoc.id;
          });

          // Initialize pages after fetching the docId
          _initializePages();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching therapist details: $e')),
      );
    }
  }

  void _initializePages() {
    _pages = [
      CommunityHomePage(),
      const AppointmentRequestsPage(),
      const AcceptedAppointmentsPage(),
      TherapistProfilePage(docId: therapistDocId!),
    ];
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "IKIGAI",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 32,
          ),
        ),
        backgroundColor: Colors.blue[200],
      ),
      drawer: Resposnive.isWeb(context) ? null : _buildDrawer(),
      body: Row(
        children: [
          if (Resposnive.isWeb(context)) ...[
            Expanded(flex: 2, child: _buildDrawerContent()),
          ],
          Expanded(flex: 5, child: _pages.isEmpty ? const Center(child: CircularProgressIndicator()) : _pages[_currentIndex]),
          if (Resposnive.isWeb(context)) ...[
            Expanded(flex: 3, child: _buildExtraContent()),
          ],
        ],
      ),
      bottomNavigationBar: Resposnive.isWeb(context)
          ? BottomNavigationBar( currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.shifting,
        backgroundColor: Colors.blue[100],

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Community",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: "Add Patient",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task_alt),
            label: "Appointments",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      )
          : BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.blue[200],

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Community",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: "Add Patient",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task_alt),
            label: "Appointments",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.blue[200],
      child: _buildDrawerContent(),
    );
  }

  Widget _buildDrawerContent() {
    return ListView(
      children: [
        UserAccountsDrawerHeader(
          accountName: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                therapistName ?? "Fetching the name...",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                therapistType ?? "Fetching the position...",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          accountEmail: Text(
            therapistEmail ?? "Fetching the email...",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 12,
            ),
          ),
          decoration: BoxDecoration(
            color: Colors.blue[200],
            backgroundBlendMode: BlendMode.multiply,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.info, color: Colors.white),
          title: Text(
            "About",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.white),
          title: Text(
            'Logout',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          onTap: () async {
            // Clear user type from SharedPreferences
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.remove('userType'); // Remove stored user type

            // Sign out from Firebase
            await FirebaseAuth.instance.signOut();

            // Navigate back to Login Page
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildExtraContent() {
    return Container(
      color: Colors.blue[100],
      child: Center(
        child: Text(
          "Extra Content",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
    );
  }
}