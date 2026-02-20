/// User model aligned with Ryde API (auth/profile).
class User {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String userType; // PASSENGER, DRIVER, ADMIN

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.userType,
  });

  /// From API response (auth/login, auth/register, auth/profile).
  factory User.fromApiJson(Map<String, dynamic> json) {
    final user = json['user'] ?? json;
    return User(
      id: user['userId'] ?? user['id'] ?? '',
      name: user['name'] ?? user['fullName'] ?? '',
      email: user['email'] ?? '',
      phoneNumber: user['phoneNumber'] ?? '',
      userType: user['userType'] ?? 'PASSENGER',
    );
  }

  /// From stored JSON (SharedPreferences).
  factory User.fromJSON(Map<String, dynamic> json) {
    return User(
      id: json['userId'] ?? json['id'] ?? '',
      name: json['name'] ?? json['fullName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      userType: json['userType'] ?? 'PASSENGER',
    );
  }

  Map<String, dynamic> toJSON() {
    return {
      'userId': id,
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'userType': userType,
    };
  }

  bool get isDriver => userType == 'DRIVER';
  bool get isPassenger => userType == 'PASSENGER';

  /// Backward compatibility for screens still using old field names.
  String get fullName => name;
  String get momoPhoneNumber => phoneNumber;
  String get countryCode => phoneNumber.startsWith('+') && phoneNumber.length >= 4
      ? phoneNumber.substring(0, 4)
      : '+250';
  int get walletBalance => 0;
  DateTime get joinedOn => DateTime.now();

  @override
  String toString() => 'User(id=$id, userType=$userType)';
}
