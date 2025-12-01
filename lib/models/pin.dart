class Pin {
  final String id, phone;
  final String? type;
  final double lat, lng;
  final double? heading;

  Pin({
    required this.id,
    required this.phone,
    required this.lat,
    required this.lng,
    this.type,
    this.heading,
  });

  factory Pin.fromJson(Map<String, dynamic> json) {
    return Pin(
      id: json['id'],
      phone: json['phone'],
      type: json['type'],
      lat: json['lat'],
      lng: json['lng'],
      heading: json['heading'],
    );
  }

  Pin copyWith(Pin pin, String? type) {
    return Pin(
      id: pin.id,
      phone: pin.phone,
      type: type ?? pin.type,
      lat: pin.lat,
      lng: pin.lng,
      heading: pin.heading,
    );
  }
}
