/*import 'package:bzu_leads/pages/OfficialNotification.dart';
import 'package:bzu_leads/pages/chattingGroup_page.dart';
import 'package:bzu_leads/pages/createEventOfficials.dart';
import 'package:bzu_leads/pages/PostFormScreen.dart';
//import 'package:bzu_leads/pages/chatting_page.dart';
import 'package:bzu_leads/pages/settingsPage.dart';
import 'package:flutter/material.dart';
import'package:bzu_leads/pages/profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
class OfficialDrawer extends StatelessWidget{
  const OfficialDrawer({super.key});

  Future<void> logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear stored session data

    // Navigate to login screen and remove all previous routes
    Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
  }
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.background,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
         Column(
          children: [
             DrawerHeader(
            child: Center(
              child: Icon(
                Icons.message, color: Theme.of(context).colorScheme.primary,
                size: 40,
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.only(left: 25.0),
          child: ListTile(
            title: Text('H O M E'),
            leading: Icon(Icons.home),
            onTap: () {
              //pop the drawer
              Navigator.pop(context);
            },
          ),
          ),
           Padding(
  padding: const EdgeInsets.only(left: 25.0),
  child: ListTile(
    title: const Text('P R O F I L E'),
    leading: const Icon(Icons.person),
    onTap: () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userID = prefs.getString("universityID");

      if (userID != null) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProfilePage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User ID not found. Please log in again.")),
        );
      }
    },
  ),
),
          SizedBox(height: 10.0),
          Padding(padding: const EdgeInsets.only(left: 25.0),
          child: ListTile(
            title: Text('Settings'),
            leading: Icon(Icons.settings),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => settingsPage())
              );
            },
          ),
          ),
          SizedBox(height: 10.0),
          Padding(padding: const EdgeInsets.only(left: 25.0),
          child: ListTile(
            title: Text('Notifications'),
            leading: Icon(Icons.notifications),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Officialnotification())
              );
            },
          ),
          ),
          SizedBox(height: 10.0),
          Padding(padding: const EdgeInsets.only(left: 25.0),
          child: ListTile(
            title: Text('Create new Post'),
            leading: Icon(Icons.notifications),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PostFormScreen())
              );
            },
          ),
          ),
          SizedBox(height: 10.0),
          Padding(padding: const EdgeInsets.only(left: 25.0),
          child: ListTile(
            title: Text('Create new Event'),
            leading: Icon(Icons.notifications),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EventFormScreen())
              );
            },
          ),
          ),
          SizedBox(height: 10.0),
          Padding(
  padding: const EdgeInsets.only(left: 25.0),
  child: ListTile(
    title: Text('Chatting groups'),
    leading: Icon(Icons.chat),
    onTap: () {
      Navigator.pop(context);  // Close the drawer
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ChattingGroupPage()),
      );
    },
  ),
),

          ],
         ),
         Padding(padding: const EdgeInsets.only(left: 25.0, bottom: 25),
          child: ListTile(
            title: Text('L O G O U T'),
            leading: Icon(Icons.logout),
            onTap: ()=> logout(context),// waits for the user to tap on the logout button
          ),
          ),
        ],
      ),
    );
  }

}*/