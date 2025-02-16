import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class AcceptedAppointmentsPage extends StatefulWidget {
  const AcceptedAppointmentsPage({Key? key}) : super(key: key);

  @override
  State<AcceptedAppointmentsPage> createState() => _AcceptedAppointmentsPageState();
}

class _AcceptedAppointmentsPageState extends State<AcceptedAppointmentsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? therapistEmail;
  String? therapistName;

  @override
  void initState() {
    super.initState();
    fetchTherapistDetails();
  }

  Future<void> fetchTherapistDetails() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        QuerySnapshot userSnapshot = await _firestore
            .collection('therapists')
            .where('email', isEqualTo: currentUser.email)
            .get();

        if (userSnapshot.docs.isNotEmpty) {
          final userDoc = userSnapshot.docs.first;
          setState(() {
            therapistEmail = userDoc['email'];
            therapistName = userDoc['name'];
          });
        }
      }
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching therapist details: $e')),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Accepted Appointments",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[200],
        automaticallyImplyLeading: false,
      ),
      body: therapistEmail == null || therapistName == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('acceptedAppointments')
            .where('therapistEmail', isEqualTo: therapistEmail)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "No accepted appointments.",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            );
          }

          final appointments = snapshot.data!.docs;

          return ListView.builder(
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointmentData = appointments[index].data() as Map<String, dynamic>;

              return Card(
                child: ListTile(
                  title: Text(
                    "Time: ${appointmentData['time'] ?? 'N/A'}",
                    style: GoogleFonts.poppins(fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("User Name: ${appointmentData['userName'] ?? 'N/A'}"),
                      Text("User Email: ${appointmentData['userEmail'] ?? 'N/A'}"),
                      Text("User Phone: ${appointmentData['userPhone'] ?? 'N/A'}"),
                      Text("Location: ${appointmentData['location'] ?? 'N/A'}"),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
