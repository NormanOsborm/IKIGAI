import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ikigai_flutter/ikigai/communityforum/profileC.dart';
import 'addapost.dart';

class CommunityHomePage extends StatefulWidget {
  @override
  _CommunityHomePageState createState() => _CommunityHomePageState();
}

class _CommunityHomePageState extends State<CommunityHomePage>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<String> _savedPosts = [];
  final Map<String, bool> _likedPosts = {};

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          "Community Forum",
          style: GoogleFonts.poppins(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue[200],
        bottom: TabBar(
          controller: _tabController,
          labelStyle: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.bold),
          // indicatorColor: Colors.white,
          tabs: const [
            Tab(
              icon: Icon(Icons.home),
              text: "Home",
            ),
            Tab(icon: Icon(Icons.bookmark), text: "Saved"),
            Tab(icon: Icon(Icons.add), text: "Add Post"),
            Tab(icon: Icon(Icons.person), text: "Profile")
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHomePage(),
          _buildSavedPostsPage(),
          AddPostPage(),
          const ProfilePage()
        ],
      ),
    );
  }

  Widget _buildHomePage() {
    return StreamBuilder(
      stream: _firestore
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final posts = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            final postId = post.id;

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 100,
                    child: SingleChildScrollView(
                      child: Text(
                        post['content'],
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Posted by: ${post['userId']}",
                        style: GoogleFonts.poppins(
                            color: Colors.black, fontSize: 10),
                      ),
                      const SizedBox(height: 5,),
                      Text(
                        post['timestamp'] != null
                            ? (post['timestamp'] as Timestamp)
                                .toDate()
                                .toString()
                                .substring(0, 16)
                            : "Just now",
                        style: GoogleFonts.poppins(color: Colors.black,fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.favorite,
                          color: _likedPosts[postId] == true
                              ? Colors.red
                              : Colors.black,
                        ),
                        onPressed: () {
                          setState(() {
                            _likedPosts[postId] =
                                !(_likedPosts[postId] ?? false);
                          });
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          _savedPosts.contains(postId)
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          color: Colors.black,
                        ),
                        onPressed: () {
                          setState(() {
                            if (_savedPosts.contains(postId)) {
                              _savedPosts.remove(postId);
                            } else {
                              _savedPosts.add(postId);
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSavedPostsPage() {
    return StreamBuilder(
      stream: _firestore.collection('posts').snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final posts = snapshot.data!.docs
            .where((post) => _savedPosts.contains(post.id))
            .toList();

        if (posts.isEmpty) {
          return Center(
              child: Text(
            "No saved posts yet.",
            style: GoogleFonts.poppins(fontWeight: FontWeight.normal),
          ));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueGrey.withOpacity(0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 100,
                    child: SingleChildScrollView(
                      child: Text(
                        post['content'],
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Posted by: ${post['userId']}",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
