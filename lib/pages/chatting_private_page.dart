import 'package:bzu_leads/components/my_textfields.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
//import 'package:shared_preferences/shared_preferences.dart';

class PrivateChattingPage extends StatefulWidget {
  final String peerId; // This should be academicID from academicRoom.dart
  final String peerName;
  final String currentUserName;
  final String currentUserId;

  const PrivateChattingPage({
    Key? key,
    required this.peerId,
    required this.peerName,
    required this.currentUserName,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<PrivateChattingPage> createState() => _PrivateChattingPageState();
}

class _PrivateChattingPageState extends State<PrivateChattingPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  FocusNode myFocus = FocusNode();

  String get chatId {
    // Use both user IDs, sorted, joined by underscore, for a unique and distinct chat document per pair
    final ids = [widget.currentUserId, widget.peerId]..sort();
    return 'privatechat_${ids[0]}_${ids[1]}'; // Prefix for clarity and uniqueness
  }

  @override
  void initState() {
    super.initState();
    myFocus.addListener(() {
      if (myFocus.hasFocus) {
        Future.delayed(
          const Duration(milliseconds: 500),
          () => scrollDown(),
        );
      }
    });
  }

  @override
  void dispose() {
    myFocus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void scrollDown() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(seconds: 1),
      curve: Curves.fastOutSlowIn,
    );
  }

  void sendMessage() async {
    if (widget.currentUserId.isEmpty || _controller.text.trim().isEmpty) return;

    try {
      final chatId = this.chatId; // Use local variable to avoid potential issues
      final privateChatDocRef = _firestore.collection('PrivateChats').doc(chatId);

      // Ensure the PrivateChats document exists
      await privateChatDocRef.set({}, SetOptions(merge: true)); // Create document if it doesn't exist

      final messageRef = privateChatDocRef
          .collection('Messages')
          .doc();

      // Ensure peerId is never null or empty
      final receiverId = widget.peerId.isNotEmpty ? widget.peerId : "unknown_peer";

      await messageRef.set({
        'message': _controller.text.trim(),
        'senderID': widget.currentUserId,
        'senderUsername': widget.currentUserName,
        'receiverID': receiverId, // Always set a value
        'messageID': messageRef.id,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _controller.clear();
      scrollDown();
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.peerName),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.green,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('PrivateChats')
          .doc(chatId)
          .collection('Messages')
          .orderBy('timestamp', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Error loading messages"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        var messages = snapshot.data?.docs ?? [];
        if (messages.isEmpty) {
          return const Center(child: Text("No messages yet"));
        }

        return ListView.builder(
          controller: _scrollController,
          itemCount: messages.length,
          itemBuilder: (context, index) {
            return _buildMessageItem(messages[index]);
          },
        );
      },
    );
  }

  Widget _buildMessageItem(DocumentSnapshot message) {
    var data = message.data() as Map<String, dynamic>?;
    if (data == null) return const SizedBox.shrink();

    String senderID = data['senderID'] ?? 'Unknown';
    String senderUsername = data['senderUsername'] ?? 'Anonymous';
    String receiverID = data['receiverID'] ?? '';
    //String messageID = data['messageID'] ?? '';
    String text = data['message'] ?? '';
    Timestamp? timestamp = data['timestamp'] as Timestamp?;

    bool isMe = senderID == widget.currentUserId;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isMe ? Colors.green[300] : Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(10),
            topRight: const Radius.circular(10),
            bottomLeft: isMe ? const Radius.circular(10) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(10),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              senderUsername,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isMe ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              text,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              "To: $receiverID",//"MsgID: $messageID | 
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[700],
              ),
            ),
            Text(
              timestamp != null ? timestamp.toDate().toLocal().toString().substring(11, 16) : "Pending",
              style: TextStyle(
                fontSize: 12,
                color: isMe ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: MyTextfields(
              hintText: "Message...",
              obscureText: false,
              controller: _controller,
            ),
          ),
          IconButton(
            onPressed: sendMessage,
            icon: const Icon(Icons.send, color: Colors.green),
          ),
        ],
      ),
    );
  }
}
