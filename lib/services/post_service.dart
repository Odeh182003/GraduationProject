import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class PostService {
  static Future<List<dynamic>> fetchPublicPosts() async {
    final http.Response response;
    if (kIsWeb) {
      response = await http.get(Uri.parse('http://localhost/public_html/FlutterGrad/getPublicPosts.php'));
    } else {
      response = await http.get(Uri.parse('http://192.168.10.5/public_html/FlutterGrad/getPublicPosts.php'));
    }

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load public posts');
    }
  }
}
