import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ryde_rw/provider/current_location_provider.dart';
import 'package:ryde_rw/service/api_service.dart';
import 'package:ryde_rw/service/realtime_location_tracker.dart';
import 'package:ryde_rw/shared/shared_states.dart';

/// Loads open passenger ride requests, nearest first.
class NearbyTripsService {
  static Future<List<Map<String, dynamic>>> load(WidgetRef ref) async {
    final user = ref.read(userProvider);
    if (user?.isDriver == true) {
      try {
        await ApiService.toggleDriverAvailability(true);
      } catch (_) {}
    }

    final location = await ref.read(currentLocationProvider.future);
    final res = await ApiService.getAvailableTrips(
      location.latitude,
      location.longitude,
    );
    final list = (res['trips'] as List?) ?? [];
    final trips = list
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    trips.sort((a, b) {
      final da = tripDouble(a, 'driverDistance') ?? double.infinity;
      final db = tripDouble(b, 'driverDistance') ?? double.infinity;
      return da.compareTo(db);
    });

    return trips;
  }
}

String formatTripFare(dynamic fare) {
  if (fare == null) return '';
  if (fare is num) {
    final intish = fare.roundToDouble() == fare.toDouble();
    final value = intish ? fare.toInt().toString() : fare.toString();
    return '$value RWF';
  }
  final s = fare.toString().trim();
  if (s.isEmpty) return '';
  return s.toUpperCase().contains('RWF') || s.toUpperCase().contains('FRW')
      ? s
      : '$s RWF';
}
