import 'package:ryde_rw/models/user.dart';

class Vehicle {
  final String vehicleMake;
  final String vehicleRegNumber;
  final String userId;
  final String? vehicleType, tin;
  final DateTime createdOn;
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
      vehicleType: map['vehicleType'],
      tin: map['tin'],
      createdOn: _parseDateTime(map['createdOn']) ?? DateTime.now(),
      approved: map['approved'],
      active: map['active'],
    );
  }

  static DateTime? _parseDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is Map && v['_seconds'] != null) return DateTime.fromMillisecondsSinceEpoch((v['_seconds'] as int) * 1000);
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'vehicleMake': vehicleMake,
      'vehicleRegNumber': vehicleRegNumber,
      'userId': userId,
      'vehicleType': vehicleType,
      'createdOn': createdOn.toIso8601String(),
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
