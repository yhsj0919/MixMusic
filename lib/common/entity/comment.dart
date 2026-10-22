class Comment {
  dynamic id;
  String content, userName;
  String? avatar;
  int? time;
  int likes;

  Comment({
    required this.id,
    required this.content,
    required this.userName,
    this.avatar,
    this.time,
    this.likes = 0,
  });

  Comment.fromJson(Map json)
    : id = json['id'],
      content = json['content'] as String,
      userName = json['userName'] as String,
      avatar = json['avatar'] as String?,
      time = json['time'] as int?,
      likes = json['likes'] as int? ?? 0;
}

typedef CommentPage = ({
  List<Comment> items,
  List<Map<String, dynamic>> categories,
  dynamic category,
  int? total,
  bool hasMore,
  dynamic cursor,
});
