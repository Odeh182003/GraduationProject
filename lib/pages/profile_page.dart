import 'dart:io';
//import 'package:bzu_leads/pages/chattingGroup_page.dart';
//import 'package:bzu_leads/pages/private_posts.dart';
//import 'package:bzu_leads/pages/settingsPage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userData;
  Map<String, dynamic>? StudentClubData;
  bool isLoading = true;
  String? userID;
  File? selectedImage;

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController roleController = TextEditingController();
  final TextEditingController genderController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController palestinianIDController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserID();
  }

  Future<void> _loadUserID() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedUserID = prefs.getString("universityID");

    if (storedUserID != null) {
      setState(() {
        userID = storedUserID;
      });
      getUserData();
    }
  }

  Future<void> getUserData() async {
    if (userID == null) return;

    final url = Uri.parse("http://localhost/public_html/FlutterGrad/getInformation.php?universityID=$userID");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (data["success"] == true) {
        setState(() {
          userData = data["data"];
          isLoading = false;

          usernameController.text = userData?["username"] ?? "";
          roleController.text = userData?["roleID"]?.toString() ?? "";
          genderController.text = userData?["GENDER"] ?? "";
          dobController.text = userData?["DATEOFBIRTH"] ?? "";
          palestinianIDController.text = userData?["PALESTINIANIDNUMBER"]?.toString() ?? "";
          passwordController.text = prefs.getString("password")??"";
           
          StudentClubData = data["data"]["studentClub"];
          if (StudentClubData != null) {
            TextEditingController studentclubName = TextEditingController();
            TextEditingController membersinceTxt = TextEditingController();
            TextEditingController endDateTxt = TextEditingController();
            TextEditingController headStudentIDTxt = TextEditingController();
            setState(() {
              studentclubName.text = StudentClubData?["studentclubname"]??"";
              membersinceTxt.text = StudentClubData?["membersince"]??"";
              endDateTxt.text = StudentClubData?["endDate"]??"";
              headStudentIDTxt.text = StudentClubData?["headStudentID"].toString()??"";
            });
          }
        });
      } else {
        setState(() {
          isLoading = false;
          userData = null;
        });
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> pickImage() async {
    if (kIsWeb) return;

    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> updateUserProfile() async {
    if (kIsWeb) return;

    var request = http.MultipartRequest(
      'POST',
      Uri.parse("http://localhost/public_html/FlutterGrad/updateUserInformation.php"),
    );

    request.fields['universityID'] = userID!;
    request.fields['username'] = usernameController.text;
    request.fields['roleID'] = roleController.text;
    request.fields['GENDER'] = genderController.text;
    request.fields['DATEOFBIRTH'] = dobController.text;
    request.fields['PALESTINIANIDNUMBER'] = palestinianIDController.text;

    if (selectedImage != null) {
      var stream = http.ByteStream(selectedImage!.openRead());
      var length = await selectedImage!.length();
      var multipartFile = http.MultipartFile(
        'image',
        stream,
        length,
        filename: selectedImage!.path.split('/').last,
      );
      request.files.add(multipartFile);
    }

    var response = await request.send();
    var responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      print("Profile updated successfully: $responseBody");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated successfully")));
      getUserData();
    } else {
      print("Failed to update profile: $responseBody");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to update profile")));
    }
  }

  String fixImageUrl(String imageUrl) {
    String baseUrl = kIsWeb
        ? "http://localhost/public_html/FlutterGrad/"
        : "http://192.168.10.4/public_html/FlutterGrad/";

    if (!imageUrl.startsWith("http")) {
      return "$baseUrl${imageUrl.replaceAll("\\", "/")}";
    }

    return imageUrl.replaceAll("http:/", "http://").replaceAll("https:/", "https://");
  }
Future<void> logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear stored session data

    // Navigate to login screen and remove all previous routes
    Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
  }
 @override
Widget build(BuildContext context) {
 // SharedPreferences prefs =  SharedPreferences.getInstance() as SharedPreferences;
  //String? username = prefs.getString("username");

  return Scaffold(
    backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text("Profile"),//$username
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.green,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              logout(context);
              },
              ),
        ],
),
    body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : userData == null
            ? const Center(child: Text("User not found"))
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: kIsWeb ? null : pickImage,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: selectedImage != null
                              ? FileImage(selectedImage!)
                              : (userData!["image"] != null && userData!["image"].isNotEmpty
                                  ? NetworkImage(fixImageUrl(userData!["image"]))
                                  : const AssetImage("assets/default_profile.png")) as ImageProvider,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (!kIsWeb)
                        TextButton(
                          onPressed: pickImage,
                          child: const Text("Choose Image"),
                        ),
                      TextField(controller: usernameController, decoration: const InputDecoration(labelText: "Username")),
                      TextField(controller: passwordController,obscureText: true, decoration: const InputDecoration(labelText: "password")),
                      //TextField(controller: roleController, decoration: const InputDecoration(labelText: "Role ID")),
                      TextField(controller: genderController, decoration: const InputDecoration(labelText: "Gender")),
                      TextField(controller: dobController, decoration: const InputDecoration(labelText: "Date of Birth")),
                      TextField(controller: palestinianIDController, decoration: const InputDecoration(labelText: "Palestinian ID")),
                      

                      // Role-Specific Sections
                      if (userData!["roleID"] == 1) studentSection(),
                      if (userData!["roleID"] == 2) academicSection(),
                      if (userData!["roleID"] == 3) officialSection(),

                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: updateUserProfile,
                        child: const Text("Update Profile"),
                      ),
                    ],
                  ),
                ),
              ),
  );
}

Widget studentSection() {
  return Column(
    children: [
      TextField(
        decoration: const InputDecoration(labelText: "Major"),
        controller: TextEditingController(text: userData?["major"] ?? ""),
      ),
      TextField(
        decoration: const InputDecoration(labelText: "Minor"),
        controller: TextEditingController(text: userData?["minor"] ?? ""),
      ),
      TextField(
        decoration: const InputDecoration(labelText: "Faculty Name"),
        controller: TextEditingController(text: userData?["facultyName"] ?? ""),
      ),
      
    ],
  );
}

// Academic-Specific Section
Widget academicSection() {
  return Column(
    children: [
      TextField(
        decoration: const InputDecoration(labelText: "Academic Name"),
        controller: TextEditingController(text: userData?["academicName"] ?? ""),
      ),
      TextField(
        decoration: const InputDecoration(labelText: "Email"),
        controller: TextEditingController(text: userData?["EMAIL"] ?? ""),
      ),
      TextField(
        decoration: const InputDecoration(labelText: "Office Hours"),
        controller: TextEditingController(text: userData?["officeHours"] ?? ""),
        maxLines: 2, // Allows two lines
  keyboardType: TextInputType.multiline,
      ),
      TextField(
        decoration: const InputDecoration(labelText: "Faculty Name"),
        controller: TextEditingController(text: userData?["facultyName"] ?? ""),
      ),
    ],
  );
}

// Official-Specific Section
Widget officialSection() {
 
  return Column(
    children: [
      TextField(
        decoration: const InputDecoration(labelText: "Email"),
        controller: TextEditingController(text: userData?["email"] ?? ""),
      ),
      
      if (userData?["studentClubID"] == 10) ...[
        const SizedBox(height: 20),
        const Text(
          "Student Club Information",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        TextField(
          decoration: const InputDecoration(labelText: "Club Name"),
          controller: TextEditingController(text: StudentClubData?["studentclubname"] ?? ""),
        ),
        TextField(
          decoration: const InputDecoration(labelText: "Member Since"),
          controller: TextEditingController(text: StudentClubData?["membersince"] ?? ""),
        ),
        TextField(
          decoration: const InputDecoration(labelText: "End Date"),
          controller: TextEditingController(text: StudentClubData?["endDate"] ?? ""),
        ),
        TextField(
          decoration: const InputDecoration(labelText: "Head Student ID"),
          controller: TextEditingController(text: StudentClubData?["headStudentID"].toString() ?? ""),
        ),
      ],
      /*TextField(
        decoration: const InputDecoration(labelText: "Official Name"),
        controller: TextEditingController(text: userData?["officialName"] ?? ""),
      ),*/
      /*TextField(
        decoration: const InputDecoration(labelText: "Department"),
        controller: TextEditingController(text: userData?["department"] ?? ""),
      ),*/
    ],
  );
}


}
