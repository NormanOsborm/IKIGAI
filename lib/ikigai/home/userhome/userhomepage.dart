import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ikigai_flutter/ikigai/home/userhome/userProfile.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../communityforum/home.dart';
import '../../login/login.dart';
import '../../sleeptracker/sleeptracker.dart';
import '../../therapyfinder/user/appointmentconfirmation.dart';
import '../../therapyfinder/user/findTherapist.dart';
import '../responsive.dart';

class Userhomepage extends StatefulWidget {
  const Userhomepage({super.key});

  @override
  State<Userhomepage> createState() => _UserhomepageState();
}

class _UserhomepageState extends State<Userhomepage> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    CommunityHomePage(),
    const FindTherapist(),
    const UserAppointmentsPage(),
    const UserProfile(),
  ];

  String? userName;
  String? userEmail;

  @override
  void initState() {
    super.initState();
    fetchUserDetails();
  }

  Future<void> fetchUserDetails() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        QuerySnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: currentUser.email)
            .get();

        if (userSnapshot.docs.isNotEmpty) {
          setState(() {
            userName = userSnapshot.docs.first['name'];
            userEmail = userSnapshot.docs.first['email'];
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching user details: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Resposnive.isMobile(context);
    final isWeb = Resposnive.isWeb(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[200],
        title: Text(
          "IKIGAI",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 20 : 30,
          ),
        ),
        actions: [
          if (isMobile)
            IconButton(
              icon: const Icon(Icons.nightlight),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SleepTrackerPage()),
                );
              },
            ),
        ],
      ),
      drawer: isWeb ? null : buildDrawer(context),
      body: Row(
        children: [
          if (isWeb) Expanded(flex: 2, child: buildDrawer(context)),
          Expanded(flex: 5, child: _pages[_currentIndex]),
          if (isWeb)
            Expanded(
              flex: 3,
              child:
                  const SleepTrackerPage(), // Show SleepTrackerPage in the right pane
            ),
        ],
      ),
      bottomNavigationBar: isWeb
          ? BottomNavigationBar(
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
                  label: "Add Therapist",
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
              backgroundColor: Colors.blue[100],
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: "Community",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.add),
                  label: "Add Therapist",
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

  Widget buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.blue[100],
      child: ListView(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
              userName ?? "Fetching name...",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            accountEmail: Text(
              userEmail ?? "Fetching email...",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            decoration: BoxDecoration(
              color: Colors.blue[200],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.nightlight, color: Colors.white),
            title: Text(
              "Sleep Tracker",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SleepTrackerPage()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.info, color: Colors.white),
            title: Text(
              "About",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.white,
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
      ),
    );
  }
}
