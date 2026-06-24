import 'dart:async';
import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:ryde_rw/service/api_service.dart';

/// Uploads own GPS position and polls trip participant locations via REST.
class RealtimeLocationTracker {
  StreamSubscription<Position>? _positionSub;
  Timer? _pollTimer;

  Future<void> startUploading({required bool isDriver}) async {
    await stopUploading();

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    final LocationSettings settings;
    if (Platform.isAndroid) {
      settings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        intervalDuration: const Duration(seconds: 10),
      );
    } else if (Platform.isIOS) {
      settings = AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );
    } else {
      settings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );
    }

    _positionSub =
        Geolocator.getPositionStream(locationSettings: settings).listen(
      (pos) async {
        try {
          if (isDriver) {
            await ApiService.updateDriverLocation(pos.latitude, pos.longitude);
          } else {
            await ApiService.updatePassengerLocation(
                pos.latitude, pos.longitude);
          }
        } catch (_) {}
      },
    );
  }

  Future<void> stopUploading() async {
    await _positionSub?.cancel();
    _positionSub = null;
  }

  void startPolling(
    String tripId,
    void Function(Map<String, dynamic> locations) onUpdate, {
    Duration interval = const Duration(seconds: 4),
  }) {
    stopPolling();

    Future<void> poll() async {
      try {
        final res = await ApiService.getTripLocations(tripId);
        onUpdate(res);
      } catch (_) {}
    }

    poll();
    _pollTimer = Timer.periodic(interval, (_) => poll());
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void dispose() {
    stopUploading();
    stopPolling();
  }
}

/// Reads trip fields from API responses (snake_case or camelCase).
String tripStr(Map<String, dynamic> m, String camelKey) {
  final snake = camelKey.replaceAllMapped(
    RegExp(r'([a-z0-9])([A-Z])'),
    (match) => '${match[1]}_${match[2]!.toLowerCase()}',
  );
  return (m[camelKey] ?? m[snake] ?? '').toString();
}

double? tripDouble(Map<String, dynamic> m, String camelKey) {
  final snake = camelKey.replaceAllMapped(
    RegExp(r'([a-z0-9])([A-Z])'),
    (match) => '${match[1]}_${match[2]!.toLowerCase()}',
  );
  final v = m[camelKey] ?? m[snake];
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.trim());
  return null;
}

Map<String, dynamic>? findActiveTrip(List<dynamic> trips) {
  const active = {'REQUESTED', 'ACCEPTED', 'IN_PROGRESS'};
  for (final t in trips) {
    if (t is! Map) continue;
    final map = Map<String, dynamic>.from(t);
    final status = tripStr(map, 'status').toUpperCase();
    if (active.contains(status)) return map;
  }
  return null;
}

bool isTrackableTripStatus(String status) {
  final s = status.toUpperCase();
  return s == 'REQUESTED' || s == 'ACCEPTED' || s == 'IN_PROGRESS';
}
