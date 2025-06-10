import 'dart:async';
import 'dart:convert';
import 'package:bzu_leads/components/my_button.dart';
import 'package:bzu_leads/components/my_textfields.dart';
import 'package:bzu_leads/services/ApiConfig.dart';
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

  // Top-level function for compute to decode JSON
  static Map<String, dynamic> parseJson(String responseBody) {
    return jsonDecode(responseBody) as Map<String, dynamic>;
  }

  // Function to decode JSON in a background thread
  Future<Map<String, dynamic>> _decodeJson(String responseBody) async {
    return await compute(parseJson, responseBody);
  }

  Future<void> login() async {
    setState(() => isLoading = true);
    Uri url;
    if (kIsWeb) {
      url = Uri.parse("http://localhost/public_html/FlutterGrad/login.php");
    } else {
      url = Uri.parse("${ApiConfig.baseUrl}/login.php");
    }

    try {
      // Retry mechanism with exponential backoff
      const int maxRetries = 3;
      int retryCount = 0;
      http.Response response;

      while (true) {
        try {
          response = await http.post(
            url,
            headers: {
              "Content-Type": "application/json",
              "Connection": "keep-alive", // Use persistent connection
            },
            body: jsonEncode({
              "universityID": _uniID.text.trim(), // Send universityID as a string
              "password": _password.text,
            }),
          );
          break; // Exit loop if request is successful
        } catch (e) {
          retryCount++;
          if (retryCount >= maxRetries) {
            throw e; // Re-throw the exception after max retries
          }
          await Future.delayed(Duration(milliseconds: 500 * retryCount)); // Exponential backoff
        }
      }

      // Decode JSON in a background thread
      var data = await _decodeJson(response.body);
      setState(() => isLoading = false);

      if (data['success']) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("username", data['username']);
        await prefs.setString("role", jsonEncode(data['roles']));
        await prefs.setString("universityID", _uniID.text.trim());
        await prefs.setString("password", _password.text);
        await prefs.setString("defaultRole", data['defaultRole']);
        await prefs.setString("facultyID", data['facultyID'].toString());
        print("Faculty ID: ${data['facultyID']}");
        // Store section IDs for student roles
        if (data['studentData'] != null) {
          List<int> sectionIDs = List<int>.from(data['studentData']['sectionIDs'] ?? []);
          List<String> sectionIDsAsStrings = sectionIDs.map((id) => id.toString()).toList(); // Convert to strings
          await prefs.setStringList("sectionIDs", sectionIDsAsStrings);
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

        // Navigate based on role
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
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
         /* Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/Blog-Olive-Tree-1.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),*/
          
          // Semi-transparent overlay
          Container(color: Colors.black.withOpacity(0.3)),

          // Top-left logo
          Positioned(
            top: 40,
            left: 40,
            child: Image.network(
        ApiConfig.systemLogoUrl,
        height: 140,
        errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image),
      
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
  }
}