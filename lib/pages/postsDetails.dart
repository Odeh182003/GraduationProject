import 'package:bzu_leads/pages/profile_page.dart';
import 'package:bzu_leads/pages/settingsPage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class Postsdetails extends StatefulWidget {
  final int postID;

  const Postsdetails({super.key, required this.postID});

  @override
  _PostsdetailsState createState() => _PostsdetailsState();
}

class _PostsdetailsState extends State<Postsdetails> {
  Map<String, dynamic>? post;

  @override
  void initState() {
    super.initState();
    fetchPostById();
  }

  Future<void> fetchPostById() async {
    final response = await http.get(Uri.parse('http://localhost/public_html/FlutterGrad/postsDetails.php?postID=${widget.postID}'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data.containsKey('post')) {
        setState(() {
          post = data['post'];
        });
      } else {
        print('Error: ${data["error"]}');
      }
    } else {
      print('Failed to load post details');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text("Public Posts"),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.green,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              // Navigate to the Settings page
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => settingsPage()),
              );
            },
          ),
          IconButton(
      icon: Icon(Icons.person),
      onPressed: () async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? userID = prefs.getString("universityID");

        if (userID != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProfilePage()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("User ID not found. Please log in again.")),
          );
        }
      },
    ),
        ],
      ),
      body: post == null
        ? Center(child: CircularProgressIndicator()) 
        : Padding(
          padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: Column(
            children: [
             Container(
  width: 250,
  height: 250, 
  
  decoration: BoxDecoration(
    borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
    image: post!['media'] != null
        ? DecorationImage(
            image: NetworkImage("http://localhost/public_html/FlutterGrad/${post!['media']}"),
            fit: BoxFit.cover, // Ensures the image covers the entire area
          )
        : null,
    color: Colors.grey.shade300, // Placeholder color if no image
  ),
  child: post!['media'] == null
      ? Center(child: Icon(Icons.image, size: 80, color: Colors.grey))
      : null,
),

              Divider(),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                            post!['posttitle'] ?? 'No Title',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'By: ${post!['username']??""}, ${post!['POSTCREATORID']??""}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          SizedBox(height: 10),
                    Text(
                      post!['CONTENT'] ?? 'No Content',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Status: ${post!['STATUS'] ?? 'N/A'}',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Approved By: ${post!['APPROVERNAME'] ?? ''}, ${post!['REVIEWEDBY']??""}',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Approver Email: ${post!['EMAIL'] ?? ''}',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    SizedBox(height: 10),
                    
                    Text(
                      'Published on: ${post!['DATECREATED']}',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                      ),
                    ),
                    Text(
                      'Approved on: ${post!['APPROVALDATE'] ?? ''}',
                      style: TextStyle(color: Colors.grey.shade500,),
                    ),
                    SizedBox(height: 10),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Center(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: Size(150, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      'Comment',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}