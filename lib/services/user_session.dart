import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserHelper {
  static Future<String?> getUniversityID() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("universityID");
  }

  static Future<int?> getFacultyID(String universityID) async {
    Uri url;
    try {
      if(kIsWeb){
      url = Uri.parse("http://localhost/public_html/FlutterGrad/getInformation.php?universityID=$universityID");
    } else {
      url = Uri.parse("http://192.168.10.5/public_html/FlutterGrad/getInformation.php?universityID=$universityID");
    }
      final response = await http.get(Uri.parse(
        
          url.toString()));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data["success"] == true) {
          return data["data"]["facultyID"];
        }
      }
    } catch (e) {
      print("Error fetching faculty ID: $e");
    }
    return null;
  }
}
