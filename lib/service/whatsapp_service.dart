import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ryde_rw/models/whatsapp_model.dart';
import 'package:ryde_rw/shared/shared_states.dart';
import 'package:ryde_rw/utils/contants.dart';

class WhatsappService {
  static final collection = FirebaseFirestore.instance.collection(
    collections.whatsappRides,
  );

  static Future<void> createRequestRide(WhatsappModel requestRide) async {
    try {
      await collection.doc(requestRide.id).set(requestRide.toMap());
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
      StreamProvider.family<WhatsappModel?, String>((ref, id) {
        return collection.doc(id).snapshots().map((snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            final data = snapshot.data()!;
            data['id'] = snapshot.id;
            return WhatsappModel.fromMap(data);
          }
          return null;
        });
      });

  static final allRequestRideStreamProvider =
      StreamProvider<List<WhatsappModel>>((ref) {
        final user = ref.watch(userProvider)!;
        return collection
            .where('country_code', isEqualTo: user.countryCode)
            .snapshots()
            .map((querySnapshot) {
              return querySnapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return WhatsappModel.fromMap(data);
              }).toList();
            });
      });

  static final ridesForRiderProvider =
      StreamProvider.family<List<WhatsappModel>, String>((ref, riderId) {
        final user = ref.watch(userProvider)!;
        return collection
            .where('rider', isEqualTo: riderId)
            .where('country_code', isEqualTo: user.countryCode)
            .snapshots()
            .map((querySnapshot) {
              return querySnapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return WhatsappModel.fromMap(data);
              }).toList();
            });
      });

  static final ridesRequestedByUserProvider =
      StreamProvider.family<List<WhatsappModel>, String>((ref, requestedbyId) {
        final user = ref.watch(userProvider)!;
        return collection
            .where('requestedBy', isEqualTo: requestedbyId)
            .where('country_code', isEqualTo: user.countryCode)
            .snapshots()
            .map((querySnapshot) {
              return querySnapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return WhatsappModel.fromMap(data);
              }).toList();
            });
      });

  static final offerpoolsForRiderProvider =
      StreamProvider.family<List<WhatsappModel>, String>((ref, offerpoolid) {
        final user = ref.watch(userProvider)!;
        return collection
            .where('offerpool', isEqualTo: offerpoolid)
            .where('country_code', isEqualTo: user.countryCode)
            .snapshots()
            .map((querySnapshot) {
              return querySnapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return WhatsappModel.fromMap(data);
              }).toList();
            });
      });
}

