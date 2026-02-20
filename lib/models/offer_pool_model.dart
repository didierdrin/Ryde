import 'package:ryde_rw/shared/locations_shared.dart';

class PassengerOfferPool {
  final String? id;
  final Location pickupLocation;
  final Location dropoffLocation;
  final DateTime dateTime;
  final int? selectedSeat;
  final int pricePerSeat;
  final String user;
  final bool completed;
  final bool pending;
  final bool isSeatFull;
  final List<String> availableSeat;
  final bool isRideStarted;
  final String? measure;
  final int? quantity;
  final String type;
  final String? countryCode;
  final int? emptySeat;

  PassengerOfferPool({
    this.id,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.dateTime,
    this.selectedSeat,
    required this.pricePerSeat,
    required this.user,
    this.completed = false,
    this.pending = false,
    this.isSeatFull = false,
    this.availableSeat = const [],
    this.isRideStarted = false,
    this.measure,
    this.quantity,
    required this.type,
    this.countryCode,
    this.emptySeat,
  });

  Map<String, dynamic> toMap() {
    return {
      'pickupLocation': pickupLocation.toMap(),
      'dropoffLocation': dropoffLocation.toMap(),
      'dateTime': dateTime.toIso8601String(),
      'selectedSeat': selectedSeat,
      'pricePerSeat': pricePerSeat,
      'user': user,
      'completed': completed,
      'pending': pending,
      'availableSeat': availableSeat,
      'isSeatFull': isSeatFull,
      'isRideStarted': isRideStarted,
      'measure': measure,
      'quantity': quantity,
      'type': type,
      'country_code': countryCode,
      'emptySeat': emptySeat,
    };
  }

  static DateTime _parseDateTime(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is DateTime) return v;
    if (v is Map && v['_seconds'] != null) return DateTime.fromMillisecondsSinceEpoch((v['_seconds'] as int) * 1000);
    if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
    return DateTime.now();
  }

  factory PassengerOfferPool.fromMap(Map<String, dynamic> map) {
    return PassengerOfferPool(
      id: map['id'],
      pickupLocation: Location.fromMap(map['pickupLocation'] as Map<String, dynamic>),
      dropoffLocation: Location.fromMap(map['dropoffLocation'] as Map<String, dynamic>),
      dateTime: _parseDateTime(map['dateTime']),
      selectedSeat: map['selectedSeat'],
      pricePerSeat: map['pricePerSeat'] ?? 0,
      user: map['user'] ?? '',
      completed: map['completed'] ?? false,
      pending: map['pending'] ?? false,
      isSeatFull: map['isSeatFull'] ?? false,
      availableSeat: List<String>.from(map['availableSeat'] ?? []),
      isRideStarted: map['isRideStarted'] ?? false,
      measure: map['measure'],
      quantity: map['quantity'],
      type: map['type'] ?? '',
      countryCode: map['country_code'],
      emptySeat: map['emptySeat'],
    );
  }
}
