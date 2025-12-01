import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ryde_rw/utils/contants.dart';

class GooglePlacesService {
  final String apiKey;

  GooglePlacesService(this.apiKey);

  Future<List<Map<String, dynamic>>> searchPlaceAutocomplete(
    String input,
    LatLng location,
  ) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&location=${location.latitude},${location.longitude}&radius=5000&key=$apiKey',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['predictions'] as List)
          .map(
            (prediction) => {
              "placeId": prediction['place_id'],
              "description": prediction['description'],
            },
          )
          .toList();
    } else {
      throw Exception('Failed to load autocomplete results');
    }
  }

  Future<Map<String, dynamic>> getPlaceDetails(String placeId) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$apiKey',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final result = data['result'];
      return {
        "name": result['name'],
        "address": result['formatted_address'],
        "location": result['geometry']['location'],
        "openingHours": result['opening_hours']?['weekday_text'] ?? [],
        "photos": result['photos'] ?? [],
      };
    } else {
      throw Exception('Failed to load place details');
    }
  }

  Future<Map<String, dynamic>> geocodeAddress(String address) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?address=$address&key=$apiKey',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final result = data['results'][0];
      return {
        "location": result['geometry']['location'],
        "formattedAddress": result['formatted_address'],
      };
    } else {
      throw Exception('Failed to geocode address');
    }
  }

  Future<Map<String, dynamic>> reverseGeocode(double lat, double lng) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final result = data['results'][0];
      return {"formattedAddress": result['formatted_address']};
    } else {
      throw Exception('Failed to reverse geocode location');
    }
  }
}

Future<String?> fetchAddress(LatLng location) async {
  final String googleMapsApiKey = apiKey;
  final String geocodeUrl =
      "https://maps.googleapis.com/maps/api/geocode/json?latlng=${location.latitude},${location.longitude}&key=$googleMapsApiKey";

  try {
    final response = await http.get(Uri.parse(geocodeUrl));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      if (data['status'] == 'OK' && data['results'].isNotEmpty) {
        List<dynamic> addressComponents =
            data['results'][0]['address_components'];

        String? streetName;
        String? subLocality;
        String? locality;
        String? placeName;

        for (var component in addressComponents) {
          List<dynamic> types = component['types'];

          if (types.contains("route")) {
            streetName = component['long_name']; // Named Street
          } else if (types.contains("sublocality_level_1")) {
            subLocality = component['long_name']; // Neighborhood
          } else if (types.contains("locality")) {
            locality = component['long_name']; // City or District
          } else if (types.contains("establishment") ||
              types.contains("point_of_interest")) {
            placeName = component['long_name']; // Landmark or known place
          }
        }

        // **Fix: If the street is "Unnamed Road", get the nearest named street**
        if (streetName == null || streetName.toLowerCase() == "unnamed road") {
          streetName = await fetchNearestStreet(location);
        }

        // **Ensure we return a valid address and not just "Kigali"**
        String formattedAddress =
            streetName ??
            placeName ??
            subLocality ??
            locality ??
            "Unknown Address";

        return formattedAddress;
      }
    } else {
      debugPrint('Failed to fetch address: ${response.body}');
    }
  } catch (e) {
    debugPrint('Error fetching address: $e');
  }

  return 'Street name not found';
}

Future<String?> fetchNearestStreet(LatLng location) async {
  final String googleMapsApiKey = apiKey;

  // Try Google Places API first for better accuracy
  final String placesUrl =
      "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${location.latitude},${location.longitude}&radius=100&types=route&key=$googleMapsApiKey";

  try {
    final response = await http.get(Uri.parse(placesUrl));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      if (data['status'] == 'OK' && data['results'].isNotEmpty) {
        for (var result in data['results']) {
          if (result.containsKey('name')) {
            return result['name']; // Returns the closest named road
          }
        }
      }
    }
  } catch (e) {
    debugPrint('Error fetching nearest named street: $e');
  }

  // If Places API fails, use Roads API as a backup
  return await fetchNearbyStreet(location);
}

Future<String?> fetchNearbyStreet(LatLng location) async {
  final String googleMapsApiKey = apiKey;
  final String roadsUrl =
      "https://roads.googleapis.com/v1/nearestRoads?points=${location.latitude},${location.longitude}&key=$googleMapsApiKey";

  try {
    final response = await http.get(Uri.parse(roadsUrl));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      if (data['snappedPoints'] != null && data['snappedPoints'].isNotEmpty) {
        String placeId = data['snappedPoints'][0]['placeId'];
        return await getStreetFromPlaceId(placeId);
      }
    }
  } catch (e) {
    debugPrint('Error fetching nearby streets: $e');
  }

  return null;
}

Future<String?> getStreetFromPlaceId(String placeId) async {
  final String googleMapsApiKey = apiKey;
  final String placeDetailsUrl =
      "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$googleMapsApiKey";

  try {
    final response = await http.get(Uri.parse(placeDetailsUrl));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      if (data['status'] == 'OK' && data['result'] != null) {
        List<dynamic> addressComponents = data['result']['address_components'];

        for (var component in addressComponents) {
          if (component['types'].contains("route")) {
            return component['long_name']; // Returns the actual street name
          }
        }
      }
    }
  } catch (e) {
    debugPrint('Error fetching street name from Place ID: $e');
  }

  return null;
}

Future<String?> _fetchNearestNamedStreet(LatLng location) async {
  final String googleMapsApiKey = apiKey;
  final String placesUrl =
      "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${location.latitude},${location.longitude}&radius=100&types=route&key=$googleMapsApiKey";

  try {
    final response = await http.get(Uri.parse(placesUrl));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      if (data['status'] == 'OK' && data['results'].isNotEmpty) {
        for (var result in data['results']) {
          if (result.containsKey('name')) {
            return result['name'];
          }
        }
      }
    } else {
      debugPrint('Failed to fetch nearest named street: ${response.body}');
    }
  } catch (e) {
    debugPrint('Error fetching nearest named street: $e');
  }

  return null;
}

// Future<String?> fetchNearbyStreet(LatLng location) async {
//   final String googleMapsApiKey = apiKey;
//   final String roadsUrl =
//       "https://roads.googleapis.com/v1/nearestRoads?points=${location.latitude},${location.longitude}&key=$googleMapsApiKey";

//   try {
//     final response = await http.get(Uri.parse(roadsUrl));

//     if (response.statusCode == 200) {
//       final Map<String, dynamic> data = json.decode(response.body);

//       if (data['snappedPoints'] != null && data['snappedPoints'].isNotEmpty) {
//         String placeId = data['snappedPoints'][0]['placeId'];
//         return await _getStreetFromPlaceId(placeId);
//       }
//     } else {
//       debugPrint('Failed to fetch nearby streets: ${response.body}');
//     }
//   } catch (e) {
//     debugPrint('Error fetching nearby streets: $e');
//   }

//   return null;
// }

Future<String?> _getStreetFromPlaceId(String placeId) async {
  final String googleMapsApiKey = apiKey;
  final String placeDetailsUrl =
      "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$googleMapsApiKey";

  try {
    final response = await http.get(Uri.parse(placeDetailsUrl));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      if (data['status'] == 'OK' && data['result'] != null) {
        List<dynamic> addressComponents = data['result']['address_components'];

        for (var component in addressComponents) {
          if (component['types'].contains("route")) {
            return component['long_name'];
          }
        }
      }
    }
  } catch (e) {
    debugPrint('Error fetching street name from Place ID: $e');
  }

  return null;
}
