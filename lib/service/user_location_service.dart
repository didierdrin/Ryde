import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ryde_rw/models/user_locations.dart';
import 'package:ryde_rw/shared/locations_shared.dart';
import 'package:ryde_rw/utils/contants.dart';

class LocationTrackingService {
  static final collection = collections.userLocations;
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> _requestPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Location services are disabled.';
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Location permissions are denied.';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Location permissions are permanently denied.';
    }
  }

  Stream<UserLocation> trackUserLocation(String userId) async* {
    await _requestPermissions();

    yield* Geolocator.getPositionStream()
        .map((Position position) async {
          final docRef = firestore.collection(collection).doc(userId);

          final docSnapshot = await docRef.get();
          if (!docSnapshot.exists) {
            final initialLocation = UserLocation(
              userId: userId,
              currentLocation: Location(
                latitude: position.latitude,
                longitude: position.longitude,
                address: 'Initial location',
              ),
            );
            await docRef.set(initialLocation.toMap(), SetOptions(merge: true));
          }

          final userLocation = UserLocation(
            userId: userId,
            currentLocation: Location(
              latitude: position.latitude,
              longitude: position.longitude,
              address: 'Current location',
            ),
          );

          await docRef.set(userLocation.toMap(), SetOptions(merge: true));
          return userLocation;
        })
        .asyncMap((futureLocation) => futureLocation);
  }

  static final userLocationStream =
      StreamProvider.family<UserLocation?, String>((ref, userId) {
        return firestore.collection(collection).doc(userId).snapshots().map((
          snapshot,
        ) {
          if (snapshot.exists) {
            final data = snapshot.data()!;
            data['id'] = snapshot.id;
            return UserLocation.fromMap(data);
          }
          return null;
        });
      });

  static final usersLocationsStream = StreamProvider<List<UserLocation>>((ref) {
    return firestore
        .collection(collection)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return UserLocation.fromMap(data);
          }).toList(),
        );
  });
}

