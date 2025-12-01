import 'dart:async';
import 'package:animation_wrappers/animations/faded_scale_animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart'
    as polyline;
import 'package:ryde_rw/components/widgets/color_button.dart';
import 'package:ryde_rw/models/request_model.dart';
import 'package:ryde_rw/screens/home/home.dart';
// import 'package:ryde_rw/screens/app_screen.dart';
import 'package:ryde_rw/service/location_service.dart';
import 'package:ryde_rw/service/offer_pool_service.dart';
import 'package:ryde_rw/shared/shared_states.dart';
import 'package:ryde_rw/theme/colors.dart';
import 'package:ryde_rw/utils/contants.dart';
import 'package:ryde_rw/utils/utils.dart';

class RideMapScreen extends ConsumerStatefulWidget {
  final RequestRide ride;

  const RideMapScreen({super.key, required this.ride});

  @override
  RideMapScreenState createState() => RideMapScreenState();
}

class RideMapScreenState extends ConsumerState<RideMapScreen> {
  GoogleMapController? mapController;
  Set<Polyline> polylines = {};
  Set<Marker> _markers = {};
  polyline.PolylinePoints polylinePoints = polyline.PolylinePoints(
    apiKey: "",
  ); // Provide google_api key

  BitmapDescriptor? pickupIcon;
  BitmapDescriptor? dropoffIcon;
  BitmapDescriptor? driverIcon;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      await _drawRoutes();
    } catch (e) {
      print(e);
    }

    print('initialized');

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _drawRoutes() async {
    final _currentPosition = ref.read(locationProvider);

    polyline.PolylineRequest driverToPickupRequest = polyline.PolylineRequest(
      origin: polyline.PointLatLng(
        _currentPosition['lat'],
        _currentPosition['long'],
      ),
      destination: polyline.PointLatLng(
        widget.ride.pickupLocation.latitude,
        widget.ride.pickupLocation.longitude,
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
        widget.ride.pickupLocation.latitude,
        widget.ride.pickupLocation.longitude,
      ),
      destination: polyline.PointLatLng(
        widget.ride.dropoffLocation.latitude,
        widget.ride.dropoffLocation.longitude,
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
    Set<Marker> markers = {
      Marker(
        markerId: MarkerId("pickup"),
        position: LatLng(
          widget.ride.pickupLocation.latitude,
          widget.ride.pickupLocation.longitude,
        ),
        infoWindow: InfoWindow(title: "Pickup Location"),
        icon:
            pickupIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      Marker(
        markerId: MarkerId("dropoff"),
        position: LatLng(
          widget.ride.dropoffLocation.latitude,
          widget.ride.dropoffLocation.longitude,
        ),
        infoWindow: InfoWindow(title: "Dropoff Location"),
        icon:
            dropoffIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };

    final _currentPosition = ref.read(locationProvider);
    markers.add(
      Marker(
        markerId: MarkerId("driver"),
        position: LatLng(_currentPosition['lat'], _currentPosition['long']),
        infoWindow: InfoWindow(title: "Driver Location"),
        icon:
            driverIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );

    setState(() {
      _markers = markers;
    });
  }

  Future<void> acceptPool() async {
    final user = ref.read(userProvider)!;
    setState(() {
      _isLoading = true;
    });
    try {
      await OfferPoolService.acceptRideRequest(widget.ride.id!, user.id);

      setState(() {
        _isLoading = false;
      });
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => Home()),  // AppScreen(currentIndex: 2)),
        (route) => false,
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Color.fromARGB(255, 227, 85, 50),
          content: Text("Fail to accept ride request"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print(_isLoading);
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: greenPrimary))
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      widget.ride.pickupLocation.latitude,
                      widget.ride.pickupLocation.longitude,
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
                    Factory<ScaleGestureRecognizer>(
                      () => ScaleGestureRecognizer(),
                    ),
                    Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
                    Factory<VerticalDragGestureRecognizer>(
                      () => VerticalDragGestureRecognizer(),
                    ),
                  },
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
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.black,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                DraggableScrollableSheet(
                  initialChildSize: 0.4,
                  minChildSize: 0.2,
                  maxChildSize: 0.6,
                  snap: true,
                  builder: (context, scrollController) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 50,
                            height: 5,
                            margin: EdgeInsets.only(bottom: 10, top: 20),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          SizedBox(height: 10),
                          Expanded(
                            child: SingleChildScrollView(
                              controller: scrollController,
                              child: buildPickupDropLocn(context, widget.ride),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Positioned(
                  bottom: 12,
                  left: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: () async {
                      await acceptPool();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: FadedScaleAnimation(
                        scaleDuration: const Duration(milliseconds: 600),
                        child: ColorButton("Confirm"), // locale!.confirmationlufiti
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget buildPickupDropLocn(BuildContext context, RequestRide location) {
    final loca = ref.read(locationProvider);
    final distance = LocationService.getDistanceFind(
      location,
      loca,
    )!.toStringAsFixed(1);
    final totalDistance = LocationService.calculateDistance(
      location.pickupLocation,
      location.dropoffLocation,
    ).toStringAsFixed(1);
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 350,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  " ${formatDate(location.requestedTime)} , ${formatTime(location.requestedTime)} ",
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                Icon(Icons.more_vert, color: Colors.grey[300], size: 17),
              ],
            ),
            SizedBox(height: 15),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    location.type == 'passengers'
                        ? Icons.local_taxi
                        : Icons.local_shipping,
                    color: Colors.blueGrey[700],
                    size: 18,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  "${location.type.capitalize()} Trip",
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey[900],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (location.type == 'goods') ...[
              Row(
                children: [
                  Icon(
                    Icons.shopping_bag_rounded,
                    color: Colors.blueGrey[600],
                    size: 18,
                  ),
                  SizedBox(width: 6),
                  Text(
                    "${location.quantity} ${location.measure!.capitalize()}",
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.blueGrey[800],
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Icon(
                    Icons.event_seat_sharp,
                    color: Colors.blueGrey[600],
                    size: 18,
                  ),
                  SizedBox(width: 6),
                  Text(
                    "${location.seats} Seats",
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.blueGrey[800],
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.social_distance,
                      color: Colors.blueGrey[600],
                      size: 18,
                    ),
                    SizedBox(width: 6),
                    Text(
                      "Distance: $distance Km",
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.blueGrey[800],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.route, color: greenPrimary, size: 18),
                    SizedBox(width: 6),
                    Text(
                      "Total Distance: $totalDistance Km",
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: greenPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.directions_walk, color: Colors.grey[400], size: 10),
                SizedBox(width: 20),
                Text(
                  "to Pickup Point",
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: Colors.grey[300],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            Icon(Icons.more_vert, color: Colors.grey[400], size: 10),
            Row(
              children: [
                Icon(Icons.circle, color: primaryColor, size: 10),
                SizedBox(width: 20),
                Expanded(
                  child: Text(
                    location.pickupLocation.address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge!.copyWith(fontSize: 13.5),
                  ),
                ),
                Spacer(),
                Text(
                  formatTime(location.requestedTime),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge!.copyWith(fontSize: 13.5),
                ),
              ],
            ),
            Icon(Icons.more_vert, color: Colors.grey[400], size: 10),
            Row(
              children: [
                Icon(Icons.drive_eta, color: Colors.grey[400], size: 10),
                SizedBox(width: 20),
                Text(
                  "Drive",
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: Colors.grey[300],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            Icon(Icons.more_vert, color: Colors.grey[400], size: 10),
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.red, size: 10),
                SizedBox(width: 20),
                Expanded(
                  child: Text(
                    location.dropoffLocation.address,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge!.copyWith(fontSize: 13.5),
                  ),
                ),
                Spacer(),
              ],
            ),
            Icon(Icons.more_vert, color: Colors.grey[400], size: 10),
            Row(
              children: [
                Icon(Icons.directions_walk, color: Colors.grey[400], size: 10),
                SizedBox(width: 20),
                Text(
                  "from Drop Point",
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: Colors.grey[300],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
