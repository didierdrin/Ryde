import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ryde_rw/models/vehicle_model.dart';
import 'package:ryde_rw/service/api_service.dart';
import 'package:ryde_rw/shared/shared_states.dart';

class VehicleService {
  Map<String, dynamic> _vehiclePayload(Vehicle data) => {
        'registrationNumber': data.vehicleRegNumber,
        'make': data.vehicleMake,
        'model': data.vehicleMake,
        'year': DateTime.now().year,
        'color': 'Unknown',
        'vehicleType': data.vehicleType ?? 'SEDAN',
      };

  Vehicle? _vehicleFromApi(Map<String, dynamic>? vehicle, String userId) {
    if (vehicle == null || vehicle.isEmpty) return null;
    return Vehicle(
      vehicleMake: vehicle['make']?.toString() ?? '',
      vehicleRegNumber: vehicle['registrationNumber']?.toString() ??
          vehicle['registration_number']?.toString() ??
          '',
      userId: userId,
      vehicleType: vehicle['vehicleType']?.toString() ?? vehicle['vehicle_type']?.toString(),
      createdOn: DateTime.now(),
      approved: true,
      active: true,
    );
  }

  Future<void> saveOrUpdateVehicle(Vehicle data, WidgetRef ref) async {
    final user = ref.read(userProvider)!;
    final payload = _vehiclePayload(data);
    try {
      await ApiService.registerVehicle(payload);
    } catch (_) {
      await ApiService.updateVehicle(payload);
    }
    ref.read(vehicleProvider.notifier).state = data.copyWithUser(user.phoneNumber);
  }

  static Future<void> updateVehicle(String id, Map<String, dynamic> data) async {
    await ApiService.updateVehicle(data);
  }

  Future<Vehicle?> getVehicleData(String userId) async {
    try {
      final res = await ApiService.getDriverProfile();
      final driver = res['driver'] as Map<String, dynamic>?;
      final vehicle = driver?['vehicle'] as Map<String, dynamic>?;
      return _vehicleFromApi(vehicle, userId);
    } catch (e) {
      print('VehicleService: Error getting vehicle data: $e');
      return null;
    }
  }

  static final vehicleStream = StreamProvider.family<Vehicle?, String>((ref, phone) {
    return Stream.periodic(const Duration(seconds: 20), (_) => phone).asyncMap((userId) async {
      final service = VehicleService();
      return service.getVehicleData(userId);
    });
  });
}

extension on Vehicle {
  Vehicle copyWithUser(String userId) => Vehicle(
        vehicleMake: vehicleMake,
        vehicleRegNumber: vehicleRegNumber,
        userId: userId,
        createdOn: createdOn,
        vehicleType: vehicleType,
        tin: tin,
        approved: approved,
        active: active,
      );
}
