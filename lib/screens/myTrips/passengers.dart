import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:ryde_rw/components/widgets/passenger_available_card.dart';
import 'package:ryde_rw/service/location_service.dart';
import 'package:ryde_rw/service/request_rider_service.dart';
import 'package:ryde_rw/service/user_service.dart';
import 'package:ryde_rw/shared/shared_states.dart';
import 'package:ryde_rw/theme/colors.dart';
import 'package:ryde_rw/utils/utils.dart';

class PassengersPool extends ConsumerStatefulWidget {
  const PassengersPool({super.key});

  @override
  ConsumerState<PassengersPool> createState() => _PassengersState();
}

class _PassengersState extends ConsumerState<PassengersPool> {
  @override
  Widget build(BuildContext context) {
    final passengersAroundStream = ref.watch(
      RequestRideService.allRequestRideStreamProvider,
    );
    final userLocation = ref.read(locationProvider);
    final userStreams = ref.watch(UserService.usersStream);
    final isLoading = passengersAroundStream.isLoading || userStreams.isLoading;

    final findingPassenger = passengersAroundStream.value ?? [];
    final users = userStreams.value ?? [];

    final passrngessLocationNear = findingPassenger.where((location) {
      final checkRequestDate = location.createdAt!.toDate();
      final now = DateTime.now();
      final truncatedNow = truncateToDate(now);
      final truncatedRequestDate = truncateToDate(checkRequestDate);
      final double radiusKm = 3.0;
      final isPickupNear = isLocationNear(
        location.pickupLocation.latitude,
        location.pickupLocation.longitude,
        userLocation['lat'] as double,
        userLocation['long'] as double,
        radiusKm,
      );
      final riderIsEmpty = location.rider.isEmpty;
      return isPickupNear &&
          (truncatedRequestDate.isAfter(truncatedNow) ||
              truncatedRequestDate.isAtSameMomentAs(truncatedNow)) &&
          riderIsEmpty &&
          !location.cancelled;
    }).toList();

    return ModalProgressHUD(
      inAsyncCall: isLoading,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (passrngessLocationNear.isEmpty && !isLoading) ...[
                      SizedBox(height: 200),
                      Icon(
                        Icons.drive_eta_rounded,
                        size: 50,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 10),
                      Text(
                        'No Passengers Found',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: passrngessLocationNear.length,
                  itemBuilder: (context, index) {
                    final ride = passrngessLocationNear[index];
                    final distance = LocationService.getDistanceFind(
                      ride,
                      userLocation,
                    )?.toStringAsFixed(1);
                    final user = users.firstWhere(
                      (element) => element.id == ride.requestedBy,
                    );
                    return PassengerAvailableCard(
                      passenger: ride,
                      image: 'assets/car.png',
                      name: user.fullName ?? user.phoneNumber,
                      time: '${distance ?? ''} km',
                      capacity: ride.seats!,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      
    );
  }
}

