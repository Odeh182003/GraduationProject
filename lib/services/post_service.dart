import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class PostService {
  static final String _baseUrl = kIsWeb
      ? "http://localhost/public_html/FlutterGrad/getPublicPosts.php"
      : "http://192.168.10.3/public_html/FlutterGrad/getPublicPosts.php";

  static Future<List<dynamic>> fetchPublicPosts() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));

      if (response.statusCode == 200) {
        // Decode with UTF-8 to support Arabic and other languages
        return await compute(_parsePosts, response.bodyBytes);
      } else {
        throw Exception('Failed to load public posts: ${response.statusCode}');
      }
    } catch (e) {
      print("Error: $e");
      rethrow;
    }
  }

  // Background parser
  static List<dynamic> _parsePosts(List<int> responseBodyBytes) {
    // Decode bytes as UTF-8 string, then parse JSON
    final decodedString = utf8.decode(responseBodyBytes);
    return jsonDecode(decodedString) as List<dynamic>;
  }
}
