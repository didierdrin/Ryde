import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import '../myTrips/finding_existing_trip.dart';
import '../myTrips/finding_pool_detail.dart';
import '../myTrips/ride_info.dart';
import 'package:ryde_rw/service/find_pool_service.dart';
import 'package:ryde_rw/service/location_service.dart';
import 'package:ryde_rw/service/offer_pool_service.dart';
import 'package:ryde_rw/service/request_rider_service.dart';
import 'package:ryde_rw/service/user_service.dart';
import 'package:ryde_rw/service/vehicle_service.dart';
import 'package:ryde_rw/shared/shared_states.dart';
import 'package:ryde_rw/theme/colors.dart';
import 'package:ryde_rw/utils/utils.dart';
import 'package:ryde_rw/provider/order_providers.dart';
import 'package:collection/collection.dart';

class FindingTab extends ConsumerStatefulWidget {
  const FindingTab({super.key});

  @override
  FindingTabState createState() => FindingTabState();
}

class FindingTabState extends ConsumerState<FindingTab> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(locationProvider);
    final findingdataStreams = ref.watch(FindPoolService.findingStreams);
    final findingpoolallStreams = ref.watch(FindPoolService.findingStreamsall);
    final userStreams = ref.watch(UserService.usersStream);
    final user = ref.watch(userProvider);
    
    // Return loading if user is not available
    if (user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading user data...'),
          ],
        ),
      );
    }
    final vehicleAsyncValue = ref.watch(VehicleService.vehicleStream(user.id));
    final offersStreams = ref.watch(OfferPoolService.offeringStreams);
    final requestStreams = ref.watch(
      RequestRideService.allRequestRideStreamProvider,
    );
    final rideOrdersStream = ref.watch(rideOrdersStreamProvider);
    final allOfferPoolStreams = ref.watch(OfferPoolService.offeringStreamsAll);
    final locationFoundStreams = ref.watch(
      OfferPoolService.allofferPoolStreamProvider,
    );

    final isLoading =
        findingdataStreams.isLoading ||
        userStreams.isLoading ||
        findingpoolallStreams.isLoading ||
        requestStreams.isLoading ||
        vehicleAsyncValue.isLoading ||
        offersStreams.isLoading ||
        locationFoundStreams.isLoading ||
        allOfferPoolStreams.isLoading ||
        rideOrdersStream.isLoading;
    final userdata = userStreams.value ?? [];
    final requested = requestStreams.value ?? [];
    final rideOrders = rideOrdersStream.value ?? [];
    final limit = DateTime.now().subtract(Duration(hours: 5));
    final locationfoundValue = locationFoundStreams.value ?? [];
    
    final requestUser = requested.where((el) {
      return el.requestedBy == user.id;
    }).toList();
    
    final userRideOrders = rideOrders.where((order) {
      return order.userId == user.id;
    }).toList();
    
    requestUser.sort(
      (a, b) => b.requestedTime.compareTo(a.requestedTime),
    );
    
    userRideOrders.sort(
      (a, b) {
        final DateTime ad = (a.createdAt as DateTime?) ?? DateTime(0);
        final DateTime bd = (b.createdAt as DateTime?) ?? DateTime(0);
        return bd.compareTo(ad);
      },
    );

    return ModalProgressHUD(
      inAsyncCall: isLoading,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, //backgroundColor,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (requestUser.isEmpty && userRideOrders.isEmpty && !isLoading)
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
                        'No Trip Found',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),
              // Display ride orders from Firebase
              ...userRideOrders.map((order) => Container(
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
              // Display request rides
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.only(top: 10, bottom: 10),
                  itemCount: requestUser.length,
                  itemBuilder: (BuildContext context, int index) {
                    final pool = requestUser[index];
                    final acceptedUser = userdata.firstWhereOrNull(
                      (user) => user.id == pool.requestedBy,
                    );

                    final locationfou = locationfoundValue.where((location) {
                      final checkRequestDate = location.dateTime;
                      final now = DateTime.now();
                      final truncatedNow = truncateToDate(now);
                      final truncatedRequestDate = truncateToDate(
                        checkRequestDate,
                      );
                      final double radiusKm = 3.0;
                      final isPickupNear = isLocationNear(
                        location.pickupLocation.latitude,
                        location.pickupLocation.longitude,
                        pool.pickupLocation.latitude,
                        pool.pickupLocation.longitude,
                        radiusKm,
                      );

                      return isPickupNear &&
                          (truncatedRequestDate.isAfter(truncatedNow) ||
                              truncatedRequestDate.isAtSameMomentAs(
                                truncatedNow,
                              )) &&
                          location.type == pool.type;
                    }).toList();

                    final userImage =
                        acceptedUser?.profilePicture ?? 'assets/replace.png';

                    final distance = LocationService.getDistanceFind(
                      pool,
                      location,
                    )!.toStringAsFixed(1);
                    final totalDistance = LocationService.calculateDistance(
                      pool.pickupLocation,
                      pool.dropoffLocation,
                    ).toStringAsFixed(1);
                    return GestureDetector(
                      onTap: () {
                        if (locationfou.isNotEmpty &&
                            pool.rider.isEmpty &&
                            !pool.cancelled) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FindingExistingTrip(
                                pickupLocation: pool.pickupLocation,
                                dropoffLocation: pool.dropoffLocation,
                                request: pool,
                              ),
                            ),
                          );
                        }

                        if (pool.rider.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RideInfo(
                                userImage,
                                user.phoneNumber,
                                true,
                                pool.id!,
                                pool,
                              ),
                            ),
                          );
                        }

                        if (pool.rider.isEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FindingPoolDetail(
                                userImage,
                                user.phoneNumber,
                                true,
                                pool.id!,
                                pool,
                              ),
                            ),
                          );
                        }
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        margin: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 15),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              formatTime(pool.requestedTime),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge!
                                                  .copyWith(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            SizedBox(height: 3),
                                          ],
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          child: Icon(
                                            Icons.circle,
                                            color: kMainColor,
                                            size: 14,
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            pool.pickupLocation.address,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge!
                                                .copyWith(fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 1,
                                      ),
                                      child: Icon(
                                        Icons.more_vert,
                                        color: kMainColor,
                                        size: 20,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.keyboard_arrow_down,
                                          color: kMainColor,
                                          size: 20,
                                        ),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            pool.dropoffLocation.address,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge!
                                                .copyWith(fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              color: Theme.of(context).dividerColor,
                              width: 1,
                              height: 130,
                            ),
                            Column(
                              children: [
                                if (pool.cancelled != true)
                                  SizedBox(
                                    width: 80,
                                    height: 80,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (pool.accepted == false)
                                          CircleAvatar(
                                            radius: 14,
                                            backgroundColor: Color(0xffd9e3ea),
                                            child: Icon(
                                              pool.type == 'passengers'
                                                  ? Icons.local_taxi
                                                  : Icons.local_shipping,
                                              color: Theme.of(
                                                context,
                                              ).scaffoldBackgroundColor,
                                              size: 20,
                                            ),
                                          )
                                        else
                                          Stack(
                                            alignment:
                                                AlignmentDirectional.topEnd,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.all(
                                                  2.0,
                                                ),
                                                child: ClipOval(
                                                  child: CachedNetworkImage(
                                                    height: 47,
                                                    width: 47,
                                                    imageUrl:
                                                        (acceptedUser
                                                                ?.profilePicture !=
                                                            null)
                                                        ? acceptedUser!
                                                              .profilePicture!
                                                        : 'assets/1.png',
                                                    fit: BoxFit.cover,
                                                    progressIndicatorBuilder:
                                                        (
                                                          context,
                                                          url,
                                                          progress,
                                                        ) => Center(
                                                          child: SizedBox(
                                                            height: 50,
                                                            width: 50,
                                                            child:
                                                                CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      2,
                                                                  value: progress
                                                                      .progress,
                                                                ),
                                                          ),
                                                        ),
                                                    errorWidget:
                                                        (context, url, error) =>
                                                            Image.asset(
                                                              'assets/1.png',
                                                            ),
                                                  ),
                                                ),
                                              ),
                                              Icon(
                                                Icons.check_circle,
                                                color: Theme.of(
                                                  context,
                                                ).primaryColor,
                                                size: 14,
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                SizedBox(height: 12),
                                if (pool.cancelled == true)
                                  Container(
                                    height: 30,
                                    width: 70,
                                    alignment: Alignment.center,
                                    child: FittedBox(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.cancel,
                                            color: Color(0xffdd142c),
                                            size: 18,
                                          ),
                                          SizedBox(height: 6),
                                          Text(
                                            'Cancelled',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: Color(0xffdd142c),
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                if (pool.cancelled != true)
                                  Container(
                                    height: 30,
                                    width: 80,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: pool.completed == true
                                          ? greenPrimary
                                          : pool.rejected == true
                                          ? Colors.red.withOpacity(0.05)
                                          : pool.accepted == false
                                          ? pool.rider.isEmpty
                                                ? Colors.grey.withOpacity(0.05)
                                                : greenPrimary.withOpacity(0.05)
                                          : greenPrimary,
                                      borderRadius:
                                          BorderRadiusDirectional.only(
                                            bottomEnd: Radius.circular(8),
                                          ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsetsDirectional.only(
                                        end: 6.0,
                                        top: 2.0,
                                        start: 4.0,
                                      ),
                                      child: Stack(
                                        alignment: AlignmentDirectional.topEnd,
                                        children: [
                                          Padding(
                                            padding:
                                                const EdgeInsetsDirectional.only(
                                                  end: 6.0,
                                                  top: 2.0,
                                                  start: 4.0,
                                                ),
                                            child: Text(
                                              '${pool.completed == true
                                                  ? 'Completed'
                                                  : pool.rejected == true
                                                  ? 'Rejected'
                                                  : pool.accepted == false
                                                  ? pool.rider.isNotEmpty
                                                        ? pool.requested
                                                              ? 'Offered'
                                                              : 'Waiting'
                                                        : 'Pending'
                                                  : 'Accepted'}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleSmall
                                                  ?.copyWith(
                                                    fontSize: 10,
                                                    color: pool.rejected == true
                                                        ? Colors.red
                                                        : pool.accepted == false
                                                        ? pool.rider.isEmpty
                                                              ? Colors.grey[400]
                                                              : greenPrimary
                                                                    .withOpacity(
                                                                      0.5,
                                                                    )
                                                        : kWhiteColor,
                                                  ),
                                            ),
                                          ),
                                          if (pool.accepted == false &&
                                              pool.rider.isNotEmpty &&
                                              pool.requested)
                                            CircleAvatar(
                                              backgroundColor: Colors.red,
                                              radius: 6,
                                              child: Text(
                                                '1',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(fontSize: 8),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
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
            ],
          ),
        ),
      
    );
  }
}

