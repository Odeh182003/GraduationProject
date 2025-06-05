import 'package:bzu_leads/pages/chatting_private_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AcademicRoomPage extends StatefulWidget {
  const AcademicRoomPage({Key? key}) : super(key: key);

  @override
  State<AcademicRoomPage> createState() => _AcademicRoomPageState();
}

class _AcademicRoomPageState extends State<AcademicRoomPage> {
  List academics = [];
  bool isLoading = true;
  String message = "Loading...";

  @override
  void initState() {
    super.initState();
    fetchAcademics();
  }

  Future<void> fetchAcademics() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? facultyID = prefs.getString("facultyID");
    if (facultyID == null) {
      setState(() {
        isLoading = false;
        message = "Faculty ID not found.";
      });
      return;
    }

    final url = Uri.parse('http://192.168.10.3/public_html/FlutterGrad/academicsInfo.php?facultyID=$facultyID');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['status'] == 'success') {
          setState(() {
            academics = jsonData['academics'];
            isLoading = false;
          });
        } else {
          setState(() {
            message = jsonData['message'] ?? "No academics found.";
            isLoading = false;
          });
        }
      } else {
        setState(() {
          message = "Failed to load data.";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        message = "Error loading data.";
        isLoading = false;
      });
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
              height: 40,
            ),
            const SizedBox(width: 8),
            const Text(
              "Academics' Information",
              style: TextStyle(color: Colors.green),
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : academics.isEmpty
              ? Center(child: Text(message))
              : ListView.builder(
                  itemCount: academics.length,
                  itemBuilder: (context, index) {
                    final academic = academics[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                      child: ListTile(
                        leading: const Icon(Icons.person, color: Colors.green, size: 36),
                        title: Text(
                          academic['name'] ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Office Hours: ${academic['officeHours'] ?? 'N/A'}", style: const TextStyle(fontSize: 18)),
                            Text("Room: ${academic['room'] ?? 'N/A'}", style: const TextStyle(fontSize: 20)),
                          ],
                        ),
                        trailing: ElevatedButton.icon(
                          icon: const Icon(Icons.chat, color: Colors.black),
                          label: const Text("Chat", style: TextStyle(color: Colors.black),),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () async {
                            SharedPreferences prefs = await SharedPreferences.getInstance();
                            String? studentId = prefs.getString("universityID");
                            String? studentName = prefs.getString("username");
                            // Use academicID as peerId
                            String academicId = academic['academicID'].toString();
                            String academicName = academic['name'] ?? 'Unknown';

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PrivateChattingPage(
                                  peerId: academicId,
                                  peerName: academicName,
                                  currentUserId: studentId ?? '',
                                  currentUserName: studentName ?? '',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
