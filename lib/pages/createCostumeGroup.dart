import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CreateCustomGroupScreen extends StatefulWidget {
  final int createdByUserID;
  final int roleID;

  const CreateCustomGroupScreen({required this.createdByUserID, required this.roleID});

  @override
  _CreateCustomGroupScreenState createState() => _CreateCustomGroupScreenState();
}

class _CreateCustomGroupScreenState extends State<CreateCustomGroupScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _selectedUsers = [];
  List<Map<String, dynamic>> _searchResults = [];

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    final response = await http.get(
      Uri.parse('http://192.168.10.5/public_html/FlutterGrad/search_users.php?query=$query'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> users = json.decode(response.body);
      setState(() {
        _searchResults = users
            .map((user) => {
                  'username': user['username'],
                  'universityID': user['universityID'],
                })
            .where((user) => !_selectedUsers.any((u) => u['universityID'] == user['universityID']))
            .toList();
      });
    } else {
      setState(() {
        _searchResults = [];
      });
    }
  }

  Future<void> _submitGroup() async {
    if (_groupNameController.text.isEmpty || _selectedUsers.isEmpty) return;

    final response = await http.post(
      Uri.parse('http://192.168.10.5/public_html/FlutterGrad/create_custom_group.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'groupName': _groupNameController.text,
        'createdBy': widget.createdByUserID,
        'roleID': widget.roleID,
        'members': _selectedUsers.map((u) => u['universityID']).toList(),
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Group Created Successfully!')));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create group.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom != 0;

    return Scaffold(
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
        "Create Costume Group",
        style: TextStyle(
          color: Colors.green, // Ensure text color matches your theme
        ),
      ),
    ],
  ),),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(), // dismiss keyboard on tap outside
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _groupNameController,
                decoration: InputDecoration(labelText: 'Group Name'),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search users',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.search),
                    onPressed: () => _searchUsers(_searchController.text),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onSubmitted: _searchUsers,
              ),
              SizedBox(height: 10),
              if (_searchResults.isNotEmpty)
                Container(
                  constraints: BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.all(8),
                    itemCount: _searchResults.length,
                    separatorBuilder: (_, __) => Divider(),
                    itemBuilder: (context, index) {
                      final user = _searchResults[index];
                      return ListTile(
                        title: Text(user['username']),
                        leading: CircleAvatar(child: Text(user['username'][0])),
                        trailing: IconButton(
                          icon: Icon(Icons.person_add, color: Colors.green),
                          onPressed: () {
                            setState(() {
                              _selectedUsers.add(user);
                              _searchResults.removeAt(index);
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: _selectedUsers.map((user) {
                  return Chip(
                    label: Text(user['username']),
                    onDeleted: () {
                      setState(() => _selectedUsers.remove(user));
                    },
                  );
                }).toList(),
              ),
              SizedBox(height: 20),
              if (!keyboardVisible) // hide button when keyboard is open
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _submitGroup,
                    icon: Icon(Icons.group_add, color: Colors.white),
                    label: Text('Create Group', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
