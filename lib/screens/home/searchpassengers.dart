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
import 'package:ryde_rw/shared/locations_shared.dart';
import 'package:ryde_rw/shared/shared_states.dart';
import 'package:ryde_rw/theme/colors.dart';
import 'package:ryde_rw/utils/utils.dart';
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
    final offerPoolStream = ref.watch(
      OfferPoolService.matchingOfferPassengersProvider(
        LocationPairD(
          pickupLocation: driverStartLocation ?? myLocation,
          dropoffLocation: driverEndLocation ?? myLocation,
        ),
      ),
    );

    final isLoading = userStreams.isLoading || offerPoolStream.isLoading;
    if (isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final userdata = userStreams.value ?? [];
    final offerPools = offerPoolStream.value ?? [];
    // final region = ref.read(regionProvider);
    final limit = DateTime.now().subtract(Duration(hours: 5));

    final offerdatasfilter = offerPools.where((e) {
      return !e.accepted &&
          e.requestedBy != user.phoneNumber &&
          e.requestedTime.toDate().isAfter(limit);
    }).toList();
    offerdatasfilter.sort(
      (a, b) => b.requestedTime.toDate().compareTo(a.requestedTime.toDate()),
    );

    final waypoints = [
      ...offerdatasfilter.map((pool) => pool.pickupLocation),
      ...offerdatasfilter.map((pool) => pool.dropoffLocation),
    ];

    final location = ref.read(locationProvider);

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
          child:  offerdatasfilter.isNotEmpty
                ? ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    itemCount: offerdatasfilter.length,
                    itemBuilder: (context, index) {
                      final pool = offerdatasfilter[index];

                      final acceptedUser = userdata.firstWhereOrNull(
                        (user) => user.id == pool.requestedBy,
                      );

                      final userName =
                          acceptedUser?.fullName ??
                          acceptedUser?.phoneNumber ??
                          "Driver";
                      final userImage =
                          acceptedUser!.profilePicture ?? 'assets/replace.png';

                      final distance = LocationService.getDistanceFind(
                        pool,
                        location,
                      )!.toStringAsFixed(1);

                      return CustomListItem(
                        image: userImage,
                        type: type,
                        // ignore: unnecessary_null_comparison
                        distance: distance == null ? '- Km' : '$distance Km',
                        quantity: pool.measure == 'ton'
                            ? removeZeros(pool.quantity.toString())
                            : pool.quantity.toString(),
                        measure: pool.measure,
                        name: userName,
                        price: "",
                        fromLocation: pool.pickupLocation.address,
                        isBike: true,
                        index: index,
                        icons: [Icons.drive_eta, Icons.account_circle],
                        destination: pool.dropoffLocation.address,
                        time: pool.createdAt,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PassengerInfo(
                                userImage,
                                userName,
                                true,
                                pool.id!,
                                pool,
                                'Drivers',
                              ),
                            ),
                          );
                        },
                      );
                    },
                  )
                : Center(child: Text('No Passenger Found NearBy You!')),
          ),
        ),
      
      bottomNavigationBar: type != null
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: GestureDetector(
                  onTap: () {
                    try {
                      // if () {
                      _launchGoogleMaps(waypoints: waypoints);
                      // } else {
                      //   ScaffoldMessenger.of(context).showSnackBar(
                      //     SnackBar(content: Text('Could not fetch all locations')),
                      //   );
                      // }
                    } catch (error) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(error.toString())));
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: kMainColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(3.0),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                              ),
                              height: double.infinity,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Image.asset(
                                  'assets/maps.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          flex: 6,
                          child: Text(
                            'View on Google Maps',
                            style: GoogleFonts.mulish(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

