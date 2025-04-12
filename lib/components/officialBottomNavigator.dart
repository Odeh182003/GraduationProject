import 'package:flutter/material.dart';
//import 'package:bzu_leads/pages/chattingGroup_page.dart';
//import 'package:bzu_leads/pages/profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfficialBottomNavigator extends StatefulWidget {
  final Function(int) onPageChanged; // Callback for page switching
  final int currentIndex; // Current selected page index

  const OfficialBottomNavigator({super.key, required this.onPageChanged, required this.currentIndex});

  @override
  _OfficialBottomNavigatorState createState() => _OfficialBottomNavigatorState();
}

class _OfficialBottomNavigatorState extends State<OfficialBottomNavigator> {
  String? userID; // Store user ID

  @override
  void initState() {
    super.initState();
    getUserID();
  }

  // Fetch user's university ID from SharedPreferences
  Future<void> getUserID() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userID = prefs.getString("universityID");
    });
  }

  void _onItemTapped(int index) async {
    if (index == 2) { // If user taps Profile
      if (userID == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User ID not found. Please log in again.")),
        );
        return; // Don't navigate if user is not logged in
      }
    }
    widget.onPageChanged(index);
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: widget.currentIndex,
      onTap: _onItemTapped,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.message), label: "Chat Groups"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
      ],
    );
  }
}
