import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GroupService {
  static final String _baseUrl = kIsWeb
      ? "http://localhost/public_html/FlutterGrad/create_group.php"
      : "http://192.168.10.5/public_html/FlutterGrad/create_group.php";

  static Future<List<Map<String, dynamic>>> getChatGroups(String universityID) async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString("role");

    if (role == null) {
      print("Role is not available");
      return [];
    }

    Uri url;
    if (role == "academic") {
      url = Uri.parse("$_baseUrl?view_academic_id=$universityID");
    } else if (role == "official") {
      url = Uri.parse("$_baseUrl?view_official_id=$universityID");
    } else {
      url = Uri.parse("$_baseUrl?view_student_id=$universityID");
    }

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result["success"] == true && result["groups"] is List) {
          final Set<String> uniqueGroupIDs = {};
          final List<Map<String, dynamic>> groups = [];

          for (var group in result["groups"]) {
            String groupID = group["groupID"].toString();
            if (!uniqueGroupIDs.contains(groupID)) {
              uniqueGroupIDs.add(groupID);
              groups.add({
                "groupID": groupID,
                "groupName": group["MESSAGINGGROUPNAME"],
                "dateCreated": group["CREATIONDATE"] ?? ""
              });
            }
          }
          return groups;
        }
      } else {
        print("Failed to fetch groups. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching groups: $e");
    }

    return [];
  }

 static Future<Map<String, dynamic>> createGroups(String universityID, String role) async {
  Uri url;
  if (role == "academic") {
    url = Uri.parse("$_baseUrl?academic_id=$universityID");
  } else if (role == "official") {
    url = Uri.parse("$_baseUrl?official_id=$universityID");
  } else {
    return {
      "success": false,
      "message": "Only academics and officials can create groups.",
    };
  }

  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);

      if (result is Map<String, dynamic>) {
        // Single map response
        return {
          "success": result["success"] == true,
          "message": result["message"] ?? "Operation completed",
        };
      } else if (result is List) {
        bool anySuccess = false;
        String message = "Groups already exist.";
        
        for (var item in result) {
          if (item is Map<String, dynamic> && item.containsKey("success")) {
            if (item["success"] == true) {
              anySuccess = true;
              message = item["message"] ?? "Group created successfully.";
              break;
            }
          }
        }

        return {
          "success": anySuccess,
          "message": message,
        };
      }
    } else {
      print("Group creation failed. Status code: ${response.statusCode}");
    }
  } catch (e) {
    print("Error creating groups: $e");
  }

  return {
    "success": false,
    "message": "Something went wrong while creating groups.",
  };
}

}
