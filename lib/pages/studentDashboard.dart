//import 'package:bzu_leads/components/my_drawer.dart';
import 'dart:async';

//import 'package:bzu_leads/components/officialBottomNavigator.dart';
//import 'package:bzu_leads/pages/chattingGroup_page.dart';
import 'package:bzu_leads/pages/RejectedPostsPage.dart';
import 'package:bzu_leads/pages/chatting_page.dart';
import 'package:bzu_leads/pages/participate.dart';
//import 'package:bzu_leads/pages/createPostsStudents.dart';
import 'package:bzu_leads/pages/private_posts.dart';
import 'package:bzu_leads/pages/profile_page.dart';
import 'package:bzu_leads/pages/settingsPage.dart';
import 'package:bzu_leads/pages/studentCreatePosts.dart';
import 'package:bzu_leads/services/group_service.dart';
import 'package:bzu_leads/services/post_service.dart';
//import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
//import 'dart:convert';
//import 'package:http/http.dart' as http;
import 'package:bzu_leads/pages/postsDetails.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
//import 'package:shared_preferences/shared_preferences.dart';

class PublicPosts extends StatefulWidget {
  const PublicPosts({super.key});

  @override
  _PublicPostsState createState() => _PublicPostsState();
}

class _PublicPostsState extends State<PublicPosts> {
 List<Map<String, dynamic>> _chatGroups = [];
String? _currentUserID;
SharedPreferences? prefs;

  List<dynamic> posts = [];
  bool _isDarkMode = false;

  /*final List<Widget> _pages = [
    const Academicdashboard(),
    const ChattingGroupPage(),
    const ProfilePage(),
  ];*/

  @override
  void initState() {
    super.initState();
    loadTheme();
    fetchPosts();
    _initializePreferences();
  }
Future<void> _initializePreferences() async {
  prefs = await SharedPreferences.getInstance();
  _currentUserID = prefs?.getString("universityID");
  await _fetchChatGroups();
}

 Future<void> _fetchChatGroups() async {
  if (_currentUserID == null) return;

  final groups = await GroupService.getChatGroups(_currentUserID!);
  setState(() {
    _chatGroups = groups;
  });
}


  void loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('darkMode') ?? false;
    });
  }

  Future<void> fetchPosts() async {
  try {
    final data = await PostService.fetchPublicPosts();
    setState(() {
      posts = data;
    });
  } catch (e) {
    // Optional: show error snackbar or message
    print("Error fetching posts: $e");
  }
}
  void _changePage(int index) {
  if (index == 1) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfilePage()),
    );
  } else if (index == 2) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PrivatePosts()),
    );
  }else if (index == 3) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) =>  Studentcreateposts()),
    );
  }else if (index == 4) {
    if (_currentUserID != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Participate(userID: _currentUserID!)),
      );
    } 
  }
  else if (index == 5) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) =>  RejectedPostsPage()),
    );
  }else if (index == 7) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) =>  settingsPage()),
    );
  }
  // index == 0 is the current dashboard, do nothing
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
Future<Size> _getImageSize(String imageUrl) async {
  final Completer<Size> completer = Completer();
  final Image image = Image.network(imageUrl);

  image.image.resolve(const ImageConfiguration()).addListener(
    ImageStreamListener((ImageInfo info, bool _) {
      final myImage = info.image;
      final size = Size(myImage.width.toDouble(), myImage.height.toDouble());
      completer.complete(size);
    }, onError: (error, stackTrace) {
      completer.complete(const Size(16, 9)); // Fallback aspect ratio
    }),
  );

  return completer.future;
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
              builder: (context) => Postsdetails(postID: int.parse(post['postID'])),//, postType: 'public',
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

  Widget _buildSideNav() {
  return Container(
    color: Colors.white, // Full white background
    height: double.infinity, // Fill screen vertically
    child: SingleChildScrollView(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: 0,
          maxHeight: double.infinity,
        ),
        child: IntrinsicHeight(
          child: NavigationRail(
            selectedIndex: 0, // Always highlight Dashboard
            onDestinationSelected: _changePage,
            labelType: NavigationRailLabelType.all,
            backgroundColor: Colors.white,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                label: Text("Dashboard"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person_2_outlined),
                label: Text("Profile"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.privacy_tip_outlined),
                label: Text("Private Posts"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.post_add),
                label: Text("Create new Posts"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.create_outlined),
                label: Text("Participate in Events"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.recycling),
                label: Text("Rejected Posts"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.calendar_month_rounded),
                label: Text("Calender"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings),
                label: Text("Settings"),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final bool isWideScreen = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.grey[100],
     // backgroundColor: Theme.of(context).colorScheme.surface,
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
        "Students' Dashboard",
        style: TextStyle(
          color: Colors.green, // Ensure text color matches your theme
        ),
      ),
    ],
  ),
        actions: isWideScreen
            ? null
            : [
                PopupMenuButton<int>(
                  icon: const Icon(Icons.menu),
                  onSelected: _changePage,
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 0, child: Text("Dashboard")),
                    const PopupMenuItem(value: 1, child: Text("Chat")),
                    const PopupMenuItem(value: 2, child: Text("Settings")),
                  ],
                )
              ],
      ),
      body: Row(
        children: [
          if (isWideScreen) _buildSideNav(),

          // Center content
          Expanded(
            flex: 3,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: posts.isEmpty
                    ? ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: 6,
                        itemBuilder: (context, index) => _buildShimmerCard(),
                      )
                    : RefreshIndicator(
                        onRefresh: fetchPosts,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: posts.length,
                          itemBuilder: (context, index) => _buildPostCard(posts[index]),
                        ),
                      ),
              ),
            ),
          ),

          // Right side - for web/tablets
          if (isWideScreen)
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(12),
                color: Colors.white,
                
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ListTile(
  leading: Icon(Icons.group, color: Colors.green),
  title: Text("My Communities"),
),
Expanded(
  child: _chatGroups.isEmpty
      ? Center(child: CircularProgressIndicator())
      : ListView.builder(
          itemCount: _chatGroups.length,
          itemBuilder: (context, index) {
            var group = _chatGroups[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                leading: CircleAvatar(
                  backgroundColor: Colors.green.shade100,
                  child: Icon(Icons.group, color: Colors.green),
                ),
                title: Text(
                  group['groupName'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  String? senderUsername = prefs?.getString("username");
                  if (senderUsername != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChattingPage(
                          groupId: group['groupID'],
                          groupName: group['groupName'],
                          senderUsername: senderUsername,
                        ),
                      ),
                    );
                  }
                },
              ),
            );
          },
        ),
),


                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: isWideScreen
    ? null
    : BottomNavigationBar(
        onTap: _changePage,
        currentIndex: 0, // Always show Dashboard as selected
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),

    );
  }
}