import 'package:bzu_leads/pages/profile_page.dart';
import 'package:bzu_leads/pages/settingsPage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
class Createpostsstudents extends StatefulWidget {
  const Createpostsstudents({super.key});

  @override
  _Createpostsstudents createState() => _Createpostsstudents();
}


class _Createpostsstudents extends State<Createpostsstudents> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _universityIdController = TextEditingController();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isPrivate = false;
  String? _selectedReference;
  final List<String> _references = ["Value 1", "Value 2", "Value 3", "Value 4"];

  @override
  void dispose() {
    _nameController.dispose();
    _universityIdController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Process the form submission
      print('Name: ${_nameController.text}');
      print('University ID: ${_universityIdController.text}');
      print('Post Title: ${_titleController.text}');
      print('Post Content: ${_contentController.text}');
      print('Is Private: $_isPrivate');
      print('Reference: $_selectedReference');
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post submitted successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     appBar: AppBar(
        title: Text("Public Posts"),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.green,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              // Navigate to the Settings page
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => settingsPage()),
              );
            },
          ),
          IconButton(
      icon: Icon(Icons.person),
      onPressed: () async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? userID = prefs.getString("universityID");

        if (userID != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProfilePage()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("User ID not found. Please log in again.")),
          );
        }
      },
    ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Name *', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Enter your full name',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                const Text('University ID *', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _universityIdController,
                  decoration: const InputDecoration(
                    hintText: 'Enter you ID',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your University ID';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                const Text('Post Title *', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: 'Enter post title',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a post title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                const Text('Post Content *', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    hintText: 'Enter what your post\'s body',
                    suffixIcon: Icon(Icons.attach_file),
                  ),
                  minLines: 3,
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter post content';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Checkbox(
                      value: _isPrivate,
                      onChanged: (value) {
                        setState(() {
                          _isPrivate = value ?? false;
                        });
                      },
                    ),
                    const Text('Is Private?'),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 32.0),
                  child: Text(
                    'Check the box if your post is private',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 16),
                
                const Text('Select your reference *', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedReference,
                  hint: const Text('Value'),
                  decoration: const InputDecoration(
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                  items: _references.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedReference = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a reference';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                
                Center(
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(150, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text('Submit'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messaging',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: 0,
        onTap: (index) {
          // Handle navigation
        },
      ),
    );
  }
}