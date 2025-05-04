import 'dart:async';
import 'package:bzu_leads/pages/privatepostsdetails.dart';
import 'package:bzu_leads/services/PrivatePost.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:bzu_leads/pages/chattingGroup_page.dart';
import 'package:bzu_leads/pages/settingsPage.dart';

class PrivatePosts extends StatefulWidget {
  const PrivatePosts({super.key});

  @override
  State<PrivatePosts> createState() => _PrivatePostsState();
}

class _PrivatePostsState extends State<PrivatePosts> {
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
    final data = await Privatepost.fetchPrivatePosts();
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
    // If there's an error, update the state and display an error message
    print("Error fetching posts: $e");
    setState(() {
      message = "Failed to load posts.";
    });
  } finally {
    setState(() {
      isLoading = false; // Set isLoading to false when done
    });
  }
}

  Future<void> logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
  }

  Future<Size> _getImageSize(String imageUrl) async {
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
  }

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
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PrivatePostDetailsState(postID: int.parse(post['postID'])),//, postType: 'public',
            ),
          );
        },
child: SingleChildScrollView(
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
                      post['username'],
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    post['DATECREATED'],
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                post['posttitle'],
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                post['CONTENT'],
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 12),
              if (post['media'] != null && post['media'].isNotEmpty)
  FutureBuilder<Size>(
    future: _getImageSize("http://192.168.10.5/public_html/FlutterGrad/${post['media']}"),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: 180,
            width: double.infinity,
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
  "http://192.168.10.5/public_html/FlutterGrad/${post['media']}",
  fit: BoxFit.contain,
  loadingBuilder: (context, child, loadingProgress) {
    if (loadingProgress == null) return child;
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 180,
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

            ],
          ),
        ),
      ),
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
          Image.asset(
            'assets/logo.png',
            height: 40, // Adjust height as needed
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
