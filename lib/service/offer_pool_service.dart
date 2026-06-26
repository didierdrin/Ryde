import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ryde_rw/models/offer_pool_model.dart';
import 'package:ryde_rw/models/request_model.dart';
import 'package:ryde_rw/screens/home/searchpooler.dart';
import 'package:ryde_rw/service/api_service.dart';
import 'package:ryde_rw/service/trip_pool_mapper.dart';
import 'package:ryde_rw/shared/locations_shared.dart';
import 'package:ryde_rw/shared/shared_states.dart';
import 'package:ryde_rw/utils/utils.dart';

const _pollInterval = Duration(seconds: 15);

class OfferPoolService {
  static Future<bool> hasDuplicateTrip({
    required String userId,
    required Location pickup,
    required Location dropoff,
    required DateTime dateTime,
  }) async {
    final res = await ApiService.getMyTrips();
    final lower = dateTime.subtract(const Duration(hours: 1));
    final upper = dateTime.add(const Duration(hours: 1));
    return tripsFromResponse(res).any((trip) {
      final ride = tripJsonToOfferPool(trip);
      return ride.user == userId &&
          ride.pickupLocation.address == pickup.address &&
          ride.dropoffLocation.address == dropoff.address &&
          !ride.dateTime.isBefore(lower) &&
          !ride.dateTime.isAfter(upper) &&
          !ride.completed;
    });
  }

  static Future<String> createFindPool(PassengerOfferPool pool) async {
    final res = await ApiService.requestTrip(offerPoolToTripPayload(pool));
    final trip = res['trip'] as Map<String, dynamic>?;
    return trip?['tripId']?.toString() ?? trip?['trip_id']?.toString() ?? '';
  }

  static Future<String> createOfferPool(Map<String, dynamic> offerPoolData) async {
    final pool = PassengerOfferPool.fromMap(offerPoolData);
    return createFindPool(pool);
  }

  static Future<bool> checkOfferPoolExists({
    required WidgetRef ref,
    required Location pickupLocation,
    required Location dropoffLocation,
    required String type,
  }) async {
    try {
      const double radius = 3.0;
      final res = await ApiService.getAvailableTrips(
        pickupLocation.latitude,
        pickupLocation.longitude,
      );
      final trips = tripsFromResponse(res);
      for (final trip in trips) {
        final offer = tripJsonToOfferPool(trip);
        final isPickupNear = isLocationNear(
          offer.pickupLocation.latitude,
          offer.pickupLocation.longitude,
          pickupLocation.latitude,
          pickupLocation.longitude,
          radius,
        );
        if (isPickupNear) return true;
      }
      return false;
    } catch (e) {
      throw Exception('Failed to check OfferPool: $e');
    }
  }

  static Stream<List<T>> _pollOfferPools<T>(
    Future<List<T>> Function() fetch,
  ) async* {
    while (true) {
      try {
        yield await fetch();
      } catch (_) {
        yield <T>[];
      }
      await Future.delayed(_pollInterval);
    }
  }

  static final offerPoolStreamProvider = StreamProvider.autoDispose
      .family<List<PassengerOfferPool>, LocationPairD>((ref, locationPair) {
    return _pollOfferPools(() async {
      final res = await ApiService.getAvailableTrips(
        locationPair.pickupLocation.latitude,
        locationPair.pickupLocation.longitude,
      );
      return tripsFromResponse(res)
          .map(tripJsonToOfferPool)
          .where((pool) =>
              pool.pickupLocation.latitude == locationPair.pickupLocation.latitude &&
              pool.pickupLocation.longitude == locationPair.pickupLocation.longitude &&
              pool.dropoffLocation.latitude == locationPair.dropoffLocation.latitude &&
              pool.dropoffLocation.longitude == locationPair.dropoffLocation.longitude)
          .toList();
    });
  });

  static final matchingOfferPoolsProvider = StreamProvider.autoDispose
      .family<List<PassengerOfferPool>, LocationPairD>((ref, locationPair) {
    return _pollOfferPools(() async {
      const radiusKm = 3.0;
      final res = await ApiService.getAvailableTrips(
        locationPair.pickupLocation.latitude,
        locationPair.pickupLocation.longitude,
      );
      return tripsFromResponse(res).map(tripJsonToOfferPool).where((trip) {
        return isLocationNear(
          trip.pickupLocation.latitude,
          trip.pickupLocation.longitude,
          locationPair.pickupLocation.latitude,
          locationPair.pickupLocation.longitude,
          radiusKm,
        );
      }).toList();
    });
  });

  static final matchingOfferPassengersProvider = StreamProvider.autoDispose
      .family<List<RequestRide>, LocationPairD>((ref, locationPair) {
    return _pollOfferPools(() async {
      const radiusKm = 3.0;
      final res = await ApiService.getAvailableTrips(
        locationPair.pickupLocation.latitude,
        locationPair.pickupLocation.longitude,
      );
      return tripsFromResponse(res).map(tripJsonToRequestRide).where((trip) {
        return isLocationNear(
          trip.pickupLocation.latitude,
          trip.pickupLocation.longitude,
          locationPair.pickupLocation.latitude,
          locationPair.pickupLocation.longitude,
          radiusKm,
        );
      }).toList();
    });
  });

  static final searchNearByDrivers =
      StreamProvider.family<List<PassengerOfferPool>, Location>((ref, location) {
    return _pollOfferPools(() async {
      const radiusKm = 3.0;
      final res = await ApiService.getAvailableTrips(location.latitude, location.longitude);
      return tripsFromResponse(res).map(tripJsonToOfferPool).where((trip) {
        return isLocationNear(
          trip.pickupLocation.latitude,
          trip.pickupLocation.longitude,
          location.latitude,
          location.longitude,
          radiusKm,
        );
      }).toList();
    });
  });

  static final allofferPoolStreamProvider = StreamProvider<List<PassengerOfferPool>>((ref) {
    final location = ref.read(locationProvider);
    return _pollOfferPools(() async {
      final res = await ApiService.getAvailableTrips(location['lat'], location['long']);
      return tripsFromResponse(res).map(tripJsonToOfferPool).toList();
    });
  });

  static final diplayDriverNearYou = StreamProvider<List<PassengerOfferPool>>((ref) {
    final location = ref.read(locationProvider);
    return _pollOfferPools(() async {
      final res = await ApiService.getAvailableTrips(location['lat'], location['long']);
      return tripsFromResponse(res).map(tripJsonToOfferPool).where((driver) {
        final distance = Geolocator.distanceBetween(
              location['lat'],
              location['long'],
              driver.pickupLocation.latitude,
              driver.pickupLocation.longitude,
            ) /
            1000;
        return distance <= 3 && !driver.isSeatFull;
      }).toList();
    });
  });

  static final offeringStreams = StreamProvider<List<PassengerOfferPool>>((ref) {
    final user = ref.read(userProvider)!;
    return _pollOfferPools(() async {
      final res = await ApiService.getMyTrips();
      return tripsFromResponse(res)
          .map(tripJsonToOfferPool)
          .where((pool) => pool.user == user.id)
          .toList();
    });
  });

  static final offeringStreamsAll = StreamProvider<List<PassengerOfferPool>>((ref) {
    return _pollOfferPools(() async {
      final res = await ApiService.getMyTrips();
      return tripsFromResponse(res).map(tripJsonToOfferPool).toList();
    });
  });

  static final poolRealTimeStreamProvider =
      StreamProvider.family<PassengerOfferPool, String>((ref, poolId) {
    return _pollOfferPools(() async {
      final res = await ApiService.getTripById(poolId);
      final trip = res['trip'] as Map<String, dynamic>?;
      if (trip == null) throw Exception('OfferPool with ID $poolId not found');
      return [tripJsonToOfferPool(trip)];
    }).map((list) => list.isNotEmpty ? list.first : throw Exception('OfferPool with ID $poolId not found'));
  });

  static final poolRealTimeStreamsProvider =
      StreamProvider.family<PassengerOfferPool?, String>((ref, poolId) {
    return _pollOfferPools(() async {
      try {
        final res = await ApiService.getTripById(poolId);
        final trip = res['trip'] as Map<String, dynamic>?;
        if (trip == null) return <PassengerOfferPool>[];
        return [tripJsonToOfferPool(trip)];
      } catch (_) {
        return <PassengerOfferPool>[];
      }
    }).map((list) => list.isEmpty ? null : list.first);
  });

  static Future<void> acceptRideRequest(String requestId, String driverId) async {
    await ApiService.acceptTrip(requestId);
  }

  static Future<void> handleRideResponse(String requestId, bool accepted) async {
    if (accepted) {
      await ApiService.acceptTrip(requestId);
      return;
    }
    await ApiService.cancelTrip(requestId);
  }

  static Future<void> updateofferpool(String id, Map<String, dynamic> data) async {
    await ApiService.cancelTrip(id);
  }

  static Future<void> cancelRide(String requestId, String userId) async {
    await ApiService.cancelTrip(requestId);
  }
}
