import 'package:location_geocoder/location_geocoder.dart';
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

  static Future<String> getAddressFromCoordinates(
    double lat,
    double long,
  ) async {
    final LocatitonGeocoder geocoder = LocatitonGeocoder(apiKey);
    final address = await geocoder.findAddressesFromCoordinates(
      Coordinates(lat, long),
    );
    if (address.isEmpty) return '';
    return address.first.addressLine ?? '';
  }
}
