// unified_dashboard.dart
import 'dart:io';
import 'package:bzu_leads/pages/chatting_page.dart';
import 'package:bzu_leads/pages/postsDetails.dart';
import 'package:bzu_leads/services/editPosts.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:bzu_leads/services/ApiConfig.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Shared AppBar
PreferredSizeWidget buildDashboardAppBar({
  required BuildContext context,
  required VoidCallback onNotificationTap,
  String? currentUserID,
  SharedPreferences? prefs,
}) {
  return AppBar(
    backgroundColor: Colors.white,
    foregroundColor: Colors.green,
    elevation: 1,
    title: Row(
      children: [
        Image.network(
          ApiConfig.systemLogoUrl,
          height: 40,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
        ),
        const SizedBox(width: 8),
        const Text(
          "Student Dashboard",
          style: TextStyle(color: Colors.green),
        ),
      ],
    ),
    actions: [
      IconButton(
        icon: const Icon(Icons.notifications, color: Colors.green),
        tooltip: "New Updates",
        onPressed: onNotificationTap,
      ),
    ],
  );
}

/// Responsive layout checker
bool isWideScreen(BuildContext context) {
  return MediaQuery.of(context).size.width > 900;
}

/// Carousel indicator dots
Widget buildCarouselIndicator(int currentIndex, int itemCount) {
  return Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        itemCount,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: currentIndex == index ? Colors.green : Colors.grey,
          ),
        ),
      ),
    ),
  );
}

/// Determines file types from extension
void classifyMedia(String item, List<String> images, List<String> files) {
  final imageExtensions = ["jpg", "jpeg", "png", "gif", "bmp"];
  final ext = item.split('.').last.toLowerCase();
  if (imageExtensions.contains(ext)) {
    images.add(item);
  } else {
    files.add(item);
  }
}

/// Community group list widget
Widget buildMyCommunitiesSection(List<Map<String, dynamic>> chatGroups, SharedPreferences prefs, BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const ListTile(
        leading: Icon(Icons.group, color: Colors.green),
        title: Text("My Communities"),
      ),
      Expanded(
        child: chatGroups.isEmpty
            ? const Center(
                child: Text(
                  "No groups found",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey),
                ),
              )
            : ListView.builder(
                itemCount: chatGroups.length,
                itemBuilder: (context, index) {
                  var group = chatGroups[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      leading: CircleAvatar(
                        backgroundColor: Colors.green.shade100,
                        child: const Icon(Icons.group, color: Colors.green),
                      ),
                      title: Text(
                        group['groupName'],
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        String? senderUsername = prefs.getString("username");
                        if (senderUsername != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChattingPage(
                                groupId: group['groupID'],
                                groupName: group['groupName'],
                                senderUsername: senderUsername,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
      ),
    ],
  );
}

/// Shimmer loading card
Widget buildShimmerCard() {
  return Card(
    margin: const EdgeInsets.symmetric(vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    child: Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 250,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.white,
        ),
      ),
    ),
  );
}

/// Media carousel (swipeable images with indicators)
Widget buildMediaCarousel(List<String> mediaList) {
  int currentIndex = 0;
  return StatefulBuilder(
    builder: (context, setState) {
      return Column(
        children: [
          SizedBox(
            height: 250,
            child: PageView.builder(
              itemCount: mediaList.length,
              onPageChanged: (index) {
                setState(() {
                  currentIndex = index;
                });
              },
             itemBuilder: (context, index) {
            final imageUrl = "${ApiConfig.baseUrl}/${mediaList[index]}"; 
            return ClipRRect(
             borderRadius: BorderRadius.circular(16),
             child: Image.network(
             imageUrl,
             fit: BoxFit.contain,
             height: 250,
             errorBuilder: (context, error, stackTrace) => Container(
             color: Colors.grey[300],
             height: 250,
             child: Icon(Icons.broken_image, size: 100, color: Colors.grey[600]),
      ),
    ),
  );
},
            ),
          ),
          if (mediaList.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  mediaList.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: currentIndex == index ? Colors.green : Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

/// Post card (for student, academic, official dashboards)
Widget buildPostCard({
  required BuildContext context,
  required dynamic post,
  String? currentUserID,
  SharedPreferences? prefs,
  Future<void> Function()? reloadPosts,
  bool showEditPen = false,
  bool showFiles = true,
}) {
  final List<dynamic> mediaList = post['media'] is List ? post['media'] : [];

  // Separate images and files by extension
  final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
  final List<String> images = [];
  final List<String> files = [];

  for (var item in mediaList) {
    if (item is String) {
      final ext = item.split('.').last.toLowerCase();
      if (imageExtensions.contains(ext)) {
        images.add(item);
      } else {
        files.add(item);
      }
    }
  }

  // Get current user ID for edit permission
  final String? currentUserId = currentUserID;

  Future<void> _downloadFile(String url, String fileName) async {
    try {
      Directory? downloadsDir;
      try {
        downloadsDir = await getDownloadsDirectory();
      } catch (e) {
        downloadsDir = await getApplicationDocumentsDirectory();
      }
      if (downloadsDir == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Cannot access downloads directory.")),
        );
        return;
      }
      final savePath = "${downloadsDir.path}/$fileName";
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final file = File(savePath);
        await file.writeAsBytes(response.bodyBytes);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Downloaded to $savePath")),
        );
        try {
          await OpenFile.open(savePath);
        } catch (_) {}
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to download file (status ${response.statusCode}).")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error downloading file: $e")),
      );
    }
  }

  return AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeInOut,
    margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.15),
          spreadRadius: 2,
          blurRadius: 8,
          offset: const Offset(0, 4),
        )
      ],
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Postsdetails(postID: int.parse(post['postID'])),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row with Avatar and user info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.green,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post['username'],
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "(${post['universityID']})",
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      post['DATECREATED'],
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    if (currentUserId != null &&
                        post['universityID']?.toString() == currentUserId)
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.green),
                        tooltip: "Edit Post",
                        onPressed: () => showEditPostDialog(
                          context: context,
                          post: post,
                          currentUserID: currentUserId,
                          prefs: prefs,
                          reloadPosts: reloadPosts ?? () async {},
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Divider to separate header and content
            Container(
              height: 1,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 12),
            // Post title and content
            Text(
              post['posttitle'],
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              post['CONTENT'],
              style: const TextStyle(fontSize: 15, height: 1.4),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            // --- Media section for images and files ---
            if (images.isNotEmpty)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: buildMediaCarousel(images),
                ),
              )
            else
              Center(
                child: Container(
                  height: 250,
                  color: Colors.grey[300],
                  child: Center(
                    child: Icon(Icons.image, size: 100, color: Colors.grey[600]),
                  ),
                ),
              ),
            if (files.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Attachments:", style: TextStyle(fontWeight: FontWeight.w600)),
                    ...files.map((file) {
                      final fileName = file.split('/').last;
                      final fileUrl = "${ApiConfig.baseUrl}/$file";
                      return ListTile(
                        leading: Icon(Icons.attach_file, color: Colors.green),
                        title: Text(fileName, overflow: TextOverflow.ellipsis),
                        onTap: () async {
                          await _downloadFile(fileUrl, fileName);
                        },
                        trailing: Icon(Icons.download, color: Colors.green),
                      );
                    }).toList(),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// Drawer navigation (pass items as needed)
Widget buildDrawerNavigation({
  required BuildContext context,
  required String? username,
  required String? userID,
  required List<Widget> items,
}) {
  return ListView(
    padding: EdgeInsets.zero,
    children: [
      DrawerHeader(
        decoration: const BoxDecoration(
          color: Colors.green,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 36, color: Colors.green),
            ),
            const SizedBox(height: 12),
            Text(
              username ?? "",
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              userID ?? "",
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
      ...items,
    ],
  );
}

/// Side navigation (pass destinations and onDestinationSelected)
Widget buildSideNav({
  required int selectedIndex,
  required void Function(int) onDestinationSelected,
  required List<NavigationRailDestination> destinations,
}) {
  return Container(
    color: Colors.white,
    height: double.infinity,
    child: SingleChildScrollView(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: 0,
          maxHeight: double.infinity,
        ),
        child: IntrinsicHeight(
          child: NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            labelType: NavigationRailLabelType.all,
            backgroundColor: Colors.white,
            destinations: destinations,
          ),
        ),
      ),
    ),
  );
}
