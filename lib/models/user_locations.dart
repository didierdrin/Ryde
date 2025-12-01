import 'package:ryde_rw/shared/locations_shared.dart';

class UserLocation {
  final String userId;
  final Location currentLocation;

  UserLocation({required this.userId, required this.currentLocation});

  Map<String, dynamic> toMap() {
    return {'userId': userId, 'currentLocation': currentLocation.toMap()};
  }

  factory UserLocation.fromMap(Map<String, dynamic> map) {
    return UserLocation(
      userId: map['userId'],
      currentLocation: Location.fromMap(map['currentLocation']),
    );
  }
}
