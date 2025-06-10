import 'dart:convert';
import 'package:bzu_leads/services/ApiConfig.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<bool> editPost({
  required int postID,
  required String postTitle,
  required String content,
  required int userID,
  required String defaultRole,
}) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/editPosts.php');

  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'postID': postID,
      'posttitle': postTitle,
      'content': content,
      'userID': userID,
      'defaultRole': defaultRole,
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['success'] == true) {
      print("Edit successful: ${data['message']}");
      return true;
    } else {
      print("Failed to edit: ${data['message']}");
      return false;
    }
  } else {
    print("Server error: ${response.statusCode}");
    return false;
  }
}

Future<void> showEditPostDialog({
  required BuildContext context,
  required dynamic post,
  required String? currentUserID,
  required SharedPreferences? prefs,
  required Future<void> Function() reloadPosts,
}) async {
  final titleController = TextEditingController(text: post['posttitle']);
  final contentController = TextEditingController(text: post['CONTENT']);
  showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text("Edit Post"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Post Title"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: "Content"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final scaffoldContext = dialogContext;
              Navigator.pop(dialogContext);
              final success = await editPost(
                postID: int.parse(post['postID'].toString()),
                postTitle: titleController.text,
                content: contentController.text,
                userID: int.parse(currentUserID ?? '0'),
                defaultRole: prefs?.getString("defaultRole") ?? "",
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                SnackBar(
                  content: Text(success
                      ? "Post updated successfully."
                      : "Failed to update post."),
                ),
              );
              if (success) {
                await reloadPosts();
              }
            },
            child: const Text("Save"),
          ),
        ],
      );
    },
  );
}

