import 'package:bzu_leads/pages/profile_page.dart';
import 'package:bzu_leads/pages/settingsPage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Officialnotification extends StatefulWidget {
  const Officialnotification({super.key});

  @override
  _Officialnotification createState() => _Officialnotification();
}
class _Officialnotification extends State<Officialnotification> {
  int _selectedIndex =
      0; // Variable to track the selected item in the bottom navigation bar
  List posts = []; // List to hold the pending posts fetched from the server

  @override
  void initState() {
    super.initState();
    fetchPendingPosts(); // Fetch the pending posts when the screen is initialized
  }

  // Function to handle bottom navigation item selection
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Update the selected index
    });
  }

  // Function to fetch pending posts from the server
  Future<void> fetchPendingPosts() async {
    final response = await http.get(
      Uri.parse(
        'http://localhost/public_html/FlutterGrad/get_pending_posts.php',
      ),
    );

    // Check if the request was successful
    if (response.statusCode == 200) {
      setState(() {
        posts = json.decode(response.body); // Decode and store the posts
      });
    }
  }

  // Function to approve a post
  Future<void> approvePost(String postID, String approverID) async {
    final response = await http.post(
      Uri.parse(' http://localhost/public_html/FlutterGrad/approve.php'),

      body: {
        'postID': postID, // Pass postID and approverID as parameters
        'approverID': approverID,
      },
    );

    // If the response is successful, fetch the updated posts
    if (json.decode(response.body)['success']) {
      fetchPendingPosts();
    }
  }

  // Function to reject a post
  Future<void> rejectPost(String postID) async {
    final response = await http.post(
      Uri.parse('http://localhost/public_html/FlutterGrad/reject.php'),
      body: {'postID': postID}, // Pass the postID to reject
    );

    // If the response is successful, fetch the updated posts
    if (json.decode(response.body)['success']) {
      fetchPendingPosts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Theme.of(
            context,
          ).colorScheme.surface, // Set the background color based on the theme
      appBar: AppBar(
        title: Text("Officials' Public Posts"), // Title for the AppBar
        backgroundColor:
            Colors.transparent, // Transparent background for AppBar
        foregroundColor: Colors.green, // Set the text color in the AppBar
        elevation: 0, // No elevation for the AppBar
        actions: [
          // Settings button to navigate to the settings page
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => settingsPage()),
              );
            },
          ),
          // Profile button to navigate to the profile page
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              String? userID = prefs.getString("universityID");

              // If a user ID exists, navigate to the profile page
              if (userID != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()),
                );
              } else {
                // Show a snack bar if user ID is not found
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("User ID not found. Please log in again."),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body:
          posts.isEmpty
              ? Center(
                child: CircularProgressIndicator(),
              ) // Show a loading spinner if posts are empty
              : ListView.builder(
                itemCount: posts.length, // Number of posts to display
                itemBuilder: (context, index) {
                  final post =
                      posts[index]; // Get each post from the posts list
                  return NotificationCard(
                    title: post['posttitle'] ?? '', // Display the post title
                    content: post['CONTENT'] ?? '', // Display the post content
                    creatorID:
                        post['POSTCREATORID'] ?? '', // Display the creator ID
                    postID: post['POSTID'] ?? '', // Display the post ID
                    onApprove: () async {
                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      String? approverID = prefs.getString("universityID");
                      if (approverID != null) {
                        await approvePost(
                          post['POSTID'],
                          approverID,
                        ); // Approve the post
                      }
                    },
                    onReject: () async {
                      await rejectPost(post['POSTID']); // Reject the post
                    },
                  );
                },
              ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex, // Tracks the currently selected item
        onTap: _onItemTapped, // Call this function when an item is tapped
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: "Explore"),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: "Messaging",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

// NotificationCard widget to display a single notification
class NotificationCard extends StatelessWidget {
  final String title;
  final String content;
  final String creatorID;
  final String postID;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const NotificationCard({
    super.key,
    required this.title,
    required this.content,
    required this.creatorID,
    required this.postID,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ), // Margin for the card
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ), // Rounded corners for the card
      child: Padding(
        padding: const EdgeInsets.all(16.0), // Padding inside the card
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start, // Align children to the left
          children: [
            Row(
              mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween, // Space between title and icon
              children: [
                Text(
                  "$creatorID",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ), // Creator ID
                Icon(
                  Icons.public,
                  color: Colors.green,
                ), // Icon for public posts
              ],
            ),
            SizedBox(height: 4),
            Text(
              "Title: $title",
              style: TextStyle(fontSize: 16),
            ), // Display post title
            SizedBox(height: 4),
            Text(
              content,
              style: TextStyle(color: Colors.grey[700]),
            ), // Display post content
            SizedBox(height: 10),
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.end, // Align buttons to the right
              children: [
                ElevatedButton(
                  onPressed:
                      onApprove, // Call the approve function when pressed
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[200],
                  ), // Green background for approve button
                  child: Text(
                    "Approve",
                    style: TextStyle(color: Colors.black),
                  ), // Button text
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onReject, // Call the reject function when pressed
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ), // Red background for reject button
                  child: Text(
                    "Reject",
                    style: TextStyle(color: Colors.white),
                  ), // Button text
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
