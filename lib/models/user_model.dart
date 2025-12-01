class UserModel {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String? profilePicture;
  final bool isDriver;
  final double? rating;
  final int? totalRides;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    this.profilePicture,
    required this.isDriver,
    this.rating,
    this.totalRides,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      profilePicture: map['profilePicture'],
      isDriver: map['isDriver'] ?? false,
      rating: map['rating']?.toDouble(),
      totalRides: map['totalRides'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'profilePicture': profilePicture,
      'isDriver': isDriver,
      'rating': rating,
      'totalRides': totalRides,
    };
  }
} 
