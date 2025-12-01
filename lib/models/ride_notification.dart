import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory RideNotification.fromJson(Map<String, dynamic> json, String id) {
    return RideNotification(
      id: id,
      recipientId: json['recipient_id'],
      title: json['title'],
      body: json['body'],
      data: json['data'],
      type: json['type'],
      isRead: json['is_read'] ?? false,
      createdAt: (json['created_at'] as Timestamp).toDate(),
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

