import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:ryde_rw/components/widgets/pooler_widget.dart';
import '../home/passenger_info.dart';
import '../home/searchpooler.dart';
import 'package:ryde_rw/service/location_service.dart';
import 'package:ryde_rw/service/offer_pool_service.dart';
import 'package:ryde_rw/service/user_service.dart';
import 'package:ryde_rw/service/order_service.dart';
import 'package:ryde_rw/shared/locations_shared.dart';
import 'package:ryde_rw/shared/shared_states.dart';
import 'package:ryde_rw/theme/colors.dart';
import 'package:ryde_rw/utils/utils.dart';
import 'package:ryde_rw/provider/order_providers.dart';
import 'package:url_launcher/url_launcher.dart';

class SearchPassengersListPage extends ConsumerWidget {
  final Location? driverStartLocation;
  final Location? driverEndLocation;
  final String? type;

  const SearchPassengersListPage({
    super.key,
    this.driverStartLocation,
    this.driverEndLocation,
    this.type,
  });

  void _launchGoogleMaps({required List<Location> waypoints}) async {
    final waypointsQuery = waypoints
        .map((loc) => '${loc.latitude},${loc.longitude}')
        .join('/');

    final googleMapsUrl =
        "https://www.google.com/maps/dir/$waypointsQuery?origin=&travelmode=driving&dir_action=navigate";

    final url = Uri.parse(googleMapsUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = ref.watch(locationProvider);
    final myLocation = Location.fromData(l);
    final user = ref.watch(userProvider)!;
    final userStreams = ref.watch(UserService.usersStream);
    final rideOrdersStream = ref.watch(rideOrdersStreamProvider);
    final requestRidesStream = ref.watch(requestRidesStreamProvider);

    final isLoading = userStreams.isLoading || rideOrdersStream.isLoading || requestRidesStream.isLoading;

    final userdata = userStreams.value ?? [];
    final rideOrders = rideOrdersStream.value ?? [];
    final requestRides = requestRidesStream.value ?? [];

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
          child: Column(
            children: [
              if (rideOrders.isEmpty && requestRides.isEmpty && !isLoading)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.drive_eta_rounded, size: 50, color: Colors.grey[400]),
                        SizedBox(height: 10),
                        Text('No Passenger Found NearBy You!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w300)),
                      ],
                    ),
                  ),
                ),
              ...rideOrders.map((order) => Container(
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
                            order.dateTime,
                            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: order.status == 'completed' ? Colors.green.withOpacity(0.1) : 
                                    order.status == 'cancelled' ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              order.status.toUpperCase(),
                              style: TextStyle(
                                color: order.status == 'completed' ? Colors.green : 
                                      order.status == 'cancelled' ? Colors.red : Colors.orange,
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
                              order.from,
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
                              order.to,
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
                            'Vehicle: ${order.vehicleType}',
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                          Text(
                            '${order.estimatedPrice} FRW',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )).toList(),
              ...requestRides.map((request) => Container(
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
                                request.accepted ? 'ACCEPTED' : request.rejected ? 'REJECTED' : 'CANCELLED',
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
                            'Type: ${request.type}',
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
              )).toList(),

            ],
          ),
          ),
        ),
      

    );
  }
}

