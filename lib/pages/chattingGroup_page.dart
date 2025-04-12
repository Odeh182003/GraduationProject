import 'dart:convert';
//import 'package:bzu_leads/pages/profile_page.dart';
import 'package:bzu_leads/pages/settingsPage.dart';
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
  Set<String> uniqueGroupIDs = {}; // Ensuring uniqueness by ID
  List<Map<String, dynamic>> fetchedGroups = [];
  try {
    var url = Uri.parse("http://localhost/public_html/FlutterGrad/login.php?universityID=$_currentUserID");
    var response = await http.get(url);
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if (data['success']) {
        await prefs?.setString("username", data['username']);
        await prefs?.setStringList("roles", List<String>.from(data['roles']));

        if (data['studentData'] != null) {
          _userSections = List<String>.from(data['studentData']['sectionIDs'] ?? []);
          await prefs?.setStringList("sectionIDs", _userSections);
        }

        // Process department clubs as head
        if (data['departmentClubHeadData'] != null) {
          List<dynamic> clubs = data['departmentClubHeadData']['clubs'] ?? [];
          for (var club in clubs) {
            String uniqueID = "dep_${club['clubID']}";
            if (!uniqueGroupIDs.contains(uniqueID)) {
              uniqueGroupIDs.add(uniqueID);
              fetchedGroups.add({
                'groupID': uniqueID,
                'groupName': club['clubName'],
                'department': club['departmentName'],
              });
            }
          }
        }

        // Process department clubs as members
        if (data['departmentClubMemberData'] != null) {
          List<dynamic> memberClubs = data['departmentClubMemberData']['clubs'] ?? [];
          for (var club in memberClubs) {
            String uniqueID = "dep_${club['clubID']}";
            if (!uniqueGroupIDs.contains(uniqueID)) {
              uniqueGroupIDs.add(uniqueID);
              fetchedGroups.add({
                'groupID': uniqueID,
                'groupName': club['clubName'],
                'department': club['departmentName'],
              });
            }
          }
        }
        if (data['studentClub'] != null) {
          String studentClubID = data['studentClub']['studentclubID'];
          String studentClubName = data['studentClub']['studentclubname'];
          String uniqueID = "stud_$studentClubID";
          
          if (!uniqueGroupIDs.contains(uniqueID)) {
            uniqueGroupIDs.add(uniqueID);
            fetchedGroups.add({
              'groupID': uniqueID,
              'groupName': studentClubName,
            });
          }
        }
        // Fetch groups based on role
        if (data['roles']?.contains('student') && _userSections.isNotEmpty) {
          for (String sectionID in _userSections) {
            var sectionUrl = Uri.parse("http://localhost/public_html/FlutterGrad/chatting_groups.php?section_id=$sectionID");
            var sectionResponse = await http.get(sectionUrl);
            if (sectionResponse.statusCode == 200) {
              var sectionData = jsonDecode(sectionResponse.body);
              if (sectionData['success']) {
                String uniqueID = "${sectionData['groupName']}_sec_$sectionID";
                if (!uniqueGroupIDs.contains(uniqueID)) {
                  uniqueGroupIDs.add(uniqueID);
                  fetchedGroups.add({
                    'groupID': uniqueID,
                    'groupName': sectionData['groupName'],
                    'students': sectionData['groupMembers'],
                    'academicID': sectionData['academicID'] ?? "Unknown",
                  });
                }
              }
            }
          }
        }

        if (data['roles']?.contains('academic') ?? false) {
  var academicUrl = Uri.parse("http://localhost/public_html/FlutterGrad/chatting_groups.php?academic_id=$_currentUserID");
  var academicResponse = await http.get(academicUrl);
  if (academicResponse.statusCode == 200) {
    var academicData = jsonDecode(academicResponse.body);
    if (academicData['success']) {
      for (var section in academicData['sections']) {
        String uniqueID = "${section['courseName']} - Section ${section['sectionID']}_sec_${section['sectionID']}";


                if (!uniqueGroupIDs.contains(uniqueID)) {
                  uniqueGroupIDs.add(uniqueID);
                  fetchedGroups.add({
                    'groupID': uniqueID,
                    'groupName': "${section['courseName']} - Section ${section['sectionID']}",
                    'courseID': section['courseID'].toString(),
                  });
                }
              }
            }
          }
        }

        if (data['roles']?.contains('official') ?? false) {
          var officialUrl = Uri.parse("http://localhost/public_html/FlutterGrad/chatting_groups.php?official_id=$_currentUserID");
          var officialResponse = await http.get(officialUrl);
          if (officialResponse.statusCode == 200) {
            var officialData = jsonDecode(officialResponse.body);
            if (officialData['success']) {
              for (var group in officialData['officialGroups'] ?? []) {
                String uniqueID = "official_${group['groupID']}";
                if (!uniqueGroupIDs.contains(uniqueID)) {
                  uniqueGroupIDs.add(uniqueID);
                  fetchedGroups.add({
                    'groupID': uniqueID,
                    'groupName': group['groupName'],
                    'members': group['members'] ?? [],
                  });
                }
              }
            }
          }
        }
      }
    }
    setState(() {
      _groups = fetchedGroups;
    });
  } catch (e) {
    print("Error fetching groups: $e");
  }
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
