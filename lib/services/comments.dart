// comment.dart or services/comments.dart

class Comment {
  final int id;
  final int creatorId;
  final String text;
  final String timestamp;

  Comment({
    required this.id,
    required this.creatorId,
    required this.text,
    required this.timestamp,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: int.parse(json['COMMENTID'].toString()),
      creatorId: int.parse(json['COMMENTCREATORID'].toString()),
      text: json['COMMENTTEXT'],
      timestamp: json['TIMESTAMP'],
    );
  }
}
