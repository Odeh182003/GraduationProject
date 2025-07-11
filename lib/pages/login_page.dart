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

  static Map<String, dynamic> parseJson(String responseBody) {
    return jsonDecode(responseBody) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _decodeJson(String responseBody) async {
    return await compute(parseJson, responseBody);
  }

  bool isStrongPassword(String password) {
    final regex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$');
    return regex.hasMatch(password);
  }

  Future<void> login() async {
    final universityID = _uniID.text.trim();
    final password = _password.text;

    // Input Validation
    if (universityID.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields.")),
      );
      return;
    }

    if (!RegExp(r'^\d+$').hasMatch(universityID)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("University ID must be numeric.")),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password must be at least 6 characters.")),
      );
      return;
    }

    if (!isStrongPassword(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password must include uppercase, lowercase, digit, and special character.")),
      );
      return;
    }

    setState(() => isLoading = true);
    Uri url;
    if (kIsWeb) {
      url = Uri.parse("http://localhost/public_html/FlutterGrad/login.php");
    } else {
      url = Uri.parse("${ApiConfig.baseUrl}/login.php");
    }

    try {
      const int maxRetries = 3;
      int retryCount = 0;
      http.Response response;

      while (true) {
        try {
          response = await http.post(
            url,
            headers: {
              "Content-Type": "application/json",
              "Connection": "keep-alive",
            },
            body: jsonEncode({
              "universityID": universityID,
              "password": password,
            }),
          );
          break;
        } catch (e) {
          retryCount++;
          if (retryCount >= maxRetries) {
            throw e;
          }
          await Future.delayed(Duration(milliseconds: 500 * retryCount));
        }
      }

      var data = await _decodeJson(response.body);
      setState(() => isLoading = false);

      if (data['success']) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("username", data['username']);
        await prefs.setString("role", jsonEncode(data['roles']));
        await prefs.setString("universityID", universityID);
        await prefs.setString("password", password);
        await prefs.setString("defaultRole", data['defaultRole']);
        await prefs.setString("facultyID", data['facultyID'].toString());

        if (data['studentData'] != null) {
          List<int> sectionIDs = List<int>.from(data['studentData']['sectionIDs'] ?? []);
          List<String> sectionIDsAsStrings = sectionIDs.map((id) => id.toString()).toList();
          await prefs.setStringList("sectionIDs", sectionIDsAsStrings);
        }

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
          Container(color: Colors.black.withOpacity(0.3)),
          Positioned(
            top: 40,
            left: 40,
            child: Image.network(
              ApiConfig.systemLogoUrl,
              height: 140,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
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
