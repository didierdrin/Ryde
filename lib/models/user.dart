class User {
  String id, phoneNumber, tMoney, countryCode, momoPhoneNumber;
  String? fullName, profilePicture;
  List<dynamic> recommendations, tokens;
  DateTime joinedOn;
  int walletBalance;
  User({
    required this.id,
    required this.phoneNumber,
    required this.tMoney,
    required this.countryCode,
    this.fullName,
    this.profilePicture,
    required this.walletBalance,
    required this.momoPhoneNumber,
    required this.recommendations,
    required this.tokens,
    required this.joinedOn,
  });

  factory User.fromJSON(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      fullName: json['fullName'],
      countryCode: json['country_code'],
      profilePicture: json['profilePicture'],
      momoPhoneNumber: json['momoPhoneNumber'],
      phoneNumber: json['phoneNumber'],
      recommendations: json['recommendations'] ?? [],
      tokens: json['tokens'] ?? [],
      tMoney: json['tMoney'] ?? json['phoneNumber'],
      joinedOn: json['joinedOn'].toDate(),
      walletBalance: json['walletBalance'] ?? 0,
    );
  }

  Map<String, dynamic> toJSON() {
    return {
      'id': id,
      'fullName': fullName,
      'country_code': countryCode,
      'profilePicture': profilePicture,
      'momoPhoneNumber': momoPhoneNumber,
      'phoneNumber': phoneNumber,
      'recommendations': recommendations,
      'tMoney': tMoney,
      'joinedOn': joinedOn,
      'tokens': tokens,
    };
  }

  @override
  String toString() {
    return 'User(id=$id)';
  }
}
