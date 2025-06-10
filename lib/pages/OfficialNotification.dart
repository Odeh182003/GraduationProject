import 'dart:async';
import 'dart:io';
import 'package:bzu_leads/services/ApiConfig.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

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
      Uri.parse('${ApiConfig.baseUrl}/get_pending_posts.php?reviewerId=$userId'),
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

  Future<void> _openAttachment(String url, String fileName) async {
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
            const SizedBox(width: 8),
            const Text(
              "Officials' Notifications",
              style: TextStyle(
                color: Colors.green,
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
                      username: post['username'] ?? 'Unknown User',
                      postID: post['POSTID']?.toString() ?? '',
                      postType: post['POSTTYPE']?.toString() ?? '',
                      mediaList: post['media'] is List ? List<String>.from(post['media']) : [],
                      onApprove: () async => await _handlePostAction(post['POSTID'], post['POSTTYPE'], 'approve'),
                      onReject: () async => await _handlePostAction(post['POSTID'], post['POSTTYPE'], 'reject'),
                      onOpenAttachment: _openAttachment,
                    );
                  },
                ),
    );
  }

  Future<void> _handlePostAction(dynamic postId, dynamic postType, String action) async {
    final url = '${ApiConfig.baseUrl}/$action.php';
    if (userId == null) return;

    final String safePostId = postId?.toString() ?? '';
    final String safePostType = postType?.toString() ?? '';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'postId': safePostId,
          'approverId': userId,
          'postType': safePostType,
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
}

class NotificationCard extends StatelessWidget {
  final String title;
  final String content;
  final String creatorID;
  final String username;
  final String postID;
  final String postType;
  final List<String> mediaList;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final Future<void> Function(String url, String fileName) onOpenAttachment;

  const NotificationCard({
    super.key,
    required this.title,
    required this.content,
    required this.creatorID,
    required this.username,
    required this.postID,
    required this.postType,
    required this.mediaList,
    required this.onApprove,
    required this.onReject,
    required this.onOpenAttachment,
  });

  bool _isImage(String path) {
    final ext = path.toLowerCase();
    return ext.endsWith('.jpg') || ext.endsWith('.jpeg') || ext.endsWith('.png') || ext.endsWith('.gif') || ext.endsWith('.bmp') || ext.endsWith('.webp');
  }

  @override
  Widget build(BuildContext context) {
    final imageUrls = mediaList
        .where((m) => _isImage(m))
        .map((m) => "${ApiConfig.baseUrl}/$m")
        .toList();
    final fileUrls = mediaList
        .where((m) => !_isImage(m))
        .map((m) => "${ApiConfig.baseUrl}/$m")
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
                    "$username: $creatorID",
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
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
              Column(
                children: imageUrls.map((url) {
                  return GestureDetector(
                    onTap: () => onOpenAttachment(url, url.split('/').last),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        url,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return const SizedBox();
                        },
                      ),
                    ),
                  );
                }).toList(),
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
                      trailing: Icon(Icons.visibility, color: Colors.green),
                      onTap: () => onOpenAttachment(url, filename),
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
