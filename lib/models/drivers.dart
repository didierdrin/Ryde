import 'package:ryde_rw/firestore_stub.dart';

class Driver {
  final String driverId;
  final String name;
  final String currentLocationAddress;
  final GeoPoint currentLocationGps;
  final String startingPoint;
  final GeoPoint startingPointGps;
  final String endPoint;
  final GeoPoint endPointGps;

  // Constructor
  Driver({
    required this.driverId,
    required this.name,
    required this.currentLocationAddress,
    required this.currentLocationGps,
    required this.startingPoint,
    required this.startingPointGps,
    required this.endPoint,
    required this.endPointGps,
  });

  // Factory constructor to create a Driver from a Map (e.g., from Firestore)
  factory Driver.fromMap(Map<String, dynamic> map) {
    return Driver(
      driverId: map['driver_id'] ?? '',
      name: map['name'] ?? '',
      currentLocationAddress: map['current_location_address'] ?? '',
      currentLocationGps: GeoPoint.fromDynamic(map['current_location_gps']),
      startingPoint: map['starting_point'] ?? '',
      startingPointGps: GeoPoint.fromDynamic(map['starting_point_gps']),
      endPoint: map['end_point'] ?? '',
      endPointGps: GeoPoint.fromDynamic(map['end_point_gps']),
    );
  }

  // Method to convert Driver to a Map (e.g., for Firestore upload)
  Map<String, dynamic> toMap() {
    return {
      'driver_id': driverId,
      'name': name,
      'current_location_address': currentLocationAddress,
      'current_location_gps': currentLocationGps,
      'starting_point': startingPoint,
      'starting_point_gps': startingPointGps,
      'end_point': endPoint,
      'end_point_gps': endPointGps,
    };
  }
}

