import 'package:bzu_leads/pages/profile_page.dart';
import 'package:bzu_leads/pages/settingsPage.dart';
import 'package:bzu_leads/services/ApiConfig.dart';
import 'package:bzu_leads/services/comments.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
class Postsdetails extends StatefulWidget {
  final int postID;

  const Postsdetails({super.key, required this.postID});

  @override
  _PostsDetailsPageState createState() => _PostsDetailsPageState();
}

class _PostsDetailsPageState extends State<Postsdetails> {
  Map<String, dynamic>? post;
  late Future<List<Comment>> _commentsFuture;

  @override
  void initState() {
    super.initState();
    fetchPostById();
    _commentsFuture = fetchComments(widget.postID);
  }

  Future<void> fetchPostById() async {
    try {
      final response = await http.get(Uri.parse(
          '${ApiConfig.baseUrl}/postsDetails.php?postID=${widget.postID}'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Check for error in response
        if (data is Map && data.containsKey('error')) {
          if (mounted) {
            setState(() {
              post = null;
            });
          }
          // Optionally show a snackbar or dialog with error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['error'].toString())),
          );
          return;
        }

        if (data.containsKey('post') && data['post'] != null) {
          if (mounted) {
            setState(() {
              // Convert all int values to String to avoid type errors in widgets
              post = (data['post'] as Map<String, dynamic>).map<String, dynamic>((key, value) {
                if (value is int) {
                  return MapEntry(key, value.toString());
                }
                return MapEntry(key, value);
              });
            });
          }
        } else {
          if (mounted) {
            setState(() {
              post = null;
            });
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Post not found.")),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            post = null;
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load post details.")),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          post = null;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading post details.")),
      );
    }
  }

  Future<void> submitComment({
    required int postID,
    required int commentCreatorID,
    required String commentText,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/insertComment.php');
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
    final url = Uri.parse("${ApiConfig.baseUrl}/getComments.php?postID=$postID");
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

  // Helper to detect Arabic text
  bool _isArabic(String? text) {
    if (text == null) return false;
    final arabicRegExp = RegExp(r'[\u0600-\u06FF]');
    return arabicRegExp.hasMatch(text);
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
           Image.network(
        ApiConfig.systemLogoUrl,
        height: 40,
        errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image),
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
                        child: (post!["media"] != null && post!["media"] is List && (post!["media"] as List).isNotEmpty)
                            ? _buildMediaCarousel(post!["media"])
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
                    Directionality(
                      textDirection: _isArabic(post!["posttitle"]) ? TextDirection.rtl : TextDirection.ltr,
                      child: Text(
                        post!["posttitle"] ?? 'No Title',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Directionality(
                      textDirection: _isArabic(post!["username"]) ? TextDirection.rtl : TextDirection.ltr,
                      child: Text(
                        "By: ${post!["username"]} (${post!["POSTCREATORID"]})",
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Directionality(
                      textDirection: _isArabic(post!["CONTENT"]) ? TextDirection.rtl : TextDirection.ltr,
                      child: Text(
                        post!["CONTENT"] ?? '',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
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
                                title: Directionality(
                                  textDirection: _isArabic(comment.text) ? TextDirection.rtl : TextDirection.ltr,
                                  child: Text(comment.text),
                                ),
                                subtitle: Directionality(
                                  textDirection: _isArabic(comment.username) ? TextDirection.rtl : TextDirection.ltr,
                                  child: Text("By  ${comment.username}, ${comment.creatorId} at ${comment.timestamp}"),
                                ),
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

  Widget _buildMediaCarousel(dynamic media) {
    // Accepts List from backend, fallback to empty list if not a List
    final List<dynamic> mediaList = (media is List) ? media : [];
    int currentIndex = 0;

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          children: [
            SizedBox(
              height: 400,
              child: PageView.builder(
                itemCount: mediaList.length,
                onPageChanged: (index) {
                  setState(() {
                    currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final url = "${ApiConfig.baseUrl}/${mediaList[index]}";
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: Icon(Icons.broken_image, size: 100, color: Colors.grey[600]),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            if (mediaList.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    mediaList.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: currentIndex == index ? Colors.green : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}