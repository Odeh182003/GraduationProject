import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Privatepost {
  static Future<List<dynamic>> fetchPrivatePosts() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? facultyID = prefs.getString('facultyID');

    if (facultyID == null) {
      throw Exception('Faculty ID not found in SharedPreferences');
    }

    final Uri url = kIsWeb
        ? Uri.parse('http://localhost/public_html/FlutterGrad/getPrivatePosts.php?facultyID=$facultyID')
        : Uri.parse('http://192.168.10.5/public_html/FlutterGrad/getPrivatePosts.php?facultyID=$facultyID');

    final http.Response response = await http.get(url);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load private posts');
    }
  }
}
