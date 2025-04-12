//import 'package:bzu_leads/components/my_drawer.dart';
import 'package:bzu_leads/pages/chattingGroup_page.dart';
//import 'package:bzu_leads/pages/profile_page.dart';
import 'package:bzu_leads/pages/settingsPage.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PrivatePosts extends StatefulWidget {
  const PrivatePosts({super.key});

  @override
  _PrivatePostsState createState() => _PrivatePostsState();
}

class _PrivatePostsState extends State<PrivatePosts> {
  List<dynamic> posts = [];
String message = "Loading posts...";
  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  Future<void> fetchPosts() async {
    final response = await http.get(Uri.parse('http://localhost/public_html/FlutterGrad/getPrivatePosts.php'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);

      if (jsonResponse["success"] == true) {
        setState(() {
          posts = jsonResponse["data"];
          message = posts.isEmpty ? "No private posts available." : "";
        });
      } else {
        setState(() {
          message = "Error fetching posts.";
        });
      }
    } else {
      setState(() {
        message = "Failed to load posts.";
      });
    }
  }

Future<void> logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear stored session data

    // Navigate to login screen and remove all previous routes
    Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text("Private Posts"),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.green,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
      icon: Icon(Icons.more_vert),
      onSelected: (String value) {
        switch (value) {
          case 'Chatting Groups':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ChattingGroupPage()),
            );
            break;
          case 'Private Posts':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PrivatePosts()),
            );
            break;
          case 'Settings':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => settingsPage()),
            );
            break;
          case 'Logout':
            logout(context);
            break;
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'Chatting Groups',
          child: ListTile(
            leading: Icon(Icons.chat),
            title: Text('Chatting Groups'),
          ),
        ),
        PopupMenuItem<String>(
          value: 'Private Posts',
          child: ListTile(
            leading: Icon(Icons.settings),
            title: Text('Private Posts'),
          ),
        ),
        PopupMenuItem<String>(
          value: 'Settings',
          child: ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
          ),
        ),
        PopupMenuItem<String>(
          value: 'Logout',
          child: ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
          ),
        ),
      ],
    ),
  ], 
      ),
     // drawer:  MyDrawer(),
       body: posts.isEmpty
          ? Center(child: Text(message))
          //? Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: EdgeInsets.all(10),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];

                return Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: EdgeInsets.symmetric(vertical: 10),
                  child: Padding(
                    padding: EdgeInsets.all(15),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile icon or placeholder
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.blueGrey[100],
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        SizedBox(width: 12),

                        // Post details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Username
                              Text(
                                post['username'],
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 5),

                              // Post content
                              Text(
                                post['CONTENT'],
                                style: TextStyle(fontSize: 14, color: Colors.black87),
                              ),
                              SizedBox(height: 10),

                              // Post date
                              Text(
                                "Created on: ${post['DATECREATED']}",
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(width: 10),

                        // Post media (if available)
                        Image.network(
                          "http://localhost/public_html/FlutterGrad/${post['media']}",
                           height: 80,
                           width: 80,
                           fit: BoxFit.cover,
                           errorBuilder: (context, error, stackTrace) {
                           return Icon(Icons.image_not_supported, size: 50, color: Colors.grey);
  },
),

                           
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
