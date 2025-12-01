class Address {
  final String addressString;
  final String type;
  final Map<String, double>? location; 

  Address({
    required this.addressString,
    required this.type,
    this.location,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      addressString: json['addressString'] ?? '',
      type: json['type'] ?? '',
      location: json['location'] != null 
        ? {
            'latitude': json['location']['latitude'],
            'longitude': json['location']['longitude']
          }
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'addressString': addressString,
      'type': type,
      'location': location != null 
        ? {
            'latitude': location!['latitude'],
            'longitude': location!['longitude']
          }
        : null,
    };
  }
}
