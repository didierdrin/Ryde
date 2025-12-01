import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:ryde_rw/models/region.dart';
import 'package:ryde_rw/models/user.dart';
import 'package:ryde_rw/service/local_storage_service.dart';
import 'package:ryde_rw/shared/shared_states.dart';
import 'package:ryde_rw/utils/contants.dart';
import 'firebase_storage.dart';

class UserService {
  static String collection = collections.users;
  static String appCollection = collections.application;
  static String regionCollection = collections.region;
  static FirebaseFirestore fireStore = FirebaseFirestore.instance;

  static Future<User?> getUser(String phone) async {
    var user = await fireStore.collection(collection).doc(phone).get();
    if (user.exists) {
      final data = user.data()!;
      data['id'] = user.id;
      return User.fromJSON(data);
    }
    return null;
  }

  static Future<User?> addUser(Map<String, dynamic> data) async {
    String phone = data['phoneNumber'];
    await fireStore.collection(collection).doc(phone.toString()).set(data);
    final snapshot = await fireStore.collection(collection).doc(phone).get();
    if (snapshot.exists) {
      final data = snapshot.data()!;
      data['id'] = snapshot.id;
      return User.fromJSON(data);
    }
    return null;
  }

  static Future<void> updateUser(
    String phone,
    Map<String, dynamic> data,
  ) async {
    await fireStore.collection(collection).doc(phone).update(data);
  }

  static final usersStream = StreamProvider<List<User>>((ref) {
    return fireStore.collection(collection).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return User.fromJSON(data);
      }).toList();
    });
  });

  static final userStream = StreamProvider.family<void, String>((ref, phone) {
    return fireStore.collection(collection).doc(phone).snapshots().map((
      snapshot,
    ) {
      if (snapshot.exists) {
        final data = snapshot.data()!;
        data['id'] = snapshot.id;
        final u = User.fromJSON(data);
        ref.read(userProvider.notifier).state = u;
        LocalStorage.setUser(u);
      }
    });
  });

  static Stream<User> userStreamQrCode(String phoneNumber) {
    return FirebaseFirestore.instance
        .collection(collection)
        .where('phoneNumber', isEqualTo: phoneNumber)
        .snapshots()
        .map((snapshot) => User.fromJSON(snapshot.docs.first.data()));
  }

  static Future<void> deleteUser(String id) async {
    await fireStore.collection(collection).doc(id).delete();
  }

  static Future<String> getToken() async {
    final snapshot = await fireStore
        .collection(appCollection)
        .doc('environments')
        .get();
    if (snapshot.exists) {
      return snapshot.data()!['token'];
    }
    return '';
  }

  static Future<String> getPaymentCode() async {
    final snapshot = await fireStore
        .collection(appCollection)
        .doc('environments')
        .get();
    if (snapshot.exists) {
      return snapshot.data()!['paymentCode'];
    }
    return '';
  }

  static Future<void> unregisterForNotifications(User user) async {
    final token = await getToken();
    final data = user.tokens;
    data.remove(token);
    final ref = fireStore.collection(collection).doc();
    await ref.update({'tokens': data});
  }

//   static Future<Region?> getRegion(String code) async {
//     final snapshot = await fireStore
//         .collection(regionCollection)
//         .where('code', isEqualTo: code)
//         .get();
//     if (snapshot.docs.isNotEmpty) {
//       final data = snapshot.docs.first.data();
//       return Region.fromJSON(data);
//     }
//     return null;
//   }

//   static final getRegionProvider = StreamProvider.family<Region?, String>((
//     ref,
//     code,
//   ) {
//     return fireStore
//         .collection(regionCollection)
//         .where('code', isEqualTo: code)
//         .snapshots()
//         .map((snapshot) {
//           if (snapshot.docs.isNotEmpty) {
//             final data = snapshot.docs.first.data();
//             return Region.fromJSON(data);
//           }
//           return null;
//         });
//   });

//   // For uploading profile images
//   static Future<void> updateUserWithFile(
//     String userId,
//     Map<String, dynamic> userData, {
//     File? file,
//     String? fileField,
//     String? storageFolder,
//   }) async {
//     try {
//       if (file != null && fileField != null && storageFolder != null) {
//         final fileUrl = await FirebaseStorageService.uploadImage(
//           file,
//           storageFolder,
//         );
//         userData[fileField] = fileUrl;
//       }
//       await fireStore.collection(collection).doc(userId).update(userData);
//     } catch (e) {
//       rethrow;
//     }
//   }
// }

// class RegionService {
//   static final collection = collections.regions;
//   static final fireStore = FirebaseFirestore.instance;

//   static Future<Region?> getRegion(String code) async {
//     final snapshot = await fireStore
//         .collection(collection)
//         .where('code', isEqualTo: code)
//         .get();

//     if (snapshot.docs.isNotEmpty) {
//       final data = snapshot.docs.first.data();
//       return Region.fromJSON(data);
//     }
//     return null;
//   }

//   static final regionsStream = StreamProvider<List<Region>>((ref) {
//     return fireStore.collection(collection).snapshots().map((snapshot) {
//       return snapshot.docs.map((doc) {
//         final data = doc.data();
//         return Region.fromJSON(data);
//       }).toList();
//     });
//   });
}

