import 'package:cloud_firestore/cloud_firestore.dart';


class ProfileInformation {
  final String userId;
  final String shortBio;
  final String hobbies;
  final String? governmentIdUrl;
  final String? drivingLicenseUrl;
  final Timestamp updatedAt;

  ProfileInformation({
    required this.userId,
    required this.shortBio,
    required this.hobbies,
    this.governmentIdUrl,
    this.drivingLicenseUrl,
    required this.updatedAt,
  });

  factory ProfileInformation.fromJSON(Map<String, dynamic> doc) {
    return ProfileInformation(
      userId: doc['userId'],
      shortBio: doc['shortBio'] ?? '',
      hobbies: doc['hobbies'] ?? '',
      governmentIdUrl: doc['governmentIdUrl'],
      drivingLicenseUrl: doc['drivingLicenseUrl'],
      updatedAt: doc['updatedAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'shortBio': shortBio,
      'hobbies': hobbies,
      'governmentIdUrl': governmentIdUrl,
      'drivingLicenseUrl': drivingLicenseUrl,
      'updatedAt': updatedAt,
    };
  }
}
