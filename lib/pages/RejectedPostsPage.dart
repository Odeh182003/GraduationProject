import 'dart:convert';
import 'package:bzu_leads/services/ApiConfig.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
            if (post['media'] != null && post['media'].toString().isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  "${ApiConfig.baseUrl}/${post['media']}",
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
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
