
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Location {
  final String address;
  final double latitude;
  final double longitude;

  Location({
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory Location.fromMap(Map<String, dynamic> map) {
    return Location(
      address: map['address'],
      latitude: map['latitude'],
      longitude: map['longitude'],
    );
  }

  factory Location.fromData(Map<String, dynamic> map) {
    return Location(
      address: map['address'],
      latitude: map['lat'],
      longitude: map['long'],
    );
  }

  LatLng latLng() {
    return LatLng(latitude, longitude);
  }

  @override
  String toString() {
    return 'Location(address: $address, latitude: $latitude, longitude: $longitude)';
  }
}

class PoolTakerRequest {
  String image;
  String rating;
  String title;
  String subTitle;
  String seatCount;
  String amount;
  String pickup;
  String drop;

  PoolTakerRequest({
    required this.image,
    required this.rating,
    required this.title,
    required this.subTitle,
    required this.seatCount,
    required this.amount,
    required this.pickup,
    required this.drop,
    this.isAccepted,
  });

  bool? isAccepted;
}

