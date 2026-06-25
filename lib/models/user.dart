/// User model aligned with Ryde API (auth/profile).
class User {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String userType; // PASSENGER, DRIVER, ADMIN
  final String? profilePictureUrl;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.userType,
    this.profilePictureUrl,
  });

  factory User.fromApiJson(Map<String, dynamic> json) {
    final user = json['user'] ?? json;
    return User(
      id: user['userId'] ?? user['id'] ?? '',
      name: user['name'] ?? user['fullName'] ?? '',
      email: user['email'] ?? '',
      phoneNumber: user['phoneNumber'] ?? '',
      userType: user['userType'] ?? 'PASSENGER',
      profilePictureUrl: user['profilePictureUrl']?.toString(),
    );
  }

  factory User.fromJSON(Map<String, dynamic> json) {
    return User(
      id: json['userId'] ?? json['id'] ?? '',
      name: json['name'] ?? json['fullName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      userType: json['userType'] ?? 'PASSENGER',
      profilePictureUrl: json['profilePictureUrl']?.toString(),
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
      if (profilePictureUrl != null) 'profilePictureUrl': profilePictureUrl,
    };
  }

  User copyWith({
    String? name,
    String? phoneNumber,
    String? profilePictureUrl,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      userType: userType,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
    );
  }

  bool get isDriver => userType == 'DRIVER';
  bool get isPassenger => userType == 'PASSENGER';
  bool get isAdmin => userType == 'ADMIN';

  String get fullName => name;
  String get momoPhoneNumber => phoneNumber;
  String get countryCode => phoneNumber.startsWith('+') && phoneNumber.length >= 4
      ? phoneNumber.substring(0, 4)
      : '+250';
  int get walletBalance => 0;
  String get profilePicture => profilePictureUrl ?? '';
  DateTime get joinedOn => DateTime.now();
  List<dynamic> get tokens => [];

  @override
  String toString() => 'User(id=$id, userType=$userType)';
}
