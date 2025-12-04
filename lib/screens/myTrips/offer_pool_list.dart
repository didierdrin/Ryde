import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import '../myTrips/pool_taker_request_screen.dart';
import 'package:ryde_rw/service/location_service.dart';
import 'package:ryde_rw/service/offer_pool_service.dart';
import 'package:ryde_rw/service/request_rider_service.dart';
import 'package:ryde_rw/service/user_service.dart';
import 'package:ryde_rw/shared/shared_states.dart';
import 'package:ryde_rw/theme/colors.dart';
import 'package:ryde_rw/utils/utils.dart';
import 'package:ryde_rw/provider/order_providers.dart';
import 'package:ryde_rw/service/order_service.dart';

class OfferingTab extends ConsumerWidget {
  const OfferingTab({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.read(userProvider);
    final location = ref.read(locationProvider);
    final offersStreams = ref.watch(OfferPoolService.offeringStreams);
    final requestonOfferPoolStreams = ref.watch(
      RequestRideService.allRequestRideStreamProvider,
    );
    final userStreams = ref.watch(UserService.usersStream);
    final rideOrdersStream = ref.watch(rideOrdersStreamProvider);
    final isLoading =
        offersStreams.isLoading ||
        requestonOfferPoolStreams.isLoading ||
        userStreams.isLoading ||
        rideOrdersStream.isLoading;
    final offerdatas = offersStreams.value ?? [];
    final requestonoffer = requestonOfferPoolStreams.value ?? [];
    final userdata = userStreams.value ?? [];
    final rideOrders = rideOrdersStream.value?.where((order) => order['userId'] == user?.id).toList() ?? [];
    final limit = DateTime.now().subtract(Duration(hours: 5));
    final offerdatasfilter = offerdatas.where((offer) {
      return offer.dateTime.toDate().isAfter(limit);
    }).toList();
    offerdatasfilter.sort(
      (a, b) => b.dateTime.toDate().compareTo(a.dateTime.toDate()),
    );

    return ModalProgressHUD(
      inAsyncCall: isLoading,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
            children: [
              if (offerdatasfilter.isEmpty && rideOrders.isEmpty && !isLoading)
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
                        'No Trip Yet',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),
              // Display ride orders
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
                            order['dateTime'] ?? 'No date',
                            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: order['status'] == 'confirmed' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  order['status'] ?? 'pending',
                                  style: TextStyle(
                                    color: order['status'] == 'confirmed' ? Colors.green : Colors.orange,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              if (order['status'] == 'confirmed' && order['driverId'] != null)
                                SizedBox(width: 8),
                              if (order['status'] == 'confirmed' && order['driverId'] != null)
                                ElevatedButton(
                                  onPressed: () async {
                                    await ref.read(orderServiceProvider).updateRideOrderStatus(
                                      order['id'],
                                      'passenger_confirmed',
                                    );
                                  },
                                  child: Text('Accept', style: TextStyle(fontSize: 10)),
                                ),
                            ],
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
                              order['from'] ?? 'Unknown',
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
                              order['to'] ?? 'Unknown',
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
                            'Vehicle: ${order['vehicleType'] ?? 'N/A'}',
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                          Text(
                            '${order['estimatedPrice'] ?? '0'} FRW',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )).toList(),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.only(top: 10, bottom: 10),
                  itemCount: offerdatasfilter.length,
                  itemBuilder: (BuildContext context, int index) {
                    final offerData = offerdatasfilter[index];
                    final reqd = requestonoffer.where(
                      (e) =>
                          e.offerpool == offerData.id &&
                          e.accepted == false &&
                          e.rejected == false &&
                          e.cancelled != true,
                    );

                    return GestureDetector(
                      onTap: () {
                        // if (!offerData.completed) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PoolTakerRequestScreen(offerPool: offerData),
                          ),
                        );
                      },
                      // },
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
                                              formatTime(offerData.dateTime),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge!
                                                  .copyWith(
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            SizedBox(height: 3),
                                          ],
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 15),
                                    Row(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          child: Icon(
                                            Icons.circle,
                                            color: kMainColor,
                                            size: 15,
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            offerData.pickupLocation.address,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge!
                                                .copyWith(fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 4),
                                      child: Icon(
                                        Icons.more_vert,
                                        color: kMainColor,
                                        size: 15,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        SizedBox(width: 2),
                                        Icon(
                                          Icons.keyboard_arrow_down,
                                          color: kMainColor,
                                          size: 20,
                                        ),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            offerData.dropoffLocation.address,
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
                                SizedBox(height: 8),
                                if (offerData.type == 'passengers')
                                  SizedBox(
                                    width: 80,
                                    height: 80,
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: GridView.builder(
                                        shrinkWrap: true,
                                        itemCount: offerData.selectedSeat,
                                        physics:
                                            AlwaysScrollableScrollPhysics(),
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 2,
                                              mainAxisSpacing: 2,
                                              crossAxisSpacing: 9,
                                            ),
                                        itemBuilder: (context, gridIndex) {
                                          final isOccupied =
                                              gridIndex <
                                              offerData.availableSeat.length;
                                          final occupantImage = isOccupied
                                              ? 'assets/profiles/img${gridIndex + 1}.png'
                                              : null;
                                          final acceptedUser = userdata
                                              .firstWhereOrNull(
                                                (user) => offerData
                                                    .availableSeat
                                                    .contains(user.id),
                                              );

                                          return Stack(
                                            alignment:
                                                AlignmentDirectional.topEnd,
                                            children: [
                                              Container(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  color: Color(0xffd9e3ea),
                                                ),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                    2.0,
                                                  ),
                                                  child: occupantImage != null
                                                      ? ClipOval(
                                                          child: CachedNetworkImage(
                                                            height: 24,
                                                            width: 24,
                                                            imageUrl:
                                                                (acceptedUser !=
                                                                        null &&
                                                                    acceptedUser
                                                                            .profilePicture !=
                                                                        null)
                                                                ? acceptedUser
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
                                                                    height: 24,
                                                                    width: 24,
                                                                    child: CircularProgressIndicator(
                                                                      strokeWidth:
                                                                          2,
                                                                      value: progress
                                                                          .progress,
                                                                    ),
                                                                  ),
                                                                ),
                                                            errorWidget:
                                                                (
                                                                  context,
                                                                  url,
                                                                  error,
                                                                ) => Image.asset(
                                                                  'assets/1.png',
                                                                ),
                                                          ),
                                                        )
                                                      : Icon(
                                                          Icons.person,
                                                          color:
                                                              Colors.grey[100],
                                                          size: 24,
                                                        ),
                                                ),
                                              ),
                                              if (isOccupied)
                                                Icon(
                                                  Icons.check_circle,
                                                  color: Theme.of(
                                                    context,
                                                  ).primaryColor,
                                                  size: 14,
                                                ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                if (offerData.type == 'goods') ...[
                                  SizedBox(height: 30),
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Color(0xffd9e3ea),
                                    child: Icon(
                                      offerData.type == 'passengers'
                                          ? Icons.local_taxi
                                          : Icons.local_shipping,
                                      color: Theme.of(
                                        context,
                                      ).scaffoldBackgroundColor,
                                      size: 20,
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                ],
                                Container(
                                  height: 40,
                                  width: 80,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).primaryColor.withOpacity(0.05),
                                    borderRadius: BorderRadiusDirectional.only(
                                      bottomEnd: Radius.circular(8),
                                    ),
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
                                          offerData.completed == true
                                              ? 'Completed'
                                              : reqd.isNotEmpty
                                              ? "Requests"
                                              : capitalizeFirstLetter(
                                                  offerData.type,
                                                ),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                fontSize: 10,
                                                color: Theme.of(
                                                  context,
                                                ).primaryColor,
                                              ),
                                        ),
                                      ),
                                    ],
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

