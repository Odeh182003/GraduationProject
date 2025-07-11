import 'dart:convert';
import 'package:bzu_leads/services/ApiConfig.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';

class RejectedPostsPage extends StatefulWidget {
  const RejectedPostsPage({super.key});

  @override
  State<RejectedPostsPage> createState() => _RejectedPostsPageState();
}

class _RejectedPostsPageState extends State<RejectedPostsPage> {
  List<dynamic> rejectedPosts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRejectedPosts();
  }

  Future<void> fetchRejectedPosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final universityID = prefs.getString('universityID');

      if (universityID == null) {
        throw Exception("User ID not found");
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/get_rejected_posts.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'universityID': universityID}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          rejectedPosts = data;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load posts');
      }
    } catch (e) {
      print("Error fetching rejected posts: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildPostCard(Map<String, dynamic> post) {
    // Separate images and files by extension
    final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    final List<String> images = [];
    final List<String> files = [];
    // Support both single string and list for media
    final mediaRaw = post['media'];
    List<dynamic> mediaList = [];
    if (mediaRaw is List) {
      mediaList = mediaRaw;
    } else if (mediaRaw is String && mediaRaw.isNotEmpty) {
      // Try to parse as JSON array, fallback to single string
      try {
        final parsed = json.decode(mediaRaw);
        if (parsed is List) {
          mediaList = parsed;
        } else {
          mediaList = [mediaRaw];
        }
      } catch (_) {
        mediaList = [mediaRaw];
      }
    }
    for (var item in mediaList) {
      if (item is String) {
        final ext = item.split('.').last.toLowerCase();
        if (imageExtensions.contains(ext)) {
          images.add(item);
        } else {
          files.add(item);
        }
      }
    }

    Future<void> downloadFile(String url, String fileName) async {
      try {
        // Use path_provider and open_file as in other pages
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

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post['post_type'] == 'private' ? 'Private Post' : 'Public Post',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red[400],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              post['posttitle'] ?? "No title",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(post['CONTENT'] ?? '', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 10),
            if (images.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  "${ApiConfig.baseUrl}/${images.first}",
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: Icon(Icons.broken_image, size: 80, color: Colors.grey[600]),
                  ),
                ),
              ),
            if (files.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Attachments:", style: TextStyle(fontWeight: FontWeight.w600)),
                    ...files.map((file) {
                      final fileName = file.split('/').last;
                      final fileUrl = "${ApiConfig.baseUrl}/$file";
                      IconData icon;
                      final ext = fileName.split('.').last.toLowerCase();
                      if (ext == 'pdf') {
                        icon = Icons.picture_as_pdf;
                      } else if (ext == 'doc' || ext == 'docx') {
                        icon = Icons.description;
                      } else {
                        icon = Icons.attach_file;
                      }
                      return ListTile(
                        leading: Icon(icon, color: Colors.green),
                        title: Text(fileName, overflow: TextOverflow.ellipsis),
                        onTap: () async {
                          await downloadFile(fileUrl, fileName);
                        },
                        trailing: Icon(Icons.download, color: Colors.green),
                      );
                    }).toList(),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Text("Date: ${post['DATECREATED']}"),
            Text("Reviewed By: ${post['REVIEWEDBY'] ?? 'N/A'}"),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        "Rejected Posts",
        style: TextStyle(
          color: Colors.green, // Ensure text color matches your theme
        ),
      ),
    ],
  ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : rejectedPosts.isEmpty
              ? const Center(child: Text("No rejected posts found."))
              : ListView.builder(
                  itemCount: rejectedPosts.length,
                  itemBuilder: (context, index) {
                    return buildPostCard(rejectedPosts[index]);
                  },
                ),
    );
  }
}
