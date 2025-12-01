import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ryde_rw/models/offer_pool_model.dart';
import 'package:ryde_rw/models/request_model.dart';
import 'package:ryde_rw/screens/home/searchpooler.dart';
import 'package:ryde_rw/shared/locations_shared.dart';
import 'package:ryde_rw/shared/shared_states.dart';
import 'package:ryde_rw/utils/contants.dart';
import 'package:ryde_rw/utils/utils.dart';
import 'package:ryde_rw/service/notification_service.dart';

class OfferPoolService {
  static final collection = collections.offerpool;
  static final collectionRequest = collections.request;
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;

  static Future<String> createFindPool(PassengerOfferPool pool) async {
    try {
      final doc = await firestore.collection(collection).add(pool.toMap());
      return doc.id;
    } catch (e) {
      throw Exception('Failed to create FindPool entry');
    }
  }

  static Future<String> createOfferPool(
    Map<String, dynamic> offerPoolData,
  ) async {
    try {
      final docRef = firestore.collection(collection).doc();
      await docRef.set(offerPoolData);
      return docRef.id;
    } catch (e) {
      print('Error creating offer pool: $e');
      throw Exception('Failed to create OfferPool entry');
    }
  }

  static Future<bool> checkOfferPoolExists({
    required WidgetRef ref,
    required Location pickupLocation,
    required Location dropoffLocation,
    required String type,
  }) async {
    try {
      final user = ref.read(userProvider)!;
      const double radius = 3.0;
      final querySnapshot = await firestore
          .collection(collection)
          .where('completed', isEqualTo: false)
          .where('isSeatFull', isEqualTo: false)
          .where('country_code', isEqualTo: user.countryCode)
          .where('type', isEqualTo: type)
          .get();

      for (final doc in querySnapshot.docs) {
        final trip = PassengerOfferPool.fromMap(doc.data());

        final isPickupNear = isLocationNear(
          trip.pickupLocation.latitude,
          trip.pickupLocation.longitude,
          pickupLocation.latitude,
          pickupLocation.longitude,
          radius,
        );

        if (isPickupNear) {
          return true;
        }
      }

      return false;
    } catch (e) {
      throw Exception('Failed to check OfferPool: $e');
    }
  }

  static final offerPoolStreamProvider = StreamProvider.autoDispose
      .family<List<PassengerOfferPool>, LocationPairD>((ref, locationPair) {
        final user = ref.read(userProvider)!;
        return firestore
            .collection(collection)
            .where(
              'pickupLocation.latitude',
              isEqualTo: locationPair.pickupLocation.latitude,
            )
            .where(
              'pickupLocation.longitude',
              isEqualTo: locationPair.pickupLocation.longitude,
            )
            .where(
              'dropoffLocation.latitude',
              isEqualTo: locationPair.dropoffLocation.latitude,
            )
            .where(
              'dropoffLocation.longitude',
              isEqualTo: locationPair.dropoffLocation.longitude,
            )
            .where('completed', isEqualTo: false)
            .where('isSeatFull', isEqualTo: false)
            .where('country_code', isEqualTo: user.countryCode)
            .snapshots()
            .map(
              (querySnapshot) => querySnapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return PassengerOfferPool.fromMap(data);
              }).toList(),
            );
      });

  static final matchingOfferPoolsProvider = StreamProvider.autoDispose
      .family<List<PassengerOfferPool>, LocationPairD>((
        ref,
        locationPair,
      ) async* {
        final user = ref.read(userProvider)!;
        yield* firestore
            .collection(collection)
            .where('completed', isEqualTo: false)
            .where('country_code', isEqualTo: user.countryCode)
            .snapshots()
            .map((querySnapshot) {
              final List<PassengerOfferPool> matchingTrips = [];

              for (final doc in querySnapshot.docs) {
                final trip = PassengerOfferPool.fromMap({
                  ...doc.data(),
                  'id': doc.id,
                });

                final double radiusKm = 3.0;

                final isPickupNear = isLocationNear(
                  trip.pickupLocation.latitude,
                  trip.pickupLocation.longitude,
                  locationPair.pickupLocation.latitude,
                  locationPair.pickupLocation.longitude,
                  radiusKm,
                );

                if (isPickupNear) {
                  matchingTrips.add(trip);
                }
              }
              return matchingTrips;
            });
      });

  static final matchingOfferPassengersProvider = StreamProvider.autoDispose
      .family<List<RequestRide>, LocationPairD>((ref, locationPair) async* {
        final user = ref.read(userProvider)!;
        yield* firestore
            .collection(collectionRequest)
            .where('accepted', isEqualTo: false)
            .where('country_code', isEqualTo: user.countryCode)
            .snapshots()
            .map((querySnapshot) {
              final List<RequestRide> matchingTrips = [];

              for (final doc in querySnapshot.docs) {
                final trip = RequestRide.fromMap({...doc.data(), 'id': doc.id});

                final double radiusKm = 3.0;

                final isPickupNear = isLocationNear(
                  trip.pickupLocation.latitude,
                  trip.pickupLocation.longitude,
                  locationPair.pickupLocation.latitude,
                  locationPair.pickupLocation.longitude,
                  radiusKm,
                );

                if (isPickupNear) {
                  matchingTrips.add(trip);
                }
              }
              return matchingTrips;
            });
      });

  static final searchNearByDrivers =
      StreamProvider.family<List<PassengerOfferPool>, Location>((
        ref,
        location,
      ) {
        final user = ref.read(userProvider)!;
        return firestore
            .collection(collection)
            .where('completed', isEqualTo: false)
            .where('country_code', isEqualTo: user.countryCode)
            .snapshots()
            .map((querySnapshot) {
              final List<PassengerOfferPool> matchingTrips = [];

              for (final doc in querySnapshot.docs) {
                final trip = PassengerOfferPool.fromMap({
                  ...doc.data(),
                  'id': doc.id,
                });

                final double radiusKm = 3.0;

                final isPickupNear = isLocationNear(
                  trip.pickupLocation.latitude,
                  trip.pickupLocation.longitude,
                  location.latitude,
                  location.longitude,
                  radiusKm,
                );

                if (isPickupNear) {
                  matchingTrips.add(trip);
                }
              }
              return matchingTrips;
            });
      });

  static final allofferPoolStreamProvider =
      StreamProvider<List<PassengerOfferPool>>((ref) {
        final user = ref.read(userProvider)!;
        return firestore
            .collection(collection)
            .where('completed', isEqualTo: false)
            .where('isSeatFull', isEqualTo: false)
            .where('country_code', isEqualTo: user.countryCode)
            .snapshots()
            .map(
              (querySnapshot) => querySnapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return PassengerOfferPool.fromMap(data);
              }).toList(),
            );
      });

  static final diplayDriverNearYou = StreamProvider<List<PassengerOfferPool>>((
    ref,
  ) {
    final user = ref.read(userProvider)!;
    final location = ref.read(locationProvider);

    return firestore
        .collection(collection)
        .where('completed', isEqualTo: false)
        .where('country_code', isEqualTo: user.countryCode)
        .snapshots()
        .map((querySnapshot) {
          final List<PassengerOfferPool> drivers = querySnapshot.docs.map((
            doc,
          ) {
            final data = doc.data();
            data['id'] = doc.id;
            return PassengerOfferPool.fromMap(data);
          }).toList();

          final List<PassengerOfferPool> nearbyDrivers = drivers.where((
            driver,
          ) {
            final double distance =
                Geolocator.distanceBetween(
                  location['lat'],
                  location['long'],
                  driver.pickupLocation.latitude,
                  driver.pickupLocation.longitude,
                ) /
                1000;

            return distance <= 3 && !driver.isSeatFull;
          }).toList();

          return nearbyDrivers;
        });
  });

  final nearbyTripsProvider = StreamProvider.autoDispose
      .family<List<PassengerOfferPool>, Location>((ref, userLocation) async* {
        final firestore = FirebaseFirestore.instance;
        final tripsSnapshot = await firestore.collection('trips').get();

        final trips = tripsSnapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return PassengerOfferPool.fromMap(data);
        }).toList();

        final filteredTrips = trips.where((trip) {
          final double distance = calculateDistance(
            userLocation.latitude,
            userLocation.longitude,
            trip.pickupLocation.latitude,
            trip.pickupLocation.longitude,
          );
          return distance <= 2 && !trip.completed && !trip.isSeatFull;
        }).toList();

        yield filteredTrips;
      });

  static final offeringStreams = StreamProvider<List<PassengerOfferPool>>((
    ref,
  ) {
    final user = ref.read(userProvider)!;
    return firestore
        .collection(collection)
        .where('user', isEqualTo: user.id)
        .where('country_code', isEqualTo: user.countryCode)
        .snapshots()
        .map(
          (event) => event.docs.map((e) {
            var data = e.data();
            data['id'] = e.id;
            return PassengerOfferPool.fromMap(data);
          }).toList(),
        );
  });

  static final offeringStreamsAll = StreamProvider<List<PassengerOfferPool>>((
    ref,
  ) {
    final user = ref.read(userProvider)!;
    return firestore
        .collection(collection)
        .where('country_code', isEqualTo: user.countryCode)
        .snapshots()
        .map(
          (event) => event.docs.map((e) {
            var data = e.data();
            data['id'] = e.id;
            return PassengerOfferPool.fromMap(data);
          }).toList(),
        );
  });

  static final poolRealTimeStreamProvider =
      StreamProvider.family<PassengerOfferPool, String>((ref, poolId) {
        return firestore.collection(collection).doc(poolId).snapshots().map((
          doc,
        ) {
          if (!doc.exists)
            throw Exception("OfferPool with ID $poolId not found");
          final data = doc.data()!;
          data['id'] = doc.id;
          return PassengerOfferPool.fromMap(data);
        });
      });

  static final poolRealTimeStreamsProvider =
      StreamProvider.family<PassengerOfferPool?, String>((ref, poolId) {
        return firestore.collection(collection).doc(poolId).snapshots().map((
          snapshot,
        ) {
          if (snapshot.exists && snapshot.data() != null) {
            final data = snapshot.data()!;
            data['id'] = snapshot.id;
            return PassengerOfferPool.fromMap(data);
          }
          return null;
        });
      });

  static Future<void> acceptRideRequest(
    String requestId,
    String driverId,
  ) async {
    try {
      DocumentSnapshot requestSnapshot = await firestore
          .collection(collectionRequest)
          .doc(requestId)
          .get();

      if (!requestSnapshot.exists) {
        throw Exception("Ride request not found");
      }
      RequestRide request = RequestRide.fromMap(
        requestSnapshot.data() as Map<String, dynamic>,
      );
      int selectedSeats = request.seats ?? 1;
      List<String> initialAvailableSeats = [request.requestedBy];

      while (initialAvailableSeats.length < selectedSeats) {
        initialAvailableSeats.add(request.requestedBy);
      }

      int emptySeats = selectedSeats - initialAvailableSeats.length;
      if (emptySeats < 0) emptySeats = 0;

      PassengerOfferPool offerPool = PassengerOfferPool(
        id: firestore.collection(collection).doc().id,
        pickupLocation: request.pickupLocation,
        dropoffLocation: request.dropoffLocation,
        dateTime: request.requestedTime,
        selectedSeat: selectedSeats,
        pricePerSeat: request.price ?? 0,
        user: driverId,
        pending: false,
        quantity: request.type == 'goods' ? request.quantity : null,
        measure: request.type == 'goods' ? request.measure : null,
        isSeatFull: emptySeats == 0,
        availableSeat: initialAvailableSeats,
        isRideStarted: false,
        type: request.type,
        countryCode: request.countryCode,
        emptySeat: emptySeats,
      );

      // Create the offer pool
      await firestore
          .collection(collection)
          .doc(offerPool.id)
          .set(offerPool.toMap());

      // Update the request with driver info and mark as accepted
      await firestore.collection(collectionRequest).doc(requestId).update({
        'rider': driverId,
        'offerpool': offerPool.id,
        'accepted': true,
        'isDriverNotified': true,
        'isPassengerNotified': true,
        'status': 'confirmed',
        'confirmed_at': FieldValue.serverTimestamp(),
      });

      // Send notification to passenger
      await NotificationService.sendNotification({
        'recipient_id': request.requestedBy,
        'title': 'Trip Request Accepted',
        'body': 'A driver has accepted your trip request',
        'data': {
          'request_id': requestId,
          'type': 'trip_accepted',
          'pickup_location': request.pickupLocation.address,
          'dropoff_location': request.dropoffLocation.address,
          'trip_time': request.requestedTime.toDate().toString(),
          'action_required': false,
          'price': request.price,
          'seats': request.seats,
          'driver_id': driverId,
          'offerpool_id': offerPool.id,
        },
      });

      // Remove both parties from nearby lists by updating their status
      await firestore.collection('users').doc(driverId).update({
        'current_status': 'in_ride',
        'current_ride_id': offerPool.id,
      });

      await firestore.collection('users').doc(request.requestedBy).update({
        'current_status': 'in_ride',
        'current_ride_id': offerPool.id,
      });
    } catch (e) {
      print('Error accepting ride request: $e');
      throw Exception("Failed to accept ride request");
    }
  }

  static Future<void> handleRideResponse(
    String requestId,
    bool accepted,
  ) async {
    try {
      final requestDoc = await firestore
          .collection(collectionRequest)
          .doc(requestId);
      final request = await requestDoc.get();
      final requestData = request.data() as Map<String, dynamic>;

      await requestDoc.update({
        'accepted': accepted,
        'rejected': !accepted,
        'cancelled': !accepted,
        'response_time': FieldValue.serverTimestamp(),
      });

      // If accepted is false (rejected), remove the request from active pools
      if (!accepted) {
        await firestore
            .collection(collection)
            .doc(requestData['offerpool'])
            .update({
              'availableSeat': FieldValue.arrayRemove([
                requestData['requestedBy'],
              ]),
            });
      }

      // Send notification to the passenger when driver responds, or to driver when passenger responds
      final isDriverResponse =
          requestData['rider'] == requestData['requestedBy'];
      final recipientId = isDriverResponse
          ? requestData['requestedBy']
          : requestData['rider'];

      await NotificationService.sendNotification({
        'recipient_id': recipientId,
        'title': accepted ? 'Trip Request Update' : 'Trip Request Update',
        'body': accepted
            ? '${isDriverResponse ? "Driver" : "Passenger"} accepted the trip'
            : '${isDriverResponse ? "Driver" : "Passenger"} rejected the trip',
        'data': {
          'request_id': requestId,
          'type': accepted ? 'trip_accepted' : 'trip_rejected',
          'user_id': isDriverResponse
              ? requestData['rider']
              : requestData['requestedBy'],
          'pickup_location': requestData['pickupLocation']['address'],
          'dropoff_location': requestData['dropoffLocation']['address'],
          'trip_time': (requestData['requestedTime'] as Timestamp)
              .toDate()
              .toString(),
          'action_required': false,
          'offerpool_id': requestData['offerpool'],
        },
      });
    } catch (e) {
      print('Error handling ride response: $e');
      throw Exception('Failed to handle ride response: $e');
    }
  }

  static Future<void> updateofferpool(
    String id,
    Map<String, dynamic> data,
  ) async {
    await firestore.collection(collection).doc(id).update(data);
  }

  static Future<void> cancelRide(String requestId, String userId) async {
    try {
      final requestDoc = await firestore
          .collection('requestRiders')
          .doc(requestId);
      final request = await requestDoc.get();

      if (!request.exists) {
        throw Exception('Ride request not found');
      }

      final requestData = request.data() as Map<String, dynamic>;

      // Update request status
      await requestDoc.update({
        'cancelled': true,
        'cancelled_by': userId,
        'cancelled_at': FieldValue.serverTimestamp(),
        'status': 'cancelled',
      });

      print('Ride request cancelled successfully');

      // Only send notification to the other party (not the one who cancelled)
      final recipientId = userId == requestData['rider']
          ? requestData['requestedBy'] // If driver cancelled, notify passenger
          : requestData['rider']; // If passenger cancelled, notify driver

      await NotificationService.sendNotification({
        'recipient_id': recipientId,
        'title': 'Ride Cancelled',
        'body': userId == requestData['rider']
            ? 'Driver has cancelled the ride'
            : 'Passenger has cancelled the ride',
        'data': {
          'request_id': requestId,
          'type': 'ride_cancelled',
          'cancelled_by': userId,
          'pickup_location': requestData['pickupLocation']['address'],
          'dropoff_location': requestData['dropoffLocation']['address'],
          'trip_time': (requestData['requestedTime'] as Timestamp)
              .toDate()
              .toString(),
          'action_required': false,
        },
      });

      // Remove from active pools if exists
      if (requestData['offerpool'] != null) {
        print('Removing user from active pool');
        await firestore
            .collection(collection)
            .doc(requestData['offerpool'])
            .update({
              'availableSeat': FieldValue.arrayRemove([userId]),
            });
      }

      print('Ride cancellation process completed successfully');
    } catch (e) {
      print('Error cancelling ride: $e');
      throw Exception('Failed to cancel ride: $e');
    }
  }
}

