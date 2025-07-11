import 'dart:async';
import 'dart:convert';

import 'package:bzu_leads/pages/chattingGroup_page.dart';
import 'package:bzu_leads/pages/chatting_page.dart';
//import 'package:bzu_leads/pages/createEventOfficials.dart';
import 'package:bzu_leads/pages/PostFormScreen.dart';
import 'package:bzu_leads/pages/chatting_private_page.dart';
import 'package:bzu_leads/pages/participate.dart';
import 'package:bzu_leads/pages/private_chats.dart';
import 'package:bzu_leads/pages/private_posts.dart';
import 'package:bzu_leads/pages/profile_page.dart';
import 'package:bzu_leads/pages/settingsPage.dart';
import 'package:bzu_leads/services/ApiConfig.dart';
import 'package:bzu_leads/services/group_service.dart';
import 'package:bzu_leads/services/post_service.dart';
//import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
//import 'dart:convert';
//import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bzu_leads/pages/UnifiedDashboard.dart';

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
  }
  else if (index == 5) {
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

  
  @override
  Widget build(BuildContext context) {
    final bool isWideScreen = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
  backgroundColor: Colors.white,
  foregroundColor: Colors.green,
 // elevation: 1,
  title: Row(
    children: [
      Flexible(
        child: Row(
          children: [
            Image.network(
              ApiConfig.systemLogoUrl,
              height: 40,
              errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image),
            ),
            const SizedBox(width: 8),
            const Text(
              "Dashboard",
              style: TextStyle(
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    ],
  ),
  actions: [
    IconButton(
      icon: const Icon(Icons.notifications, color: Colors.green),
      tooltip: "New Updates",
      onPressed: () {
        _showUpdatesDialog();
      },
    ),
  ],
),

      // Use a Drawer on small screens for complete navigation
      drawer: !isWideScreen ? Drawer(child: buildDrawerNavigation(
                context: context,
                username: _academicName,
                userID: _currentUserID,
                items: [
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
          leading: const Icon(Icons.private_connectivity),
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
              )) : null,
      body: Row(
        children: [
          if (isWideScreen)
            buildSideNav(
              selectedIndex: 0,
              onDestinationSelected: _changePage,
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
                NavigationRailDestination(
                  icon: Icon(Icons.settings),
                  label: Text("Settings"),
                ),
              ],
            ),
          Expanded(
            flex: 3,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: posts.isEmpty
                    ? ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: 6,
                        itemBuilder: (context, index) => buildShimmerCard(),
                      )
                    : RefreshIndicator(
                        onRefresh: fetchPosts,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: posts.length,
                          itemBuilder: (context, index) => buildPostCard(
                            context: context,
                            post: posts[index],
                            currentUserID: _currentUserID,
                            prefs: prefs,
                            reloadPosts: fetchPosts,
                            showEditPen: _currentUserID != null &&
                                posts[index]['universityID']?.toString() == _currentUserID,
                            showFiles: true,
                          ),
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

void _showUpdatesDialog() async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? currentUserId = prefs.getString("universityID");

  if (currentUserId == null) return;

  showDialog(
    context: context,
    builder: (context) {
      // State inside the dialog
      int newPrivateMessages = 0;
      int newGroupMessages = 0;
      bool isLoading = true;

      return StatefulBuilder(
        builder: (context, setState) {
     if (isLoading) {
  Future(() async {
    int privateCount = 0;
    int groupCount = 0;

    final privateChatsSnapshot = await firestore.collection('PrivateChats').get();
    for (var chatDoc in privateChatsSnapshot.docs) {
      final messagesSnapshot = await firestore
          .collection('PrivateChats')
          .doc(chatDoc.id)
          .collection('Messages')
          .where('receiverID', isEqualTo: currentUserId)
          .get();
      privateCount += messagesSnapshot.docs.length;
    }

    final groupChatsSnapshot = await firestore.collection('Groups').get();
    for (var groupDoc in groupChatsSnapshot.docs) {
      final messagesSnapshot = await firestore
          .collection('Groups')
          .doc(groupDoc.id)
          .collection('Messages')
          .where('senderID', isNotEqualTo: currentUserId)
          .get();
      groupCount += messagesSnapshot.docs.length;
    }


    setState(() {
      newPrivateMessages = privateCount;
      newGroupMessages = groupCount;
      isLoading = false; // trigger UI update
    });
  });
}


          return AlertDialog(
            title: const Text("New Updates"),
            content: 
              isLoading ? const SizedBox(height:60, child: Center(child: CircularProgressIndicator()),)
             : Column(
               mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
               children: [
               Text("New private messages: $newPrivateMessages"),
               const SizedBox(height: 8),
               Text("New group messages: $newGroupMessages"),
              
              ],
    

            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          );
        },
      );
    },
  );
}

}