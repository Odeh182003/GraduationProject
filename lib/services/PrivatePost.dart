import 'dart:convert';
import 'package:bzu_leads/services/ApiConfig.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class Privatepost {
  static const String _baseWebURL = 'http://localhost/public_html/FlutterGrad/getPublicPosts.php';
  static final String _baseMobileURL = '${ApiConfig.baseUrl}/getPublicPosts.php';

  static String get _baseURL => kIsWeb ? _baseWebURL : _baseMobileURL;

  // Fetch posts filtered by facultyID
  static Future<List<dynamic>> fetchPrivatePostsByFaculty(String? facultyID) async {
    if (facultyID == null || facultyID.isEmpty) {
      throw Exception('Faculty ID not found or empty');
    }

    final Uri url = Uri.parse(_baseURL).replace(queryParameters: {'facultyID': facultyID});

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return compute(_parsePosts, response.bodyBytes);
      } else {
        throw Exception('Failed to load private posts: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Fetch all private posts (for university administrator)
  static Future<List<dynamic>> fetchAllPrivatePosts() async {
    // Use a query parameter to force backend to return all private posts
    final url = Uri.parse('$_baseURL?allPrivate');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return compute(_parsePosts, response.bodyBytes);
      } else {
        throw Exception('Failed to load all private posts: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  static List<dynamic> _parsePosts(List<int> responseBodyBytes) {
    // Decode bytes as UTF-8 string, then parse JSON
    final decodedString = utf8.decode(responseBodyBytes);
    return jsonDecode(decodedString) as List<dynamic>;
  }
}
