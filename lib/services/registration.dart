import 'dart:convert';
import 'package:http/http.dart' as http;

class RegistrationService {
  static Future<Map<String, dynamic>> registerUser(
      {required String universityID,
      required String username,
      required String password,
      required int roleID,
      String? gender,
      String? dateOfBirth,
      String? palestinianIDNumber,
      String? image,
      int? facultyID,
      int? departmentID,
      String? major,
      String? minor,
      String? email,
      String? officeHours,
      String? room,
      String? hobbies}) async {
    final url = Uri.parse('http://192.168.10.3/public_html/FlutterGrad/registration.php');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'universityID': universityID,
          'username': username,
          'password': password,
          'roleID': roleID,
          'GENDER': gender ?? '',
          'DATEOFBIRTH': dateOfBirth ?? '',
          'PALESTINIANIDNUMBER': palestinianIDNumber ?? '',
          'image': image ?? '',
          'facultyID': facultyID,
          'DEPARTMENTID': departmentID,
          'major': major ?? '',
          'minor': minor ?? '',
          'email': email ?? '',
          'officeHours': officeHours ?? '',
          'room': room ?? '',
          'HOBBIES': hobbies ?? '',
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'success': false, 'message': 'Failed to connect to the server'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}
