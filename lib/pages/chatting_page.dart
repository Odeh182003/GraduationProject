import 'package:bzu_leads/components/my_textfields.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import 'package:image_picker/image_picker.dart';

class ChattingPage extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String senderUsername;

  const ChattingPage({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.senderUsername,
  });

  @override
  _ChattingPageState createState() => _ChattingPageState();
}

class _ChattingPageState extends State<ChattingPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _controller = TextEditingController();
  String? _currentUserId;
  FocusNode myFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    myFocus.addListener((){
      if(myFocus.hasFocus){
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
  final ScrollController _scrollController = ScrollController();
  void scrollDown(){
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent, duration: const Duration(seconds: 1), curve: Curves.fastOutSlowIn);
  }
  Future<void> _loadCurrentUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString("universityID");
    if (mounted) {
      setState(() {
        _currentUserId = userId;
      });
    }
  }

  void sendMessage() async {
    if (_currentUserId == null || _controller.text.trim().isEmpty) return;

    try {
      await _firestore.collection('Groups').doc(widget.groupId).collection('Messages').add({
        'message': _controller.text.trim(),
        'senderID': _currentUserId!,
        'senderUsername': widget.senderUsername,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _controller.clear();
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: Text(widget.groupName),
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.green,
      elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(child: _buildGroupMessageList()),
          _buildGroupMessageInput(),
        ],
      ),
    );
  }

  Widget _buildGroupMessageList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('Groups')
          .doc(widget.groupId)
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
          return const Center(child: Text("No messages in this group yet"));
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
    String text = data['message'] ?? '';
    Timestamp? timestamp = data['timestamp'] as Timestamp?;

    bool isMe = senderID == _currentUserId;

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

  Widget _buildGroupMessageInput() {
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
