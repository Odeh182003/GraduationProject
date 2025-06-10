import 'package:bzu_leads/services/ApiConfig.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Participate extends StatefulWidget {
  final String userID; // Pass current logged-in user's ID

  Participate({required this.userID});

  @override
  _Participate createState() => _Participate();
}

class _Participate extends State<Participate> {
  List activities = [];
  bool isLoading = true;

  // Add filter state
  String selectedStatus = 'All';
  final List<String> statusOptions = ['All', 'Cancelled', 'Pending', 'Done'];

  // Track participation status for each activity
  Map<String, dynamic> participationStatus = {}; // activityID -> {status, reason, count}

  @override
  void initState() {
    super.initState();
    fetchActivities();
    fetchParticipationStatuses();
  }

  Future<void> fetchActivities() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/fetch_activities.php');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['status'] == 'success' && mounted) {
          setState(() {
            activities = jsonData['activities'];
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching activities: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // Fetch participation status for this user for all activities
  Future<void> fetchParticipationStatuses() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/user_participation_status.php?userID=${widget.userID}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['status'] == 'success' && mounted) {
          setState(() {
            // Map: activityID -> {status, reason, count}
            participationStatus = Map<String, dynamic>.from(jsonData['statuses']);
          });
        }
      }
    } catch (e) {
      print('Error fetching participation statuses: $e');
    }
  }

  // Send participation request (not direct participation)
  bool isSubmitting = false;

Future<void> participateInActivity(String activityID) async {
  if (isSubmitting) return;
  setState(() => isSubmitting = true);
  final url = Uri.parse('${ApiConfig.baseUrl}/request_participation.php');
  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "userID": widget.userID,
        "activityID": activityID,
      }),
    );
    final jsonData = json.decode(response.body);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(jsonData['message'] ?? 'Request sent.')),
      );
    }
    fetchParticipationStatuses();
  } catch (e) {
    print('Error sending participation request: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending participation request.')),
      );
    }
  } finally {
    setState(() => isSubmitting = false);
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
            Image.network(
        ApiConfig.systemLogoUrl,
        height: 40,
        errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image),
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

                                // Participation status for this activity
                                final Map<String, dynamic>? partStatus = participationStatus[activity['activityID'].toString()];
                                final String status = partStatus?['status'] ?? '';
                                final String? rejectionReason = partStatus?['rejection_reason'];
                                final int rejectionCount = (partStatus?['rejection_count'] ?? 0) as int;

                                Widget participationSection;
                                if (status == 'pending') {
                                  participationSection = Row(
                                    children: [
                                      Icon(Icons.hourglass_top, color: Colors.orange),
                                      SizedBox(width: 6),
                                      Text(
                                        "Your participation is pending approval.",
                                        style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  );
                                } else if (status == 'accepted') {
                                  participationSection = Row(
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.green),
                                      SizedBox(width: 6),
                                      Text(
                                        "Your participation is accepted!",
                                        style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  );
                                } else if (status == 'rejected') {
  if (rejectionCount >= 3) {
    participationSection = Text(
      "You have reached the maximum participation attempts.",
      style: TextStyle(color: Colors.grey[600]),
    );
  } else {
    participationSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.cancel, color: Colors.red),
            SizedBox(width: 6),
            Text(
              "Your participation was rejected.",
              style: TextStyle(color: Colors.red[800], fontWeight: FontWeight.w600),
            ),
          ],
        ),
        if (rejectionReason != null)
          Padding(
            padding: const EdgeInsets.only(left: 28.0, top: 4),
            child: Text(
              "Reason: $rejectionReason",
              style: TextStyle(color: Colors.grey[700], fontStyle: FontStyle.italic),
            ),
          ),
        Text(
          "Rejection Count: $rejectionCount",
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: (activity['status'] == 'Done' || activity['status'] == 'Cancelled')
                ? null
                : () {
                    participateInActivity(activity['activityID']);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Participate'),
          ),
        ),
      ],
    );
  }
} else if (status == 'participated') {
                                  participationSection = Row(
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.blue),
                                      SizedBox(width: 6),
                                      Text(
                                        "You have already participated in this activity.",
                                        style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  );
                                } else {
                                  // Check rejection count
                                  if (rejectionCount >= 3) {
                                    participationSection = Text(
                                      "You have reached the maximum participation attempts.",
                                      style: TextStyle(color: Colors.grey[600]),
                                    );
                                  } else {
                                    participationSection = Align(
                                      alignment: Alignment.centerRight,
                                      child: ElevatedButton(
                                        onPressed: (activity['status'] == 'Done' || activity['status'] == 'Cancelled')
                                            ? null // Disable button if activity is Done or Cancelled
                                            : () {
                                                participateInActivity(activity['activityID']);
                                              },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Participate'),
                                      ),
                                    );
                                  }
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
                                            Text(
                                              'Status: ${activity['status']}',
                                              style: TextStyle(
                                                color: statusColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        Text('Date: ${activity['activityDate']}'),
                                        SizedBox(height: 8),
                                        //Text('Type: ${activity['participationType']}'),
                                        //SizedBox(height: 8),
                                        Text('Details: ${activity['CONTENT']}'),
                                        SizedBox(height: 12),
                                        participationSection,
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
