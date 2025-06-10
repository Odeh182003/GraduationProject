import 'dart:async';
import 'dart:io';
import 'package:bzu_leads/pages/postsDetails.dart';
import 'package:bzu_leads/services/ApiConfig.dart';
//import 'package:bzu_leads/pages/privatepostsdetails.dart';
//import 'package:url_launcher/url_launcher.dart';
import 'package:bzu_leads/services/PrivatePost.dart';
import 'package:bzu_leads/services/editPosts.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:bzu_leads/pages/chattingGroup_page.dart';
import 'package:bzu_leads/pages/settingsPage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

import 'package:open_file/open_file.dart';

class PrivatePosts extends StatefulWidget {
  const PrivatePosts({super.key});

  @override
  State<PrivatePosts> createState() => _PrivatePostsState();
}

class _PrivatePostsState extends State<PrivatePosts> {
  String? _currentUserID;
SharedPreferences? prefs;
  List<dynamic> posts = [];
  bool isLoading = true;
  String message = "Loading posts...";

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  Future<void> fetchPosts() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? defaultRole = prefs.getString("defaultRole");
      // If user is universityAdministrator, fetch all private posts
      if (defaultRole == "universityAdministrator") {
        final data = await Privatepost.fetchAllPrivatePosts();
        setState(() {
          posts = data;
          isLoading = false;
        });
        if (data.isEmpty) {
          setState(() {
            message = "No posts available.";
          });
        }
        return;
      }
      // For other users, fetch posts filtered by facultyID
      String? facultyID = prefs.getString("facultyID");
      final data = await Privatepost.fetchPrivatePostsByFaculty(facultyID);
      if (data.isNotEmpty) {
        setState(() {
          posts = data;
        });
      } else {
        setState(() {
          message = "No posts available.";
        });
      }
    } catch (e) {
      print("Error fetching posts: $e");
      setState(() {
        message = "Failed to load posts.";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
  }

  /*Future<Size> _getImageSize(String imageUrl) async {
    final Completer<Size> completer = Completer();
    final Image image = Image.network(imageUrl);

    image.image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        final myImage = info.image;
        final size = Size(myImage.width.toDouble(), myImage.height.toDouble());
        completer.complete(size);
      }, onError: (error, stackTrace) {
        completer.complete(const Size(16, 9));
      }),
    );

    return completer.future;
  }*/

  Widget _buildShimmerCard() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          height: 250,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildPostCard(dynamic post) {
    final List<dynamic> mediaList = post['media'] is List ? post['media'] : [];

    // Separate images and files by extension
    final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    final List<String> images = [];
    final List<String> files = [];

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

    Future<void> _downloadFile(String url, String fileName) async {
      prefs = await SharedPreferences.getInstance();
  _currentUserID = prefs?.getString("universityID");
      try {
        Directory? downloadsDir;
        // Try to get the downloads directory (works on Android, iOS, desktop)
        try {
          downloadsDir = await getDownloadsDirectory();
        } catch (e) {
          // Fallback to documents directory if downloads is not available
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
          // Optionally open the file after download
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

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(vertical: 12),
        width: 700,
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
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Postsdetails(postID: int.parse(post['postID'].toString())),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row with Avatar and user info (fixed layout)
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.green,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post['username'],
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "(${post['universityID']})",
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                   const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        post['DATECREATED'],
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      if (_currentUserID != null &&
                          post['universityID']?.toString() == _currentUserID)
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.green),
                          tooltip: "Edit Post",
                          onPressed: () => showEditPostDialog(
                          context: context,
                          post: post,
                         currentUserID: _currentUserID,
                        prefs: prefs,
                        reloadPosts: fetchPosts,
),
                        ),
                    ],
                  ),
                  ],
                ),
                const SizedBox(height: 12),
                // Divider to separate header and content
                Container(
                  height: 1,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 12),
                // Post title and content
                Text(
                  post['posttitle'],
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  post['CONTENT'],
                  style: const TextStyle(fontSize: 15, height: 1.4),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                // --- Media section for images and files ---
                if (images.isNotEmpty)
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _buildMediaCarousel(images),
                    ),
                  )
                else
                  Center(
                    child: Container(
                      height: 250,
                      color: Colors.grey[300],
                      child: Center(
                        child: Icon(Icons.image, size: 100, color: Colors.grey[600]),
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
                          return ListTile(
                            leading: Icon(Icons.attach_file, color: Colors.green),
                            title: Text(fileName, overflow: TextOverflow.ellipsis),
                            onTap: () async {
                              await _downloadFile(fileUrl, fileName);
                            },
                            trailing: Icon(Icons.download, color: Colors.green),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaCarousel(List<String> mediaList) {
    int currentIndex = 0;
    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          children: [
            SizedBox(
              height: 250,
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
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      height: 250,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[300],
                        height: 250,
                        child: Icon(Icons.broken_image, size: 100, color: Colors.grey[600]),
                      ),
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
              "Private Posts",
              style: TextStyle(
                color: Colors.green, // Ensure text color matches your theme
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (String value) {
              switch (value) {
                case 'Chatting Groups':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ChattingGroupPage()));
                  break;
                case 'Private Posts':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivatePosts()));
                  break;
                case 'Settings':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const settingsPage()));
                  break;
                case 'Logout':
                  logout(context);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'Chatting Groups',
                child: ListTile(
                  leading: Icon(Icons.chat),
                  title: Text('Chatting Groups'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'Private Posts',
                child: ListTile(
                  leading: Icon(Icons.lock),
                  title: Text('Private Posts'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'Settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Settings'),
                ),
              ),
              const PopupMenuItem<String>(
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
      body: isLoading
          ? ListView.builder(
              itemCount: 4,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) => _buildShimmerCard(),
            )
          : posts.isEmpty
              ? Center(child: Text(message))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: posts.length,
                  itemBuilder: (context, index) => _buildPostCard(posts[index]),
                ),
    );
  }
}
