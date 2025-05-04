import 'dart:convert';
import 'package:bzu_leads/components/my_button.dart';
import 'package:bzu_leads/components/my_textfields.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _uniID = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool isLoading = false;

Future<void> login() async {
   setState(() => isLoading = true);
    Uri url;
    if(kIsWeb){
      url = Uri.parse("http://localhost/public_html/FlutterGrad/login.php");
    } else {
      url = Uri.parse("http://192.168.10.5/public_html/FlutterGrad/login.php");
    }
  var response = await http.post(
    url,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "universityID": _uniID.text,
      "password": _password.text,
    }),
  );

  var data = jsonDecode(response.body);
  setState(() => isLoading = false);

  if (data['success']) {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("username", data['username']);
    await prefs.setString("role", jsonEncode(data['roles']));
    await prefs.setString("universityID", _uniID.text);
    await prefs.setString("password", _password.text);
    await prefs.setString("defaultRole", data['defaultRole']);
    await prefs.setString("facultyID", data['facultyID'].toString());
print("Saved role JSON: ${jsonEncode(data['roles'])}"); // 👈 Print role
  print("Default role: ${data['defaultRole']}");    
    // Store section IDs for student roles
    if (data['studentData'] != null) {
      List<String> sectionIDs = List<String>.from(data['studentData']['sectionIDs'] ?? []);
      await prefs.setStringList("sectionIDs", sectionIDs);
    }

    // Store club data for official roles
    if (data['officialData'] != null) {
      List<Map<String, dynamic>> officialClubs = List<Map<String, dynamic>>.from(
        data['officialData']['clubs'].map((club) => {
          'studentclubID': club['studentclubID'],
          'studentclubname': club['studentclubname'],
        }) ?? [],
      );
      await prefs.setStringList("officialClubs", officialClubs.map((club) => jsonEncode(club)).toList());
    }

    String defaultRole = data['defaultRole'];

// Treat university admin as a special type of official
if (defaultRole == "official" || defaultRole == "universityAdministrator") {
  Navigator.pushReplacementNamed(context, "/official_dashboard");
} else if (defaultRole == "student") {
  Navigator.pushReplacementNamed(context, "/student_dashboard");
} else if (defaultRole == "academic") {
  Navigator.pushReplacementNamed(context, "/academic_dashboard");
} else {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Invalid role")),
  );
}

  } else {
    String errorMessage = data['message'] ?? "Login failed. Please try again.";
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Login Failed"),
        content: Text(errorMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}

 @override
  Widget build(BuildContext context) {
    return Scaffold(
  body: Stack(
    children: [
      // Background Image
      Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/Blog-Olive-Tree-1.png"),
            fit: BoxFit.cover,
          ),
        ),
      ),

      // Semi-transparent overlay
      Container(color: Colors.black.withOpacity(0.3)),

      // Top-left logo
      Positioned(
        top: 40,
        left: 40,
        child: Image.asset(
  'assets/logo.png',
  height: 150,
),
      ),

      // Main content
      Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Login Form Container
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 30),
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Login to BZU Leads',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 20),
                    MyTextfields(
                      hintText: "University ID",
                      obscureText: false,
                      controller: _uniID,
                    ),
                    const SizedBox(height: 10),
                    MyTextfields(
                      hintText: "Password",
                      obscureText: true,
                      controller: _password,
                    ),
                    const SizedBox(height: 20),
                    isLoading
                        ? const CircularProgressIndicator()
                        : MyButton(
                            text: "Login",
                            onTap: login,
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  ),
);
  }}