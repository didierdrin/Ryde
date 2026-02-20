import 'package:ryde_rw/firestore_stub.dart';
import 'package:ryde_rw/shared/locations_shared.dart';

class PassengerFindPool {
  final String? id;
  final Location pickupLocation;
  final Location dropoffLocation;
  final Timestamp dateTime;
  final int selectedSeat;
  final String user;
  final String? acceptedByDriver;
  final bool? pending;
  final bool? accepted;
  final bool? completed;
  final String? countryCode;

  PassengerFindPool({
    this.id,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.dateTime,
    required this.selectedSeat,
    required this.user,
    this.acceptedByDriver,
    this.pending,
    this.accepted,
    this.completed,
    this.countryCode,
  });

  Map<String, dynamic> toMap() {
    return {
      'pickupLocation': pickupLocation.toMap(),
      'dropoffLocation': dropoffLocation.toMap(),
      'dateTime': dateTime,
      'selectedSeat': selectedSeat,
      'user': user,
      'acceptedByDriver': acceptedByDriver,
      'pending': pending,
      'accepted': accepted,
      'completed': completed,
      'country_code': countryCode,
    };
  }

  factory PassengerFindPool.fromMap(Map<String, dynamic> map) {
    return PassengerFindPool(
      id: map['id'] ?? '',
      pickupLocation: Location.fromMap(map['pickupLocation']),
      dropoffLocation: Location.fromMap(map['dropoffLocation']),
      dateTime: map['dateTime'],
      selectedSeat: map['selectedSeat'],
      user: map['user'],
      acceptedByDriver: map['acceptedByDriver'],
      pending: map['pending'],
      accepted: map['accepted'],
      completed: map['completed'],
      countryCode: map['country_code'],
    );
  }
}

