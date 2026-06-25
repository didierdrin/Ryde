import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:ryde_rw/service/realtime_location_tracker.dart';

/// Circle avatar for trip lists — supports network URLs and data: URIs.
class TripListAvatar extends StatelessWidget {
  final String? imageUrl;
  final IconData fallbackIcon;
  final Color? fallbackColor;
  final double radius;

  const TripListAvatar({
    super.key,
    this.imageUrl,
    this.fallbackIcon = Icons.person,
    this.fallbackColor,
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';
    if (url.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: (fallbackColor ?? Colors.blue).withOpacity(0.12),
        child: Icon(fallbackIcon, color: fallbackColor ?? Colors.blue, size: radius),
      );
    }

    if (url.startsWith('data:')) {
      try {
        final base64Data = url.split(',').last;
        final bytes = base64Decode(base64Data);
        return CircleAvatar(
          radius: radius,
          backgroundImage: MemoryImage(Uint8List.fromList(bytes)),
        );
      } catch (_) {}
    }

    if (url.startsWith('http')) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey.shade200,
        backgroundImage: NetworkImage(url),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: (fallbackColor ?? Colors.blue).withOpacity(0.12),
      child: Icon(fallbackIcon, color: fallbackColor ?? Colors.blue, size: radius),
    );
  }
}

String? tripProfileImage(Map<String, dynamic> trip) {
  final url = tripStr(trip, 'passengerProfilePictureUrl');
  return url.isEmpty ? null : url;
}

String? tripVehicleImage(Map<String, dynamic> trip) {
  final url = tripStr(trip, 'vehicleImageUrl');
  return url.isEmpty ? null : url;
}
