import 'package:ryde_rw/firestore_stub.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ryde_rw/models/vehicle_model.dart';
import 'package:ryde_rw/shared/shared_states.dart';
import 'package:ryde_rw/utils/contants.dart';

class VehicleService {
  static final collection = collections.vehicle;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveOrUpdateVehicle(Vehicle data, WidgetRef ref) async {
    print('$data');
    final user = ref.read(userProvider)!;
    final userId = user.phoneNumber;
    try {
      final existingVehicle = await _firestore
          .collection(collection)
          .where('userId', isEqualTo: userId)
          .get();
      if (existingVehicle.docs.isNotEmpty) {
        final docId = existingVehicle.docs.first.id;
        await _firestore.collection(collection).doc(docId).update(data.toMap());
      } else {
        await _firestore
            .collection(collection)
            .doc(userId)
            .set(data.toMap()..['userId'] = userId);
      }
      ref.read(vehicleProvider.notifier).state = data;
    } catch (e) {
      throw Exception("Failed to save vehicle data.");
    }
  }

  static Future<void> updateVehicle(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection(collection).doc(id).update(data);
    } catch (e) {
      throw Exception("Failed to update vehicle data.");
    }
  }

  Future<Vehicle?> getVehicleData(String userId) async {
    try {
      final vehicleData = await _firestore
          .collection(collection)
          .where('userId', isEqualTo: userId)
          .get();
      if (vehicleData.docs.isNotEmpty) {
        return Vehicle.fromJSON(vehicleData.docs.first.data());
      }
      return null;
    } catch (e, stackTrace) {
      print('VehicleService: Error getting vehicle data: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  static final vehicleStream = StreamProvider.family<Vehicle?, String>((
    ref,
    phone,
  ) {
    return FirebaseFirestore.instance
        .collection(collection)
        .doc(phone)
        .snapshots()
        .map((snapshot) {
          try {
            if (snapshot.exists && snapshot.data() != null) {
              final data = snapshot.data()!;
              data['id'] = snapshot.id;
              if (data['approved'] == true) {
                return Vehicle.fromJSON(data);
              } else {
                return null;
              }
            } else {
              return null;
            }
          } catch (e, stackTrace) {
            print('VehicleService: Error in vehicleStream: $e');
            print('Stack trace: $stackTrace');
            return null;
          }
        })
        .handleError((error, stackTrace) {
          print('VehicleService: Stream error: $error');
          print('Stack trace: $stackTrace');
        });
  });

  static final allVehicleStreamProvider = StreamProvider<List<Vehicle>>((ref) {
    return _firestore
        .collection(collection)
        .snapshots()
        .map(
          (event) {
            try {
              return event.docs.map((e) {
                try {
                  var data = e.data();
                  data['id'] = e.id;
                  return Vehicle.fromJSON(data);
                } catch (e) {
                  print('VehicleService: Error parsing vehicle document: $e');
                  return null;
                }
              }).where((vehicle) => vehicle != null).cast<Vehicle>().toList();
            } catch (e, stackTrace) {
              print('VehicleService: Error in allVehicleStreamProvider: $e');
              print('Stack trace: $stackTrace');
              return <Vehicle>[];
            }
          },
        )
        .handleError((error, stackTrace) {
          print('VehicleService: All vehicles stream error: $error');
          print('Stack trace: $stackTrace');
        });
  });

  static final vehicleDetailsStreamProvider =
      StreamProvider.family<Vehicle?, String>((ref, vehicleId) {
        return _firestore.collection(collection).doc(vehicleId).snapshots().map(
          (snapshot) {
            if (snapshot.exists && snapshot.data() != null) {
              final data = snapshot.data()!;
              data['id'] = snapshot.id;
              return Vehicle.fromJSON(data);
            }
            return null;
          },
        );
      });

  static final approvedVehicleStream = StreamProvider<List<Vehicle>>((ref) {
    return _firestore
        .collection(collection)
        .where('approved', isEqualTo: true)
        .where('active', isEqualTo: true)
        .snapshots()
        .map(
          (event) => event.docs.map((e) {
            var data = e.data();
            data['id'] = e.id;
            return Vehicle.fromJSON(data);
          }).toList(),
        );
  });
}

