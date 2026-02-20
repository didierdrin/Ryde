import 'package:ryde_rw/firestore_stub.dart';

class RideNotification {
  final String id;
  final String recipientId;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final bool requiresResponse;

  RideNotification({
    required this.id,
    required this.recipientId,
    required this.title,
    required this.body,
    required this.data,
    required this.type,
    required this.isRead,
    required this.createdAt,
    required this.requiresResponse,
  });

  static DateTime _parseDateTime(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is DateTime) return v;
    if (v is Timestamp) return v.toDate();
    if (v is Map && v['_seconds'] != null) return DateTime.fromMillisecondsSinceEpoch((v['_seconds'] as int) * 1000);
    if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
    return DateTime.now();
  }

  factory RideNotification.fromJson(Map<String, dynamic> json, String id) {
    return RideNotification(
      id: id,
      recipientId: json['recipient_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      data: json['data'] is Map ? Map<String, dynamic>.from(json['data'] as Map) : {},
      type: json['type']?.toString() ?? '',
      isRead: json['is_read'] ?? false,
      createdAt: _parseDateTime(json['created_at']),
      requiresResponse: json['requires_response'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recipient_id': recipientId,
      'title': title,
      'body': body,
      'data': data,
      'type': type,
      'is_read': isRead,
      'created_at': Timestamp.fromDate(createdAt),
      'requires_response': requiresResponse,
    };
  }
} 

