import 'package:ryde_rw/shared/locations_shared.dart';

class Collections {
  final String users = 'users';
  final String application = 'application';
  final String region = 'region';
  final String notifications = 'notifications';
  final String vehicle = 'vehicles';
  final String profileinfo = 'profiles_info';
  final String findPool = 'findPool';
  final String offerpool = 'offerPool';
  final String request = 'requestRiders';
  final String userLocations = 'userLocations';
  final String messages = 'messages';
  final String regions = 'regions';
  final String whatsappRides = 'whatsappRides';
}

Collections collections = Collections();

const String apiKey = 'AIzaSyC0hBNKoBnYhqmle-QoJwk4_GObUQGm3E8';

final List<Map<String, dynamic>> seats = [
  {"label": "1 Seat", "value": 1},
  {"label": "2 Seats", "value": 2},
  {"label": "3 Seats", "value": 3},
  {"label": "4 Seats", "value": 4},
  {"label": "5 Seats", "value": 5},
  {"label": "6 Seats", "value": 6},
  {"label": "7 Seats", "value": 7},
  {"label": "8 Seats", "value": 8},
  {"label": "9 Seats", "value": 9},
  {"label": "10 Seats", "value": 10},
];

final List<Map<String, dynamic>> weights = [
  {"label": "500kg", "value": 500, "measure": "kg"},
  {"label": "1 Ton", "value": 1000, "measure": "ton"},
  {"label": "2 Tons", "value": 2000, "measure": "ton"},
  {"label": "3 Tons", "value": 3000, "measure": "ton"},
  {"label": "4 Tons", "value": 4000, "measure": "ton"},
  {"label": "5 Tons", "value": 5000, "measure": "ton"},
  {"label": "6 Tons", "value": 6000, "measure": "ton"},
  {"label": "7 Tons", "value": 7000, "measure": "ton"},
  {"label": "8 Tons", "value": 8000, "measure": "ton"},
  {"label": "9 Tons", "value": 9000, "measure": "ton"},
  {"label": "10 Tons", "value": 10000, "measure": "ton"},
];

class LocationPair {
  final Location pickupLocation;
  final Location dropoffLocation;

  LocationPair({required this.pickupLocation, required this.dropoffLocation});
}

const String playStore =
    'https://play.google.com/store/apps/details?id=com.ikanisa.lifuti';
const String appleStore = 'https://apps.apple.com/rw/app/rifuti/id6474266973';

class LocationDD {
  final String address;
  final double latitude;
  final double longitude;

  LocationDD({
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {'address': address, 'latitude': latitude, 'longitude': longitude};
  }

  factory LocationDD.fromMap(Map<String, dynamic> map) {
    return LocationDD(
      address: map['address'],
      latitude: map['latitude'],
      longitude: map['longitude'],
    );
  }
  @override
  String toString() {
    return 'Location(address: $address, latitude: $latitude, longitude: $longitude)';
  }
}

const List<String> vehicleTypes = ["Taxi/Cab", "Moto", "Truck", "Three Wheels"];

enum TransactionStatus { pending, completed, failed }

enum TransactionType {
  deposit,
  withdrawal,
  transfer,
  payment,
  credit,
  tripPayment,
}

