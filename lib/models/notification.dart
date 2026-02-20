import 'package:ryde_rw/firestore_stub.dart';

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

  static DateTime _parseDateTime(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is DateTime) return v;
    if (v is Timestamp) return v.toDate();
    if (v is Map && v['_seconds'] != null) return DateTime.fromMillisecondsSinceEpoch((v['_seconds'] as int) * 1000);
    if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
    return DateTime.now();
  }

  factory UserNotification.fromJson(Map<String, dynamic> json, String id) {
    return UserNotification(
      id: id,
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      userId: json['user_id'] ?? '',
      isRead: json['isRead'] ?? false,
      data: json['data'] is Map ? Map<String, dynamic>.from(json['data'] as Map) : {},
      createdAt: _parseDateTime(json['created_at']),
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

