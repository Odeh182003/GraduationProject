import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bzu_leads/components/user_tile.dart';
import 'package:bzu_leads/pages/chatting_page.dart';

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

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserID = prefs.getString("universityID");
      _userSections = prefs.getStringList("sectionIDs") ?? [];
      _role = prefs.getString("role");
    });

    if (_currentUserID != null && _role != null) {
      _fetchGroups();
    }
  }

Future<void> _fetchGroups() async {
  List<Map<String, dynamic>> fetchedGroups = [];

  if (_role == 'student') {
    // Fetch groups based on sections for students
    for (String sectionID in _userSections) {
      var url = Uri.parse("http://172.19.41.196/public_html/FlutterGrad/chatting_groups.php?section_id=$sectionID");
      var response = await http.get(url);
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['success']) {
          fetchedGroups.add({
            'groupID': sectionID,
            'groupName': "${data['courseName']} - Section $sectionID",
            'students': data['Students'],
            'academicID': data['AcademicID'],
          });
        }
      } else {
        print("Failed to fetch groups for section ID: $sectionID");
      }
    }
  } else if (_role == 'academic') {
    // Fetch groups based on academic role
    // Example: Show all sections that the academic is associated with
    // The academic role has a list of sectionIDs, so we'll loop through and fetch the data
    for (String sectionID in _userSections) {
      var url = Uri.parse("http://172.19.41.196/public_html/FlutterGrad/chatting_groups.php?section_id=$sectionID");
      var response = await http.get(url);
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['success']) {
          fetchedGroups.add({
            'groupID': sectionID,
            'groupName': "${data['courseName']} - Section $sectionID",
            'students': data['Students'],
            'academicID': data['AcademicID'],
          });
        }
      } else {
        print("Failed to fetch groups for section ID: $sectionID");
      }
    }
  } else if (_role == 'official') {
    // Fetch student clubs for officials
    var url = Uri.parse("http://172.19.41.196/public_html/FlutterGrad/official_clubs.php?official_id=$_currentUserID");
    var response = await http.get(url);
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if (data['success']) {
        // The official is associated with student clubs
        for (var club in data['clubs']) {
          fetchedGroups.add({
            'clubID': club['studentclubID'],
            'clubName': club['studentclubname'],
            'memberSince': club['membersince'],
            'endDate': club['endDate'],
          });
        }
      }
    } else {
      print("Failed to fetch student clubs for official $_currentUserID");
    }
  }

  setState(() {
    _groups = fetchedGroups; // Assign the fetched groups to the local groups list
  });
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text("Chatting Groups"),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.green,
        elevation: 0,
      ),
      body: _buildGroupList(),
    );
  }

  Widget _buildGroupList() {
    if (_groups.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: _groups.length,
      itemBuilder: (context, index) {
        var group = _groups[index];
        return _buildGroupListItem(group, context);
      },
    );
  }

  Widget _buildGroupListItem(Map<String, dynamic> group, BuildContext context) {
    return UserTile(
      text: group['groupName'],
      onTap: () async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? senderUsername = prefs.getString("username");

        if (senderUsername == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error: User not authenticated")),
          );
          return;
        }

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
