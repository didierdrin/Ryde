import 'package:ryde_rw/firestore_stub.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ryde_rw/models/request_model.dart';
import 'package:ryde_rw/shared/shared_states.dart';
import 'package:ryde_rw/utils/contants.dart';

class RequestRideService {
  static final collection = FirebaseFirestore.instance.collection(
    collections.request,
  );

  static Future<void> createRequestRide(RequestRide requestRide) async {
    try {
      print(requestRide.toMap());
      final docRef = requestRide.id != null && requestRide.id!.isNotEmpty
          ? collection.doc(requestRide.id)
          : collection.doc();

      if (requestRide.id == null || requestRide.id!.isEmpty) {
        requestRide = RequestRide(
          id: docRef.id,
          rider: requestRide.rider,
          pickupLocation: requestRide.pickupLocation,
          dropoffLocation: requestRide.dropoffLocation,
          requestedTime: requestRide.requestedTime,
          requestedBy: requestRide.requestedBy,
          createdAt: requestRide.createdAt,
          offerpool: requestRide.offerpool,
          rejected: requestRide.rejected,
          accepted: requestRide.accepted,
          paid: requestRide.paid,
          pickup: requestRide.pickup,
          dropoff: requestRide.dropoff,
          seats: requestRide.seats,
          price: requestRide.price,
          completed: requestRide.completed,
          cancelled: requestRide.cancelled,
          measure: requestRide.measure,
          quantity: requestRide.quantity,
          type: requestRide.type,
          countryCode: requestRide.countryCode,
          requested: requestRide.requested,
          notificationId: requestRide.notificationId,
          isDriverNotified: requestRide.isDriverNotified,
          isPassengerNotified: requestRide.isPassengerNotified,
        );
      }

      await docRef.set(requestRide.toMap());
    } catch (e) {
      throw Exception("Failed to create RequestRide: $e");
    }
  }

  static Future<void> updateRequestRide(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      await collection.doc(id).update(data);
    } catch (e) {
      throw Exception("Failed to update RequestRide: $e");
    }
  }

  static final requestRideStreamProvider =
      StreamProvider.family<RequestRide?, String>((ref, id) {
        return collection.doc(id).snapshots().map((snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            final data = snapshot.data()!;
            data['id'] = snapshot.id;
            return RequestRide.fromMap(data);
          }
          return null;
        });
      });

  static final allRequestRideStreamProvider = StreamProvider<List<RequestRide>>(
    (ref) {
      // final region = ref.watch(regionProvider)!;
      return collection          
          .snapshots()
          .map((querySnapshot) {
            return querySnapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return RequestRide.fromMap(data);
            }).toList();
          });
    },
  );

  static final ridesForRiderProvider =
      StreamProvider.family<List<RequestRide>, String>((ref, riderId) {
        final user = ref.watch(userProvider)!;
        return collection
            .where('rider', isEqualTo: riderId)
            .snapshots()
            .map((querySnapshot) {
              return querySnapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return RequestRide.fromMap(data);
              }).toList();
            });
      });

  static final ridesRequestedByUserProvider =
      StreamProvider.family<List<RequestRide>, String>((ref, requestedbyId) {
        final user = ref.watch(userProvider)!;
        return collection
            .where('requestedBy', isEqualTo: requestedbyId)
            .snapshots()
            .map((querySnapshot) {
              return querySnapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return RequestRide.fromMap(data);
              }).toList();
            });
      });

  static final offerpoolsForRiderProvider =
      StreamProvider.family<List<RequestRide>, String>((ref, offerpoolid) {
        final user = ref.watch(userProvider)!;
        return collection
            .where('offerpool', isEqualTo: offerpoolid)
            .snapshots()
            .map((querySnapshot) {
              return querySnapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return RequestRide.fromMap(data);
              }).toList();
            });
      });

  static final diplayPassengerNearYou = StreamProvider<List<RequestRide>>((
    ref,
  ) {
    final user = ref.read(userProvider)!;
    final location = ref.read(locationProvider);
    return collection
        .where('completed', isEqualTo: false)
        .where('accepted', isEqualTo: false)
        .where('cancelled', isEqualTo: false)
        .snapshots()
        .map((querySnapshot) {
          final List<RequestRide> passengers = querySnapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return RequestRide.fromMap(data);
          }).toList();

          final List<RequestRide> nearbyPassengers = passengers.where((
            passenger,
          ) {
            final double distance =
                Geolocator.distanceBetween(
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

          return nearbyPassengers;
        });
  });
}

