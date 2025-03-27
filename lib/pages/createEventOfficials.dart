import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EventFormScreen extends StatefulWidget {
  const EventFormScreen({super.key});

  @override
  _EventFormScreenState createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController universityIdController = TextEditingController();
  final TextEditingController eventTitleController = TextEditingController();
  final TextEditingController eventContentController = TextEditingController();
  DateTime? selectedDate;
  String selectedParticipationType = 'Organizer'; // Default value

  @override
  void dispose() {
    nameController.dispose();
    universityIdController.dispose();
    eventTitleController.dispose();
    eventContentController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  // Function to submit the form to the PHP server
  void _submitForm() async {
    String name = nameController.text.trim();
    String universityId = universityIdController.text.trim();
    String eventTitle = eventTitleController.text.trim();
    String eventContent = eventContentController.text.trim();
    String date = selectedDate != null
        ? DateFormat('yyyy-MM-dd').format(selectedDate!)
        : "No date selected";
    String participationType = selectedParticipationType;
    String timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    if (name.isEmpty || universityId.isEmpty || eventTitle.isEmpty || eventContent.isEmpty) {
      _showErrorDialog("Please fill in all required fields.");
      return;
    }

    // Prepare JSON data for the request
    Map<String, String> data = {
      'activityName': name,
      'activityHostID': universityId,
      'activityDate': date,
      'participationType': participationType,
      'timestamp': timestamp,
      'CONTENT': eventContent,
    };

    // Send data to PHP backend via POST request
    var response = await http.post(
      Uri.parse('http://172.19.41.196/public_html/FlutterGrad/officials_new_event.php'), 
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );

    // Handle the response from the server
    if (response.statusCode == 200) {
      var responseData = json.decode(response.body);
      if (responseData['status'] == 'success') {
        _showSuccessDialog(responseData['message']);
      } else {
        _showErrorDialog(responseData['message']);
      }
    } else {
      _showErrorDialog("Failed to submit event. Please try again.");
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Success"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Error"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text("Create New Event"),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.green,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             _buildTextField(
                "Event Title *", eventTitleController, "Enter event title"),
           // _buildTextField("Name *", nameController, "Enter your full name"),
            _buildTextField(
                "University ID *", universityIdController, "Enter Host university ID"),
           
            _buildTextField("Event Content *", eventContentController,
                "Enter event content", maxLines: 4),

            // Date Picker
            SizedBox(height: 10),
            Text("Date"),
            Row(
              children: [
                Text(
                  selectedDate == null
                      ? "No date selected"
                      : DateFormat('yyyy-MM-dd').format(selectedDate!),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => _selectDate(context),
                  child: Text("Pick Date"),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Participation Type Dropdown
            Text("Participation Type"),
            DropdownButton<String>(
              value: selectedParticipationType,
              onChanged: (String? newValue) {
                setState(() {
                  selectedParticipationType = newValue!;
                });
              },
              items: <String>['Organizer', 'Participate']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            SizedBox(height: 20),

            // Submit Button
            Center(
              child: ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                ),
                child: Text("Submit", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: "Explore"),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: "Messaging",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      String hintText, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hintText,
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
