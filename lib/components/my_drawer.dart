/*import 'package:bzu_leads/pages/chattingGroup_page.dart';
import 'package:bzu_leads/pages/createPostsStudents.dart';
import 'package:bzu_leads/pages/private_posts.dart';
import 'package:bzu_leads/pages/profile_page.dart';
//import 'package:bzu_leads/pages/chatting_page.dart';
import 'package:bzu_leads/pages/settingsPage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
class MyDrawer extends StatelessWidget{
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
          SizedBox(height: 10.0),
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
          SizedBox(height: 10.0),
      
SizedBox(height: 10.0),
          Padding(
  padding: const EdgeInsets.only(left: 25.0),
  child: ListTile(
    title: Text('Chatting Groups'),
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

          SizedBox(height: 10.0),
          Padding(padding: const EdgeInsets.only(left: 25.0),
          child: ListTile(
            title: Text('Private Posts'),
            leading: Icon(Icons.settings),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PrivatePosts())
              );
            },
          ),
          ),
          SizedBox(height: 10.0),
          Padding(padding: const EdgeInsets.only(left: 25.0),
          child: ListTile(
            title: Text('Create new Post'),
            leading: Icon(Icons.new_releases),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Createpostsstudents())
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