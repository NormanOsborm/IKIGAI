import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart'; // For image picking
import 'dart:io';

import '../../registration/user/registration.dart'; // For file handling

class TherapistProfilePage extends StatefulWidget {
  final String docId;

  const TherapistProfilePage({Key? key, required this.docId}) : super(key: key);

  @override
  State<TherapistProfilePage> createState() => _TherapistProfilePageState();
}

class _TherapistProfilePageState extends State<TherapistProfilePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  String? selectedTherapistType;
  String? selectedLocation;
  File? profileImage;

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

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    try {
      final doc = await _firestore.collection('therapists').doc(widget.docId).get();
      if (doc.exists) {
        final data = doc.data()!;
        nameController.text = data['name'] ?? '';
        emailController.text = data['email'] ?? '';
        phoneController.text = data['phone'] ?? ''; // Ensure phone is fetched
        bioController.text = data['bio'] ?? '';
        selectedTherapistType = data['therapistType'];
        selectedLocation = data['location'];
        setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching profile data: $e")),
      );
    }
  }

  Future<void> _updateProfile() async {
    try {
      final data = {
        'id': widget.docId,
        'name': nameController.text,
        'email': emailController.text,
        'phone': phoneController.text,
        'bio': bioController.text,
        'therapistType': selectedTherapistType,
        'location': selectedLocation,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (profileImage != null) {
        // Add logic to upload the image to Firebase Storage and get the URL
        final imageUrl = await _uploadProfileImage();
        data['profileImage'] = imageUrl;
      }

      await _firestore.collection('therapists').doc(widget.docId).update(data);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating profile: $e")),
      );
    }
  }

  Future<String> _uploadProfileImage() async {
    // Implement Firebase Storage upload logic here
    // Return the uploaded image's URL
    return "https://example.com/image-url"; // Placeholder
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _deleteAccount() async {
    try {
      final therapy = _auth.currentUser;
      if (therapy != null) {
        await _firestore.collection('therapists').doc(widget.docId).delete();
        await therapy.delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account deleted successfully!")),
        );

        Navigator.push(context, MaterialPageRoute(builder: (context)=> const ThApp())); // Navigate back to the login screen
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting account: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile",
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 24)),
        backgroundColor: Colors.blue[200],
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Delete Account"),
                  content: const Text(
                      "Are you sure you want to delete your account? This action cannot be undone."),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Delete"),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                _deleteAccount();
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickProfileImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage:
                      profileImage != null ? FileImage(profileImage!) : null,
                  child: profileImage == null
                      ? const Icon(Icons.camera_alt, size: 50)
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(nameController, 'Name'),
              _buildTextField(emailController, 'Email'),
              _buildTextField(phoneController, 'Phone'),
              _buildTextField(bioController, 'Bio', maxLines: 4),
              DropdownButtonFormField<String>(
                value: selectedTherapistType,
                onChanged: (value) =>
                    setState(() => selectedTherapistType = value),
                items: therapistTypes
                    .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(
                          type,
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        )))
                    .toList(),
                decoration: InputDecoration(
                    labelText: "Therapist Type",
                    border:  OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(width: 0.2),
                    ),
                    labelStyle:
                        GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedLocation,
                onChanged: (value) => setState(() => selectedLocation = value),
                items: locations
                    .map((loc) => DropdownMenuItem(
                        value: loc,
                        child: Text(
                          loc,
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        )))
                    .toList(),
                decoration: InputDecoration(
                  labelText: "Location",
                  labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  border:  OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _updateProfile,
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
                  "Publish",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.blue[500],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey[200],
          hintStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          labelText: label,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
