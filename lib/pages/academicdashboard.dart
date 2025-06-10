import 'dart:async';
import 'dart:convert';
import 'dart:io';
//import 'package:bzu_leads/components/officialBottomNavigator.dart';
//import 'package:bzu_leads/pages/OfficialNotification.dart';
//import 'package:bzu_leads/components/official_drawer.dart';
//import 'package:bzu_leads/pages/chattingGroup_page.dart';
//import 'package:bzu_leads/pages/OfficialNotification.dart';
//import 'package:bzu_leads/pages/calender.dart';
import 'package:bzu_leads/pages/chattingGroup_page.dart';
import 'package:bzu_leads/pages/chatting_page.dart';
//import 'package:bzu_leads/pages/createEventOfficials.dart';
import 'package:bzu_leads/pages/PostFormScreen.dart';
import 'package:bzu_leads/pages/chatting_private_page.dart';
import 'package:bzu_leads/pages/participate.dart';
import 'package:bzu_leads/pages/postsDetails.dart';
import 'package:bzu_leads/pages/private_chats.dart';
import 'package:bzu_leads/pages/private_posts.dart';
import 'package:bzu_leads/pages/profile_page.dart';
import 'package:bzu_leads/pages/settingsPage.dart';
import 'package:bzu_leads/services/ApiConfig.dart';
import 'package:bzu_leads/services/editPosts.dart';
import 'package:bzu_leads/services/group_service.dart';
import 'package:bzu_leads/services/post_service.dart';
//import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
//import 'dart:convert';
//import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Academicdashboard extends StatefulWidget {
  const Academicdashboard({super.key});

  @override
  _Academicdashboard createState() => _Academicdashboard();
}

class _Academicdashboard extends State<Academicdashboard> {
  List<Map<String, dynamic>> _chatGroups = [];
String? _currentUserID;
String? _academicName;
SharedPreferences? prefs;
bool _isLoading = true;


  List<dynamic> posts = [];
 // bool _isDarkMode = false;

  /*final List<Widget> _pages = [
    const Academicdashboard(),
    const ChattingGroupPage(),
    const ProfilePage(),
  ];*/

  @override
 @override
void initState() {
  super.initState();
 // loadTheme();
  fetchPosts();
  _initializePreferences().then((_) {
    _fetchChatGroups();
    _loadAcademicName();
  });
}

Future<void> _loadAcademicName() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  setState(() {
    _academicName = prefs.getString("username");
  });
}

List<String> _roleList = [];
Future<void> _initializePreferences() async {
  prefs = await SharedPreferences.getInstance();
  _currentUserID = prefs?.getString("universityID");

  // Decode the roles as a list
  final rolesJson = prefs?.getString("role");
  if (rolesJson != null) {
    List<dynamic> decodedRoles = [];
    try {
      decodedRoles = rolesJson.contains('[')
          ? List<String>.from(jsonDecode(rolesJson))
          : [rolesJson]; // handle string fallback
    } catch (_) {
      decodedRoles = [rolesJson]; // Fallback to single string role
    }

    setState(() {
      _roleList = decodedRoles.cast<String>();
    });
  }

  await _fetchChatGroups();
}



 Future<void> _fetchChatGroups() async {
  if (_currentUserID == null) return;

  try {
  final groups = await GroupService.getChatGroups(_currentUserID!);
  setState(() {
    _chatGroups = groups;
    _isLoading = false;
  });
} catch (e) {
  print("Error loading groups: $e");
  setState(() => _isLoading = false);
}

}


 /* void loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('darkMode') ?? false;
    });
  }
*/
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
/*void _onBottomNavSelected(int index) {
  final isWideScreen = MediaQuery.of(context).size.width >= 900;

  switch (index) {
    case 0:
// Dashboard
      break;
    case 1:
      if (isWideScreen) {
// Chatting group inline
      } else {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ChattingGroupPage()));
      }
      break;
    case 2:
      Navigator.push(context, MaterialPageRoute(builder: (_) => settingsPage()));
      break;
  }
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
/*Future<Size> _getImageSize(String imageUrl) async {
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
}*/

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


  Future<void> downloadFile(String url, String fileName) async {
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

  return AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeInOut,
    margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.15),
          spreadRadius: 2,
          blurRadius: 8,
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
            builder: (context) => Postsdetails(postID: int.parse(post['postID'])),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row with Avatar and user info
            Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.green,
                  child: Icon(Icons.person, color: Colors.white),
                ),
              //  const SizedBox(width: 10),
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
            const SizedBox(height: 10),
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
                      final fileUrl = "http://localhost/public_html/FlutterGrad/$file";
                      return ListTile(
                        leading: Icon(Icons.attach_file, color: Colors.green),
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
          ],
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
            final imageUrl = "${ApiConfig.baseUrl}/${mediaList[index]}"; 
            return ClipRRect(
             borderRadius: BorderRadius.circular(16),
             child: Image.network(
             imageUrl,
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
      MaterialPageRoute(builder: (context) =>  Participate(userID: _currentUserID!)),
    );
  }else if (index == 4) {
    if (_currentUserID != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PostFormScreen()),
      );
    } 
  }else if (index == 5) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) =>  PrivateChats()),
    );
  }
  else if (index == 6) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) =>  settingsPage()),
    );
  }
  // index == 0 is the current dashboard, do nothing
}

  Widget _buildSideNav() {
    /*final bool isDark = _isDarkMode;
    final Color selectedColor = isDark ? Colors.white : Colors.green;
    final Color unselectedColor = isDark ? Colors.white70 : Colors.black54;
    final Color backgroundColor = isDark ? Colors.black : Colors.white;
*/
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
          icon: Icon(Icons.create_outlined),
          label: Text("Participate in Events"),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.post_add),
          label: Text("Create new Posts"),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.personal_injury),
          label: Text("Private Chats"),
        ),
       /* NavigationRailDestination(
          icon: Icon(Icons.calendar_month_rounded),
          label: Text("Calender"),
        ),*/
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
  Widget _buildDrawerNavigation() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        DrawerHeader(
          decoration: const BoxDecoration(
            color: Colors.green,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 36, color: Colors.green),
              ),
              const SizedBox(height: 12),
              Text(
                _academicName ?? "Academic",
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                _currentUserID ?? "",
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
        ListTile(
          leading: const Icon(Icons.dashboard_outlined),
          title: const Text('Dashboard'),
          onTap: () {
            Navigator.pop(context);
          },
        ),
        ListTile(
          leading: const Icon(Icons.person_2_outlined),
          title: const Text('Profile'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
          },
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('Private Posts'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivatePosts()));
          },
        ),
        ListTile(
          leading: const Icon(Icons.create_outlined),
          title: const Text('Participate in Events'),
          onTap: () {
            Navigator.pop(context);
            if (_currentUserID != null) {
              Navigator.push(context, MaterialPageRoute(builder: (context) => Participate(userID: _currentUserID!)));
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.post_add),
          title: const Text('Create new Posts'),
          onTap: () {
            Navigator.pop(context);
            if (_currentUserID != null) {
              Navigator.push(context, MaterialPageRoute(builder: (context) => PostFormScreen()));
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.group),
          title: const Text('Group Chats'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (context) => ChattingGroupPage()));
          },
        ),
        ListTile(
          leading: const Icon(Icons.personal_injury),
          title: const Text('Private Chats'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (context) => PrivateChats()));
          },
        ),
        ListTile(
          leading: const Icon(Icons.settings),
          title: const Text('Settings'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (context) => settingsPage()));
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isWideScreen = MediaQuery.of(context).size.width > 900;

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
      const SizedBox(width: 8),
      const Text(
        "academics' Dashboard",
        style: TextStyle(
          color: Colors.green,
        ),
      ),
    ],
  ),
  actions: isWideScreen ? null : null,
),

      // NEW: Use a Drawer on small screens for complete navigation
      drawer: !isWideScreen ? Drawer(child: _buildDrawerNavigation()) : null,
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
                      child: Column(
                        children: [
                          // ...existing group chat code...
                          Expanded(
                            child: _isLoading
                                ? const Center(child: CircularProgressIndicator())
                                : _chatGroups.isEmpty
                                    ? const Center(child: Text("No groups found"))
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
                                              //trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                              onTap: () {
                                                String? senderUsername = prefs?.getString("username");
                                                String? academicId = _currentUserID;
                                                String? academicName = _academicName;
                                                if (senderUsername != null && academicId != null && academicName != null) {
                                                 
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
                          // --- NEW: Show private chat requests/messages for this academic ---
// --- NEW: Show private chat requests/messages for this academic ---
                          StreamBuilder<QuerySnapshot>(

                            stream: _currentUserID == null
                                ? null
                                : FirebaseFirestore.instance
                                    .collection('PrivateChats')
                                    .where(FieldPath.documentId, isGreaterThanOrEqualTo: _currentUserID!)
                                    .snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return const SizedBox.shrink();
                              final docs = snapshot.data!.docs;
                              // Only show chats where the academic is a participant and there are messages
                              final privateChats = docs.where((doc) {
                                final docId = doc.id;
                                return docId.contains(_currentUserID!) && docId != "${_currentUserID!}_null";
                              }).toList();

                              if (privateChats.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: privateChats.length,
                                itemBuilder: (context, index) {
                                  final chatDoc = privateChats[index];
                                  final chatId = chatDoc.id;
                                  final ids = chatId.split('_');
                                  // Academic ID is _currentUserID, peerId is the other participant (student)
                                  final peerId = ids[0] == _currentUserID ? ids[1] : ids[0];

                                  // Get the latest message to show senderUsername (student name)
                                  return StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('PrivateChats')
                                        .doc(chatId)
                                        .collection('Messages')
                                        .orderBy('timestamp', descending: true)
                                        .limit(1)
                                        .snapshots(),
                                    builder: (context, msgSnapshot) {
                                      String studentName = "Student $peerId";
                                      if (msgSnapshot.hasData && msgSnapshot.data!.docs.isNotEmpty) {
                                        final msgData = msgSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                                        // If the sender is not the academic, use their username
                                        if (msgData['senderID'] != _currentUserID && msgData['senderUsername'] != null) {
                                          studentName = msgData['senderUsername'];
                                        }
                                      }
                                      return Card(
                                        color: Colors.green[50],
                                        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                        child: ListTile(
                                          leading: const Icon(Icons.person, color: Colors.green),
                                          title: Text("Chat with $studentName"),
                                          subtitle: const Text("New message from student"),
                                          trailing: const Icon(Icons.chat, color: Colors.green),
                                          onTap: () async {
                                            SharedPreferences prefs = await SharedPreferences.getInstance();
                                            String? academicName = prefs.getString("username");
                                            String? academicId = _currentUserID;
                                            // Pass both IDs to PrivateChattingPage
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => PrivateChattingPage(
                                                  peerId: peerId,
                                                  peerName: studentName,
                                                  currentUserName: academicName ?? '',
                                                  currentUserId: academicId ?? '',
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      // Remove bottomNavigationBar for small screens
      bottomNavigationBar: isWideScreen ? null : null,
      floatingActionButton: (_roleList.contains("academic") || _roleList.contains("official"))
          && MediaQuery.of(context).size.width > 900
          ? FloatingActionButton(
              onPressed: _createGroups,
              backgroundColor: Colors.green,
              child: const Icon(Icons.group_add),
            )
          : null,
    );
  }
   
bool _isCreating = false;
  Future<void> _createGroups() async {
  if (_isCreating) return; // Prevent double-tap

  setState(() {
    _isCreating = true;
  });

if (_currentUserID != null && (_roleList.contains("academic") || _roleList.contains("official"))) {
    final response = await GroupService.createGroups(_currentUserID!, _roleList.last);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(response['message'] ?? "Something happened")),
    );

    if (response['success']) {
      await _fetchChatGroups();
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Only academics and officials can create groups")),
    );
  }

  setState(() {
    _isCreating = false;
  });
}



}
