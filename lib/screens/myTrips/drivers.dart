import 'package:ryde_rw/firestore_stub.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:ryde_rw/components/widgets/driver_available_card.dart';
import 'package:ryde_rw/models/vehicle_model.dart';
import 'package:ryde_rw/service/location_service.dart';
import 'package:ryde_rw/service/offer_pool_service.dart';
import 'package:ryde_rw/service/vehicle_service.dart';
import 'package:ryde_rw/shared/shared_states.dart';
import 'package:ryde_rw/theme/colors.dart';
import 'package:ryde_rw/utils/utils.dart';

class DriversPool extends ConsumerStatefulWidget {
  const DriversPool({super.key});

  @override
  ConsumerState<DriversPool> createState() => _DriversState();
}

class _DriversState extends ConsumerState<DriversPool> {
  @override
  Widget build(BuildContext context) {
    final driverAroundStream = ref.watch(
      OfferPoolService.allofferPoolStreamProvider,
    );
    final vehicleStream = ref.watch(VehicleService.allVehicleStreamProvider);
    final userLocation = ref.read(locationProvider);
    // final region = ref.read(regionProvider);

    final isLoading = driverAroundStream.isLoading || vehicleStream.isLoading;

    final offerPool = driverAroundStream.value ?? [];
    final vehicles = vehicleStream.value ?? [];

    final driverLocationNear = offerPool.where((location) {
      final checkRequestDate = location.dateTime;
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

      return isPickupNear &&
          (truncatedRequestDate.isAfter(truncatedNow) ||
              truncatedRequestDate.isAtSameMomentAs(truncatedNow));
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
              if (driverLocationNear.isEmpty && !isLoading)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 200),
                      Icon(
                        Icons.drive_eta_rounded,
                        size: 50,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 10),
                      Text(
                        'No Drivers Found',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: driverLocationNear.length,
                  itemBuilder: (context, index) {
                    final ride = driverLocationNear[index];

                    final vehicle = vehicles.firstWhere(
                      (element) => element.userId == ride.user,
                      orElse: () => Vehicle(
                        userId: ride.user,
                        vehicleRegNumber: 'N/A',
                        vehicleMake: 'N/A',
                        createdOn: DateTime.now(),
                      ),
                    );
                    final distance = LocationService.getDistanceOffer(
                      ride,
                      userLocation,
                    )?.toStringAsFixed(1);
                    return DriverAvailableCard(
                      image: 'assets/car.png',
                      name: vehicle.vehicleRegNumber,
                      ride: ride,
                      price:
                          '${"RWF"} ${formatPriceWithCommas(ride.pricePerSeat)}',
                      time: '${distance ?? ''} km',
                      capacity: ride.emptySeat == null
                          ? ride.selectedSeat!
                          : ride.emptySeat!,
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

