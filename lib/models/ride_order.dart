import 'package:ryde_rw/firestore_stub.dart';

class RideOrder {
  final String? id;
  final Timestamp createdAt;
  final String dateTime;
  final String estimatedPrice;
  final String from;
  final String status;
  final String to;
  final String userId;
  final String vehicleType;

  RideOrder({
    this.id,
    required this.createdAt,
    required this.dateTime,
    required this.estimatedPrice,
    required this.from,
    required this.status,
    required this.to,
    required this.userId,
    required this.vehicleType,
  });

  factory RideOrder.fromMap(Map<String, dynamic> map, {String? docId}) {
    return RideOrder(
      id: docId,
      createdAt: map['createdAt'] ?? Timestamp.now(),
      dateTime: map['dateTime'] ?? '',
      estimatedPrice: map['estimatedPrice'] ?? '',
      from: map['from'] ?? '',
      status: map['status'] ?? '',
      to: map['to'] ?? '',
      userId: map['userId'] ?? '',
      vehicleType: map['vehicleType'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'createdAt': createdAt,
      'dateTime': dateTime,
      'estimatedPrice': estimatedPrice,
      'from': from,
      'status': status,
      'to': to,
      'userId': userId,
      'vehicleType': vehicleType,
    };
  }
}