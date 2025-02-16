import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../login/login.dart';

class Superhome extends StatefulWidget {
  const Superhome({super.key});

  @override
  State<Superhome> createState() => _SuperhomeState();
}

class _SuperhomeState extends State<Superhome> with SingleTickerProviderStateMixin {
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
  }

  Stream<QuerySnapshot> fetchData(String collection) {
    return FirebaseFirestore.instance.collection(collection).snapshots();
  }

  Future<void> deleteUser(String collection, String docId) async {
    try {
      await FirebaseFirestore.instance.collection(collection)
          .doc(docId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deleted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting document: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[200],
      appBar: AppBar(
        backgroundColor: Colors.blue[200],
        automaticallyImplyLeading: false,
        title: Text(
          "IKIGAI",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 32,
          ),
        ),
        bottom: TabBar(
          controller: tabController,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: "Users"),
            Tab(icon: Icon(Icons.verified_user), text: "Therapists"),
          ],
        ),
      ),

      drawer: Drawer(
        backgroundColor: Colors.blue[200],
        child: ListView(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                "HARI" ,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16),
              ),
              accountEmail: Text(
                "Creator And Controller of This Application",
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 12),
              ),
              currentAccountPicture: const CircleAvatar(
                backgroundImage:
                AssetImage("assets/images/Firefly 202412012005043.png"),
                radius: 30.0,
              ),
              decoration: BoxDecoration(color: Colors.blue[200]),
            ),
            ListTile(
              leading: const Icon(
                Icons.logout,
                color: Colors.black,
              ),
              title: Text(
                'BYE SIR',
                style: GoogleFonts.poppins(
                    color: Colors.black, fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          // Users Tab
          buildTabContent("users"),
          // Therapists Tab
          buildTabContent("therapists"),
        ],
      ),
    );
  }

  Widget buildTabContent(String collection) {
    return StreamBuilder<QuerySnapshot>(
      stream: fetchData(collection),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              "No $collection found.",
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
            ),
          );
        }

        final data = snapshot.data!.docs;
        return ListView.builder(
          itemCount: data.length,
          itemBuilder: (context, index) {
            final doc = data[index];
            return GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16)),
                  ),
                  builder: (context) {
                    return buildDetailContainer(collection, doc);
                  },
                );
              },
              child: Card(
                margin: const EdgeInsets.all(8.0),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: ListTile(
                  title: Text(
                    doc['name'] ?? 'No Name',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    doc['email'] ?? 'No Email',
                    style: GoogleFonts.poppins(),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => deleteUser(collection, doc.id),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget buildDetailContainer(String collection, QueryDocumentSnapshot doc) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Details",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 16.0),
            if (collection == 'users') ...[
              buildDetailField("Name", doc['name'] ?? 'No Name'),
              buildDetailField("Email", doc['email'] ?? 'No Email'),
              buildDetailField("Phone", doc['phone'] ?? 'No Phone'),
              buildDetailField(
                  "Created At", formatTimestamp(doc['createdAt'])),
            ] else
              if (collection == 'therapists') ...[
                buildDetailField("Name", doc['name'] ?? 'No Name'),
                buildDetailField("Email", doc['email'] ?? 'No Email'),
                buildDetailField("Phone", doc['phone'] ?? 'No Phone'),
                buildDetailField(
                    "Created At", formatTimestamp(doc['createdAt'])),
                buildDetailField("Bio", doc['bio'] ?? 'No Bio'),
                buildDetailField("Location", doc['location'] ?? 'No Location'),
                buildDetailField(
                    "Therapist Type", doc['therapistType'] ?? 'No Type'),
                buildDetailField(
                    "Updated At", formatTimestamp(doc['updatedAt'])),
              ],
            const SizedBox(height: 16.0),
            Align(
              alignment: Alignment.center,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.delete, color: Colors.white),
                label: const Text("Delete"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context); // Close the bottom sheet
                  deleteUser(collection, doc.id);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDetailField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.blue[900],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  String formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return "${date.day}/${date.month}/${date.year} ${date.hour}:${date
          .minute}";
    }
    return "No Timestamp";
  }
}