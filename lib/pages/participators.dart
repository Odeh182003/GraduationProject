import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Participators extends StatefulWidget {
  final String userID;

  Participators({required this.userID});

  @override
  _Participators createState() => _Participators();
}

class _Participators extends State<Participators> {
  List activities = [];
  bool isLoading = true;

  // Add filter state
  String selectedStatus = 'All';
  final List<String> statusOptions = ['All', 'Cancelled', 'Pending', 'Done'];

  @override
  void initState() {
    super.initState();
    fetchActivities();
  }

  Future<void> fetchActivities() async {
    final url = Uri.parse('http://192.168.10.3/public_html/FlutterGrad/fetch_activities.php');
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

// filepath: c:\Users\odehl\Desktop\bzu_leads\lib\pages\participators.dart
// ...existing code...

  Future<void> showParticipatorsDialog(String activityID) async {
    final participatorsUrl = Uri.parse('http://192.168.10.3/public_html/FlutterGrad/participators.php');
    final requestsUrl = Uri.parse('http://192.168.10.3/public_html/FlutterGrad/activity_requests.php?activityID=$activityID');

    final payload = {
      "activityID": activityID,
      "userID": widget.userID,
    };

    try {
      // Fetch accepted participators
      final participatorsResponse = await http.post(
        participatorsUrl,
        headers: {"Content-Type": "application/json"},
        body: json.encode(payload),
      );
      final participatorsData = json.decode(participatorsResponse.body);

      // Fetch pending requests
      final requestsResponse = await http.get(requestsUrl);
      final requestsData = json.decode(requestsResponse.body);

      if (participatorsData['status'] == 'success' && requestsData['status'] == 'success') {
        List participators = participatorsData['participators'];
        List requests = requestsData['requests'];

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Participators'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (requests.isNotEmpty) ...[
                      Text("Pending Requests", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: requests.length,
                        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[300]),
                        itemBuilder: (context, index) {
                          final r = requests[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.orange[100],
                              child: Icon(Icons.hourglass_top, color: Colors.orange[800]),
                            ),
                            title: Text(r['username'] ?? 'Unknown', style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('User ID: ${r['userID']}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.check, color: Colors.green),
                                  tooltip: "Accept",
                                  onPressed: () async {
                                    await handleRequest(r['requestID'], 'accept');
                                    Navigator.pop(context);
                                    showParticipatorsDialog(activityID);
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.close, color: Colors.red),
                                  tooltip: "Reject",
                                  onPressed: () async {
                                    await handleRequest(r['requestID'], 'reject');
                                    Navigator.pop(context);
                                    showParticipatorsDialog(activityID);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      Divider(),
                    ],
                    Text("Accepted Participators", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    participators.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text("No participators yet."),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: participators.length,
                            separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[300]),
                            itemBuilder: (context, index) {
                              final p = participators[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.green[100],
                                  child: Icon(Icons.person, color: Colors.green[800]),
                                ),
                                title: Text(p['username'] ?? 'Unknown', style: TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('User ID: ${p['userID']}'),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Close"),
              )
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading participators or requests.")),
        );
      }
    } catch (e) {
      print("Error fetching participators or requests: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching participators or requests.")),
      );
    }
  }

  Future<void> handleRequest(int requestID, String action) async {
    final url = Uri.parse('http://192.168.10.3/public_html/FlutterGrad/handle_request_participation.php');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "requestID": requestID,
          "action": action,
        }),
      );
      final jsonData = json.decode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(jsonData['message'])),
      );
    } catch (e) {
      print('Error handling request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error handling request.')),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    // Filter activities based on selected status
    List filteredActivities = selectedStatus == 'All'
        ? activities
        : activities.where((a) {
            final status = a['status']?.toString().toLowerCase();
            if (selectedStatus == 'Pending') {
              // Handle possible typo in status value
              return status == 'pending' || status == 'pendding';
            }
            return status == selectedStatus.toLowerCase();
          }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.green,
        elevation: 1,
        title: Row(
          children: [
            Image.asset('assets/logo.png', height: 40),
            const SizedBox(width: 8),
            const Text("Available Activities", style: TextStyle(color: Colors.green)),
          ],
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : activities.isEmpty
              ? Center(child: Text('No activities available.'))
              : Column(
                  children: [
                    // Status filter dropdown aligned to the right
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Spacer(),
                          Text("Status: ",
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.green[800],
                              )),
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedStatus,
                                items: statusOptions
                                    .map((status) => DropdownMenuItem(
                                          value: status,
                                          child: Text(status),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      selectedStatus = value;
                                    });
                                  }
                                },
                                style: TextStyle(
                                  color: Colors.green[900],
                                  fontWeight: FontWeight.w500,
                                ),
                                dropdownColor: Colors.green[50],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: filteredActivities.isEmpty
                          ? Center(child: Text('No activities for selected status.'))
                          : ListView.builder(
                              itemCount: filteredActivities.length,
                              itemBuilder: (context, index) {
                                final activity = filteredActivities[index];
                                Color statusColor;

                                switch (activity['status']) {
                                  case 'Done':
                                    statusColor = Colors.brown;
                                    break;
                                  case 'Cancelled':
                                    statusColor = Colors.red;
                                    break;
                                  case 'Pendding':
                                  case 'Pending':
                                  default:
                                    statusColor = Colors.green;
                                    break;
                                }

                                // Check if current user is the host of this activity
                                final bool isHost = activity['activityHostID'].toString() == widget.userID;

                                return Card(
                                  margin: EdgeInsets.all(10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
                                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            Text(
                                              'Status: ${activity['status']}',
                                              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold,fontSize: 24),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        Text('Date: ${activity['activityDate']}',style: TextStyle(fontSize: 18),),
                                        
                                        SizedBox(height: 8),
                                        Text('Details: ${activity['CONTENT']}',style: TextStyle(fontSize: 19),),
                                        SizedBox(height: 8),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: ElevatedButton(
                                            onPressed: isHost
                                                ? () {
                                                    showParticipatorsDialog(activity['activityID']);
                                                  }
                                                : null, // Disabled for non-hosts
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                            ),
                                            child: Text('Participators'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
