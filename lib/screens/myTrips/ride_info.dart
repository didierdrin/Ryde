import 'dart:async';
import 'package:animation_wrappers/animations/faded_slide_animation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:ryde_rw/components/widgets/available_seat.dart';
import 'package:ryde_rw/components/widgets/button_bar.dart';
import 'package:ryde_rw/components/widgets/user_vehicle.dart';

import 'package:ryde_rw/models/offer_pool_model.dart';
import 'package:ryde_rw/models/request_model.dart';
import 'package:ryde_rw/service/location_service.dart';
import 'package:ryde_rw/service/messages_service.dart';
import 'package:ryde_rw/service/offer_pool_service.dart';
import 'package:ryde_rw/service/request_rider_service.dart';
import 'package:ryde_rw/shared/shared_states.dart';
import 'package:ryde_rw/theme/colors.dart';
import 'package:ryde_rw/utils/contants.dart';
import 'package:ryde_rw/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class RideInfo extends ConsumerStatefulWidget {
  final String img;
  final String name;
  final bool isFindPool;
  final String id;
  final RequestRide offer;

  const RideInfo(
    this.img,
    this.name,
    this.isFindPool,
    this.id,
    this.offer, {
    super.key,
  });

  @override
  RideInfoConsumerState createState() => RideInfoConsumerState();
}

class RideInfoConsumerState extends ConsumerState<RideInfo> {
  bool poolerDetails = false;
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
  bool loading = false;

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

  Future handleAccept() async {
    setState(() {
      loading = true;
    });
    final String currentUser = widget.offer.requestedBy;
    final int userRequestedSeats = widget.offer.seats!;

    await RequestRideService.updateRequestRide(widget.offer.id!, {
      'accepted': true,
    });

    // offerPoo.availableSeat
    //     .add(currentUser);

    await MessengerService.acceptedLifuti(widget.offer, context);
    // await OfferPoolService
    //     .updateofferpool(
    //         widget.offer.offerpool, {
    //   'availableSeat':
    //       offerPoo.availableSeat,
    //   'emptySeat': 1,
    // });

    await OfferPoolService.updateofferpool(widget.offer.offerpool, {
      'isSeatFull': false,
    });
    setState(() {
      loading = true;
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final locations = ref.read(locationProvider);
    // final region = ref.watch(regionProvider);
    final poolInfoStream = ref.watch(
      OfferPoolService.poolRealTimeStreamProvider(widget.offer.offerpool),
    );
    final allOfferPoolStreams = ref.watch(OfferPoolService.offeringStreamsAll);

    final isLoading = poolInfoStream.isLoading || allOfferPoolStreams.isLoading;

    final PassengerOfferPool? pooldata = poolInfoStream.value;
    final removeseatOffData = allOfferPoolStreams.value ?? [];

    if (pooldata == null) {
      return Container();
    }

    final distance = LocationService.getDistanceFind(
      widget.offer,
      locations,
    )!.toStringAsFixed(1);

    final totalDistance = LocationService.calculateDistance(
      widget.offer.pickupLocation,
      widget.offer.dropoffLocation,
    ).toStringAsFixed(1);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: ModalProgressHUD(
        inAsyncCall: isLoading || loading,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Positioned.fill(child: _buildGoogleMap(ref, widget.offer)),
            DraggableScrollableSheet(
              initialChildSize: 0.4,
              minChildSize: 0.2,
              maxChildSize: 0.7,
              builder: (context, scrollController) {
                return Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: ListView(
                    controller: scrollController,
                    shrinkWrap: false,
                    physics: ClampingScrollPhysics(),
                    children: [
                      Row(
                        children: [
                          Icon(Icons.circle, color: primaryColor, size: 10),
                          SizedBox(width: 20),
                          Expanded(
                            child: Text(
                              widget.offer.pickupLocation.address,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(
                                context,
                              ).textTheme.bodyLarge!.copyWith(fontSize: 13.5),
                            ),
                          ),
                          Spacer(),
                          Text(
                            formatTime(widget.offer.requestedTime),
                            style: Theme.of(
                              context,
                            ).textTheme.bodyLarge!.copyWith(fontSize: 13.5),
                          ),
                        ],
                      ),
                      Icon(Icons.more_vert, color: Colors.grey[800], size: 10),
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.red, size: 10),
                          SizedBox(width: 20),
                          Expanded(
                            child: Text(
                              widget.offer.dropoffLocation.address,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              style: Theme.of(
                                context,
                              ).textTheme.bodyLarge!.copyWith(fontSize: 13.5),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(color: Colors.white),
                        child: FadedSlideAnimation(
                          beginOffset: Offset(0, 0.4),
                          endOffset: Offset(0, 0),
                          slideCurve: Curves.linearToEaseOut,
                          child: ListView(
                            physics: NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            children: [
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
                                      "${"RWF"} ${formatPriceWithCommas(pooldata.pricePerSeat)}",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge!
                                          .copyWith(fontSize: 15),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (!widget.offer.accepted &&
                          !widget.offer.rejected &&
                          widget.offer.requested)
                        SizedBox(
                          height: 50,
                          child: Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    showModalBottomSheet(
                                      context: context,
                                      backgroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(25),
                                        ),
                                      ),
                                      isScrollControlled: true,
                                      builder: (BuildContext context) {
                                        return AnimatedPadding(
                                          padding: MediaQuery.of(
                                            context,
                                          ).viewInsets,
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          child: Container(
                                            padding: EdgeInsets.all(20),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.vertical(
                                                    top: Radius.circular(25),
                                                  ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.1),
                                                  spreadRadius: 5,
                                                  blurRadius: 10,
                                                  offset: Offset(0, -5),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.warning_amber_outlined,
                                                  color: Colors.orange[600],
                                                  size: 40,
                                                ),
                                                SizedBox(height: 16),
                                                Text(
                                                  "Are you sure you want to decline this offer?",
                                                  style: GoogleFonts.mulish(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w300,
                                                    color: Colors.black54,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                SizedBox(height: 24),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceEvenly,
                                                  children: [
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                      },
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.transparent,
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              horizontal: 24,
                                                              vertical: 12,
                                                            ),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                          side: BorderSide(
                                                            color: Colors
                                                                .grey[400]!,
                                                          ),
                                                        ),
                                                        elevation: 0,
                                                      ),
                                                      child: Text(
                                                        "Cancel",
                                                        style: TextStyle(
                                                          color: Colors.black,
                                                          fontWeight:
                                                              FontWeight.w300,
                                                        ),
                                                      ),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () async {
                                                        await RequestRideService.updateRequestRide(
                                                          widget.offer.id!,
                                                          {'rejected': true},
                                                        );
                                                        await MessengerService.lifutiRejected(
                                                          widget.offer,
                                                          context,
                                                        );
                                                        Navigator.pop(context);
                                                      },
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: Color(
                                                          0xfffbe3e3,
                                                        ),
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              horizontal: 24,
                                                              vertical: 12,
                                                            ),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                        elevation: 0,
                                                      ),
                                                      child: Text(
                                                        "Yes, Decline",
                                                        style:
                                                            GoogleFonts.mulish(
                                                              color: Colors.red,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
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
                                    );
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                      color: Color(0xfffbe3e3),
                                    ),
                                    child: Center(
                                      child: Text(
                                        "Decline", //locale?.decline ?? '',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge!
                                            .copyWith(
                                              fontSize: 10,
                                              color: Color(0xffdd142c),
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    showModalBottomSheet(
                                      context: context,
                                      useSafeArea: true,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(20),
                                        ),
                                      ),
                                      builder: (BuildContext context) {
                                        return Container(
                                          padding: EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(20),
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(height: 20),
                                              // Confirmation Message
                                              Text(
                                                "Are you sure you want to confirm this Offer?",
                                                style: GoogleFonts.mulish(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black54,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              SizedBox(height: 20),
                                              // Action Buttons
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceEvenly,
                                                children: [
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                    },
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          Colors.transparent,
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 24,
                                                            vertical: 12,
                                                          ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                        side: BorderSide(
                                                          color:
                                                              Colors.grey[400]!,
                                                        ),
                                                      ),
                                                      elevation: 0,
                                                    ),
                                                    child: Text(
                                                      "Cancel",
                                                      style: GoogleFonts.mulish(
                                                        color: Colors.black54,
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                      ),
                                                    ),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () async {
                                                      Navigator.of(
                                                        context,
                                                      ).pop();
                                                      handleAccept();
                                                    },
                                                    style: ElevatedButton.styleFrom(
                                                      elevation: 0,
                                                      backgroundColor: Theme.of(
                                                        context,
                                                      ).primaryColor,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 24,
                                                            vertical: 12,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      "Confirm",
                                                      style: GoogleFonts.mulish(
                                                        color: Colors.white,
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    child: Center(
                                      child: Text(
                                        "Accept", //locale?.accept ?? '',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge!
                                            .copyWith(
                                              fontSize: 10,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
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
                );
              },
            ),
            if (!widget.offer.cancelled) ...[
              Positioned(
                child: Container(
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
                          color: kWhiteColor,
                          border: Border.all(color: primaryColor, width: 1.5),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: GestureDetector(
                          child: Image.asset(width: 45, 'assets/whatsapp.png'),
                          onTap: () async {
                            final phone = widget.offer.requestedBy.replaceFirst(
                              '+',
                              '',
                            );
                            print(phone);
                            final Uri url = Uri.parse('https://wa.me/$phone');

                            try {
                              if (await canLaunchUrl(url)) {
                                await launchUrl(
                                  url,
                                  mode: LaunchMode.externalApplication,
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Could not launch WhatsApp.'),
                                  ),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: Fail')),
                              );
                            }
                          },
                        ),
                      ),
                      SizedBox(width: 20),
                      if (!widget.offer.rejected &&
                          !widget.offer.completed) ...[
                        Expanded(
                          child: BottomBar(
                            text: widget.offer.cancelled != true
                                ? 'Cancel'
                                : 'Trip Cancelled',
                            onTap: () {
                              if (widget.offer.pickup != true) {
                                showModalBottomSheet(
                                  context: context,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                  ),
                                  builder: (BuildContext context) {
                                    return Container(
                                      padding: EdgeInsets.all(20),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 4,
                                            margin: EdgeInsets.only(bottom: 20),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[300],
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                          Container(
                                            padding: EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.red.withOpacity(
                                                0.1,
                                              ),
                                            ),
                                            child: Icon(
                                              Icons.warning_amber_rounded,
                                              size: 40,
                                              color: Colors.red,
                                            ),
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            'Are you sure you want to cancel this trip?',
                                            textAlign: TextAlign.center,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium,
                                          ),
                                          SizedBox(height: 24),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              Expanded(
                                                child: OutlinedButton(
                                                  style: OutlinedButton.styleFrom(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          vertical: 12,
                                                        ),
                                                    side: BorderSide(
                                                      color: Colors.red,
                                                    ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    'No',
                                                    style: TextStyle(
                                                      color: Colors.redAccent,
                                                    ),
                                                  ),
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                ),
                                              ),
                                              SizedBox(width: 16),
                                              Expanded(
                                                child: ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          vertical: 12,
                                                        ),
                                                    backgroundColor:
                                                        greenPrimary,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    'Yes, Cancel',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  onPressed: () async {
                                                    try {
                                                      Future.delayed(
                                                        Duration(
                                                          milliseconds: 200,
                                                        ),
                                                        () {
                                                          if (mounted) {
                                                            Navigator.of(
                                                              context,
                                                            ).pop();
                                                            Navigator.of(
                                                              context,
                                                            ).pop();
                                                          }
                                                        },
                                                      );

                                                      await RequestRideService.updateRequestRide(
                                                        widget.offer.id!,
                                                        {'cancelled': true},
                                                      );

                                                      if (widget
                                                          .offer
                                                          .rider
                                                          .isNotEmpty) {
                                                        await MessengerService.lifutiCancelled(
                                                          widget.offer,
                                                          context,
                                                        );

                                                        if (widget.offer.type ==
                                                            'passengers') {
                                                          final check = removeseatOffData
                                                              .firstWhereOrNull(
                                                                (e) =>
                                                                    e.id ==
                                                                    widget
                                                                        .offer
                                                                        .offerpool,
                                                              );

                                                          if (check != null) {
                                                            if (check
                                                                .availableSeat
                                                                .contains(
                                                                  widget
                                                                      .offer
                                                                      .requestedBy,
                                                                )) {
                                                              check
                                                                  .availableSeat
                                                                  .removeWhere(
                                                                    (seat) =>
                                                                        seat ==
                                                                        widget
                                                                            .offer
                                                                            .requestedBy,
                                                                  );

                                                              int
                                                              updatedEmptySeats =
                                                                  check
                                                                      .selectedSeat! -
                                                                  check
                                                                      .availableSeat
                                                                      .length;
                                                              if (updatedEmptySeats <
                                                                  0) {
                                                                updatedEmptySeats =
                                                                    0;
                                                              }

                                                              await OfferPoolService.updateofferpool(
                                                                widget
                                                                    .offer
                                                                    .offerpool,
                                                                {
                                                                  'availableSeat':
                                                                      check
                                                                          .availableSeat,
                                                                  'emptySeat':
                                                                      updatedEmptySeats,
                                                                  'isSeatFull':
                                                                      updatedEmptySeats ==
                                                                      0,
                                                                },
                                                              );
                                                            } else {
                                                              throw Exception(
                                                                'Failed to find available seat',
                                                              );
                                                            }
                                                          } else {
                                                            throw Exception(
                                                              'Failed to find offerpool',
                                                            );
                                                          }
                                                        } else {
                                                          final check = removeseatOffData
                                                              .firstWhereOrNull(
                                                                (e) =>
                                                                    e.id ==
                                                                    widget
                                                                        .offer
                                                                        .offerpool,
                                                              );

                                                          if (check != null) {
                                                            if (check
                                                                .availableSeat
                                                                .contains(
                                                                  widget
                                                                      .offer
                                                                      .requestedBy,
                                                                )) {
                                                              check
                                                                  .availableSeat
                                                                  .removeWhere(
                                                                    (seat) =>
                                                                        seat ==
                                                                        widget
                                                                            .offer
                                                                            .requestedBy,
                                                                  );
                                                              final int
                                                              canceledQuantity =
                                                                  widget
                                                                      .offer
                                                                      .quantity ??
                                                                  0;
                                                              final int
                                                              updatedQuantity =
                                                                  (check.quantity ??
                                                                      0) +
                                                                  canceledQuantity;

                                                              String
                                                              updatedMeasure =
                                                                  updatedQuantity >=
                                                                      1000
                                                                  ? 'ton'
                                                                  : 'kg';
                                                              int
                                                              normalizedQuantity =
                                                                  updatedMeasure ==
                                                                      'ton'
                                                                  ? updatedQuantity
                                                                  : updatedQuantity;

                                                              await OfferPoolService.updateofferpool(
                                                                widget
                                                                    .offer
                                                                    .offerpool,
                                                                {
                                                                  'availableSeat':
                                                                      check
                                                                          .availableSeat,
                                                                  'quantity':
                                                                      normalizedQuantity,
                                                                  'measure':
                                                                      updatedMeasure,
                                                                  'isSeatFull':
                                                                      false,
                                                                },
                                                              );
                                                            } else {
                                                              throw Exception(
                                                                'Failed to find available seat',
                                                              );
                                                            }
                                                          } else {
                                                            throw Exception(
                                                              'Failed to find offerpool',
                                                            );
                                                          }
                                                        }
                                                      }
                                                    } catch (e) {
                                                      throw Exception(
                                                        'Failed to handle cancellation',
                                                      );
                                                    }
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 16),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: Color(0xffdd142c),
                                    content: Text(
                                      'OOPS! You can not Cancel Trip already Started',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              }
                            },
                            color: const Color.fromARGB(255, 164, 48, 48),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleMap(WidgetRef ref, RequestRide pool) {
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
