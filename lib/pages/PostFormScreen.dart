import 'dart:io';
import 'package:bzu_leads/services/ApiConfig.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class PostFormScreen extends StatefulWidget {
  @override
  _PostFormScreenState createState() => _PostFormScreenState();
}

class _PostFormScreenState extends State<PostFormScreen> {
  int? approverId;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String? _postType = "public"; // Default post type
  List<File> _selectedImages = [];
  List<File> _selectedFiles = []; // For attachments
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedUserId = prefs.getString("universityID");
    //String? storedFacultyId = prefs.getString("facultyID");

    if (!mounted) return;
    setState(() {
      _userId = storedUserId;
    });
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? pickedFiles = await picker.pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        _selectedImages = pickedFiles.map((file) => File(file.path)).toList();
      });
    }
  }

  Future<void> _pickFiles() async {
    // Requires: file_picker: ^5.0.0 or newer in pubspec.yaml
    // import 'package:file_picker/file_picker.dart';
    // Uncomment the following lines if file_picker is available:
    
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: false, // set to true if you want bytes instead of files
      );
      if (result != null) {
        setState(() {
          _selectedFiles = result.paths
              .where((path) => path != null)
              .map((path) => File(path!))
              .toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking files: $e")),
      );
    }
    
  }

  Future<void> _submitPost() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty || _userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all fields."))
      );
      return;
    }

    int? facultyIdToSend;
    if (_postType == "private") {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? defaultRole = prefs.getString("defaultRole");
      if (defaultRole == "universityAdministrator") {
        facultyIdToSend = null;
      } else {
        String? storedFacultyId = prefs.getString("facultyID");
        if (storedFacultyId != null && storedFacultyId != "null" && storedFacultyId.isNotEmpty) {
          facultyIdToSend = int.tryParse(storedFacultyId);
        } else {
          facultyIdToSend = null;
        }
        if (facultyIdToSend == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Faculty ID not found. Please re-login."))
          );
          return;
        }
      }
    }

    String apiUrl = "${ApiConfig.baseUrl}/addpost.php";

    var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
    request.fields["POSTCREATORID"] = _userId.toString();
    request.fields["posttitle"] = _titleController.text;
    request.fields["CONTENT"] = _contentController.text;
    request.fields["APPROVALSTATUS"] = "approved";
    final now = DateTime.now();
    final dateStr = now.toIso8601String();
    request.fields["DATECREATED"] = dateStr;
    request.fields["REVIEWEDBY"] = _userId.toString();
    request.fields["REVIEWEDDATE"] = dateStr;
    request.fields["postType"] = _postType ?? "public";

    if (approverId != null) {
      request.fields["APPROVALID"] = approverId.toString();
    }

    if (_postType == "private" && facultyIdToSend != null) {
      request.fields["facultyID"] = facultyIdToSend.toString();
    }

    // Add images as media[]
    for (var image in _selectedImages) {
      request.files.add(await http.MultipartFile.fromPath(
        'media[]',
        image.path,
      ));
    }

    // Add attachments as media[] (if you want to allow any file type)
    for (var file in _selectedFiles) {
      request.files.add(await http.MultipartFile.fromPath(
        'media[]',
        file.path,
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
        _selectedImages.clear();
        _selectedFiles.clear();
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
            const SizedBox(width: 8),
            const Text(
              "Posts' Form",
              style: TextStyle(
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Create a New Post", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
                SizedBox(height: 24),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: "Post Title",
                    prefixIcon: Icon(Icons.title),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _contentController,
                  maxLines: 6,
                  decoration: InputDecoration(
                    labelText: "Content",
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.description),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Images", style: TextStyle(fontWeight: FontWeight.w600)),
                    ElevatedButton.icon(
                      onPressed: _pickImages,
                      icon: Icon(Icons.image, color: Colors.white),
                      label: Text("Pick Images", style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                if (_selectedImages.isNotEmpty)
                  Container(
                    height: 110,
                    margin: EdgeInsets.only(top: 10, bottom: 10),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      separatorBuilder: (_, __) => SizedBox(width: 10),
                      itemBuilder: (context, idx) {
                        final image = _selectedImages[idx];
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(image, height: 100, width: 100, fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedImages.removeAt(idx);
                                  });
                                },
                                child: CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Colors.white,
                                  child: Icon(Icons.cancel, color: Colors.red, size: 18),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text("No images selected", style: TextStyle(color: Colors.grey)),
                  ),
                // --- Attachments section ---
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Attachments", style: TextStyle(fontWeight: FontWeight.w600)),
                    ElevatedButton.icon(
                      onPressed: _pickFiles, // Uncomment and implement _pickFiles with file_picker
                      icon: Icon(Icons.attach_file, color: Colors.white),
                      label: Text("Pick Files", style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                if (_selectedFiles.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _selectedFiles.map((file) => ListTile(
                      leading: Icon(Icons.insert_drive_file, color: Colors.green),
                      title: Text(file.path.split('/').last),
                      trailing: IconButton(
                        icon: Icon(Icons.cancel, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _selectedFiles.remove(file);
                          });
                        },
                      ),
                    )).toList(),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text("No attachments selected", style: TextStyle(color: Colors.grey)),
                  ),
                Divider(height: 32),
                Text("Post Type", style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                Row(
                  children: [
                    ChoiceChip(
                      label: Text("Public"),
                      selected: _postType == "public",
                      selectedColor: Colors.green.shade100,
                      onSelected: (selected) {
                        if (selected) setState(() => _postType = "public");
                      },
                      labelStyle: TextStyle(color: _postType == "public" ? Colors.green : Colors.black),
                    ),
                    SizedBox(width: 12),
                    ChoiceChip(
                      label: Text("Private"),
                      selected: _postType == "private",
                      selectedColor: Colors.green.shade100,
                      onSelected: (selected) {
                        if (selected) setState(() => _postType = "private");
                      },
                      labelStyle: TextStyle(color: _postType == "private" ? Colors.green : Colors.black),
                    ),
                  ],
                ),
                SizedBox(height: 32),
                Center(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _submitPost,
                      icon: Icon(Icons.send, color: Colors.white),
                      label: Text("Submit Post", style: TextStyle(fontSize: 18, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size.fromHeight(50),
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
