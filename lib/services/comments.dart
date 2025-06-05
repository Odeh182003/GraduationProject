class Comment {
  final int id;
  final int creatorId;
  final String username;
  final String text;
  final String timestamp;

  Comment({
    required this.id,
    required this.creatorId,
    required this.username,
    required this.text,
    required this.timestamp,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: int.parse(json['COMMENTID'].toString()),
      creatorId: int.parse(json['COMMENTCREATORID'].toString()),
      username: json['username'] ?? 'Unknown',
      text: json['COMMENTTEXT'],
      timestamp: json['TIMESTAMP'],
    );
  }
}
