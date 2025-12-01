import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ryde_rw/models/user.dart';

class Vehicle {
  final String vehicleMake;
  final String vehicleRegNumber;
  final String userId;
  final String? vehicleType, tin;
  final Timestamp createdOn;
  final bool? approved, active;

  Vehicle({
    required this.vehicleMake,
    required this.vehicleRegNumber,
    required this.userId,
    required this.createdOn,
    this.vehicleType,
    this.tin,
    this.approved,
    this.active,
  });

  factory Vehicle.fromJSON(Map<String, dynamic> map) {
    return Vehicle(
      vehicleMake: map['vehicleMake'] ?? '',
      vehicleRegNumber: map['vehicleRegNumber'] ?? '',
      userId: map['userId'] ?? '',
      vehicleType: map['vehicleType'] ?? '',
      tin: map['tin'] ?? '',
      createdOn: map['createdOn'] ?? Timestamp.now(),
      approved: map['approved'] ?? false,
      active: map['active'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vehicleMake': vehicleMake,
      'vehicleRegNumber': vehicleRegNumber,
      'userId': userId,
      'vehicleType': vehicleType,
      'createdOn': createdOn,
      'approved': approved,
      'tin': tin,
      'active': active,
    };
  }
}

class UserVehicle {
  final User? user;
  final Vehicle userVehicle;
  UserVehicle({required this.user, required this.userVehicle});
}

