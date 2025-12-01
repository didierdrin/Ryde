import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ryde_rw/components/widgets/pooler_widget.dart';
import 'package:ryde_rw/models/request_model.dart';
import '../home/searchpooler.dart';
import '../myTrips/request_existing_location.dart';
import 'package:ryde_rw/service/location_service.dart';
import 'package:ryde_rw/service/offer_pool_service.dart';
import 'package:ryde_rw/service/user_service.dart';
import 'package:ryde_rw/shared/locations_shared.dart';
import 'package:ryde_rw/shared/shared_states.dart';
import 'package:ryde_rw/theme/colors.dart';
import 'package:url_launcher/url_launcher.dart';

class FindingExistingTrip extends ConsumerWidget {
  final Location pickupLocation;
  final Location dropoffLocation;
  final RequestRide request;
  // final String type;

  const FindingExistingTrip({
    super.key,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.request,
    // required this.type,
  });

  void _launchGoogleMaps({
    required double userLat,
    required double userLng,
    required List<Location> waypoints,
  }) async {
    final waypointsQuery = waypoints
        .map((loc) => '${loc.latitude},${loc.longitude}')
        .join('|');
    final coordinate =
        '${dropoffLocation.latitude},${dropoffLocation.longitude}';
    final dir = '$coordinate/$waypointsQuery';

    final googleMapsUrl =
        "https://www.google.com/maps/dir/$dir?origin=&travelmode=driving&dir_action=navigate";

    final url = Uri.parse(googleMapsUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userStreams = ref.watch(UserService.usersStream);
    final offerPoolStream = ref.watch(
      OfferPoolService.matchingOfferPoolsProvider(
        LocationPairD(
          pickupLocation: pickupLocation,
          dropoffLocation: dropoffLocation,
        ),
      ),
    );

    final requesterLocationStream = ref.watch(
      userLocationTrackerStream(request.requestedBy),
    );

    final isLoading = userStreams.isLoading || offerPoolStream.isLoading;

    print(isLoading);
    if (isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final userdata = userStreams.value ?? [];
    final offerPools = offerPoolStream.value ?? [];
    // final region = ref.read(regionProvider);

    final offerdatasfilter = offerPools.where((e) {
      final checkNow = e.dateTime.toDate();
      final truncatedCheckNow = DateTime(
        checkNow.year,
        checkNow.month,
        checkNow.day,
      );
      final truncatedNow = DateTime.now();
      final truncatedCurrentDate = DateTime(
        truncatedNow.year,
        truncatedNow.month,
        truncatedNow.day,
      );
      return !e.completed &&
          !e.isSeatFull &&
          (truncatedCheckNow.isAfter(truncatedCurrentDate) ||
              truncatedCheckNow.isAtSameMomentAs(truncatedCurrentDate)) &&
          e.type == request.type;
    }).toList();

    final tripCreatorLocationStreams = offerdatasfilter.map((trip) {
      return ref.watch(userLocationTrackerStream(trip.user));
    }).toList();

    final requesterLocation = requesterLocationStream.value?.currentLocation;
    final tripCreatorLocations = tripCreatorLocationStreams
        .where((stream) => stream.value != null)
        .map((stream) => stream.value!.currentLocation)
        .toList();

    final waypoints = [
      if (requesterLocation != null) requesterLocation,
      ...tripCreatorLocations,
      ...offerdatasfilter.map((pool) => pool.pickupLocation),
      ...offerdatasfilter.map((pool) => pool.dropoffLocation),
    ];

    final location = ref.read(locationProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Trips scheduled',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: ListView.builder(
          padding: EdgeInsets.symmetric(vertical: 10),
          itemCount: offerdatasfilter.length,
          itemBuilder: (context, index) {
            final pool = offerdatasfilter[index];
            final acceptedUser = userdata.firstWhereOrNull(
              (user) => user.id == pool.user,
            );
            final userName = acceptedUser?.fullName ?? "Driver";
            final userImage = acceptedUser?.profilePicture ?? "assets/1.png";
            final distance = LocationService.getDistanceOffer(
              pool,
              location,
            )!.toStringAsFixed(1);

            return CustomListItem(
              image: userImage,
              distance: distance,
              name: userName.isEmpty ? 'Driver' : userName,
              price: "${"RWF"} ${pool.pricePerSeat}",
              fromLocation: pool.pickupLocation.address,
              isBike: true,
              index: index,
              icons: [Icons.drive_eta, Icons.account_circle],
              destination: pool.dropoffLocation.address,
              time: pool.dateTime,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RequestExistingLocation(
                      userImage,
                      userName,
                      true,
                      pool.id!,
                      request,
                      pool,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: GestureDetector(
            onTap: () {
              try {
                if (requesterLocation != null) {
                  _launchGoogleMaps(
                    userLat: requesterLocation.latitude,
                    userLng: requesterLocation.longitude,
                    waypoints: waypoints,
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not fetch all locations')),
                  );
                }
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
      ),
    );
  }
}

extension ListExtensions<T> on List<T> {
  void addIfNotNull(T? value) {
    if (value != null) {
      add(value);
    }
  }
}
