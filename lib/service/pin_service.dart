import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ryde_rw/models/pin.dart';
import 'package:ryde_rw/utils/contants.dart';

class PinService {
  static final collection = collections.userLocations;
  static final fireStore = FirebaseFirestore.instance;

  static final pinStream = StreamProvider<List<Pin>>((ref) {
    return fireStore
        .collection(collection)
        .where('currentLocation', isNotEqualTo: null)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data()['currentLocation'];
            return Pin(
              id: doc.id,
              phone: doc.id,
              lat: data['latitude'],
              lng: data['longitude'],
            );
          }).toList();
        });
  });
}

