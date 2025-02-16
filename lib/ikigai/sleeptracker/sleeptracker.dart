import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../home/responsive.dart';

class SleepTrackerPage extends StatefulWidget {
  const SleepTrackerPage({Key? key}) : super(key: key);

  @override
  State<SleepTrackerPage> createState() => _SleepTrackerPageState();
}

class _SleepTrackerPageState extends State<SleepTrackerPage> {
  TimeOfDay? _sleepTime;
  TimeOfDay? _wakeTime;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? userName;
  String? userEmail;

  @override
  void initState() {
    super.initState();
    fetchUser();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Resposnive.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Sleep Tracker",
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white),
        ),
        backgroundColor: Colors.blue[200],
        automaticallyImplyLeading: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Log Sleep Data",
              style: GoogleFonts.poppins(
                  fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            isMobile
                ? Column(
              children: _buildTimeButtons(context),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _buildTimeButtons(context),
            ),
            const SizedBox(height: 16),
            Center(
              child: SizedBox(
                width: double.infinity,
                height: 60.0,
                child: ElevatedButton(
                  style: ButtonStyle(
                      backgroundColor:
                      MaterialStateProperty.all<Color>(Colors.blue[100]!)),
                  onPressed: _addSleepData,
                  child: Text(
                    "Save Sleep Data",
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontSize: 17),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Sleep History",
              style: GoogleFonts.poppins(
                  fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getSleepDataStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return const Center(child: Text("Error fetching data"));
                  }

                  final sleepDocs = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: sleepDocs.length,
                    itemBuilder: (context, index) {
                      final data =
                      sleepDocs[index].data() as Map<String, dynamic>;
                      return ListTile(
                        title: Text(
                          "Date: ${data['date']}",
                          style:
                          GoogleFonts.poppins(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "Duration: ${data['duration']} hours",
                          style:
                          GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Sleep Duration Graph",
              style: GoogleFonts.poppins(
                  fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(child: _buildGraph()),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTimeButtons(BuildContext context) {
    return [
      ElevatedButton(
        onPressed: () async {
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
          );
          if (time != null) {
            setState(() {
              _sleepTime = time;
            });
          }
        },
        child: Text(
          _sleepTime == null
              ? "Select Sleep Time"
              : "Sleep: ${_sleepTime!.format(context)}",
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600, color: Colors.black),
        ),
      ),
      ElevatedButton(
        onPressed: () async {
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
          );
          if (time != null) {
            setState(() {
              _wakeTime = time;
            });
          }
        },
        child: Text(
          _wakeTime == null
              ? "Select Wake Time"
              : "Wake: ${_wakeTime!.format(context)}",
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600, color: Colors.black),
        ),
      ),
    ];
  }

  Future<void> fetchUser() async {
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

  Future<void> _addSleepData() async {
    if (_sleepTime == null || _wakeTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select both times.")),
      );
      return;
    }

    final sleepDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final sleepDuration = _calculateSleepDuration(_sleepTime!, _wakeTime!);

    if (sleepDuration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Wake time must be after sleep time.")),
      );
      return;
    }

    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final sleepDataRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('sleepData')
          .doc();

      await sleepDataRef.set({
        'date': sleepDate,
        'sleepTime': _sleepTime!.format(context),
        'wakeTime': _wakeTime!.format(context),
        'duration': sleepDuration,
        'userName': userName,
        'userEmail': userEmail,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sleep data saved successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving data: $e")),
      );
    }
  }

  Stream<QuerySnapshot> _getSleepDataStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('sleepData')
        .orderBy('date', descending: true)
        .snapshots();
  }

  double _calculateSleepDuration(TimeOfDay sleepTime, TimeOfDay wakeTime) {
    final sleepDateTime = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      sleepTime.hour,
      sleepTime.minute,
    );
    final wakeDateTime = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      wakeTime.hour,
      wakeTime.minute,
    );
    final duration = wakeDateTime.difference(sleepDateTime).inMinutes / 60.0;
    return duration < 0 ? duration + 24 : duration;
  }

  Widget _buildGraph() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getSleepDataStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(child: Text("Error fetching graph data"));
        }

        final sleepDocs = snapshot.data!.docs;
        final graphData = sleepDocs
            .map((doc) =>
        (doc.data() as Map<String, dynamic>)['duration'] as double)
            .toList();

        return LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: true),
            lineBarsData: [
              LineChartBarData(
                isCurved: true,
                color: Colors.blue,
                spots: List.generate(
                  graphData.length,
                      (index) => FlSpot(index.toDouble(), graphData[index]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
