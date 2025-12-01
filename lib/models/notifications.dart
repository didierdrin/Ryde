import 'package:cloud_firestore/cloud_firestore.dart';

class UserNotification {
  final String id;
  final String title;
  final String body;
  final String userId;
  final bool isRead;
  final Map<String, dynamic> data;
  final DateTime createdAt;

  UserNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.userId,
    required this.isRead,
    required this.data,
    required this.createdAt,
  });

  factory UserNotification.fromJson(Map<String, dynamic> json, String id) {
    return UserNotification(
      id: id,
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      userId: json['user_id'] ?? '',
      isRead: json['isRead'] ?? false,
      data: json['data'] ?? {},
      createdAt: (json['created_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'body': body,
      'user_id': userId,
      'isRead': isRead,
      'data': data,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}

