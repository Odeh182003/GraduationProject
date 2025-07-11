import 'dart:convert';
//import 'package:crypto/crypto.dart';
//import 'package:bzu_leads/services/noti_service.dart';
import 'package:bzu_leads/services/ApiConfig.dart';
import 'package:http/http.dart' as http;
import 'package:bzu_leads/components/my_button.dart';
import 'package:bzu_leads/pages/profile_page.dart';
import 'package:bzu_leads/themes/theme_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; 

class settingsPage extends StatelessWidget {
  const settingsPage({super.key});

  void _showChangePasswordDialog(BuildContext context) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    bool isStrongPassword(String password) {
      // At least one uppercase, one lowercase, one digit, one special char, min 8 chars
      final regex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$');
      return regex.hasMatch(password);
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SingleChildScrollView( // <-- Fix overflow on keyboard open
            padding: EdgeInsets.zero,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Change Password",
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: oldPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Old Password",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: newPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "New Password",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Confirm New Password",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        onPressed: () async {
                          final oldPass = oldPasswordController.text.trim();
                          final newPass = newPasswordController.text.trim();
                          final confirmPass = confirmPasswordController.text.trim();

                          if (newPass.isEmpty || oldPass.isEmpty || confirmPass.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("All fields are required.")),
                            );
                            return;
                          }
                          if (!isStrongPassword(newPass)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Password must be at least 8 characters and include uppercase, lowercase, number, and special character.",
                                ),
                              ),
                            );
                            return;
                          }
                          if (newPass != confirmPass) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Passwords do not match.")),
                            );
                            return;
                          }

                          SharedPreferences prefs = await SharedPreferences.getInstance();
                          String? universityID = prefs.getString("universityID");
                          if (universityID == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("User not found.")),
                            );
                            return;
                          }

                          final response = await changePasswordRequest(
                            universityID,
                            oldPass, 
                            newPass, 
                          );

                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(response)),
                          );
                        },
                        child: const Text("Change"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Future<String> changePasswordRequest(
      String universityID, String oldPassword, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/changePass.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'universityID': universityID,
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
      );
      final data = jsonDecode(response.body);
      return data['message'] ?? (data['success'] == true ? "Password updated successfully" : "Failed to update password");
    } catch (e) {
      return "Error: $e";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
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
      const SizedBox(width: 8), // Space between image and text
      const Text(
        "Settings",
        style: TextStyle(
          color: Colors.green, // Ensure text color matches your theme
        ),
      ),
    ],
  ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Dark Mode Toggle
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(25),
              padding: const EdgeInsets.all(26),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Dark Mode"),
                  CupertinoSwitch(
                    value: Provider.of<ThemeProvider>(context, listen: false).isDarkMode,
                    onChanged: (value) => Provider.of<ThemeProvider>(context, listen: false).toggleTheme(),
                  ),
                ],
              ),
            ),
            
            // Edit Profile and Change Password
            ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProfilePage()),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Padding(
                            padding: EdgeInsets.only(left: 20),
                            child: Text('Edit Profile'),
                          ),
                          Padding(
                            padding: EdgeInsets.only(right: 20),
                            child: Icon(Icons.arrow_forward_ios, size: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: InkWell(
                      onTap: () {
                        _showChangePasswordDialog(context);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Padding(
                            padding: EdgeInsets.only(left: 20),
                            child: Text('Change Password'),
                          ),
                          Padding(
                            padding: EdgeInsets.only(right: 20),
                            child: Icon(Icons.arrow_forward_ios, size: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Log Out Button
            const SizedBox(height: 30),

// Log Out Button
Center(
  child: SizedBox(
    width: 160, 
    child: MyButton(
      text: "Log Out",
      onTap: () async {
        logout(context);
      },
    ),
  ),
),

          ],
        ),
      ),
    );
  }
  Future<void> logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear stored session data

    // Navigate to login screen and remove all previous routes
    Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
  }
}
