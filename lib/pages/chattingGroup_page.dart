//import 'dart:convert';
//import 'package:bzu_leads/pages/profile_page.dart';
import 'package:bzu_leads/pages/settingsPage.dart';
import 'package:flutter/material.dart';
//import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bzu_leads/components/user_tile.dart';
import 'package:bzu_leads/pages/chatting_page.dart';
import 'package:bzu_leads/services/group_service.dart';
class ChattingGroupPage extends StatefulWidget {
  const ChattingGroupPage({super.key});

  @override
  _ChattingGroupPageState createState() => _ChattingGroupPageState();
}

class _ChattingGroupPageState extends State<ChattingGroupPage> {
  
  List<Map<String, dynamic>> _groups = [];
  String? _currentUserID;
  List<String> _userSections = [];
  String? _role;
  SharedPreferences? prefs;

  @override
  void initState() {
    super.initState();
    _initializePreferences();
  }

  Future<void> _initializePreferences() async {
    prefs = await SharedPreferences.getInstance();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    setState(() {
      _currentUserID = prefs?.getString("universityID");
      _userSections = prefs?.getStringList("sectionIDs") ?? [];
      _role = prefs?.getString("role");
    });

    if (_currentUserID != null && _role != null) {
      _fetchGroups();
    }
  }

Future<void> _fetchGroups() async {
  if (_currentUserID == null) return;

  final groups = await GroupService.getChatGroups(_currentUserID!);
  setState(() {
    _groups = groups;
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text("Chatting Groups"),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.green,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => settingsPage()),
              );
            },
          ),
          
        ],
      ),
      body: _buildGroupList(),
    );
  }

 Widget _buildGroupList() {
  if (_groups.isEmpty) {
    return  Center(
      child:CircularProgressIndicator()
    );
  }else{
    return ListView.builder(
    itemCount: _groups.length,
    itemBuilder: (context, index) {
      var group = _groups[index];
      return _buildGroupListItem(group, context);
    },
  );
  }
  
}


  Widget _buildGroupListItem(Map<String, dynamic> group, BuildContext context) {
    return UserTile(
      text: group['groupName'],
      onTap: () async {
        String? senderUsername = prefs?.getString("username");
        if (senderUsername == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error: User not authenticated")),
          );
          return;
        }
         print("Navigating to chat with group ID: ${group['groupID']}");
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
        
      },
    );
  }
}
