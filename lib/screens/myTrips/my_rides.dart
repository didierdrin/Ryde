import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:ryde_rw/provider/order_providers.dart';
import 'package:ryde_rw/theme/colors.dart';

class MyRidesTab extends ConsumerWidget {
  const MyRidesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestRidesStream = ref.watch(requestRidesStreamProvider);

    return requestRidesStream.when(
      data: (requestRides) => ModalProgressHUD(
        inAsyncCall: false,
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: requestRides.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.drive_eta_rounded,
                        size: 50,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 10),
                      Text(
                        'No Rides Yet',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  itemCount: requestRides.length,
                  itemBuilder: (context, index) {
                    final ride = requestRides[index];
                    return Container(
                      width: MediaQuery.of(context).size.width,
                      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  ride.requestedTime.toDate().toString().substring(0, 16),
                                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: ride.completed
                                        ? Colors.green.withOpacity(0.1)
                                        : ride.cancelled
                                            ? Colors.red.withOpacity(0.1)
                                            : ride.accepted
                                                ? Colors.blue.withOpacity(0.1)
                                                : Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    ride.completed
                                        ? 'COMPLETED'
                                        : ride.cancelled
                                            ? 'CANCELLED'
                                            : ride.accepted
                                                ? 'ACCEPTED'
                                                : 'PENDING',
                                    style: TextStyle(
                                      color: ride.completed
                                          ? Colors.green
                                          : ride.cancelled
                                              ? Colors.red
                                              : ride.accepted
                                                  ? Colors.blue
                                                  : Colors.orange,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 15),
                            Row(
                              children: [
                                Icon(Icons.circle, color: kMainColor, size: 15),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    ride.pickupLocation.address,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(Icons.more_vert, color: kMainColor, size: 15),
                            ),
                            Row(
                              children: [
                                SizedBox(width: 2),
                                Icon(Icons.keyboard_arrow_down, color: kMainColor, size: 20),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    ride.dropoffLocation.address,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Seats: ${ride.seats ?? 1}',
                                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                ),
                                Text(
                                  '${ride.price ?? 0} FRW',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
      loading: () => ModalProgressHUD(
        inAsyncCall: true,
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
      error: (error, stack) => Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 50, color: Colors.red),
              SizedBox(height: 10),
              Text(
                'Error loading rides',
                style: TextStyle(fontSize: 16, color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
