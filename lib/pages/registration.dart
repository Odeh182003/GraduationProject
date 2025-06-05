import 'dart:io';
import 'package:bzu_leads/services/registration.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _universityIDController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

  int _roleID = 1; // Default to Student
  String? _gender = "Male"; // Default to Male
  String? _palestinianIDNumber;
  int? _facultyID;
  int? _departmentID;
  String? _major;
  String? _minor;
  String? _email;
  String? _officeHours;
  String? _room;
  String? _hobbies;

  List<Map<String, dynamic>> _faculties = [];
  List<Map<String, dynamic>> _departments = [];

  @override
  void initState() {
    super.initState();
    _fetchFaculties(); // Fetch faculties on initialization
  }

  Future<void> _fetchFaculties() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.10.3/public_html/FlutterGrad/get_faculties.php'));
      if (response.statusCode == 200) {
        setState(() {
          _faculties = List<Map<String, dynamic>>.from(json.decode(response.body).map((faculty) => {
                "facultyID": int.parse(faculty["facultyID"].toString()), // Ensure facultyID is parsed as int
                "facultyName": faculty["facultyName"],
              }));
        });
      } else {
        throw Exception('Failed to load faculties');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch faculties: $e')),
      );
    }
  }

  Future<void> _fetchDepartments(int facultyID) async {
    try {
      final response = await http.get(Uri.parse('http://192.168.10.3/public_html/FlutterGrad/get_departments.php?facultyID=$facultyID'));
      if (response.statusCode == 200) {
        setState(() {
          _departments = List<Map<String, dynamic>>.from(json.decode(response.body).map((department) => {
                "departmentID": int.parse(department["departmentID"].toString()), // Ensure departmentID is parsed as int
                "departmentName": department["departmentName"],
              }));
        });
      } else {
        throw Exception('Failed to load departments');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch departments: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _universityIDController,
                decoration: const InputDecoration(labelText: 'University ID'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your University ID';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your Username';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your Password';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Gender'),
                value: _gender,
                items: const [
                  DropdownMenuItem(value: "Male", child: Text('Male')),
                  DropdownMenuItem(value: "Female", child: Text('Female')),
                ],
                onChanged: (value) {
                  setState(() {
                    _gender = value;
                  });
                },
              ),
              TextFormField(
                controller: _dateOfBirthController,
                decoration: const InputDecoration(labelText: 'Date of Birth (YYYY-MM-DD)'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your Date of Birth';
                  }
                  return null;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Palestinian ID Number'),
                onChanged: (value) {
                  _palestinianIDNumber = value;
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _pickImage,
                    child: const Text('Pick Image'),
                  ),
                  const SizedBox(width: 10),
                  if (_selectedImage != null)
                    Text(
                      'Image Selected',
                      style: const TextStyle(color: Colors.green),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Role'),
                value: _roleID,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Student')),
                  DropdownMenuItem(value: 2, child: Text('Academic')),
                ],
                onChanged: (value) {
                  setState(() {
                    _roleID = value!;
                  });
                },
              ),
              if (_roleID == 1) ...[ // For students
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Faculty'),
                  value: _facultyID,
                  items: _faculties
                      .map<DropdownMenuItem<int>>((faculty) => DropdownMenuItem<int>(
                            value: faculty['facultyID'],
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Text(faculty['facultyName']),
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _facultyID = value;
                      _departmentID = null; // Reset department when faculty changes
                    });
                    if (value != null) {
                      _fetchDepartments(value); // Fetch departments for the selected faculty
                    }
                  },
                ),
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Department'),
                  value: _departmentID,
                  items: _departments
                      .map<DropdownMenuItem<int>>((department) => DropdownMenuItem<int>(
                            value: department['departmentID'],
                            child: Text(department['departmentName']),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _departmentID = value;
                    });
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Major'),
                  onChanged: (value) {
                    _major = value;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Minor'),
                  onChanged: (value) {
                    _minor = value;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Email'),
                  onChanged: (value) {
                    _email = value;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Hobbies'),
                  onChanged: (value) {
                    _hobbies = value;
                  },
                ),
              ],
              if (_roleID == 2) ...[ // For academics
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Faculty'),
                  value: _facultyID,
                  items: _faculties
                      .map<DropdownMenuItem<int>>((faculty) => DropdownMenuItem<int>(
                            value: faculty['facultyID'],
                            child: Text(faculty['facultyName']),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _facultyID = value;
                    });
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Email'),
                  onChanged: (value) {
                    _email = value;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Room'),
                  onChanged: (value) {
                    _room = value;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Office Hours'),
                  maxLines: 3, // Allow up to 3 lines
                  onChanged: (value) {
                    _officeHours = value;
                  },
                ),
              ],
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    String? base64Image;
                    if (_selectedImage != null) {
                      base64Image = base64Encode(_selectedImage!.readAsBytesSync());
                    }

                    final result = await RegistrationService.registerUser(
                      universityID: _universityIDController.text,
                      username: _usernameController.text,
                      password: _passwordController.text,
                      roleID: _roleID,
                      gender: _gender,
                      dateOfBirth: _dateOfBirthController.text,
                      palestinianIDNumber: _palestinianIDNumber,
                      image: base64Image,
                      facultyID: _facultyID,
                      departmentID: _departmentID,
                      major: _major,
                      minor: _minor,
                      email: _email,
                      officeHours: _officeHours,
                      room: _room,
                      hobbies: _hobbies,
                    );

                    if (result['success']) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(result['message'])),
                      );
                      // Reset state
                      setState(() {
                        _universityIDController.clear();
                        _usernameController.clear();
                        _passwordController.clear();
                        _dateOfBirthController.clear();
                        _selectedImage = null;
                        _gender = "Male";
                        _palestinianIDNumber = null; // Clear Palestinian ID Number
                        _facultyID = null;
                        _departmentID = null;
                        _major = null; // Clear Major
                        _minor = null; // Clear Minor
                        _email = null; // Clear Email
                        _officeHours = null;
                        _room = null;
                        _hobbies = null; // Clear Hobbies
                        _roleID = 1;
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(result['message'])),
                      );
                    }
                  }
                },
                child: const Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
