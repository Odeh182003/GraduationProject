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
      url = Uri.parse("http://192.168.10.4/public_html/FlutterGrad/login.php");
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

    // Navigate based on the default role
    String defaultRole = data['defaultRole'];
    if (defaultRole == "official") {
      Navigator.pushReplacementNamed(context, "/official_dashboard");
    } else if (defaultRole == "student") {
      Navigator.pushReplacementNamed(context, "/student_dashboard");
    }else if(defaultRole == "academic"){
      Navigator.pushReplacementNamed(context, "/academic_dashboard");    }
     else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid role")),
      );
    }
  } else {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Login failed"),
        content: const Text("Check your credentials."),
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
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Login', style: TextStyle(fontSize: 30, color: Colors.green)),
              const Icon(Icons.login_rounded, size: 60),
              const SizedBox(height: 50),
              const Text("Welcome To BZU Leads", style: TextStyle(color: Colors.green, fontSize: 18)),
              const SizedBox(height: 25),
              MyTextfields(hintText: "University ID", obscureText: false, controller: _uniID),
              const SizedBox(height: 10.0),
              MyTextfields(hintText: "Password", obscureText: true, controller: _password),
              const SizedBox(height: 25.0),
              isLoading ? const CircularProgressIndicator() : MyButton(text: "Login", onTap: login, TextStyle: Colors.green),
              const SizedBox(height: 25.0),
            ],
          ),
        ),
      ),
    );
  }
}
