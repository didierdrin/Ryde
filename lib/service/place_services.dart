import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:ryde_rw/utils/contants.dart';

class PlaceSuggestion {
  final String description, placeId;
  PlaceSuggestion(this.description, this.placeId);
}

class PlaceServices {
  static final String baseUrl = 'https://maps.googleapis.com/maps/api';

  static Future<List<Map<String, dynamic>>> placeSuggestions(
    String code,
    String input,
  ) async {
    try {
      final serviceUrl = '$baseUrl/place/autocomplete/json';
      final urlQueries = 'key=$apiKey&input=$input&components=country:$code';
      final url = '$serviceUrl?$urlQueries';
      final http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = await json.decode(response.body);
        final List<dynamic> suggestions = data['predictions'];
        return suggestions.map((suggestion) {
          final placeId = suggestion['place_id'] as String;
          final formattedName = suggestion['structured_formatting'];
          final description = formattedName['main_text'] as String;
          return {'description': description, 'place_id': placeId};
        }).toList();
      }
    } catch (_) {
      return [];
    }
    return [];
  }

  static Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    final serviceUrl = '$baseUrl/place/details/json';
    final url = Uri.parse('$serviceUrl?placeid=$placeId&key=$apiKey');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['result'];
    }
    return null;
  }

  static Future<String> placeIdFromNearbySearch(double lat, double lng) async {
    final serviceUrl = '$baseUrl/place/nearbysearch/json';
    final String url = '$serviceUrl?location=$lat,$lng&radius=50&key=$apiKey';

    final http.Response response = await http.get(Uri.parse(url));

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
