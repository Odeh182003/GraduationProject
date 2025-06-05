import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:shimmer/shimmer.dart';

class OfficialNotification extends StatefulWidget {
  const OfficialNotification({super.key});

  @override
  State<OfficialNotification> createState() => _OfficialNotificationState();
}

class _OfficialNotificationState extends State<OfficialNotification> {
  List posts = [];
  String? userId;
  bool _isLoading = true;

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
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchPendingPosts(String userId) async {
    final response = await http.get(
      Uri.parse('http://192.168.10.3/public_html/FlutterGrad/get_pending_posts.php?reviewerId=$userId'),
    );

    if (response.statusCode == 200) {
      try {
        final data = json.decode(response.body);
        setState(() {
          posts = data;
          _isLoading = false;
        });
      } catch (e) {
        print("Error decoding JSON: $e");
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      print("Failed to fetch posts: ${response.statusCode}");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handlePostAction(String postId, String postType, String action) async {
    final url = 'http://192.168.10.3/public_html/FlutterGrad/$action.php';
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
        
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : posts.isEmpty
              ? const Center(child: Text("No new Notification", style: TextStyle(fontSize: 18, color: Colors.grey)))
              : ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return NotificationCard(
                      title: post['posttitle'] ?? '',
                      content: post['CONTENT'] ?? '',
                      creatorID: post['POSTCREATORID']?.toString() ?? '',
                      postID: post['POSTID']?.toString() ?? '',
                      postType: post['POSTTYPE']?.toString() ?? '',
                      mediaList: post['media'] is List ? List<String>.from(post['media']) : [],
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
  final List<String> mediaList; // <-- changed from mediaUrl
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const NotificationCard({
    super.key,
    required this.title,
    required this.content,
    required this.creatorID,
    required this.postID,
    required this.postType,
    required this.mediaList,
    required this.onApprove,
    required this.onReject,
  });

  bool _isImage(String path) {
    final ext = path.toLowerCase();
    return ext.endsWith('.jpg') || ext.endsWith('.jpeg') || ext.endsWith('.png') || ext.endsWith('.gif') || ext.endsWith('.bmp') || ext.endsWith('.webp');
  }

  Future<void> _downloadAndOpenFile(BuildContext context, String url, String fileName) async {
    try {
      Directory? downloadsDir;
      try {
        downloadsDir = await getDownloadsDirectory();
      } catch (e) {
        downloadsDir = await getApplicationDocumentsDirectory();
      }
      if (downloadsDir == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Cannot access downloads directory.")),
        );
        return;
      }
      final savePath = "${downloadsDir.path}/$fileName";
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final file = File(savePath);
        await file.writeAsBytes(response.bodyBytes);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Downloaded to $savePath")),
        );
        try {
          await OpenFile.open(savePath);
        } catch (_) {}
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to download file (status ${response.statusCode}).")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error downloading file: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    int currentIndex = 0;
    final imageUrls = mediaList
        .where((m) => _isImage(m))
        .map((m) => "http://192.168.10.3/public_html/FlutterGrad/$m")
        .toList();
    final fileUrls = mediaList
        .where((m) => !_isImage(m))
        .map((m) => "http://192.168.10.3/public_html/FlutterGrad/$m")
        .toList();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 3,
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.green,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    creatorID,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
               // Icon(postType == 'private' ? Icons.lock : Icons.public, color: Colors.green),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              content,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 12),
            if (imageUrls.isNotEmpty)
              StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    children: [
                      AspectRatio(
                        aspectRatio: 4 / 3,
                        child: PageView.builder(
                          itemCount: imageUrls.length,
                          onPageChanged: (index) {
                            setState(() {
                              currentIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                imageUrls[index],
                                fit: BoxFit.contain,
                                width: double.infinity,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Shimmer.fromColors(
                                    baseColor: Colors.grey[300]!,
                                    highlightColor: Colors.grey[100]!,
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return const SizedBox();
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      if (imageUrls.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              imageUrls.length,
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
              ),
            if (fileUrls.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: fileUrls.map((url) {
                    final filename = url.split('/').last;
                    return ListTile(
                      leading: Icon(Icons.attach_file, color: Colors.green),
                      title: Text(filename, style: TextStyle(fontSize: 14)),
                      trailing: Icon(Icons.download, color: Colors.green),
                      onTap: () async {
                        await _downloadAndOpenFile(context, url, filename);
                      },
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 12),
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
