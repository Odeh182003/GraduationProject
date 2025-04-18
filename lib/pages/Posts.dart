/*import 'package:bzu_leads/components/officialBottomNavigator.dart';
import 'package:bzu_leads/pages/postsDetails.dart';
import 'package:bzu_leads/pages/private_posts.dart';
import 'package:bzu_leads/pages/profile_page.dart';
import 'package:bzu_leads/pages/settingsPage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:shimmer/shimmer.dart';
import 'package:bzu_leads/pages/chattingGroup_page.dart';
import 'package:http/http.dart' as http;
//import 'package:shared_preferences/shared_preferences.dart';

class Posts extends StatefulWidget {
  const Posts({super.key});

  @override
  _Posts createState() => _Posts();
}

class _Posts extends State<Posts> {
  List<dynamic> posts = [];
  int _selectedIndex = 0;
  bool _isDarkMode = false;
  @override
  void initState() {
    super.initState();
    loadTheme();
    fetchPosts();
  }
void loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('darkMode') ?? false;
    });
  }
  Future<void> fetchPosts() async {
    await Future.delayed(const Duration(seconds: 2));
    final http.Response response;
    if(kIsWeb){
           response = await http.get(Uri.parse('http://localhost/public_html/FlutterGrad/getPublicPosts.php'));
    }else{
           response = await http.get(Uri.parse('http://192.168.10.4/public_html/FlutterGrad/getPublicPosts.php'));

    }
    if (response.statusCode == 200) {
      setState(() {
        posts = json.decode(response.body);
      });
    } else {
      throw Exception('Failed to load posts');
    }
  }

final List<Widget> _pages = [
    Posts(), // Home page
    ChattingGroupPage(), // Chatting groups
    ProfilePage(), // User profile
  ];
  void _changePage(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  Widget _buildShimmerCard() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          height: 200,
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
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  Postsdetails(postID: int.parse(post['postID'])),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.green,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      post['username'],
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    "Created on: ${post['DATECREATED']}",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                post['posttitle'],
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                post['CONTENT'],
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              if (post['media'] != null &&
                  post['media'].isNotEmpty) // media display
                ClipRRect(
  borderRadius: BorderRadius.circular(10),
  child: Stack(
    children: [
      Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          height: 180,
          width: double.infinity,
          color: Colors.white,
        ),
      ),
      FadeInImage.assetNetwork(
        placeholder: 'assets/transparent.png', // 1x1 transparent PNG
        image:
                        "http://localhost/public_html/FlutterGrad/${post['media']}",
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    ],
  ),
)
            ],
          ),
        ),
      ),
    );
  }
@override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: Scaffold(
        appBar: AppBar(
              title: const Text("Academics' Public Posts"),
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.green,
              elevation: 0,
        ),
        body: _selectedIndex == 0
            ? (posts.isEmpty
                ? ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 6,
                    itemBuilder: (context, index) => _buildShimmerCard(),
                  )
                : RefreshIndicator(
                    onRefresh: fetchPosts,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        return _buildPostCard(post);
                      },
                    ),
                  ))
            : _pages[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _changePage,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}*/