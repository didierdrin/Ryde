import 'package:ryde_rw/firestore_stub.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ryde_rw/models/find_pool_model.dart';
import 'package:ryde_rw/shared/shared_states.dart';
import 'package:ryde_rw/utils/contants.dart';

class FindPoolService {
  static final collection = collections.findPool;
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;

  static Future<void> createFindPool(PassengerFindPool pool) async {
    try {
      await firestore.collection(collection).doc(pool.id).set(pool.toMap());
    } catch (e) {
      throw Exception('Failed to create FindPool entry');
    }
  }

  static final findingStreams = StreamProvider<List<PassengerFindPool>>((ref) {
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
            return PassengerFindPool.fromMap(data);
          }).toList(),
        );
  });

  static final findingStreamsall = StreamProvider<List<PassengerFindPool>>((
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
            return PassengerFindPool.fromMap(data);
          }).toList(),
        );
  });

  static Future<void> updateFindpool(
    String id,
    Map<String, dynamic> data,
  ) async {
    await firestore.collection(collection).doc(id).update(data);
  }
}

