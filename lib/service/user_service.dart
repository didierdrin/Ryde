import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ryde_rw/models/user.dart';
import 'package:ryde_rw/utils/contants.dart';
import 'firebase_storage.dart';

class UserService {
  static String collection = collections.users;
  static String appCollection = collections.application;
  static String regionCollection = collections.region;

  static Future<User?> getUser(String phone) async {
    return null;
  }

  static Future<User?> addUser(Map<String, dynamic> data) async {
    return null;
  }

  static Future<void> updateUser(
    String phone,
    Map<String, dynamic> data,
  ) async {}

  static final usersStream = StreamProvider<List<User>>((ref) {
    return Stream.value([]);
  });

  static final userStream = StreamProvider.family<void, String>((ref, phone) {
    return Stream.value(null);
  });

  static Stream<User> userStreamQrCode(String phoneNumber) {
    return Stream.empty();
  }

  static Future<void> deleteUser(String id) async {}

  static Future<String> getToken() async {
    return '';
  }

  static Future<String> getPaymentCode() async {
    return '';
  }

  static Future<void> unregisterForNotifications(User user) async {}

  static Future<void> updateUserWithFile(
    String userId,
    Map<String, dynamic> userData, {
    File? file,
    String? fileField,
    String? storageFolder,
  }) async {
    try {
      if (file != null && fileField != null && storageFolder != null) {
        final fileUrl = await FirebaseStorageService.uploadImage(
          file,
          storageFolder,
        );
        userData[fileField] = fileUrl;
      }
    } catch (e) {
      rethrow;
    }
  }
}
