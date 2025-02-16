import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FindTherapist extends StatefulWidget {
  const FindTherapist({super.key});

  @override
  State<FindTherapist> createState() => _FindTherapistState();
}

class _FindTherapistState extends State<FindTherapist> {
  String? selectedTimeSlot;
  final List<String> locations = [
    "Thiruvananthapuram",
    "Kollam",
    "Pathanamthitta",
    "Alappuzha",
    "Kottayam",
    "Idukki",
    "Ernakulam",
    "Thrissur",
    "Palakkad",
    "Malappuram",
    "Kozhikode",
    "Wayanad",
    "Kannur",
    "Kasaragod"
  ];

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
  final List<String> timeSlots = [
    "9:00 AM - 11:00 AM",
    "11:30 AM - 1:00 PM",
    "1:30 PM - 3:00 PM",
    "3:30 PM - 5:00 PM"
  ];

  String? selectedLocation;
  String? selectedTherapistType;

  List<Map<String, dynamic>> therapists = [];



  Future<void> fetchTherapists() async {
    try {
      final query = FirebaseFirestore.instance.collection('therapists');
      QuerySnapshot snapshot;

      if (selectedLocation != null && selectedTherapistType != null) {
        snapshot = await query
            .where('location', isEqualTo: selectedLocation)
            .where('therapistType', isEqualTo: selectedTherapistType)
            .get();
      } else {
        return;
      }

      final docs = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Attach the document ID to the data
        return data;
      }).toList();

      setState(() {
        therapists = docs;
      });
    } catch (e) {
      if (ScaffoldMessenger.maybeOf(context) != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching therapists: $e")),
        );
      }
    }
  }

  void showTherapistDetails(Map<String, dynamic> therapist) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(therapist['name'] ?? "Therapist Details",style: GoogleFonts.poppins(fontWeight: FontWeight.bold),),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Name: ${therapist['name']}"),
                Text("Email: ${therapist['email']}"),
                Text("Phone: ${therapist['phone']}"),
                Text("Type: ${therapist['therapistType']}"),
                Text("Location: ${therapist['location']}"),
                const SizedBox(height: 16),
                const Text("Bio:", style: TextStyle(fontWeight: FontWeight.bold)),
                Text(therapist['bio'] ?? "No bio available."),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child:  Text("Close",style: GoogleFonts.poppins(fontWeight: FontWeight.w600),),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                showBookingDialog(therapist);
              },
              child:  Text("Make an Appointment",style: GoogleFonts.poppins(fontWeight: FontWeight.bold),),
            ),
          ],
        );
      },
    );
  }

  void showBookingDialog(Map<String, dynamic> therapist) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Book an Appointment",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Select a convenient time slot:",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              DropdownButtonFormField<String>(
                value: selectedTimeSlot,
                onChanged: (value) {
                  setState(() {
                    selectedTimeSlot = value;
                  });
                },
                items: timeSlots
                    .map((slot) => DropdownMenuItem<String>(
                  value: slot,
                  child: Text(
                    slot,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                ))
                    .toList(),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedTimeSlot == null) {
                  if (ScaffoldMessenger.maybeOf(context) != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please select a time slot.")),
                    );
                  }
                  return;
                }

                try {
                  User? currentUser = FirebaseAuth.instance.currentUser;

                  if (currentUser == null) {
                    throw Exception("User not logged in.");
                  }

                  final userDoc = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(currentUser.uid)
                      .get();

                  if (!userDoc.exists) {
                    throw Exception("User details not found.");
                  }

                  final userData = userDoc.data();

                  if (userData == null) {
                    throw Exception("User data is empty.");
                  }

                  await FirebaseFirestore.instance.collection('appointments').add({
                    'therapistId': therapist['id'],
                    'therapistName': therapist['name'],
                    'therapistEmail': therapist['email'],
                    'time': selectedTimeSlot,
                    'status': 'pending',
                    'location': therapist['location'],
                    'therapistType': therapist['therapistType'],
                    'userName': userData['name'] ?? 'N/A',
                    'userEmail': userData['email'] ?? 'N/A',
                    'userPhone': userData['phone'] ?? 'N/A',
                  });

                  Navigator.pop(context);
                  if (ScaffoldMessenger.maybeOf(this.context) != null) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(content: Text("Appointment request sent successfully!")),
                    );
                  }
                } catch (e) {
                  if (ScaffoldMessenger.maybeOf(this.context) != null) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(content: Text("Error: $e")),
                    );
                  }
                }
              },
              child: Text(
                "Confirm",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Therapist Finder",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 22,
          ),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blue[200],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedLocation,
              hint:  Text("Select Location",style: GoogleFonts.poppins(fontWeight: FontWeight.w600),),
              onChanged: (value) {
                setState(() {
                  selectedLocation = value;
                });
              },
              items: locations
                  .map((loc) => DropdownMenuItem(value: loc, child: Text(loc,style: GoogleFonts.poppins(fontWeight: FontWeight.bold),)))
                  .toList(),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[200],
                hintStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                //: label,
                labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedTherapistType,
              hint:  Text("Select Therapist Type",style: GoogleFonts.poppins(fontWeight: FontWeight.w600),),
              onChanged: (value) {
                setState(() {
                  selectedTherapistType = value;
                });
              },
              items: therapistTypes
                  .map((type) => DropdownMenuItem(value: type, child: Text(type,style: GoogleFonts.poppins(fontWeight: FontWeight.bold),)))
                  .toList(),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[200],
                hintStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                //labelText: label,
                labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: fetchTherapists,
              child:  Text("Find Therapists" ,style: GoogleFonts.poppins(fontWeight: FontWeight.bold),),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: therapists.isEmpty
                  ? const Center(child: Text("No therapists found"))
                  : ListView.builder(
                itemCount: therapists.length,
                itemBuilder: (context, index) {
                  final therapist = therapists[index];
                  return Card(
                    child: ListTile(
                      title: Text(therapist['name'] ?? "Therapist Name",style: GoogleFonts.poppins(fontWeight: FontWeight.bold),),
                      subtitle: Text(
                          "${therapist['therapistType']} - ${therapist['location']}",style: GoogleFonts.poppins(fontWeight: FontWeight.w600),),
                      onTap: () {
                        showTherapistDetails(therapist);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}