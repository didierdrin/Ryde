import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ryde_rw/firestore_stub.dart';
import 'package:ryde_rw/models/find_pool_model.dart';
import 'package:ryde_rw/service/api_service.dart';
import 'package:ryde_rw/service/trip_pool_mapper.dart';
import 'package:ryde_rw/shared/shared_states.dart';

class FindPoolService {
  static Future<void> createFindPool(PassengerFindPool pool) async {
    await ApiService.requestTrip({
      'pickupLatitude': pool.pickupLocation.latitude,
      'pickupLongitude': pool.pickupLocation.longitude,
      'pickupAddress': pool.pickupLocation.address,
      'destinationLatitude': pool.dropoffLocation.latitude,
      'destinationLongitude': pool.dropoffLocation.longitude,
      'destinationAddress': pool.dropoffLocation.address,
      'distance': 5,
      'fare': pool.selectedSeat * 1000,
      'serviceType': 'FindPool',
    });
  }

  static Stream<List<PassengerFindPool>> _pollFindPools(
    Future<List<PassengerFindPool>> Function() fetch,
  ) async* {
    while (true) {
      try {
        yield await fetch();
      } catch (_) {
        yield [];
      }
      await Future.delayed(const Duration(seconds: 15));
    }
  }

  static PassengerFindPool _fromTrip(Map<String, dynamic> trip) {
    final pool = tripJsonToOfferPool(trip);
    return PassengerFindPool(
      id: pool.id,
      pickupLocation: pool.pickupLocation,
      dropoffLocation: pool.dropoffLocation,
      dateTime: Timestamp.fromDate(pool.dateTime),
      selectedSeat: pool.emptySeat ?? 1,
      user: pool.user,
      countryCode: pool.countryCode,
    );
  }

  static final findingStreams = StreamProvider<List<PassengerFindPool>>((ref) {
    final user = ref.read(userProvider)!;
    return _pollFindPools(() async {
      final res = await ApiService.getMyTrips();
      return tripsFromResponse(res)
          .where((t) => (t['serviceType'] ?? t['service_type']) == 'FindPool')
          .map(_fromTrip)
          .where((pool) => pool.user == user.id)
          .toList();
    });
  });

  static final findingStreamsall = StreamProvider<List<PassengerFindPool>>((ref) {
    return _pollFindPools(() async {
      final res = await ApiService.getMyTrips();
      return tripsFromResponse(res)
          .where((t) => (t['serviceType'] ?? t['service_type']) == 'FindPool')
          .map(_fromTrip)
          .toList();
    });
  });
}
