import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Editactivity extends StatefulWidget {
  final String userID; // Pass current logged-in user's ID

  Editactivity({required this.userID});

  @override
  _Editactivity createState() => _Editactivity();
}

class _Editactivity extends State<Editactivity> {
  List activities = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchActivities();
  }

  Future<void> fetchActivities() async {
    final url = Uri.parse('http://192.168.10.5/public_html/FlutterGrad/fetch_activities.php');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['status'] == 'success') {
          setState(() {
            activities = jsonData['activities'];
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching activities: $e');
      setState(() {
        isLoading = false;
      });
    }
  }
Future<void> updateActivityStatus(String activityID, String newStatus) async {
  final url = Uri.parse('http://192.168.10.5/public_html/FlutterGrad/update_activity_status.php');
  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "activityID": activityID,
        "status": newStatus,
      }),
    );
    final jsonData = json.decode(response.body);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(jsonData['message'])),
    );

    if (jsonData['status'] == 'success') {
      fetchActivities(); // Refresh
    }
  } catch (e) {
    print('Error updating status: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error updating status.')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
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
        "Available Activities",
        style: TextStyle(
          color: Colors.green, // Ensure text color matches your theme
        ),
      ),
    ],
  ),
     ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : activities.isEmpty
              ? Center(child: Text('No activities available.'))
              : ListView.builder(
                  itemCount: activities.length,
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    Color statusColor;

  switch (activity['status']) {
    case 'Done':
      statusColor = Colors.brown;
      break;
    case 'Cancelled':
      statusColor = Colors.red;
      break;
    case 'Pendding':
    default:
      statusColor = Colors.green;
      break;
  }
return Card(
  margin: EdgeInsets.all(10),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(15),
  ),
  elevation: 5,
  child: Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                activity['activityName'],
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Column(
             children: [
              Text(
  'Status: ${activity['status']}',
  style: TextStyle(
    color: statusColor,
    fontWeight: FontWeight.bold,
  ),
),
Text('Expiry: ${activity['expiryDate']}'),
             ] ,
            ),
            
          ],
        ),
        SizedBox(height: 8),
        Text('Date: ${activity['activityDate']}'),
        SizedBox(height: 8),
        Text('Type: ${activity['participationType']}'),
        SizedBox(height: 8),
        Text('Details: ${activity['CONTENT']}'),
        SizedBox(height: 8),
        Align(
  alignment: Alignment.centerRight,
  child: ElevatedButton(
    onPressed: (activity['status'] == 'Done' || activity['status'] == 'Cancelled')
        ? null
        : () => updateActivityStatus(activity['activityID'], 'Cancelled'),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.red,
      foregroundColor: Colors.white,
    ),
    child: const Text('Cancel'),
  ),
),

      ],
    ),
  ),
);

                  },
                ),
    );
  }
}
