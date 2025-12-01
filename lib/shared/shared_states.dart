import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ryde_rw/models/profiles_info.dart';
import 'package:ryde_rw/models/user.dart';
import 'package:ryde_rw/models/user_locations.dart';
import 'package:ryde_rw/models/vehicle_model.dart';
import 'package:ryde_rw/service/location_service.dart';
import 'package:ryde_rw/service/qr_code_service.dart';
import 'package:ryde_rw/service/user_location_service.dart';
import 'package:ryde_rw/service/user_service.dart';

final userProvider = NotifierProvider<UserNotifier, User?>(() {
  return UserNotifier();
});

class UserNotifier extends Notifier<User?> {
  @override
  User? build() {
    return null;
  }

  void setUser(User? user) {
    state = user;
  }
}

final vehicleProvider = NotifierProvider<VehicleNotifier, Vehicle?>(() {
  return VehicleNotifier();
});

class VehicleNotifier extends Notifier<Vehicle?> {
  @override
  Vehicle? build() {
    return null;
  }

  void setVehicle(Vehicle? vehicle) {
    state = vehicle;
  }
}

final profileinfoProvider =
    NotifierProvider<ProfileInfoNotifier, ProfileInformation?>(() {
      return ProfileInfoNotifier();
    });

class ProfileInfoNotifier extends Notifier<ProfileInformation?> {
  @override
  ProfileInformation? build() {
    return null;
  }

  void setProfileInfo(ProfileInformation? info) {
    state = info;
  }
}

final locationProvider =
    NotifierProvider<LocationNotifier, Map<String, dynamic>>(() {
      return LocationNotifier();
    });

class LocationNotifier extends Notifier<Map<String, dynamic>> {
  @override
  Map<String, dynamic> build() {
    return {};
  }

  void setLocation(Map<String, dynamic> location) {
    state = location;
  }
}



final locationTrackingServiceProvider = Provider<LocationTrackingService>((
  ref,
) {
  return LocationTrackingService();
});

final userLocationTrackerStream = StreamProvider.family<UserLocation, String>((
  ref,
  userId,
) {
  final locationTrackingService = ref.watch(locationTrackingServiceProvider);
  return locationTrackingService.trackUserLocation(userId);
});

final qrCodeProvider = StreamProvider.family<String?, String>((ref, userId) {
  return QRCodeService.getQRCodeStream(userId);
});

final userQrCodeProvider = StreamProvider.autoDispose.family<User, String>((
  ref,
  phoneNumber,
) {
  return UserService.userStreamQrCode(phoneNumber);
});

final locationsProvider = StreamProvider<Position>((ref) async* {
  final locationService = LocationsService();
  await locationService.checkLocationPermissions();
  yield* locationService.locationStream;
});
