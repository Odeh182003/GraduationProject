import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:bzu_leads/pages/profile_page.dart';
import 'package:bzu_leads/pages/settingsPage.dart';
import 'package:shimmer/shimmer.dart';

class OfficialNotification extends StatefulWidget {
  const OfficialNotification({super.key});

  @override
  State<OfficialNotification> createState() => _OfficialNotificationState();
}

class _OfficialNotificationState extends State<OfficialNotification> {
  //int _selectedIndex = 0;
  List posts = [];
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadUserIdAndFetchPosts();
  }

  Future<void> _loadUserIdAndFetchPosts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString("universityID");

    if (userId != null) {
      await _fetchPendingPosts(userId!);
    } else {
      print("User ID not found.");
    }
  }

  Future<void> _fetchPendingPosts(String userId) async {
    final response = await http.get(
      Uri.parse('http://192.168.10.5/public_html/FlutterGrad/get_pending_posts.php?reviewerId=$userId'),
    );

    if (response.statusCode == 200) {
      try {
        final data = json.decode(response.body);
        setState(() {
          posts = data;
        });
      } catch (e) {
        print("Error decoding JSON: $e");
      }
    } else {
      print("Failed to fetch posts: ${response.statusCode}");
    }
  }

  Future<void> _handlePostAction(String postId, String postType, String action) async {
    final url = 'http://192.168.10.5/public_html/FlutterGrad/$action.php';
    if (userId == null) return;

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'postId': postId,
          'approverId': userId,
          'postType': postType,
        }),
      );

      final result = jsonDecode(response.body);
      if (response.statusCode == 200 && result['success']) {
        print('Post $action successful.');
        
        await _fetchPendingPosts(userId!);
      } else {
        print('Post $action failed: ${result['error']}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  /*void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
    }
  }*/


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
              "Officials' Notifications",
              style: TextStyle(
                color: Colors.green, // Ensure text color matches your theme
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const settingsPage())),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              if (userId != null) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("User ID not found. Please log in again.")),
                );
              }
            },
          ),
        ],
      ),
      body: posts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return NotificationCard(
                  title: post['posttitle'] ?? '',
                  content: post['CONTENT'] ?? '',
                  creatorID: post['POSTCREATORID']?.toString() ?? '',
                  postID: post['POSTID']?.toString() ?? '',
                  postType: post['POSTTYPE'] ?? 'public',
                  mediaUrl: post['media'] ?? '', // Pass media URL
                  onApprove: () => _handlePostAction(post['POSTID'].toString(), post['POSTTYPE'], 'approve'),
                  onReject: () => _handlePostAction(post['POSTID'].toString(), post['POSTTYPE'], 'reject'),
                );
              },
            ),
    );
  }
}
class NotificationCard extends StatelessWidget {
  final String title;
  final String content;
  final String creatorID;
  final String postID;
  final String postType;
  final String mediaUrl;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const NotificationCard({
    super.key,
    required this.title,
    required this.content,
    required this.creatorID,
    required this.postID,
    required this.postType,
    required this.mediaUrl,
    required this.onApprove,
    required this.onReject,
  });

  // Function to get image size
  Future<Size> _getImageSize(String imageUrl) async {
    final image = NetworkImage(imageUrl);
    final configuration = ImageConfiguration();
    final imageStream = image.resolve(configuration);
    final completer = Completer<ImageInfo>();
    imageStream.addListener(ImageStreamListener((info, _) {
      completer.complete(info);
    }));
    final imageInfo = await completer.future;
    return Size(imageInfo.image.width.toDouble(), imageInfo.image.height.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    String fullMediaUrl = 'http://192.168.10.5/public_html/FlutterGrad/$mediaUrl'; // Full image URL

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(creatorID, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
                Icon(postType == 'private' ? Icons.lock : Icons.public, color: Colors.green),
              ],
            ),
            const SizedBox(height: 4),
            Text("Title: $title", style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(content, style: TextStyle(color: Colors.black, fontSize: 30)),

            // Add image if mediaUrl is not empty
            if (mediaUrl.isNotEmpty)
              FutureBuilder<Size>(
                future: _getImageSize(fullMediaUrl),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        height: 120, // Reduced height for the image
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  } else if (snapshot.hasData) {
                    final aspectRatio = snapshot.data!.width / snapshot.data!.height;
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: aspectRatio,
                        child: Image.network(
                          fullMediaUrl, // Use the full URL path
                          fit: BoxFit.cover, // Use cover to make the image fill the container
                          height: 120, // Set a fixed height for the image
                          width: 120, // Ensure the image takes up the full width
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(
                                height: 120, // Reduced height
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const SizedBox(); // or show a fallback image/icon
                          },
                        ),
                      ),
                    );
                  } else {
                    return const SizedBox(); // fallback if error
                  }
                },
              ),

            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: onApprove,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green[200]),
                  child: const Text("Approve", style: TextStyle(color: Colors.green)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onReject,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                  child: const Text("Reject", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
