import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ryde_rw/models/request_model.dart';
import 'package:ryde_rw/service/offer_pool_service.dart';
import 'package:ryde_rw/shared/shared_states.dart';
import 'package:ryde_rw/theme/colors.dart';
import 'package:ryde_rw/utils/utils.dart';
import 'package:ryde_rw/provider/current_location_provider.dart';

final _nearbyPassengersProvider = StreamProvider.family<List<RequestRide>, LatLng>((ref, location) {
  final user = ref.read(userProvider)!;
  return FirebaseFirestore.instance
      .collection('requestRiders')
      .where('completed', isEqualTo: false)
      .where('accepted', isEqualTo: false)
      .where('cancelled', isEqualTo: false)
      .where('country_code', isEqualTo: user.countryCode)
      .snapshots()
      .map((querySnapshot) {
        final List<RequestRide> passengers = querySnapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return RequestRide.fromMap(data);
        }).toList();

        final List<RequestRide> nearbyPassengers = passengers.where((passenger) {
          final double distance = Geolocator.distanceBetween(
            location.latitude,
            location.longitude,
            passenger.pickupLocation.latitude,
            passenger.pickupLocation.longitude,
          ) / 1000;

          return distance <= 3 &&
              !passenger.accepted &&
              passenger.rider.isEmpty &&
              !passenger.cancelled &&
              passenger.requestedBy != user.id;
        }).toList();

        return nearbyPassengers;
      });
});

class SearchPassengersListPage extends ConsumerWidget {
  final String? type;

  const SearchPassengersListPage({
    super.key,
    this.type,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider)!;
    final locationAsync = ref.watch(currentLocationProvider);

    return locationAsync.when(
      data: (location) {
        final passengerNearYouStream = ref.watch(_nearbyPassengersProvider(location));
        
        return passengerNearYouStream.when(
          data: (requestRides) => _buildContent(context, ref, user, false, requestRides),
          loading: () => _buildContent(context, ref, user, true, []),
          error: (error, stack) => _buildContent(context, ref, user, false, []),
        );
      },
      loading: () => Scaffold(
        appBar: type != null
            ? AppBar(
                titleSpacing: 0,
                elevation: 0,
                backgroundColor: Colors.white,
                title: Text(
                  capitalizeFirstLetter(type!),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              )
            : null,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Getting your location...'),
            ],
          ),
        ),
      ),
      error: (error, stack) => Scaffold(
        appBar: type != null
            ? AppBar(
                titleSpacing: 0,
                elevation: 0,
                backgroundColor: Colors.white,
                title: Text(
                  capitalizeFirstLetter(type!),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              )
            : null,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('Error getting location: $error'),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(currentLocationProvider),
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, dynamic user, bool isLoading, List<RequestRide> requestRides) {
    return Scaffold(
      appBar: type != null
          ? AppBar(
              titleSpacing: 0,
              elevation: 0,
              backgroundColor: Colors.white,
              title: Text(
                capitalizeFirstLetter(type!),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            )
          : null,
      body: ModalProgressHUD(
        inAsyncCall: isLoading,
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: requestRides.isEmpty && !isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.drive_eta_rounded, size: 50, color: Colors.grey[400]),
                      SizedBox(height: 10),
                      Text('No Passenger Found NearBy You!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w300)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: requestRides.length,
                  itemBuilder: (context, index) {
                    final request = requestRides[index];
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
                                  formatTime(request.requestedTime),
                                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (!request.accepted && !request.rejected && !request.cancelled)
                                  ElevatedButton(
                                    onPressed: () async {
                                      await OfferPoolService.acceptRideRequest(
                                        request.id!,
                                        user.id,
                                      );
                                    },
                                    child: Text('Accept', style: TextStyle(fontSize: 12)),
                                  )
                                else
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: request.accepted ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      request.accepted ? 'ACCEPTED' : 'REJECTED',
                                      style: TextStyle(
                                        color: request.accepted ? Colors.green : Colors.red,
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
                                    request.pickupLocation.address,
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
                                    request.dropoffLocation.address,
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
                                  'Seats: ${request.seats}',
                                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                ),
                                Text(
                                  '${request.price ?? 0} FRW',
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
    );
  }
}


