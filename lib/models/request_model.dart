import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ryde_rw/shared/locations_shared.dart';

class RequestRide {
  String? id;
  String rider;
  Location pickupLocation;
  Location dropoffLocation;
  Timestamp requestedTime;
  String requestedBy;
  Timestamp? createdAt;
  String offerpool;
  bool rejected;
  bool accepted;
  bool pickup;
  bool dropoff;
  bool paid;
  int? seats;
  int? price;
  bool completed;
  bool cancelled;
  String? measure;
  int? quantity;
  String type;
  String? countryCode;
  bool requested;
  String? notificationId;
  bool isDriverNotified;
  bool isPassengerNotified;

  RequestRide({
    this.id,
    required this.rider,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.requestedTime,
    required this.requestedBy,
    this.createdAt,
    required this.offerpool,
    this.rejected = false,
    this.accepted = false,
    this.paid = false,
    this.pickup = false,
    this.dropoff = false,
    this.seats,
    this.price,
    this.completed = false,
    this.cancelled = false,
    this.measure,
    this.quantity,
    required this.type,
    this.countryCode,
    this.requested = false,
    this.notificationId,
    this.isDriverNotified = false,
    this.isPassengerNotified = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'rider': rider,
      'pickupLocation': pickupLocation.toMap(),
      'dropoffLocation': dropoffLocation.toMap(),
      'requestedTime': requestedTime,
      'requestedBy': requestedBy,
      'offerpool': offerpool,
      'createdAt': createdAt,
      'rejected': rejected,
      'accepted': accepted,
      'pickup': pickup,
      'dropoff': dropoff,
      'paid': paid,
      'seats': seats,
      'price': price,
      'completed': completed,
      'cancelled': cancelled,
      'measure': measure,
      'quantity': quantity,
      'type': type,
      'country_code': countryCode,
      'requested': requested,
      'notification_id': notificationId,
      'is_driver_notified': isDriverNotified,
      'is_passenger_notified': isPassengerNotified,
    };
  }

  factory RequestRide.fromMap(Map<String, dynamic> map) {
    return RequestRide(
      id: map['id'] ?? '',
      rider: map['rider'] ?? '',
      pickupLocation: Location.fromMap(map['pickupLocation']),
      dropoffLocation: Location.fromMap(map['dropoffLocation']),
      requestedTime: map['requestedTime'] ?? Timestamp.now,
      requestedBy: map['requestedBy'] ?? '',
      offerpool: map['offerpool'],
      createdAt: map['createdAt'] ?? Timestamp.now(),
      rejected: map['rejected'] ?? false,
      accepted: map['accepted'] ?? false,
      pickup: map['pickup'] ?? false,
      dropoff: map['dropoff'] ?? false,
      paid: map['paid'] ?? false,
      seats: map['seats'],
      price: map['price'],
      completed: map['completed'] ?? false,
      cancelled: map['cancelled'] ?? false,
      measure: map['measure'],
      quantity: map['quantity'],
      type: map['type'],
      countryCode: map['country_code'],
      requested: map['requested'] ?? false,
      notificationId: map['notification_id'],
      isDriverNotified: map['is_driver_notified'] ?? false,
      isPassengerNotified: map['is_passenger_notified'] ?? false,
    );
  }
}

