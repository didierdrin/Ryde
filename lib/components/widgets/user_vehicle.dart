import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:ryde_rw/models/offer_pool_model.dart';
import 'package:ryde_rw/models/vehicle_model.dart';
import 'package:ryde_rw/service/vehicle_service.dart';

class DriverVehicle extends ConsumerWidget {
  final PassengerOfferPool pool;
  const DriverVehicle({super.key, required this.pool});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicleDetails = ref.watch(
      VehicleService.vehicleDetailsStreamProvider(pool.user),
    );
    final isLoading = vehicleDetails.isLoading;

    final Vehicle? vehicle = vehicleDetails.value;

    if (vehicle == null) {
      return Container();
    }

    return ModalProgressHUD(
      inAsyncCall: isLoading,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Vehicle Info",
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 13.5,
                    color: Color(0xffb3b3b3),
                  ),
                ),
                SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      vehicle.vehicleMake,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge!.copyWith(fontSize: 13.5),
                    ),
                    SizedBox(width: 10),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  "Vehicle Registration",
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 13.5,
                    color: Color(0xffb3b3b3),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  vehicle.vehicleRegNumber,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium!.copyWith(fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
