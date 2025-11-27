import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  String id;
  String title;
  String content;
  DateTime date;
  String authorName;

  Post({
    this.id = '',
    required this.title,
    required this.content,
    required this.date,
    required this.authorName,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'date': Timestamp.fromDate(date),
      'authorName': authorName,
    };
  }

  factory Post.fromMap(Map<String, dynamic> data, String id) {
    return Post(
      id: id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      authorName: data['authorName'] ?? 'Teacher',
    );
  }
}