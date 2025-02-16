import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class UserAppointmentsPage extends StatefulWidget {
  const UserAppointmentsPage({Key? key}) : super(key: key);

  @override
  State<UserAppointmentsPage> createState() => _UserAppointmentsPageState();
}

class _UserAppointmentsPageState extends State<UserAppointmentsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> appointments = [];
  String? userEmail;

  @override
  void initState() {
    super.initState();
    fetchUserAppointments();
  }

  Future<void> fetchUserAppointments() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        userEmail = currentUser.email;

        // Fetch appointments
        QuerySnapshot snapshot = await _firestore
            .collection('appointments')
            .where('userEmail', isEqualTo: userEmail)
            .orderBy('time', descending: true)
            .get();

        // Include approved appointments
        QuerySnapshot approvedSnapshot = await _firestore
            .collection('acceptedAppointments')
            .where('userEmail', isEqualTo: userEmail)
            .get();

        setState(() {
          appointments = [
            ...snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>),
            ...approvedSnapshot.docs.map((doc) => {
              ...doc.data() as Map<String, dynamic>,
              'status': 'approved',
              // 'message': 'Appointment approved by the therapist.',
            }),
          ];
        });
      }
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching appointments: $e")),
        );
      });
    }
  }

  Widget buildAppointmentCard(Map<String, dynamic> appointment) {
    final status = appointment['status'] ?? 'unknown';
    final statusColor = {
      'pending': Colors.blueGrey,
      'approved': Colors.blue[200],
      'rejected': Colors.red,
    }[status] ?? Colors.grey;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Therapist: ${appointment['therapistName'] ?? 'N/A'}",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              "Type: ${appointment['therapistType'] ?? 'N/A'}",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            Text(
              "Location: ${appointment['location'] ?? 'N/A'}",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              "Time: ${appointment['time'] ?? 'N/A'}",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              "Status: ${status[0].toUpperCase()}${status.substring(1)}",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),

          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "My Appointments",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[200],
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: appointments.isEmpty
            ? Center(
          child: Text(
            "No appointments found.",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
        )
            : ListView.builder(
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            return buildAppointmentCard(appointments[index]);
          },
        ),
      ),
    );
  }
}
