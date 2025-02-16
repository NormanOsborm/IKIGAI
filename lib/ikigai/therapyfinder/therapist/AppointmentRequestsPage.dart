import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class AppointmentRequestsPage extends StatefulWidget {
  const AppointmentRequestsPage({Key? key}) : super(key: key);

  @override
  State<AppointmentRequestsPage> createState() =>
      _AppointmentRequestsPageState();
}

class _AppointmentRequestsPageState extends State<AppointmentRequestsPage> {
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

  Future<void> _updateAppointmentStatus(String appointmentId, String status) async {
    try {
      // Prompt the doctor to select a specific time
      String? selectedTime;
      if (status == 'Accepted') {
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Select a Specific Time", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              content: TextField(
                decoration: const InputDecoration(
                  hintText: "Enter time within user's slot",
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  selectedTime = value;
                },
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Confirm", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                ),
              ],
            );
          },
        );
      }

      // Update appointment status
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': status,
        'selectedTime': selectedTime,
      });

      if (status == 'Accepted') {
        DocumentSnapshot appointmentDoc = await _firestore.collection('appointments').doc(appointmentId).get();
        final appointmentData = appointmentDoc.data() as Map<String, dynamic>;

        await _firestore.collection('acceptedAppointments').doc(appointmentId).set({
          'therapistEmail': therapistEmail,
          'therapistName': therapistName,
          'time': selectedTime,
          'userName': appointmentData['userName'],
          'userEmail': appointmentData['userEmail'],
          'userPhone': appointmentData['userPhone'],
          'location': appointmentData['location'],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Appointment marked as $status.')),
        );
      });
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Appointment Requests",
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
            .collection('appointments')
            .where('therapistEmail', isEqualTo: therapistEmail)
            .where('status', isEqualTo: 'pending')
            .orderBy('time') // Ensure sorting
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "No pending appointment requests.",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            );
          }

          final appointments = snapshot.data!.docs;

          return ListView.builder(
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointmentData =
              appointments[index].data() as Map<String, dynamic>;
              final appointmentId = appointments[index].id;

              return Card(
                child: ListTile(
                  title: Text(
                    "Time: ${appointmentData['time']}",
                    style: GoogleFonts.poppins(fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("User Name: ${appointmentData['userName'] ?? 'N/A'}"),
                      Text("User Email: ${appointmentData['userEmail'] ?? 'N/A'}"),
                      Text("User Phone: ${appointmentData['userPhone'] ?? 'N/A'}"),
                      Text("Time Slot: ${appointmentData['time'] ?? 'N/A'}"),
                      Text("Location: ${appointmentData['location'] ?? 'N/A'}"),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () {
                          _updateAppointmentStatus(appointmentId, 'Accepted');
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          _updateAppointmentStatus(appointmentId, 'Declined');
                        },
                      ),
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
