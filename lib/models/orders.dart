import 'package:cloud_firestore/cloud_firestore.dart';

class UserOrder {
  final String orderId;
  final String parcelType;
  final String pickupAddress;
  final GeoPoint pickupGps;
  final String dropoffAddress;
  final GeoPoint dropoffGps;
  final String receiverName;
  final String receiverPhone;

  // Constructor
  UserOrder({
    required this.orderId,
    required this.parcelType,
    required this.pickupAddress,
    required this.pickupGps,
    required this.dropoffAddress,
    required this.dropoffGps,
    required this.receiverName,
    required this.receiverPhone,
  });

  // Factory constructor to create a UserOrder from a Map (e.g., from Firestore)
  factory UserOrder.fromMap(Map<String, dynamic> map) {
    return UserOrder(
      orderId: map['order_id'] ?? '',
      parcelType: map['parcel_type'] ?? '',
      pickupAddress: map['pickup_address'] ?? '',
      pickupGps: map['pickup_gps'] ?? GeoPoint(0, 0), // Default GeoPoint if null
      dropoffAddress: map['dropoff_address'] ?? '',
      dropoffGps: map['dropoff_gps'] ?? GeoPoint(0, 0), // Default GeoPoint if null
      receiverName: map['receiver_name'] ?? '',
      receiverPhone: map['receiver_phone'] ?? '',
    );
  }


  Map<String, dynamic> toMap() {
    return {
      'order_id': orderId,
      'parcel_type': parcelType,
      'pickup_address': pickupAddress,
      'pickup_gps': pickupGps,
      'dropoff_address': dropoffAddress,
      'dropoff_gps': dropoffGps,
      'receiver_name': receiverName,
      'receiver_phone': receiverPhone,
    };
  }
}
