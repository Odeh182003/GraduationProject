import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MaterialApp(home: PostFormScreen()));
}

class PostFormScreen extends StatefulWidget {
  @override
  _PostFormScreenState createState() => _PostFormScreenState();
}

class _PostFormScreenState extends State<PostFormScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String? _postType = "public"; // Default post type
  File? _selectedImage;
  String? _userId;
  int? _facultyId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedUserId = prefs.getString("universityID");

    if (storedUserId != null) {
      setState(() {
        _userId = storedUserId;
      });
      await _fetchFacultyId(storedUserId.toString());
    }
  }

  Future<void> _fetchFacultyId(String userId) async {
    try {
      final response = await http.get(
        Uri.parse("http://localhost/public_html/FlutterGrad/getInformation.php?universityID=$userId"),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data["success"] == true) {
          setState(() {
            _facultyId = data["data"]["facultyID"];
          });
        }
      }
    } catch (e) {
      print("Error fetching faculty ID: $e");
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

Future<void> _submitPost() async {
  if (_titleController.text.isEmpty || _contentController.text.isEmpty || _userId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Please fill all fields."))
    );
    return;
  }

  if (_postType == "private" && _facultyId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Fetching faculty ID... Please wait."))
    );
    return;
  }

  String apiUrl = _postType == "public"
      ? "http://localhost/public_html/FlutterGrad/add_public_post.php"
      : "http://localhost/public_html/FlutterGrad/add_private_post.php";

  var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
  request.fields["POSTCREATORID"] = _userId.toString();
  request.fields["posttitle"] = _titleController.text;
  request.fields["CONTENT"] = _contentController.text;
  request.fields["APPROVALID"] = "Null";
  request.fields["APPROVALSTATUS"] = "approved";
  request.fields["DATECREATED"] = DateTime.now().toUtc().toIso8601String();
  request.fields["REVIEWEDBY"] = _userId.toString();
  request.fields["REVIEWEDDATE"] = DateTime.now().toUtc().toIso8601String();

  if (_postType == "private") {
    request.fields["facultyID"] = _facultyId.toString();
  }

  if (_selectedImage != null) {
    request.files.add(await http.MultipartFile.fromPath(
      'media',
      _selectedImage!.path,
    ));
  }

  var response = await request.send();
  if (response.statusCode == 200) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Post submitted successfully."))
    );
    _titleController.clear();
    _contentController.clear();
    setState(() {
      _selectedImage = null;
    });
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Submission failed."))
    );
  }
}


  @override
  Widget build(BuildContext context) {
   return Scaffold(
  appBar: AppBar(title: Text("Create Post")),
  resizeToAvoidBottomInset: true,  // Prevent overflow when keyboard appears
  body: SingleChildScrollView(
    child: Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Prevent excessive space
        children: [
          TextField(
            controller: _titleController,
            decoration: InputDecoration(labelText: "Post Title"),
          ),
          TextField(
            controller: _contentController,
            decoration: InputDecoration(labelText: "Content"),
            maxLines: 3,
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Text("Post Type: "),
              Radio(
                value: "public",
                groupValue: _postType,
                onChanged: (value) {
                  setState(() {
                    _postType = value.toString();
                  });
                },
              ),
              Text("Public"),
              Radio(
                value: "private",
                groupValue: _postType,
                onChanged: (value) {
                  setState(() {
                    _postType = value.toString();
                  });
                },
              ),
              Text("Private"),
            ],
          ),
          SizedBox(height: 10),
          _selectedImage != null
              ? Image.file(_selectedImage!, height: 100)
              : Text("No image selected"),
          ElevatedButton(
            onPressed: _pickImage,
            child: Text("Pick Image"),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _submitPost,
            child: Text("Submit Post"),
          ),
        ],
      ),
    ),
  ),
);

  }
}
