import 'package:flutter/material.dart';
class Officialnotification extends StatefulWidget {
  const Officialnotification({super.key});

  @override
  _Officialnotification createState() => _Officialnotification();
}

// State class associated with NotificationsScreen
class _Officialnotification extends State<Officialnotification> {
  int _selectedIndex =
      0; // Variable to track the selected item in the bottom navigation bar

  // Function called when an item in the bottom navigation bar is tapped
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Updating the index based on the tapped item
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: Text("Official Notifications"),
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.green,
      elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(
              16.0,
            ), // Adding padding around the widget
            child: Row(
              
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 3, // Number of notifications to display
              itemBuilder: (context, index) {
                return NotificationCard(); // Creating a notification card for each item in the list
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex, // Tracks the currently selected item
        onTap: _onItemTapped, // Calls the function when an item is tapped
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: "Explore",
          ), // "Explore" tab
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: "Messaging",
          ), // "Messaging" tab
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ), // "Profile" tab
        ],
      ),
    );
  }
}

// Class to create a notification card
class NotificationCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ), // Setting margins around the card
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ), // Making card corners rounded
      child: Padding(
        padding: const EdgeInsets.all(16.0), // Adding padding inside the card
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start, // Aligning elements to the left
          children: [
            Row(
              mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween, // Distributing elements to opposite sides
              children: [
                Text(
                  "Student Name & ID", // Placeholder for student name and ID
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Icon(Icons.close, color: Colors.grey), // Close icon
              ],
            ),
            SizedBox(height: 4), // Spacing between text elements
            Text(
              "Message",
              style: TextStyle(color: Colors.grey),
            ), // Notification message text
            SizedBox(height: 10), // Spacing before buttons
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.end, // Aligning buttons to the right
              children: [
                ElevatedButton(
                  onPressed: () {}, // No action defined yet for "Approve"
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300], // Background color
                  ),
                  child: Text(
                    "Approve",
                    style: TextStyle(color: Colors.black),
                  ), // Button text
                ),
                SizedBox(width: 8), // Spacing between buttons
                ElevatedButton(
                  onPressed: () {}, // No action defined yet for "Reject"
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black, // Background color
                  ),
                  child: Text(
                    "Reject",
                    style: TextStyle(color: Colors.white),
                  ), // Button text
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
