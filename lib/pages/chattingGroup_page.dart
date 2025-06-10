import 'dart:convert';

import 'package:bzu_leads/services/ApiConfig.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import 'package:bzu_leads/components/user_tile.dart';
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
  String? _role;
  SharedPreferences? _prefs;
  bool _isLoading = true; // Add loading state

  @override
  void initState() {
    super.initState();
    _initializePreferences();
  }

  Future<void> _initializePreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final universityID = _prefs?.getString("universityID");
    final roleJson = _prefs?.getString("role");

    if (universityID != null && roleJson != null) {
      final decodedRoles = List<String>.from(jsonDecode(roleJson));

      setState(() {
        _currentUserID = universityID;
        _role = decodedRoles.contains("academic")
            ? "academic"
            : decodedRoles.contains("official")
                ? "official"
                : null;
      });
      print("Decoded Roles: $decodedRoles");
      _fetchGroups();
    }
  }

  Future<void> _fetchGroups() async {
    if (_currentUserID == null) return;
    setState(() {
      _isLoading = true;
    });
    final groups = await GroupService.getChatGroups(_currentUserID!);
    setState(() {
      _groups = groups;
      _isLoading = false;
    });
  }
bool _isCreating = false;
  Future<void> createGroups() async {
  if (_isCreating) return; // Prevent double-tap

  setState(() {
    _isCreating = true;
  });

  if (_currentUserID != null && (_role == "academic" || _role == "official")) {
    final response = await GroupService.createGroups(_currentUserID!, _role!);
    print("Assigned Role: $_role");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(response['message'] ?? "Something happened")),
    );

    if (response['success']) {
      _fetchGroups(); // Refresh the list if successful
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
        "Chatting Groups Page",
        style: TextStyle(
          color: Colors.green, // Ensure text color matches your theme
        ),
      ),
    ],
  ),
    ),
    body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _groups.isEmpty
              ? const Center(
                  child: Text(
                    "No Groups found",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: _groups.length,
                  itemBuilder: (context, index) {
                    final group = _groups[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 3,
                      child: ListTile(
                        title: Text(
                          group['groupName'],
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        onTap: () => _navigateToChattingPage(group),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.green),
                      ),
                    );
                  },
                ),
    floatingActionButton: (_role == "academic" || _role == "official")
        ? FloatingActionButton(
            onPressed: createGroups,
            backgroundColor: Colors.green,
            child: const Icon(Icons.group_add),
          )
        : null,
  );
}
void _navigateToChattingPage(Map<String, dynamic> group) {
  String? senderUsername = _prefs?.getString("username");
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
}

/* Widget _buildGroupListItem(Map<String, dynamic> group) {
    return UserTile(
      text: group['groupName'],
      onTap: () async {
        String? senderUsername = _prefs?.getString("username");
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
  }*/
}
