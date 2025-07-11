import 'package:bzu_leads/pages/chatting_private_page.dart';
import 'package:bzu_leads/services/ApiConfig.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrivateChats extends StatefulWidget {
  const PrivateChats({Key? key}) : super(key: key);

  @override
  State<PrivateChats> createState() => _PrivateChatsState();
}

class _PrivateChatsState extends State<PrivateChats> {
  String? academicId;
  String? academicName;
  SharedPreferences? _prefs;

  @override
  void initState() {
    print('initState called'); // Add this line
    super.initState();
    _initializeUser();
    // Add this test
    try {
      FirebaseFirestore.instance.collection('PrivateChats').snapshots().listen((snapshot) {
        print('TEST: PrivateChats docs count: ${snapshot.docs.length}');
        for (var doc in snapshot.docs) {
          print('TEST: doc.id=${doc.id}');
        }
      });
    } catch (e) {
      print('Error setting up stream listener: $e');
    }
  }

  Future<void> _initializeUser() async {
    _prefs = await SharedPreferences.getInstance();
    final loadedAcademicId = _prefs?.getString("universityID")?.trim();
    final loadedAcademicName = _prefs?.getString("username")?.trim();

    print('Loaded academicId: $loadedAcademicId, academicName: $loadedAcademicName');

    setState(() {
      academicId = loadedAcademicId;
      academicName = loadedAcademicName;
    });
  }

  Stream<List<Map<String, dynamic>>> _privateChatsStream() {
    if (academicId == null) {
      print('academicId is null, returning empty stream');
      return Stream.value([]);
    }
    print('Setting up stream for academicId: $academicId');

    // Listen to all documents in PrivateChats collection
    return FirebaseFirestore.instance
        .collection('PrivateChats')
        .snapshots()
        .asyncMap((privateChatsSnapshot) async {
      print('Fetched ${privateChatsSnapshot.docs.length} PrivateChats documents');

      List<Map<String, dynamic>> chats = [];

      // Iterate through each document in PrivateChats
      for (var privateChatDoc in privateChatsSnapshot.docs) {
        final privateChatDocId = privateChatDoc.id;

        // Check if the document ID matches the expected pattern and contains the academicId
        final parts = privateChatDocId.split('_');
        if (parts.length == 3 && parts[2].trim() == academicId) {
          print('Found relevant chat doc: $privateChatDocId');

          final senderId = parts[1];

          // Query the Messages subcollection for the last message
          final messagesQuery = FirebaseFirestore.instance
              .collection('PrivateChats')
              .doc(privateChatDocId)
              .collection('Messages')
              .orderBy('timestamp', descending: true)
              .limit(1);

          final messagesSnapshot = await messagesQuery.get(); // Changed to .get()

          if (messagesSnapshot.docs.isNotEmpty) {
            final messageData = messagesSnapshot.docs.first.data(); // Removed unnecessary type cast
            final lastMessage = messageData['message'] ?? '';
            final senderName = messageData['senderUsername'] ?? "Student $senderId";

            chats.add({
              'chatDocId': privateChatDocId,
              'senderId': senderId,
              'senderUsername': senderName,
              'message': lastMessage,
            });
            print('Added chat: $privateChatDocId with last message');
          } else {
            print('No messages found in chat: $privateChatDocId');
          }
        } else {
          print('Irrelevant chat doc: $privateChatDocId');
        }
      }
      print('Returning ${chats.length} chats');
      return chats;
    });
  }

  void _navigateToPrivateChat(Map<String, dynamic> chat) {
    if (academicId == null || academicName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: User not authenticated")),
      );
      return;
    }

    final peerId = chat['senderId'] ?? ''; // Ensure peerId is not null
    final peerName = chat['senderUsername'] ?? 'Unknown'; // Ensure peerName is not null

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrivateChattingPage(
          peerId: peerId,
          peerName: peerName,
          currentUserId: academicId!,
          currentUserName: academicName!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  backgroundColor: Colors.white,
  foregroundColor: Colors.green,
  elevation: 1,
  title: Row(
    children: [
      Image.network(
        ApiConfig.systemLogoUrl,
        height: 40,
        errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image),
      ),
      const SizedBox(width: 8), // Space between image and text
      const Text(
        "Private Chats",
        style: TextStyle(
          color: Colors.green, 
        ),
      ),
    ],
  ),
      ),
      body: academicId == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: _privateChatsStream(),
              builder: (context, snapshot) {
                print('StreamBuilder: connectionState=${snapshot.connectionState}, hasData=${snapshot.hasData}');
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final chats = snapshot.data ?? [];
                print('StreamBuilder: chats.length=${chats.length}');
                if (chats.isEmpty) {
                  return const Center(child: Text("No private chats found."));
                }
                return ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                      child: ListTile(
                        leading: const Icon(Icons.person, color: Colors.green, size: 36),
                        title: Text(
                          chat['senderUsername'],
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
                        ),
                        subtitle: Text(
                          chat['message'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chat, color: Colors.green),
                        onTap: () => _navigateToPrivateChat(chat),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
