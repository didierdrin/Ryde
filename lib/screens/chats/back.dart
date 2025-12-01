// import 'dart:math';

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:ryde_rw/service/offer_pool_service.dart';

// class AvailableTrips extends ConsumerWidget {
//   final double userLatitude;
//   final double userLongitude;

//   const AvailableTrips({
//     super.key,
//     required this.userLatitude,
//     required this.userLongitude,
//   });

//   // Calculate distance between two geographical points using the Haversine formula
//   double calculateDistance(
//       double lat1, double lon1, double lat2, double lon2) {
//     const double radiusOfEarthKm = 6371; // Earth's radius in kilometers
//     final double dLat = _degreesToRadians(lat2 - lat1);
//     final double dLon = _degreesToRadians(lon2 - lon1);
//     final double a = sin(dLat / 2) * sin(dLat / 2) +
//         cos(_degreesToRadians(lat1)) *
//             cos(_degreesToRadians(lat2)) *
//             sin(dLon / 2) *
//             sin(dLon / 2);
//     final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
//     return radiusOfEarthKm * c;
//   }

//   double _degreesToRadians(double degrees) {
//     return degrees * pi / 180;
//   }

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final tripsStream = ref.watch(OfferPoolService.allTripsStreamProvider);

//     if (tripsStream.isLoading) {
//       return Center(child: CircularProgressIndicator());
//     }

//     final allTrips = tripsStream.value ?? [];

//     // Filter trips based on proximity and availability
//     final filteredTrips = allTrips.where((trip) {
//       final double distance = calculateDistance(
//         userLatitude,
//         userLongitude,
//         trip.pickupLocation.latitude,
//         trip.pickupLocation.longitude,
//       );
//       return distance <= 1 && // Check proximity (1 km or less)
//           !trip.completed && // Ensure the trip is not completed
//           !trip.isSeatFull && // Ensure the trip has available seats
//           !trip.isRideStarted; // Ensure the trip has not started
//     }).toList();

//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Available Trips"),
//       ),
//       body: filteredTrips.isEmpty
//           ? Center(child: Text("No available trips nearby."))
//           : ListView.builder(
//               itemCount: filteredTrips.length,
//               itemBuilder: (context, index) {
//                 final trip = filteredTrips[index];
//                 return ListTile(
//                   title: Text("Trip from ${trip.pickupLocation.address}"),
//                   subtitle: Text("To: ${trip.dropoffLocation.address}"),
//                   trailing: Text("${trip.pricePerSeat} RWF/Seat"),
//                   onTap: () {
//                     // Handle trip selection
//                   },
//                 );
//               },
//             ),
//     );
//   }
// }

