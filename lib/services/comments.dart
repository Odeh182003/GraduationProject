class Comment {
  final int id;
  final int creatorId;
  final String username;
  final String text;
  final String timestamp;
  final String? attachment; 

  Comment({
    required this.id,
    required this.creatorId,
    required this.username,
    required this.text,
    required this.timestamp,
    this.attachment, 
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
  return Comment(
    id: int.tryParse(json['commentid'].toString()) ?? 0,
    creatorId: int.tryParse(json['commentcreatorid'].toString()) ?? 0,
    username: json['username'] ?? 'Unknown',
    text: json['commenttext'] ?? '',
    timestamp: json['timestamp'] ?? '',
    attachment: json['attachment'], 
  );
}

}
