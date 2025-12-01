import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart'
    as polyline;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:ryde_rw/components/widgets/color_button.dart';

import 'package:ryde_rw/models/offer_pool_model.dart';
import 'package:ryde_rw/models/request_model.dart';
import 'package:ryde_rw/models/user.dart';
import 'package:ryde_rw/screens/home/home.dart';
//import 'package:ryde_rw/screens/app_screen.dart';
import 'package:ryde_rw/service/offer_pool_service.dart';
import 'package:ryde_rw/service/request_rider_service.dart';
import 'package:ryde_rw/service/user_location_service.dart';
import 'package:ryde_rw/service/user_service.dart';
import 'package:ryde_rw/shared/shared_states.dart';
import 'package:ryde_rw/theme/colors.dart';
import 'package:ryde_rw/utils/contants.dart';
import 'package:ryde_rw/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class PoolTakerAcceptedOffer extends ConsumerStatefulWidget {
  final PassengerOfferPool offerpool;
  const PoolTakerAcceptedOffer({super.key, required this.offerpool});

  @override
  ConsumerState<PoolTakerAcceptedOffer> createState() =>
      _PoolTakerAcceptedOfferState();
}

class _PoolTakerAcceptedOfferState
    extends ConsumerState<PoolTakerAcceptedOffer> {
  final Set<Marker> _markers = {};
  final Completer<GoogleMapController> _mapController = Completer();
  GoogleMapController? mapStyleController;
  bool isLoading = false;

  final Set<Polyline> _polylines = {};
  polyline.PolylinePoints polylinePoints = polyline.PolylinePoints(
    apiKey: "",
  ); // Provide google api key

  @override
  void initState() {
    super.initState();
    fetchRouteAndMarkers();
  }

  Future<void> fetchRouteAndMarkers() async {
    final usersLocationStream = ref.read(
      LocationTrackingService.usersLocationsStream,
    );
    final usersLocations = usersLocationStream.value ?? [];

    final driverLocation = ref.read(
      LocationTrackingService.userLocationStream(widget.offerpool.user),
    );

    if (driverLocation.value == null) return;

    final driverLatLng = LatLng(
      driverLocation.value!.currentLocation.latitude,
      driverLocation.value!.currentLocation.longitude,
    );

    final wayPoints = widget.offerpool.availableSeat.map((userId) {
      final userLocation = usersLocations.firstWhere(
        (element) => element.userId == userId,
      );
      return LatLng(
        userLocation.currentLocation.latitude,
        userLocation.currentLocation.longitude,
      );
    }).toList();

    final pickupLatLng = LatLng(
      widget.offerpool.pickupLocation.latitude,
      widget.offerpool.pickupLocation.longitude,
    );
    final dropoffLatLng = LatLng(
      widget.offerpool.dropoffLocation.latitude,
      widget.offerpool.dropoffLocation.longitude,
    );

    await _drawPolyline(
      driverLatLng,
      pickupLatLng,
      "driver_to_pickup",
      Colors.green,
    );
    await _drawPolylineWithWaypoints(
      pickupLatLng,
      dropoffLatLng,
      wayPoints,
      "pickup_to_dropoff",
      Colors.blue,
    );
    _updateMarkers(driverLatLng, pickupLatLng, dropoffLatLng, wayPoints);
  }

  Future<void> _drawPolyline(
    LatLng start,
    LatLng end,
    String id,
    Color color,
  ) async {
    polyline.PolylineRequest request = polyline.PolylineRequest(
      origin: polyline.PointLatLng(start.latitude, start.longitude),
      destination: polyline.PointLatLng(end.latitude, end.longitude),
      mode: polyline.TravelMode.driving,
    );

    polyline.PolylineResult result = await polylinePoints
        .getRouteBetweenCoordinates(
          request: request,
          // googleApiKey: apiKey,
        );

    if (result.points.isNotEmpty) {
      setState(() {
        _polylines.add(
          Polyline(
            polylineId: PolylineId(id),
            color: color,
            width: 5,
            points: result.points
                .map((p) => LatLng(p.latitude, p.longitude))
                .toList(),
          ),
        );
      });
    }
  }

  Future<void> _drawPolylineWithWaypoints(
    LatLng start,
    LatLng end,
    List<LatLng> waypoints,
    String id,
    Color color,
  ) async {
    polyline.PolylineRequest request = polyline.PolylineRequest(
      origin: polyline.PointLatLng(start.latitude, start.longitude),
      destination: polyline.PointLatLng(end.latitude, end.longitude),
      wayPoints: waypoints
          .map(
            (wp) => polyline.PolylineWayPoint(
              location: "${wp.latitude},${wp.longitude}",
            ),
          )
          .toList(),
      mode: polyline.TravelMode.driving,
    );

    polyline.PolylineResult result = await polylinePoints
        .getRouteBetweenCoordinates(
          request: request,
          // googleApiKey: apiKey,
        );

    if (result.points.isNotEmpty) {
      setState(() {
        _polylines.add(
          Polyline(
            polylineId: PolylineId(id),
            color: color,
            width: 6,
            points: result.points
                .map((p) => LatLng(p.latitude, p.longitude))
                .toList(),
          ),
        );
      });
    }
  }

  void _updateMarkers(
    LatLng driver,
    LatLng pickup,
    LatLng dropoff,
    List<LatLng> waypoints,
  ) {
    Set<Marker> updatedMarkers = {
      Marker(
        markerId: MarkerId("driver"),
        position: driver,
        infoWindow: InfoWindow(title: "Driver"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
      Marker(
        markerId: MarkerId("pickup"),
        position: pickup,
        infoWindow: InfoWindow(title: "Pickup Location"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      Marker(
        markerId: MarkerId("dropoff"),
        position: dropoff,
        infoWindow: InfoWindow(title: "Dropoff Location"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };

    for (var i = 0; i < waypoints.length; i++) {
      updatedMarkers.add(
        Marker(
          markerId: MarkerId("waypoint_$i"),
          position: waypoints[i],
          infoWindow: InfoWindow(title: "Passenger Stop"),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
        ),
      );
    }

    setState(() {
      _markers.clear();
      _markers.addAll(updatedMarkers);
    });
  }

  Future<void> completed() async {
    setState(() {
      isLoading = true;
    });

    await OfferPoolService.updateofferpool(widget.offerpool.id!, {
      'completed': true,
    });
    // await RequestRideService.updateRequestRide(widget.off)
    setState(() {
      isLoading = false;
    });
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => Home()), //AppScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final offerpool = ref.watch(
      OfferPoolService.poolRealTimeStreamProvider(widget.offerpool.id!),
    );
    final userStreams = ref.watch(UserService.usersStream);
    final usersLocationStream = ref.watch(
      LocationTrackingService.usersLocationsStream,
    );
    final requestonOfferPoolStreams = ref.watch(
      RequestRideService.offerpoolsForRiderProvider(widget.offerpool.id!),
    );
    final isLoadingstr =
        offerpool.isLoading ||
        userStreams.isLoading ||
        usersLocationStream.isLoading ||
        requestonOfferPoolStreams.isLoading;
    final dataofferpool = offerpool.value ?? [] as PassengerOfferPool;
    final users = userStreams.value ?? [];
    final usersLocations = usersLocationStream.value ?? [];
    final requestonOfferPool = (requestonOfferPoolStreams.value ?? [])
        .where((e) => e.accepted == true && e.rejected != true)
        .toList();
    final user = ref.watch(userProvider);
    final userLocationAsync = ref.watch(
      LocationTrackingService.userLocationStream(user!.id),
    );

    return Scaffold(
      body: ModalProgressHUD(
        inAsyncCall: isLoading || isLoadingstr,
        child: Stack(
          children: [
            userLocationAsync.when(
              data: (position) {
                return GoogleMap(
                  mapType: MapType.normal,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      position!.currentLocation.latitude,
                      position.currentLocation.longitude,
                    ),
                    zoom: 15.0,
                  ),
                  onMapCreated: (GoogleMapController controller) {
                    _mapController.complete(controller);
                  },
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: true,
                  compassEnabled: true,
                  zoomGesturesEnabled: true,
                  scrollGesturesEnabled: true,
                  rotateGesturesEnabled: true,
                  tiltGesturesEnabled: true,
                  gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                    Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
                    Factory<ScaleGestureRecognizer>(
                      () => ScaleGestureRecognizer(),
                    ),
                    Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
                    Factory<VerticalDragGestureRecognizer>(
                      () => VerticalDragGestureRecognizer(),
                    ),
                  },
                );
              },
              loading: () => Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) =>
                  Center(child: Text('Failed to load map')),
            ),
            Positioned(
              top: 50,
              left: 16,
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 5),
                    ],
                  ),
                  child: Icon(Icons.arrow_back, color: Colors.black, size: 24),
                ),
              ),
            ),
            Positioned(
              top: 50,
              right: 16,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 4.0,
                ),
                child: FloatingActionButton(
                  onPressed: () async {
                    final userLat = widget.offerpool.pickupLocation.latitude;
                    final userLng = widget.offerpool.pickupLocation.longitude;
                    final driverEndLocation = widget.offerpool.dropoffLocation;
                    final poolUsers = widget.offerpool.availableSeat;

                    final wayPoints = poolUsers.map((userId) {
                      final userLocation = usersLocations.firstWhere(
                        (element) => element.userId == userId,
                      );
                      return LatLng(
                        userLocation.currentLocation.latitude,
                        userLocation.currentLocation.longitude,
                      );
                    }).toList();

                    final waypointsQuery = wayPoints
                        .map((loc) => '${loc.latitude},${loc.longitude}')
                        .join('|');
                    final coordinate =
                        '${driverEndLocation.latitude},${driverEndLocation.longitude}';

                    final dir = '$coordinate/$waypointsQuery';
                    final String googleMapsUrl =
                        "https://www.google.com/maps/dir/$dir?origin=&travelmode=driving&dir_action=navigate";

                    final url = Uri.parse(googleMapsUrl);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  backgroundColor: Color(0xffe32727),
                  child: Icon(Icons.navigation),
                ),
              ),
            ),
            Positioned.fill(
              child: dataofferpool.isRideStarted
                  ? buildRoadmapSheet(dataofferpool, requestonOfferPool, users)
                  : startRideSheet(dataofferpool, users),
            ),
          ],
        ),
      ),
    );
  }

  DraggableScrollableSheet buildRoadmapSheet(
    PassengerOfferPool offer,
    List<RequestRide> request,
    List<User> user,
  ) {
    final bool drop = request.every((e) => e.dropoff == true);
    return DraggableScrollableSheet(
      maxChildSize: 0.7,
      builder: (context, controller) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          controller: controller,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Color(0xfffcfdfd),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      height: 4,
                      width: 66,
                      margin: EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                  ),
                  ListView.separated(
                    physics: NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    separatorBuilder: (context, index) {
                      return Divider(thickness: 4, height: 4);
                    },
                    itemCount: request.length,
                    itemBuilder: (context, index) {
                      final req = request[index];
                      final users = user.firstWhere(
                        (element) => element.id == req.requestedBy,
                      );
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14.0),
                        child: Column(
                          children: [
                            SizedBox(height: 18),
                            Row(
                              children: [
                                Image.network(
                                  users.profilePicture ?? '',
                                  height: 40,
                                  width: 40,
                                  errorBuilder: (d, e, r) {
                                    return Image.asset(
                                      'assets/1.png',
                                      height: 60,
                                      width: 60,
                                    );
                                  },
                                ),
                                SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    users.fullName ?? users.phoneNumber,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontSize: 15),
                                  ),
                                ),
                                if (!req.pickup)
                                  InkWell(
                                    onTap: () async {
                                      await RequestRideService.updateRequestRide(
                                        req.id!,
                                        {'pickup': true},
                                      );
                                    },
                                    child: Container(
                                      width: 100,
                                      padding: EdgeInsets.only(
                                        top: 8,
                                        bottom: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(28),
                                        color: Theme.of(context).primaryColor,
                                      ),
                                      child: Row(
                                        children: [
                                          SizedBox(width: 14),
                                          Icon(
                                            Icons.arrow_upward,
                                            size: 16,
                                            color: Theme.of(
                                              context,
                                            ).scaffoldBackgroundColor,
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            "Pick", 
                                            // AppLocalizations.of(
                                            //       context,
                                            //     )?.pick.toUpperCase() ??
                                            //     '',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          SizedBox(width: 20),
                                        ],
                                      ),
                                    ),
                                  ),
                                if (!req.dropoff && req.pickup)
                                  InkWell(
                                    onTap: () async {
                                      await RequestRideService.updateRequestRide(
                                        req.id!,
                                        {'dropoff': true, 'completed': true},
                                      );
                                    },
                                    child: Container(
                                      width: 100,
                                      padding: EdgeInsets.only(
                                        top: 8,
                                        bottom: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(28),
                                        color: Color(0xffe3ac17),
                                      ),
                                      child: Row(
                                        children: [
                                          SizedBox(width: 14),
                                          Icon(
                                            Icons.arrow_downward,
                                            size: 16,
                                            color: Theme.of(
                                              context,
                                            ).scaffoldBackgroundColor,
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            "Drop", 
                                            // AppLocalizations.of(
                                            //   context,
                                            // )!.drop.toUpperCase(),
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          SizedBox(width: 20),
                                        ],
                                      ),
                                    ),
                                  ),
                                if (req.dropoff)
                                  Icon(
                                    Icons.check_circle,
                                    color: primaryColor,
                                    size: 18,
                                  ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Column(
                                  children: [
                                    Icon(
                                      Icons.circle,
                                      size: 14,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    SizedBox(height: 4),
                                    Icon(
                                      Icons.circle,
                                      size: 3,
                                      color: Theme.of(context).hintColor,
                                    ),
                                    SizedBox(height: 4),
                                    Icon(
                                      Icons.circle,
                                      size: 3,
                                      color: Theme.of(context).hintColor,
                                    ),
                                    SizedBox(height: 4),
                                    Icon(
                                      Icons.circle,
                                      size: 3,
                                      color: Theme.of(context).hintColor,
                                    ),
                                    SizedBox(height: 4),
                                    Icon(
                                      Icons.location_on,
                                      color: Color(0xffdd142c),
                                    ),
                                  ],
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        req.pickupLocation.address,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge!
                                            .copyWith(fontSize: 13.5),
                                      ),
                                      SizedBox(height: 14),
                                      Text(
                                        req.dropoffLocation.address,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge!
                                            .copyWith(fontSize: 13.5),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                          ],
                        ),
                      );
                    },
                  ),
                  Divider(thickness: 4, height: 4),
                  SizedBox(height: 14),
                  if (drop)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            await completed();
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              color: Color(0xffe32727),
                            ),
                            child: Center(
                              child: Text(
                                "End ride", 
                                // AppLocalizations.of(
                                //       context,
                                //     )?.endRide.toUpperCase() ??
                                //     '',
                                style: Theme.of(context).textTheme.bodyLarge!
                                    .copyWith(
                                      fontSize: 15,
                                      letterSpacing: 3,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  SizedBox(height: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  DraggableScrollableSheet startRideSheet(
    PassengerOfferPool offer,
    List<User> user,
  ) {
    return DraggableScrollableSheet(
      maxChildSize: 0.7,
      builder: (context, controller) => Container(
        decoration: BoxDecoration(
          color: Color(0xfffcfdfd),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          controller: controller,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 20),
                  Text(
                    "Ride starts soon", 
                    // '${AppLocalizations.of(context)?.rideStartson} ${formatDate(offer.dateTime)} ${formatTime(offer.dateTime)} ',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 30),
                  buildPickupDropLocn(context, offer),
                ],
              ),
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Passengers", 
                    // AppLocalizations.of(context)?.passengers ?? '',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(fontSize: 14),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: offer.availableSeat.map((seatId) {
                      final passenger = user.firstWhere(
                        (element) => element.id == seatId,
                      );

                      if (passenger != null) {
                        return buildPassenger(
                          context,
                          passenger.profilePicture ??
                              'assets/profiles/default.png',
                          passenger.fullName ?? passenger.phoneNumber,
                        );
                      }

                      return SizedBox.shrink();
                    }).toList(),
                  ),
                  SizedBox(height: 50),
                  GestureDetector(
                    onTap: () async {
                      setState(() {
                        isLoading = true;
                      });

                      await OfferPoolService.updateofferpool(offer.id!, {
                        'isRideStarted': true,
                      });
                      try {
                        final usersLocationStream = ref.watch(
                          LocationTrackingService.usersLocationsStream,
                        );
                        final usersLocations = usersLocationStream.value ?? [];

                        final userLat =
                            widget.offerpool.pickupLocation.latitude;
                        final userLng =
                            widget.offerpool.pickupLocation.longitude;
                        final driverEndLocation =
                            widget.offerpool.dropoffLocation;
                        final poolUsers = widget.offerpool.availableSeat;
                        final wayPoints = poolUsers.map((userId) {
                          final userLocation = usersLocations.firstWhere(
                            (element) => element.userId == userId,
                          );
                          return LatLng(
                            userLocation.currentLocation.latitude,
                            userLocation.currentLocation.longitude,
                          );
                        }).toList();

                        final waypointsQuery = wayPoints
                            .map((loc) => '${loc.latitude},${loc.longitude}')
                            .join('|');
                        final coordinate = '$userLat,$userLng';
                        final dir =
                            '$coordinate/$waypointsQuery/${driverEndLocation.latitude},${driverEndLocation.longitude}';
                        final String googleMapsUrl =
                            "https://www.google.com/maps/dir/$dir?origin=&travelmode=driving&dir_action=navigate";
                        final url = Uri.parse(googleMapsUrl);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(
                            url,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      } catch (e) {
                        setState(() {
                          isLoading = false;
                        });
                      }

                      setState(() {
                        isLoading = false;
                      });
                    },
                    child: ColorButton("Start ride"), // AppLocalizations.of(context)?.startRide
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Row buildPickupDropLocn(BuildContext context, PassengerOfferPool location) {
    return Row(
      children: [
        Column(
          children: [
            Icon(Icons.circle, size: 14, color: Theme.of(context).primaryColor),
            SizedBox(height: 4),
            Icon(Icons.circle, size: 3, color: Theme.of(context).hintColor),
            SizedBox(height: 4),
            Icon(Icons.circle, size: 3, color: Theme.of(context).hintColor),
            SizedBox(height: 4),
            Icon(Icons.circle, size: 3, color: Theme.of(context).hintColor),
            SizedBox(height: 4),
            Icon(Icons.location_on, color: Color(0xffdd142c)),
          ],
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                location.pickupLocation.address,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              SizedBox(height: 18),
              Text(
                location.dropoffLocation.address,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Column buildPassenger(BuildContext context, String imageUrl, String name) {
    return Column(
      children: [
        SizedBox(width: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            imageBuilder: (context, imageProvider) =>
                CircleAvatar(backgroundImage: imageProvider),
            placeholder: (context, url) => SizedBox(
              height: 40,
              width: 40,
              child: CircularProgressIndicator(),
            ),
            errorWidget: (context, url, error) => CircleAvatar(
              backgroundImage: AssetImage('assets/1.png'),
              radius: 20,
            ),
          ),
        ),
        SizedBox(height: 10),
        Text(
          name,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(fontSize: 10),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
