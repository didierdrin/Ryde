// address_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ryde_rw/models/address_model.dart';

class AddressService {
  static const String collection = 'addresses';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> saveAddress({
    required String phoneNumber,
    required String addressString,
    required String type,
    final Map<String, double>? location,
  }) async {
    final docRef = _firestore.collection(collection).doc(phoneNumber);

    final doc = await docRef.get();

    if (doc.exists) {
      await docRef.update({
        type: {
          'addressString': addressString,
          'type': type,
          'location': location,
        },
      });
    } else {
      await docRef.set({
        type: {
          'addressString': addressString,
          'type': type,
          'location': location,
        },
      });
    }
  }

  static Future<Map<String, Address>> getAddresses(String phoneNumber) async {
    final doc = await _firestore.collection(collection).doc(phoneNumber).get();
    if (!doc.exists) return {};
    final data = doc.data()!;
    final addresses = <String, Address>{};

    data.forEach((key, value) {
      if (value is Map) {
        addresses[key] = Address.fromJson(Map<String, dynamic>.from(value));
      }
    });
    return addresses;
  }

  static final addressesProviderd =
      StreamProvider.family<Map<String, Address>, String>((ref, phoneNumber) {
        return FirebaseFirestore.instance
            .collection('addresses')
            .doc(phoneNumber)
            .snapshots()
            .map((snapshot) {
              if (!snapshot.exists) return {};

              final data = snapshot.data()!;
              final addresses = <String, Address>{};

              data.forEach((key, value) {
                if (value is Map) {
                  addresses[key] = Address.fromJson(
                    Map<String, dynamic>.from(value),
                  );
                }
              });

              return addresses;
            });
      });
}

final addressesProvider = StreamProvider.family<Map<String, Address>, String>((
  ref,
  phoneNumber,
) {
  return FirebaseFirestore.instance
      .collection('addresses')
      .doc(phoneNumber)
      .snapshots()
      .map((snapshot) {
        if (!snapshot.exists) return {};

        final data = snapshot.data()!;
        final addresses = <String, Address>{};

        data.forEach((key, value) {
          if (value is Map) {
            addresses[key] = Address.fromJson(Map<String, dynamic>.from(value));
          }
        });

        return addresses;
      });
});
