import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GroupService {
  static Future<List<Map<String, dynamic>>> getChatGroups(String universityID) async {
    final List<Map<String, dynamic>> fetchedGroups = [];
    final Set<String> uniqueGroupIDs = {};

    try {
      var url = Uri.parse("http://localhost/public_html/FlutterGrad/login.php?universityID=$universityID");
      var response = await http.get(url);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        if (data['success']) {
          if (data['studentData'] != null) {
            List<String> sectionIDs = List<String>.from(data['studentData']['sectionIDs'] ?? []);
            final prefs = await SharedPreferences.getInstance();
            await prefs.setStringList("sectionIDs", sectionIDs);

            for (String sectionID in sectionIDs) {
              var sectionUrl = Uri.parse("http://localhost/public_html/FlutterGrad/chatting_groups.php?section_id=$sectionID");
              var sectionResponse = await http.get(sectionUrl);
              if (sectionResponse.statusCode == 200) {
                var sectionData = jsonDecode(sectionResponse.body);
                if (sectionData['success']) {
                  String uniqueID = "${sectionData['groupName']}_sec_$sectionID";
                  if (!uniqueGroupIDs.contains(uniqueID)) {
                    uniqueGroupIDs.add(uniqueID);
                    fetchedGroups.add({
                      'groupID': uniqueID,
                      'groupName': sectionData['groupName'],
                    });
                  }
                }
              }
            }
          }

          if (data['departmentClubHeadData'] != null) {
            for (var club in data['departmentClubHeadData']['clubs'] ?? []) {
              String uniqueID = "dep_${club['clubID']}";
              if (!uniqueGroupIDs.contains(uniqueID)) {
                uniqueGroupIDs.add(uniqueID);
                fetchedGroups.add({
                  'groupID': uniqueID,
                  'groupName': club['clubName'],
                });
              }
            }
          }

          if (data['departmentClubMemberData'] != null) {
            for (var club in data['departmentClubMemberData']['clubs'] ?? []) {
              String uniqueID = "dep_${club['clubID']}";
              if (!uniqueGroupIDs.contains(uniqueID)) {
                uniqueGroupIDs.add(uniqueID);
                fetchedGroups.add({
                  'groupID': uniqueID,
                  'groupName': club['clubName'],
                });
              }
            }
          }

          if (data['studentClub'] != null) {
            String clubID = data['studentClub']['studentclubID'];
            String clubName = data['studentClub']['studentclubname'];
            String uniqueID = "stud_$clubID";
            if (!uniqueGroupIDs.contains(uniqueID)) {
              uniqueGroupIDs.add(uniqueID);
              fetchedGroups.add({
                'groupID': uniqueID,
                'groupName': clubName,
              });
            }
          }

          if (data['roles']?.contains('academic') ?? false) {
            var academicUrl = Uri.parse("http://localhost/public_html/FlutterGrad/chatting_groups.php?academic_id=$universityID");
            var academicResponse = await http.get(academicUrl);
            if (academicResponse.statusCode == 200) {
              var academicData = jsonDecode(academicResponse.body);
              if (academicData['success']) {
                for (var section in academicData['sections']) {
                  String uniqueID = "${section['courseName']} - Section ${section['sectionID']}_sec_${section['sectionID']}";
                  if (!uniqueGroupIDs.contains(uniqueID)) {
                    uniqueGroupIDs.add(uniqueID);
                    fetchedGroups.add({
                      'groupID': uniqueID,
                      'groupName': "${section['courseName']} - Section ${section['sectionID']}",
                    });
                  }
                }
              }
            }
          }

          if (data['roles']?.contains('official') ?? false) {
            var officialUrl = Uri.parse("http://localhost/public_html/FlutterGrad/chatting_groups.php?official_id=$universityID");
            var officialResponse = await http.get(officialUrl);
            if (officialResponse.statusCode == 200) {
              var officialData = jsonDecode(officialResponse.body);
              if (officialData['success']) {
                for (var group in officialData['officialGroups'] ?? []) {
                  String uniqueID = "official_${group['groupID']}";
                  if (!uniqueGroupIDs.contains(uniqueID)) {
                    uniqueGroupIDs.add(uniqueID);
                    fetchedGroups.add({
                      'groupID': uniqueID,
                      'groupName': group['groupName'],
                    });
                  }
                }
              }
            }
          }
        }
      }
    } catch (e) {
      print("Error in GroupService: $e");
    }

    return fetchedGroups;
  }
}
