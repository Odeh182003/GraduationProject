import 'package:bzu_leads/pages/profile_page.dart';
import 'package:bzu_leads/pages/settingsPage.dart';
import 'package:bzu_leads/services/comments.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class PrivatePostDetailsState extends StatefulWidget {
  final int postID;

  const PrivatePostDetailsState({super.key, required this.postID});

  @override
  _PrivatePostDetailsState createState() => _PrivatePostDetailsState();
}

class _PrivatePostDetailsState extends State<PrivatePostDetailsState> {
  Map<String, dynamic>? post;
  late Future<List<Comment>> _commentsFuture;

  @override
  void initState() {
    super.initState();
    fetchPostById();
    _commentsFuture = fetchComments(widget.postID);
  }

  Future<void> fetchPostById() async {
    final response = await http.get(Uri.parse(
        'http://192.168.10.5/public_html/FlutterGrad/privatepostsdetails.php?postID=${widget.postID}'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data.containsKey('post')) {
        setState(() {
          post = data['post'];
        });
      }
    }
  }

  Future<void> submitComment({
    required int postID,
    required int commentCreatorID,
    required String commentText,
  }) async {
    final url = Uri.parse('http://192.168.10.5/public_html/FlutterGrad/insertCommentPrivate.php');
    final response = await http.post(
      url,
      body: {
        'postID': postID.toString(),
        'commentCreatorID': commentCreatorID.toString(),
        'commentText': commentText,
      },
    );
    final result = json.decode(response.body);
    if (response.statusCode == 200 && result['success'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Comment published!")),
      );
      setState(() {
        _commentsFuture = fetchComments(widget.postID);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add comment: ${result['error']}")),
      );
    }
  }
Future<List<Comment>> fetchComments(int postID) async {
  final url = Uri.parse("http://192.168.10.5/public_html/FlutterGrad/getCommentsPrivate.php?postID=$postID");
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final data = json.decode(response.body);

    if (data['comments'] is List) {
      return (data['comments'] as List)
          .map((c) => Comment.fromJson(c))
          .toList();
    }
  }
  return [];
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
  backgroundColor: Colors.white,
  foregroundColor: Colors.green,
  elevation: 1,
  title: Row(
    children: [
      Image.asset(
        'assets/logo.png',
        height: 40, // Adjust height as needed
      ),
      const SizedBox(width: 8), // Space between image and text
      const Text(
        "Posts Details",
        style: TextStyle(
          color: Colors.green, // Ensure text color matches your theme
        ),
      ),
    ],
  ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => settingsPage()),
            ),
          ),
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              String? userID = prefs.getString("universityID");
              if (userID != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProfilePage()),
                );
              }
            },
          ),
        ],
      ),
      body: post == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
  child: ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: post!["media"] != null
        ? Image.network(
            'http://192.168.10.5/public_html/FlutterGrad/${post!["media"]}',
            width: 250,
            height: 250,
            fit: BoxFit.cover,
          )
        : Container(
            height: 250,
            color: Colors.grey[300],
            child: Center(
              child: Icon(Icons.image, size: 100, color: Colors.grey[600]),
            ),
          ),
  ),
),

                    const SizedBox(height: 20),
                    Text(post!["posttitle"] ?? 'No Title',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text("By: ${post!["username"]} (${post!["POSTCREATORID"]})",
                        style: TextStyle(color: Colors.black)),
                    const SizedBox(height: 10),
                    Text(post!["CONTENT"] ?? '',
                        style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 10),
                    Divider(),
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green[700]),
                        const SizedBox(width: 8),
                        Expanded(child: Text("Status: ${post!["STATUS"]}")),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text("Approved By: ${post!["APPROVERNAME"] ?? ''}, ${post!["REVIEWEDBY"] ?? ''}"),
                    const SizedBox(height: 8),
                    Text("Email: ${post!["email"] ?? ''}"),
                    const SizedBox(height: 8),
                    Text("Published: ${post!["DATECREATED"]}"),
                    Text("Approved: ${post!["APPROVALDATE"] ?? ''}"),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          SharedPreferences prefs = await SharedPreferences.getInstance();
                          String? userID = prefs.getString("universityID");

                          if (userID == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Please login to comment.")));
                            return;
                          }

                          String commentText = '';

                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text("Add Comment"),
                              content: TextField(
                                maxLines: 3,
                                onChanged: (value) => commentText = value,
                                decoration: InputDecoration(
                                    hintText: "Type your comment...",
                                    border: OutlineInputBorder()),
                              ),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text("Cancel")),
                                ElevatedButton(
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    await submitComment(
                                      postID: widget.postID,
                                      commentCreatorID: int.parse(userID),
                                      commentText: commentText,
                                    );
                                  },
                                  child: Text("Publish"),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.comment,
                          color: Colors.white,  // Set the color to white
),

                        label: Text(
                                "Comment",
                                 style: TextStyle(color: Colors.white), 
),

                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text("Comments",
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    FutureBuilder<List<Comment>>(
                      future: _commentsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(child: Text("No comments yet."));
                        }
                        final comments = snapshot.data!;
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: comments.length,
                          itemBuilder: (context, index) {
                            final comment = comments[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                title: Text(comment.text),
                                subtitle: Text("By user ${comment.creatorId} at ${comment.timestamp}"),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}  