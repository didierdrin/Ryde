import 'package:ryde_rw/models/user.dart';
import 'package:ryde_rw/service/local_storage_service.dart';
import 'package:ryde_rw/service/api_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserServiceApi {
  // Migrated to use REST API instead of Firebase
  static Future<User?> getUser(String phone) async {
    try {
      final response = await ApiService.getProfile();
      if (response['user'] != null) {
        // Map API response to User model
        final userData = response['user'];
        return User.fromJSON({
          'id': userData['user_id'],
          'phoneNumber': userData['phone_number'],
          'fullName': userData['name'],
          'country_code': '+250', // Default for Rwanda
          'profilePicture': null,
          'momoPhoneNumber': userData['phone_number'],
          'recommendations': [],
          'tokens': [],
          'joinedOn': Timestamp.fromDate(DateTime.parse(userData['registration_date'])),
          'walletBalance': 0,
        });
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  static Future<User?> addUser(Map<String, dynamic> data) async {
    try {
      // Map to API format
      final apiData = {
        'name': data['fullName'] ?? data['name'] ?? '',
        'email': data['email'] ?? '${data['phoneNumber']}@ryde.rw',
        'phoneNumber': data['phoneNumber'],
        'password': data['password'] ?? 'defaultPassword123', // Should be provided
        'userType': data['userType'] ?? 'PASSENGER',
        if (data['licenseNumber'] != null) 'licenseNumber': data['licenseNumber'],
      };

      final response = await ApiService.register(apiData);
      if (response['user'] != null) {
        final userData = response['user'];
        return User.fromJSON({
          'id': userData['userId'],
          'phoneNumber': userData['phoneNumber'],
          'fullName': userData['name'],
          'country_code': '+250',
          'profilePicture': null,
          'momoPhoneNumber': userData['phoneNumber'],
          'recommendations': [],
          'tokens': [],
          'joinedOn': Timestamp.fromDate(DateTime.now()),
          'walletBalance': 0,
        });
      }
      return null;
    } catch (e) {
      print('Error adding user: $e');
      return null;
    }
  }

  static Future<void> updateUser(
    String phone,
    Map<String, dynamic> data,
  ) async {
    try {
      // Note: API doesn't have update user endpoint yet, would need to be added
      // For now, this is a placeholder
      print('Update user not yet implemented in API');
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }
}
