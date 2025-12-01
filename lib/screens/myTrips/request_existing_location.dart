import 'dart:async';

import 'package:animation_wrappers/animations/faded_scale_animation.dart';
import 'package:animation_wrappers/animations/faded_slide_animation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:modern_dialog/dialogs/vertical.dart';
import 'package:modern_dialog/modern_dialog.dart';
import 'package:ryde_rw/components/widgets/available_seat.dart';
import 'package:ryde_rw/components/widgets/color_button.dart';
import 'package:ryde_rw/components/widgets/user_vehicle.dart';

import 'package:ryde_rw/models/offer_pool_model.dart';
import 'package:ryde_rw/models/request_model.dart';
//import 'package:ryde_rw/screens/app_screen.dart';
import 'package:ryde_rw/service/location_service.dart';
import 'package:ryde_rw/service/offer_pool_service.dart';
import 'package:ryde_rw/service/request_rider_service.dart';
import 'package:ryde_rw/shared/shared_states.dart';
import 'package:ryde_rw/theme/colors.dart';
import 'package:ryde_rw/utils/contants.dart';
import 'package:ryde_rw/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class RequestExistingLocation extends ConsumerStatefulWidget {
  final String img;
  final String name;
  final bool isFindPool;
  final String id;
  final PassengerOfferPool offer;
  final RequestRide requestUser;

  const RequestExistingLocation(
    this.img,
    this.name,
    this.isFindPool,
    this.id,
    this.requestUser,
    this.offer, {
    super.key,
  });

  @override
  RequestExistingLocationConsumerState createState() =>
      RequestExistingLocationConsumerState();
}

class RequestExistingLocationConsumerState
    extends ConsumerState<RequestExistingLocation> {
  bool poolerDetails = false;
  bool isLoading = false;
  double iconSize = 10;
  bool isRideRequested = false;
  int selectedSeat = 1;

  Set<Polyline> polylines = {};
  Set<Marker> _markers = {};
  PolylinePoints polylinePoints = PolylinePoints(
    apiKey: "",
  ); // provide google api key
  GoogleMapController? mapController;
  GoogleMapController? mapStyleController;

  BitmapDescriptor? pickupIcon;
  BitmapDescriptor? dropoffIcon;
  BitmapDescriptor? driverIcon;

  @override
  void initState() {
    super.initState();
    _initializeMap();
    _updateMarkers();
  }

  Future<void> _initializeMap() async {
    await _drawRoutes();
  }

  Future<void> _drawRoutes() async {
    final location = ref.read(locationProvider);
    PolylineRequest driverToPickupRequest = PolylineRequest(
      origin: PointLatLng(location['lat'], location['long']),
      destination: PointLatLng(
        widget.offer.pickupLocation.latitude,
        widget.offer.pickupLocation.longitude,
      ),
      mode: TravelMode.driving,
    );

    PolylineResult driverToPickupResult = await polylinePoints
        .getRouteBetweenCoordinates(
          request: driverToPickupRequest,
          // googleApiKey: apiKey,
        );

    if (driverToPickupResult.points.isNotEmpty) {
      setState(() {
        polylines.add(
          Polyline(
            polylineId: PolylineId("driver_to_pickup"),
            color: const Color.fromARGB(255, 9, 165, 212),
            width: 5,
            patterns: [PatternItem.dot, PatternItem.gap(10)],
            points: driverToPickupResult.points
                .map((point) => LatLng(point.latitude, point.longitude))
                .toList(),
          ),
        );
      });
    }

    PolylineRequest pickupToDropoffRequest = PolylineRequest(
      origin: PointLatLng(
        widget.offer.pickupLocation.latitude,
        widget.offer.pickupLocation.longitude,
      ),
      destination: PointLatLng(
        widget.offer.dropoffLocation.latitude,
        widget.offer.dropoffLocation.longitude,
      ),
      mode: TravelMode.driving,
    );

    PolylineResult pickupToDropoffResult = await polylinePoints
        .getRouteBetweenCoordinates(
          request: pickupToDropoffRequest,
          // googleApiKey: apiKey,
        );

    if (pickupToDropoffResult.points.isNotEmpty) {
      setState(() {
        polylines.add(
          Polyline(
            polylineId: PolylineId("pickup_to_dropoff"),
            color: const Color.fromARGB(255, 21, 27, 198),
            width: 6,
            jointType: JointType.round,
            endCap: Cap.roundCap,
            points: pickupToDropoffResult.points
                .map((point) => LatLng(point.latitude, point.longitude))
                .toList(),
          ),
        );
      });

      _fitRouteInMap(
        driverToPickupResult.points + pickupToDropoffResult.points,
      );
    }
  }

  void _fitRouteInMap(List<PointLatLng> routePoints) {
    if (routePoints.isEmpty || mapController == null) return;

    List<LatLng> latLngPoints = routePoints
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList();

    LatLngBounds bounds = _getBounds(latLngPoints);

    mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  LatLngBounds _getBounds(List<LatLng> points) {
    double southWestLat = points.first.latitude;
    double southWestLng = points.first.longitude;
    double northEastLat = points.first.latitude;
    double northEastLng = points.first.longitude;

    for (LatLng point in points) {
      if (point.latitude < southWestLat) southWestLat = point.latitude;
      if (point.longitude < southWestLng) southWestLng = point.longitude;
      if (point.latitude > northEastLat) northEastLat = point.latitude;
      if (point.longitude > northEastLng) northEastLng = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(southWestLat, southWestLng),
      northeast: LatLng(northEastLat, northEastLng),
    );
  }

  void _updateMarkers() {
    final location = ref.read(locationProvider);

    Set<Marker> markers = {
      Marker(
        markerId: MarkerId("pickup"),
        position: LatLng(
          widget.offer.pickupLocation.latitude,
          widget.offer.pickupLocation.longitude,
        ),
        infoWindow: InfoWindow(title: "Pickup Location"),
        icon:
            pickupIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      Marker(
        markerId: MarkerId("dropoff"),
        position: LatLng(
          widget.offer.dropoffLocation.latitude,
          widget.offer.dropoffLocation.longitude,
        ),
        infoWindow: InfoWindow(title: "Dropoff Location"),
        icon:
            dropoffIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };

    markers.add(
      Marker(
        markerId: MarkerId("Current"),
        position: LatLng(location['lat'], location['long']),
        infoWindow: InfoWindow(title: "Your Location"),
        icon:
            driverIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );

    setState(() {
      _markers = markers;
    });
  }

  Future<void> _requestRider() async {
    final user = ref.read(userProvider);
    if (user == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      await RequestRideService.updateRequestRide(widget.requestUser.id!, {
        'rider': widget.offer.user,
        'offerpool': widget.offer.id,
        'price': widget.offer.pricePerSeat,
      });

      ModernDialog.showVerticalDialog(
        context,
        title: "REQUEST RIDE",
        content: const Text(
          "Your pool request has requested successfully located.",
          style: TextStyle(fontSize: 16),
        ),
        buttons: [
          DialogButton(
            title: "Proceed",
            onPressed: () {
              Navigator.pop(context);
              // Navigator.pushReplacement(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) => AppScreen(currentIndex: 2),
              //   ),
              // );
            },
            color: Colors.green,
          ),
        ],
      );
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text(
              'Failed to send ride request. Please try again later.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Close'),
              ),
            ],
          );
        },
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('object');

    // final region = ref.watch(regionProvider);
    final poolStream = ref.watch(
      OfferPoolService.poolRealTimeStreamsProvider(widget.offer.id!),
    );
    final isLoadingStream = poolStream.isLoading;
    final location = ref.read(locationProvider);

    final PassengerOfferPool? poolSeatValue = poolStream.value;
    final distance = LocationService.getDistanceOffer(
      widget.offer,
      location,
    )!.toStringAsFixed(1);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: ModalProgressHUD(
        inAsyncCall: isLoading || isLoadingStream,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width,
              child: _buildGoogleMap(ref, widget.offer),
            ),
            FadedSlideAnimation(
              beginOffset: Offset(0, 0.4),
              endOffset: Offset(0, 0),
              slideCurve: Curves.linearToEaseOut,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width,
                    height: 350,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                "${"Ride starts on"} ${formatDate(widget.offer.dateTime)} ",
                                style: Theme.of(context).textTheme.bodyLarge!
                                    .copyWith(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              Spacer(),
                              Icon(
                                Icons.more_vert,
                                color: Colors.grey[300],
                                size: 17,
                              ),
                            ],
                          ),
                          SizedBox(height: 15),
                          SizedBox(height: 15),
                          Text(
                            "Distance: $distance Km",
                            style: Theme.of(context).textTheme.bodySmall!
                                .copyWith(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.directions_walk,
                                color: Colors.grey[400],
                                size: 10,
                              ),
                              SizedBox(width: 20),
                              Text(
                                "to Pickup Point",
                                style: Theme.of(context).textTheme.bodyLarge!
                                    .copyWith(
                                      color: Colors.grey[300],
                                      fontSize: 11,
                                    ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.more_vert,
                            color: Colors.grey[400],
                            size: 10,
                          ),
                          Row(
                            children: [
                              Icon(Icons.circle, color: primaryColor, size: 10),
                              SizedBox(width: 20),
                              Expanded(
                                child: Text(
                                  widget.offer.pickupLocation.address,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyLarge!
                                      .copyWith(fontSize: 13.5),
                                ),
                              ),
                              Spacer(),
                              Text(
                                formatTime(widget.offer.dateTime),
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyLarge!.copyWith(fontSize: 13.5),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.more_vert,
                            color: Colors.grey[400],
                            size: 10,
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.drive_eta,
                                color: Colors.grey[400],
                                size: 10,
                              ),
                              SizedBox(width: 20),
                              Text(
                                "Drive",
                                style: Theme.of(context).textTheme.bodyLarge!
                                    .copyWith(
                                      color: Colors.grey[300],
                                      fontSize: 11,
                                    ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.more_vert,
                            color: Colors.grey[400],
                            size: 10,
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 10,
                              ),
                              SizedBox(width: 20),
                              Expanded(
                                child: Text(
                                  widget.offer.dropoffLocation.address,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyLarge!
                                      .copyWith(fontSize: 13.5),
                                ),
                              ),
                              Spacer(),
                            ],
                          ),
                          widget.isFindPool
                              ? Icon(
                                  Icons.more_vert,
                                  color: Colors.grey[400],
                                  size: 10,
                                )
                              : SizedBox.shrink(),
                          widget.isFindPool
                              ? Row(
                                  children: [
                                    Icon(
                                      Icons.directions_walk,
                                      color: Colors.grey[400],
                                      size: 10,
                                    ),
                                    SizedBox(width: 20),
                                    Text(
                                      "from Drop Point",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge!
                                          .copyWith(
                                            color: Colors.grey[300],
                                            fontSize: 11,
                                          ),
                                    ),
                                  ],
                                )
                              : SizedBox.shrink(),
                        ],
                      ),
                    ),
                  ),
                  SingleChildScrollView(
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      margin: EdgeInsets.only(
                        top: MediaQuery.of(context).size.height - 165,
                      ),
                      height: !widget.isFindPool ? 440 : 600,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey[200]!,
                            offset: Offset(0, 0.3),
                            blurRadius: 10,
                            spreadRadius: 7,
                          ),
                        ],
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: FadedSlideAnimation(
                        beginOffset: Offset(0, 0.4),
                        endOffset: Offset(0, 0),
                        slideCurve: Curves.linearToEaseOut,
                        child: ListView(
                          physics: NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 150,
                              ),
                              child: Divider(
                                color: Colors.grey[300],
                                thickness: 5,
                              ),
                            ),
                            ListTile(
                              // onTap: () {
                              //   setState(() {
                              //     poolerDetails = !poolerDetails;
                              //   });
                              // },
                              leading: SizedBox(
                                height: 50,
                                width: 50,
                                child: ClipRect(
                                  child: CachedNetworkImage(
                                    imageUrl: widget.img,
                                    fit: BoxFit.cover,
                                    progressIndicatorBuilder:
                                        (context, url, progress) => Center(
                                          child: SizedBox(
                                            height: 50,
                                            width: 50,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              value: progress.progress,
                                            ),
                                          ),
                                        ),
                                    errorWidget: (context, url, error) =>
                                        Image.asset('assets/1.png'),
                                  ),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    widget.name.isEmpty
                                        ? 'Driver'
                                        : widget.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge!
                                        .copyWith(fontSize: 15),
                                  ),
                                  Spacer(),
                                  Text(
                                    "${"RWF"} ${formatPriceWithCommas(widget.offer.pricePerSeat)}",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge!
                                        .copyWith(fontSize: 15),
                                  ),
                                ],
                              ),
                              subtitle: Row(
                                children: [
                                  Icon(
                                    Icons.verified_user,
                                    size: iconSize,
                                    color: primaryColor,
                                  ),
                                  SizedBox(width: 5),
                                  // Text(
                                  //   "Bank of USA",
                                  //   style: TextStyle(
                                  //       fontSize: 10, color: Color(0xffa8aeb2)),
                                  // ),
                                  Spacer(),
                                  widget.isFindPool
                                      ? Row(
                                          children: [
                                            Icon(
                                              Icons.directions_bike,
                                              size: iconSize,
                                              color: Colors.grey[300],
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 3,
                                                  ),
                                              child: Icon(
                                                Icons.circle,
                                                size: 4,
                                                color: Colors.grey[300],
                                              ),
                                            ),
                                            Icon(
                                              Icons.account_circle,
                                              size: iconSize,
                                              color: Colors.grey[300],
                                            ),
                                            Icon(
                                              Icons.account_circle,
                                              size: iconSize,
                                              color: Colors.grey[300],
                                            ),
                                            Icon(
                                              Icons.account_circle,
                                              size: iconSize,
                                              color: Colors.grey[300],
                                            ),
                                          ],
                                        )
                                      : Text(
                                          "1 ${"seat"}",
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Color(0xffa8aeb2),
                                          ),
                                        ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: widget.isFindPool ? 20 : 0),
                                widget.isFindPool
                                    ? Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                        ),
                                        child: Text(
                                          "Co-passengers",
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium!
                                              .copyWith(
                                                fontSize: 13.5,
                                                color: Color(0xffb3b3b3),
                                              ),
                                        ),
                                      )
                                    : SizedBox.shrink(),
                                SizedBox(height: 10),
                                widget.isFindPool
                                    ? ProfileAvatar(pool: widget.offer)
                                    : SizedBox.shrink(),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  child: Divider(thickness: 3),
                                ),
                                DriverVehicle(pool: widget.offer),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (poolSeatValue != null &&
                      widget.requestUser.seats != null &&
                      poolSeatValue.selectedSeat! >= widget.requestUser.seats!)
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: 50,
                            width: 50,
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              border: Border.all(
                                color: primaryColor,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: GestureDetector(
                              child: Image.asset(
                                width: 45,
                                'assets/whatsapp.png',
                              ),
                              onTap: () async {
                                final phone = widget.offer.user.replaceFirst(
                                  '+',
                                  '',
                                );
                                print(phone);
                                // final Uri url = Uri.parse(
                                //   'https://wa.me/$phone',
                                // );

                                // try {
                                //   if (await canLaunchUrl(url)) {
                                //     await launchUrl(url, mode: LaunchMode.externalApplication);
                                //   } else {
                                //     ScaffoldMessenger.of(context)
                                //         .showSnackBar(
                                //       SnackBar(
                                //           content: Text(
                                //               'Could not launch WhatsApp.')),
                                //     );
                                //   }
                                // } catch (e) {
                                //   ScaffoldMessenger.of(context)
                                //       .showSnackBar(
                                //     SnackBar(content: Text('Error: Fail')),
                                //   );
                                // }
                              },
                            ),
                          ),
                          SizedBox(width: 20),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                await _requestRider();
                              },
                              child: FadedScaleAnimation(
                                scaleDuration: const Duration(
                                  milliseconds: 600,
                                ),
                                child: SizedBox(
                                  height: 52,
                                  child: isRideRequested && !widget.isFindPool
                                      ? Container(
                                          width: double.infinity,
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 50,
                                            vertical: 15,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.surface,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.check,
                                                color: Theme.of(
                                                  context,
                                                ).primaryColor,
                                              ),
                                              SizedBox(width: 18),
                                              Text(
                                                "Request Sent".toUpperCase(),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyLarge!
                                                    .copyWith(
                                                      fontSize: 15,
                                                      letterSpacing: 3,
                                                      color: Theme.of(
                                                        context,
                                                      ).primaryColor,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : ColorButton(
                                          widget.isFindPool
                                              ? "Request Ride"
                                              : "Offer Ride",
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleMap(WidgetRef ref, PassengerOfferPool pool) {
    return GoogleMap(
      mapType: MapType.normal,
      initialCameraPosition: CameraPosition(
        target: LatLng(
          pool.pickupLocation.latitude,
          pool.pickupLocation.longitude,
        ),
        zoom: 16,
      ),
      onMapCreated: (GoogleMapController controller) {
        mapController = controller;
      },
      markers: _markers,
      polylines: polylines,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: true,
      zoomGesturesEnabled: true,
      scrollGesturesEnabled: true,
      rotateGesturesEnabled: true,
      tiltGesturesEnabled: true,
      compassEnabled: true,
      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
        Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
        Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
        Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
        Factory<VerticalDragGestureRecognizer>(
          () => VerticalDragGestureRecognizer(),
        ),
      },
    );
  }
}
