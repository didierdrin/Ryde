import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart'
    as polyline;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:ryde_rw/components/widgets/available_seat.dart';
import 'package:ryde_rw/components/widgets/button_bar.dart';
import 'package:ryde_rw/components/widgets/user_vehicle.dart';

import 'package:ryde_rw/models/offer_pool_model.dart';
import 'package:ryde_rw/models/request_model.dart';
//import 'package:ryde_rw/screens/app_screen.dart';
import 'package:ryde_rw/service/location_service.dart';
import 'package:ryde_rw/service/request_rider_service.dart';
import 'package:ryde_rw/shared/shared_states.dart';
import 'package:ryde_rw/theme/colors.dart';
import 'package:ryde_rw/utils/contants.dart';
import 'package:ryde_rw/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class PoolerInfo extends ConsumerStatefulWidget {
  final String img;
  final String name;
  final bool isFindPool;
  final String id;
  final PassengerOfferPool offer;
  final String type;

  const PoolerInfo(
    this.img,
    this.name,
    this.isFindPool,
    this.id,
    this.offer,
    this.type, {
    super.key,
  });

  @override
  PoolerInfoConsumerState createState() => PoolerInfoConsumerState();
}

class PoolerInfoConsumerState extends ConsumerState<PoolerInfo> {
  bool poolerDetails = false;
  bool isLoading = false;
  double iconSize = 10;
  bool isRideRequested = false;
  // int selectedSeat = 0;
  // int? selectedWeight;
  String? selectedMeasure;

  GoogleMapController? mapStyleController;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  Set<Polyline> polylines = {};
  Set<Marker> _markers = {};
  polyline.PolylinePoints polylinePoints = polyline.PolylinePoints(
    apiKey: "",
  ); // provide google_api key
  GoogleMapController? mapController;
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
    polyline.PolylineRequest driverToPickupRequest = polyline.PolylineRequest(
      origin: polyline.PointLatLng(location['lat'], location['long']),
      destination: polyline.PointLatLng(
        widget.offer.pickupLocation.latitude,
        widget.offer.pickupLocation.longitude,
      ),
      mode: polyline.TravelMode.driving,
    );

    polyline.PolylineResult driverToPickupResult = await polylinePoints
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

    polyline.PolylineRequest pickupToDropoffRequest = polyline.PolylineRequest(
      origin: polyline.PointLatLng(
        widget.offer.pickupLocation.latitude,
        widget.offer.pickupLocation.longitude,
      ),
      destination: polyline.PointLatLng(
        widget.offer.dropoffLocation.latitude,
        widget.offer.dropoffLocation.longitude,
      ),
      mode: polyline.TravelMode.driving,
    );

    polyline.PolylineResult pickupToDropoffResult = await polylinePoints
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

  void _fitRouteInMap(List<polyline.PointLatLng> routePoints) {
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
      final requestRide = RequestRide(
        rider: widget.offer.user,
        requestedBy: user.id,
        pickupLocation: widget.offer.pickupLocation,
        dropoffLocation: widget.offer.dropoffLocation,
        requestedTime: Timestamp.now(),
        createdAt: Timestamp.now(),
        rejected: false,
        accepted: false,
        type: widget.type,
        offerpool: widget.offer.id!,
        paid: false,
        price: widget.offer.pricePerSeat,
        seats: 1,
        quantity: 1,
        measure: selectedMeasure,
        countryCode: user.countryCode,
        requested: true,
      );

      await RequestRideService.createRequestRide(requestRide);
      Navigator.pop(context);
      // Navigator.pushAndRemoveUntil(
      //   context,
      //   MaterialPageRoute(builder: (context) => AppScreen(currentIndex: 1)),
      //   (route) => false,
      // );
    } catch (e) {
      print(e);
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
    // final region = ref.watch(regionProvider);
    final location = ref.read(locationProvider);
    final distance = LocationService.getDistanceOffer(
      widget.offer,
      location,
    )!.toStringAsFixed(1);

    print('pool info');

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: ModalProgressHUD(
        inAsyncCall: isLoading,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Positioned.fill(child: _buildGoogleMap(ref, widget.offer)),
            DraggableScrollableSheet(
              initialChildSize: 0.4,
              minChildSize: 0.2,
              maxChildSize: 1,
              builder: (context, scrollController) {
                return Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 150),
                          child: Divider(color: Colors.grey[300], thickness: 5),
                        ),
                        Container(
                          width: MediaQuery.of(context).size.width,
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
                                    Icon(
                                      Icons.circle,
                                      color: primaryColor,
                                      size: 10,
                                    ),
                                    SizedBox(width: 20),
                                    Expanded(
                                      child: Text(
                                        widget.offer.pickupLocation.address,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge!
                                            .copyWith(fontSize: 13.5),
                                      ),
                                    ),
                                    Spacer(),
                                    Text(
                                      formatTime(widget.offer.dateTime),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge!
                                          .copyWith(fontSize: 13.5),
                                    ),
                                  ],
                                ),
                                Icon(
                                  Icons.more_vert,
                                  color: Colors.grey[800],
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
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge!
                                            .copyWith(fontSize: 13.5),
                                      ),
                                    ),
                                    Spacer(),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        Column(
                          children: [
                            ListTile(
                              // onTap: () {
                              //   setState(() {
                              //     poolerDetails = !poolerDetails;
                              //   });
                              // },
                              leading: SizedBox(
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
                                    "${"RWF"} ${formatPriceWithCommas(widget.offer.pricePerSeat)} ",
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
                      ],
                    ),
                  ),
                );
              },
            ),
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
                          final phone = widget.offer.user.replaceFirst('+', '');
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
                    Expanded(
                      child: BottomBar(
                          // isValid: isValid(),
                          onTap: () async {
                            await _requestRider();
                          },
                          text: "Request Ride",
                          textColor: kWhiteColor,
                        ),
                      
                    ),
                  ],
                ),
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

