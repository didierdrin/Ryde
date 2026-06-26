import 'package:ryde_rw/models/offer_pool_model.dart';
import 'package:ryde_rw/models/request_model.dart';
import 'package:ryde_rw/shared/locations_shared.dart';

DateTime _parseDateTime(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}

Location _locationFromTrip(Map<String, dynamic> trip, {required bool pickup}) {
  if (pickup) {
    return Location(
      address: trip['pickupAddress'] ?? trip['pickup_address'] ?? '',
      latitude: (trip['pickupLatitude'] ?? trip['pickup_latitude'] ?? 0).toDouble(),
      longitude: (trip['pickupLongitude'] ?? trip['pickup_longitude'] ?? 0).toDouble(),
    );
  }
  return Location(
    address: trip['destinationAddress'] ?? trip['destination_address'] ?? '',
    latitude: (trip['destinationLatitude'] ?? trip['destination_latitude'] ?? 0).toDouble(),
    longitude: (trip['destinationLongitude'] ?? trip['destination_longitude'] ?? 0).toDouble(),
  );
}

String _tripStatus(Map<String, dynamic> trip) =>
    (trip['status'] ?? 'REQUESTED').toString();

PassengerOfferPool tripJsonToOfferPool(Map<String, dynamic> trip) {
  final status = _tripStatus(trip);
  return PassengerOfferPool(
    id: trip['tripId'] ?? trip['trip_id'],
    pickupLocation: _locationFromTrip(trip, pickup: true),
    dropoffLocation: _locationFromTrip(trip, pickup: false),
    dateTime: _parseDateTime(trip['requestTime'] ?? trip['request_time']),
    pricePerSeat: (trip['fare'] as num?)?.toInt() ?? 0,
    user: trip['passengerName'] ??
        trip['passenger_name'] ??
        trip['passengerUserId'] ??
        trip['passenger_user_id'] ??
        '',
    completed: status == 'COMPLETED' || status == 'CANCELLED',
    pending: status == 'REQUESTED',
    isRideStarted: status == 'IN_PROGRESS' || status == 'ACCEPTED',
    isSeatFull: false,
    type: trip['serviceType'] ?? trip['service_type'] ?? 'passengers',
    countryCode: '+250',
    emptySeat: 1,
  );
}

RequestRide tripJsonToRequestRide(Map<String, dynamic> trip) {
  final status = _tripStatus(trip);
  return RequestRide(
    id: trip['tripId'] ?? trip['trip_id'],
    rider: trip['driverUserId'] ?? trip['driver_user_id'] ?? '',
    pickupLocation: _locationFromTrip(trip, pickup: true),
    dropoffLocation: _locationFromTrip(trip, pickup: false),
    requestedTime: _parseDateTime(trip['requestTime'] ?? trip['request_time']),
    requestedBy: trip['passengerUserId'] ??
        trip['passenger_user_id'] ??
        trip['passengerName'] ??
        trip['passenger_name'] ??
        '',
    offerpool: trip['tripId'] ?? trip['trip_id'] ?? '',
    accepted: status == 'ACCEPTED' || status == 'IN_PROGRESS' || status == 'COMPLETED',
    completed: status == 'COMPLETED',
    cancelled: status == 'CANCELLED',
    price: (trip['fare'] as num?)?.toInt(),
    seats: 1,
    type: trip['serviceType'] ?? trip['service_type'] ?? 'passengers',
    countryCode: '+250',
  );
}

Map<String, dynamic> offerPoolToTripPayload(PassengerOfferPool pool) {
  return {
    'pickupLatitude': pool.pickupLocation.latitude,
    'pickupLongitude': pool.pickupLocation.longitude,
    'pickupAddress': pool.pickupLocation.address,
    'destinationLatitude': pool.dropoffLocation.latitude,
    'destinationLongitude': pool.dropoffLocation.longitude,
    'destinationAddress': pool.dropoffLocation.address,
    'distance': 5,
    'fare': pool.pricePerSeat,
    'serviceType': 'Pool',
  };
}

Map<String, dynamic> requestRideToTripPayload(RequestRide request) {
  return {
    'pickupLatitude': request.pickupLocation.latitude,
    'pickupLongitude': request.pickupLocation.longitude,
    'pickupAddress': request.pickupLocation.address,
    'destinationLatitude': request.dropoffLocation.latitude,
    'destinationLongitude': request.dropoffLocation.longitude,
    'destinationAddress': request.dropoffLocation.address,
    'distance': 5,
    'fare': request.price ?? 0,
    'serviceType': 'Pool',
  };
}

List<Map<String, dynamic>> tripsFromResponse(Map<String, dynamic> response) {
  final raw = response['trips'];
  if (raw is! List) return [];
  return raw.map((item) => Map<String, dynamic>.from(item as Map)).toList();
}
