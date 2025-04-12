import 'package:bzu_leads/components/officialBottomNavigator.dart';
import 'package:bzu_leads/pages/OfficialNotification.dart';
//import 'package:bzu_leads/components/official_drawer.dart';
import 'package:bzu_leads/pages/chattingGroup_page.dart';
import 'package:bzu_leads/pages/createEventOfficials.dart';
import 'package:bzu_leads/pages/PostFormScreen.dart';
import 'package:bzu_leads/pages/postsDetails.dart';
import 'package:bzu_leads/pages/private_posts.dart';
import 'package:bzu_leads/pages/profile_page.dart';
import 'package:bzu_leads/pages/settingsPage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
//import 'package:shared_preferences/shared_preferences.dart';

class Officialsdashboard extends StatefulWidget {
  const Officialsdashboard({super.key});

  @override
  _Officialsdashboard createState() => _Officialsdashboard();
}

class _Officialsdashboard extends State<Officialsdashboard> {
  List<dynamic> posts = [];
  int _selectedIndex = 0;
  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  Future<void> fetchPosts() async {
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
    Officialsdashboard(), // Home page
    ChattingGroupPage(), // Chatting groups
    ProfilePage(), // User profile
  ];
  void _changePage(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
       backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _selectedIndex == 0
          ? AppBar(
              title: const Text("Officials' Public Posts"),
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.green,
              elevation: 0,
              actions: [
          PopupMenuButton<String>(
      icon: Icon(Icons.more_vert),
      onSelected: (String value) {
        switch (value) {
         
          case 'Private Posts':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PrivatePosts()),
            );
            break;
             case 'Create new Post':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PostFormScreen()),
            );
            break;
            case 'Create new Event':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => EventFormScreen()),
            );
            break;
            case 'Officials\' Notification':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Officialnotification()),
            );
            break;
          case 'Settings':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => settingsPage()),
            );
            break;
          
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        
        PopupMenuItem<String>(
          value: 'Private Posts',
          child: ListTile(
            leading: Icon(Icons.settings),
            title: Text('Private Posts'),
          ),
        ),
        PopupMenuItem<String>(
          value: 'Create new Post',
          child: ListTile(
            leading: Icon(Icons.create),
            title: Text('Create new Post'),
          ),
        ),
        PopupMenuItem<String>(
          value: 'Create new Event',
          child: ListTile(
            leading: Icon(Icons.create),
            title: Text('Create new Event'),
          ),
        ),
        PopupMenuItem<String>(
          value: 'Officials\' Notification',
          child: ListTile(
            leading: Icon(Icons.create),
            title: Text('Officials\' Notification'),
          ),
        ),
        PopupMenuItem<String>(
          value: 'Settings',
          child: ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
          ),
        ),
        
      ],
    ),
  ],
            )
          : null, 
     // drawer:  AcademicDrawer(),
      body: _selectedIndex == 0
          ? (posts.isEmpty
              ? const Center(child: CircularProgressIndicator())
      : ListView.builder(
    padding: EdgeInsets.all(10),
    itemCount: posts.length,
    itemBuilder: (context, index) {
      final post = posts[index];

      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Postsdetails(postID: int.parse(post['postID'])),
            ),
          );
        },
        child: Card(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.symmetric(vertical: 10),
          child: Padding(
            padding: EdgeInsets.all(15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile icon or placeholder
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.blueGrey[100],
                  child: Icon(Icons.person, color: Colors.white),
                ),
                SizedBox(width: 12),

                // Post details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Username
                      Text(
                        post['posttitle'],
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 5),

                      // Post content
                      Text(
                        post['CONTENT'],
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                      SizedBox(height: 10),

                      // Post date
                      Text(
                        "Created on: ${post['DATECREATED']}",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 10),
                Text(
                        "${post['username']}",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                SizedBox(width: 10),

                // Post media (if available)
                Image.network(
                  "http://localhost/public_html/FlutterGrad/${post['media']}",
                  height: 80,
                  width: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.image_not_supported, size: 50, color: Colors.grey);
                  },
                ),
              ],
            ),
          ),
        ),
      );
    },
  ))
          : _pages[_selectedIndex],
           bottomNavigationBar: OfficialBottomNavigator(
        onPageChanged: _changePage,
        currentIndex: _selectedIndex,
      ), 
           
    );
  }
}
