import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ryde_rw/models/request_model.dart';
import 'package:ryde_rw/service/api_service.dart';
import 'package:ryde_rw/service/trip_pool_mapper.dart';
import 'package:ryde_rw/shared/shared_states.dart';

const _pollInterval = Duration(seconds: 15);

class RequestRideService {
  static Future<void> createRequestRide(RequestRide requestRide) async {
    final res = await ApiService.requestTrip(requestRideToTripPayload(requestRide));
    final trip = res['trip'] as Map<String, dynamic>?;
    requestRide.id = trip?['tripId']?.toString() ?? trip?['trip_id']?.toString();
  }

  static Future<void> updateRequestRide(String id, Map<String, dynamic> data) async {
    if (data['cancelled'] == true || data['rejected'] == true) {
      await ApiService.cancelTrip(id);
    }
  }

  static Stream<T?> _pollSingle<T>(Future<T?> Function() fetch) async* {
    while (true) {
      try {
        yield await fetch();
      } catch (_) {
        yield null;
      }
      await Future.delayed(_pollInterval);
    }
  }

  static Stream<List<T>> _pollList<T>(Future<List<T>> Function() fetch) async* {
    while (true) {
      try {
        yield await fetch();
      } catch (_) {
        yield [];
      }
      await Future.delayed(_pollInterval);
    }
  }

  static final requestRideStreamProvider =
      StreamProvider.family<RequestRide?, String>((ref, id) {
    return _pollSingle(() async {
      final res = await ApiService.getTripById(id);
      final trip = res['trip'] as Map<String, dynamic>?;
      if (trip == null) return null;
      return tripJsonToRequestRide(trip);
    });
  });

  static final allRequestRideStreamProvider = StreamProvider<List<RequestRide>>((ref) {
    return _pollList(() async {
      final res = await ApiService.getMyTrips();
      return tripsFromResponse(res).map(tripJsonToRequestRide).toList();
    });
  });

  static final ridesForRiderProvider =
      StreamProvider.family<List<RequestRide>, String>((ref, riderId) {
    return _pollList(() async {
      final res = await ApiService.getMyTrips();
      return tripsFromResponse(res)
          .map(tripJsonToRequestRide)
          .where((ride) => ride.rider == riderId)
          .toList();
    });
  });

  static final ridesRequestedByUserProvider =
      StreamProvider.family<List<RequestRide>, String>((ref, requestedById) {
    return _pollList(() async {
      final res = await ApiService.getMyTrips();
      return tripsFromResponse(res)
          .map(tripJsonToRequestRide)
          .where((ride) => ride.requestedBy == requestedById)
          .toList();
    });
  });

  static final offerpoolsForRiderProvider =
      StreamProvider.family<List<RequestRide>, String>((ref, offerPoolId) {
    return _pollList(() async {
      final res = await ApiService.getTripById(offerPoolId);
      final trip = res['trip'] as Map<String, dynamic>?;
      if (trip == null) return [];
      return [tripJsonToRequestRide(trip)];
    });
  });

  static final diplayPassengerNearYou = StreamProvider<List<RequestRide>>((ref) {
    final location = ref.read(locationProvider);
    return _pollList(() async {
      final res = await ApiService.getAvailableTrips(location['lat'], location['long']);
      return tripsFromResponse(res).map(tripJsonToRequestRide).where((passenger) {
        final distance = Geolocator.distanceBetween(
              location['lat'],
              location['long'],
              passenger.pickupLocation.latitude,
              passenger.pickupLocation.longitude,
            ) /
            1000;
        return distance <= 3 &&
            !passenger.accepted &&
            passenger.rider.isEmpty &&
            !passenger.cancelled;
      }).toList();
    });
  });
}
