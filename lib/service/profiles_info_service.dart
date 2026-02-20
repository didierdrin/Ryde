import 'package:ryde_rw/firestore_stub.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ryde_rw/models/profiles_info.dart';
import 'package:ryde_rw/shared/shared_states.dart';
import 'package:ryde_rw/utils/contants.dart';

class ProfilesInfoService {
  static final String collection = collections.profileinfo;
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;

  static Future<void> saveOrUpdateProfiles(
    ProfileInformation data,
    WidgetRef ref,
  ) async {
    final userId = data.userId;
    try {
      final existingProfiles = await firestore
          .collection(collection)
          .where('userId', isEqualTo: userId)
          .get();
      if (existingProfiles.docs.isNotEmpty) {
        final docId = existingProfiles.docs.first.id;
        await firestore.collection(collection).doc(docId).update(data.toMap());
      } else {
        await firestore.collection(collection).doc(userId).set(data.toMap());
      }
      ref.read(profileinfoProvider.notifier).state = data;
    } catch (e) {
      throw Exception("Failed to save Profiles data: $e");
    }
  }

  static final profileinformationStream = StreamProvider.family<void, String>((
    ref,
    phone,
  ) {
    return firestore.collection(collection).doc(phone).snapshots().map((
      snapshot,
    ) {
      if (snapshot.exists) {
        final data = snapshot.data()!;
        data['id'] = snapshot.id;
        final u = ProfileInformation.fromJSON(data);
        ref.read(profileinfoProvider.notifier).state = u;
      }
      return;
    });
  });
}

