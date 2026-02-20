import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location_geocoder/location_geocoder.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:ryde_rw/models/offer_pool_model.dart';
import 'package:ryde_rw/models/request_model.dart';
import 'package:ryde_rw/shared/shared_states.dart';
import 'package:ryde_rw/utils/contants.dart';

class LocationService {
  static Future<Map<String, double>> getCoordinatesFromAddress(
    String address,
  ) async {
    final LocatitonGeocoder geocoder = LocatitonGeocoder(apiKey);
    final response = await geocoder.findAddressesFromQuery(address);
    if (response.isNotEmpty) {
      final res = response.first.coordinates;
      return {'lat': res.latitude ?? 0.0, 'long': res.longitude ?? 0.0};
    }
    return {'lat': 0.0, 'long': 0.0};
  }

  static double? getDistanceFind(
    RequestRide passengers,
    Map<String, dynamic> location,
  ) {
    if (location.isEmpty) return null;
    final coordinates = passengers.pickupLocation;

    double distance = Geolocator.distanceBetween(
      location['lat'] as double,
      location['long'] as double,
      coordinates.latitude,
      coordinates.longitude,
    );
    double distanceInKm = distance / 1000;
    return distanceInKm;
  }

  static double? getDistanceOffer(
    PassengerOfferPool driver,
    Map<String, dynamic> location,
  ) {
    if (location.isEmpty) return null;
    final coordinates = driver.pickupLocation;

    double distance = Geolocator.distanceBetween(
      location['lat'] as double,
      location['long'] as double,
      coordinates.latitude,
      coordinates.longitude,
    );
    double distanceInKm = distance / 1000;
    return distanceInKm;
  }

  static double calculateDistance(pickup, dropoff) {
    return Geolocator.distanceBetween(
          pickup.latitude,
          pickup.longitude,
          dropoff.latitude,
          dropoff.longitude,
        ) /
        1000;
  }

  static Future<String> getAddressFromCoordinates(
    double lat,
    double long,
  ) async {
    final LocatitonGeocoder geocoder = LocatitonGeocoder(apiKey);
    final addresses = await geocoder.findAddressesFromCoordinates(
      Coordinates(lat, long),
    );
    if (addresses.isEmpty) return '';
    return addresses.first.addressLine ?? '';
  }

  static Future<Map<String, dynamic>> getCountryAddressFromCoordinates(
    double lat,
    double long,
  ) async {
    final LocatitonGeocoder geocoder = LocatitonGeocoder(apiKey);
    final addresses = await geocoder.findAddressesFromCoordinates(
      Coordinates(lat, long),
    );
    if (addresses.isEmpty) return {};
    return {
      'address': addresses.first.addressLine ?? '',
      'country': addresses.first.countryName ?? '',
    };
  }

  static Future<void> locationStreaming(WidgetRef ref) async {
    final user = ref.read(userProvider);
    late LocationSettings locationSettings;
    if (Platform.isAndroid) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        forceLocationManager: true,
        intervalDuration: const Duration(seconds: 5),
      );
    } else if (Platform.isIOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.fitness,
        distanceFilter: 5,
        pauseLocationUpdatesAutomatically: true,
        showBackgroundLocationIndicator: false,
      );
    }
    Geolocator.getPositionStream(locationSettings: locationSettings).listen((
      Position? position,
    ) async {
      if (position != null && user != null) {
        final address = await getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
        final location = ref.read(locationProvider);
        ref.read(locationProvider.notifier).setLocation({
          ...location,
          'lat': position.latitude,
          'long': position.longitude,
          'address': address,
          'heading': position.heading,
        });
      }
    });
  }
}

class PlacesService {
  Future<List<dynamic>> getAutocompleteSuggestions(String input) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$apiKey&components=country:rw',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['predictions'];
    } else {
      throw Exception("Failed to load suggestions");
    }
  }

  static Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json?placeid=$placeId&key=$apiKey',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['result'];
    } else {
      throw Exception("Failed to load place details");
    }
  }

  Future<Map<String, dynamic>> geocodeAddress(String address) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?address=$address&key=$apiKey',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['results'][0]['geometry']['location'];
    } else {
      throw Exception("Failed to geocode address");
    }
  }

  Future<String> reverseGeocode(LatLng location) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?latlng=${location.latitude},${location.longitude}&key=$apiKey',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['results'][0]['formatted_address'];
    } else {
      throw Exception("Failed to reverse geocode");
    }
  }

  Future<List<dynamic>> getNearbyPlaces(LatLng location) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${location.latitude},${location.longitude}&radius=1500&type=restaurant&key=$apiKey',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['results'];
    } else {
      throw Exception("Failed to load nearby places");
    }
  }

  static Future<String> getCountryCode(LatLng location) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        return placemarks.first.isoCountryCode ?? 'US';
      }
    } catch (e) {
      debugPrint('Error fetching country code: $e');
    }
    return 'US';
  }

  static Future<String> fetchPlaceIdFromNearbySearch(
    double lat,
    double lng,
  ) async {
    final baseUrl =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json';
    final String nearbyUrl =
        '$baseUrl?location=$lat,$lng&radius=50&key=$apiKey';

    final http.Response response = await http.get(Uri.parse(nearbyUrl));

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);

      if (jsonResponse['status'] == 'OK' &&
          jsonResponse['results'].isNotEmpty) {
        return jsonResponse['results'][0]['place_id'];
      } else {
        throw Exception(
          'No nearby places found. Status: ${jsonResponse['status']}',
        );
      }
    } else {
      throw Exception(
        'Failed to fetch nearby places. HTTP status code: ${response.statusCode}',
      );
    }
  }
}

class LocationsService {
  Stream<Position> get locationStream {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }

  Future<void> checkLocationPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }
  }
}

