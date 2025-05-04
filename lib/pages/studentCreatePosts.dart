import 'dart:convert';
import 'dart:io';
import 'package:bzu_leads/services/user_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class Studentcreateposts extends StatefulWidget {
  const Studentcreateposts({super.key});

  @override
  _Studentcreateposts createState() => _Studentcreateposts();
}

class _Studentcreateposts extends State<Studentcreateposts> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String _postType = 'public';
  File? _selectedImage;
  String? _userId;
  int? _facultyId;
  int? _selectedApproverId;
  List<Map<String, dynamic>> _approvers = [];

  @override
  void initState() {
    super.initState();
    _initUserAndFaculty();
  }

  Future<void> _initUserAndFaculty() async {
    _userId = await UserHelper.getUniversityID();
    if (_userId != null) {
      _facultyId = await UserHelper.getFacultyID(_userId!);
      _fetchApprovers(); // Fetch default (public) approvers on load
    }
  }

  Future<void> _fetchApprovers() async {
    if (_facultyId == null || _userId == null) return;
    Uri uri;
    if(kIsWeb){
      uri = Uri.parse("http://localhost/public_html/FlutterGrad/getApprovers.php");
    } else {
      uri = Uri.parse("http://172.19.20.206/public_html/FlutterGrad/getApprovers.php");
    }
     uri = Uri.parse(uri.toString()).replace(queryParameters: {
      "postType": _postType,
      "facultyID": _facultyId.toString(),
      "studentID": _userId!
    });

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          setState(() {
            _approvers = List<Map<String, dynamic>>.from(data["data"]);
            _selectedApproverId = null;
          });
        } else {
          print("Fetch failed: ${data['message']}");
        }
      }
    } catch (e) {
      print("Error loading approvers: $e");
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

Future<void> _submitPost() async {
  if (_titleController.text.isEmpty || _contentController.text.isEmpty || _userId == null) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please fill all required fields.")));
    return;
  }

  final url = _postType == 'public'
      ? "http://localhost/public_html/FlutterGrad/studentPublicPost.php"
      : "http://localhost/public_html/FlutterGrad/studentPrivatePost.php";

  String? base64Image;
  if (_selectedImage != null) {
    List<int> imageBytes = await _selectedImage!.readAsBytes();
    base64Image = base64Encode(imageBytes);
  }

  Map<String, dynamic> jsonBody = {
    "POSTCREATORID": int.parse(_userId!),
    "posttitle": _titleController.text,
    "CONTENT": _contentController.text,
    "REVIEWEDBY": _selectedApproverId,
    "media": base64Image,  // Send the base64 encoded image data
  };

  if (_postType == "private") {
    jsonBody["facultyID"] = _facultyId;
  }

  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(jsonBody),
    );

    final responseData = jsonDecode(response.body);
    if (response.statusCode == 200 && responseData["success"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Post submitted successfully!")));
      _titleController.clear();
      _contentController.clear();
      setState(() {
        _selectedImage = null;
        _selectedApproverId = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: ${responseData['message']}")));
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error submitting post.")));
  }
}


  void _onPostTypeChanged(String? newValue) {
    if (newValue != null && newValue != _postType) {
      setState(() {
        _postType = newValue;
        _selectedApproverId = null;
        _approvers = [];
      });
      _fetchApprovers(); // Re-fetch approvers based on new post type
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
        "Student Create Post",
        style: TextStyle(
          color: Colors.green, // Ensure text color matches your theme
        ),
      ),
    ],
  ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: _titleController, decoration: InputDecoration(labelText: "Post Title")),
            SizedBox(height: 16),
            TextField(
              controller: _contentController,
              maxLines: 5,
              decoration: InputDecoration(labelText: "Content"),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: Icon(Icons.image),
              label: Text("Pick Image"),
            ),
            if (_selectedImage != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.file(_selectedImage!, height: 150),
              ),
            SizedBox(height: 20),
            Row(
              children: [
                Text("Post Type: "),
                Radio<String>(
                  value: "public",
                  groupValue: _postType,
                  onChanged: _onPostTypeChanged,
                ),
                Text("Public"),
                Radio<String>(
                  value: "private",
                  groupValue: _postType,
                  onChanged: _onPostTypeChanged,
                ),
                Text("Private"),
              ],
            ),
            SizedBox(height: 16),
            _approvers.isEmpty
                ? Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<int>(
                    value: _selectedApproverId,
                    decoration: InputDecoration(labelText: "Select Approver"),
                    items: _approvers.map((approver) {
                      return DropdownMenuItem<int>(
                        value: approver["id"],
                        child: Text(approver["name"]),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedApproverId = value),
                  ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitPost,
              style: ElevatedButton.styleFrom(minimumSize: Size.fromHeight(45)),
              child: Text("Submit Post"),
            ),
          ],
        ),
      ),
    );
  }
}
