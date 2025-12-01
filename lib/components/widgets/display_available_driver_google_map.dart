import 'dart:async';
import 'package:animation_wrappers/animations/faded_scale_animation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart'
    as polyline;
import 'package:ryde_rw/components/widgets/available_seat.dart';
import 'package:ryde_rw/components/widgets/button_bar.dart';
import 'package:ryde_rw/models/offer_pool_model.dart';
import 'package:ryde_rw/models/request_model.dart';
import 'package:ryde_rw/screens/home/home.dart';
// import 'package:ryde_rw/screens/app_screen.dart';
import 'package:ryde_rw/service/location_service.dart';
import 'package:ryde_rw/service/request_rider_service.dart';
import 'package:ryde_rw/shared/shared_states.dart';
import 'package:ryde_rw/theme/colors.dart';
import 'package:ryde_rw/utils/contants.dart';
import 'package:ryde_rw/utils/utils.dart';

import 'package:ryde_rw/service/notification_service.dart';
import 'package:intl/intl.dart';

class DisplayAvailableDriverGoogleMap extends ConsumerStatefulWidget {
  final PassengerOfferPool ride;

  const DisplayAvailableDriverGoogleMap({super.key, required this.ride});

  @override
  DisplayAvailableDriverGoogleMapState createState() =>
      DisplayAvailableDriverGoogleMapState();
}

class DisplayAvailableDriverGoogleMapState
    extends ConsumerState<DisplayAvailableDriverGoogleMap> {
  GoogleMapController? mapController;
  Position? _currentPosition;
  Set<Polyline> polylines = {};
  Set<Marker> _markers = {};
  polyline.PolylinePoints polylinePoints = polyline.PolylinePoints(
    apiKey: "",
  ); // correct the apikey issue - provide the Google API
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  BitmapDescriptor? pickupIcon;
  BitmapDescriptor? dropoffIcon;
  BitmapDescriptor? driverIcon;

  bool _isLoading = true;
  bool isLoading = false;

  int selectedSeat = 0;
  int? selectedWeight;
  String? selectedMeasure;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    // await _getCurrentLocation();
    await _drawRoutes();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );

    setState(() {
      _currentPosition = position;
    });

    _updateMarkers();
  }

  Future<void> _drawRoutes() async {
    if (_currentPosition == null) return;

    polyline.PolylineRequest driverToPickupRequest = polyline.PolylineRequest(
      origin: polyline.PointLatLng(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
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

    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: MarkerId("Current"),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          infoWindow: InfoWindow(title: "Your Location"),
          icon:
              driverIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

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
      // Generate a new document reference to get the ID
      final requestDoc = RequestRideService.collection.doc();

      final requestRide = RequestRide(
        id: requestDoc.id, // Set the ID from the generated document reference
        rider: widget.ride.user,
        requestedBy: user.id,
        pickupLocation: widget.ride.pickupLocation,
        dropoffLocation: widget.ride.dropoffLocation,
        requestedTime: Timestamp.now(),
        createdAt: Timestamp.now(),
        rejected: false,
        accepted: false,
        type: widget.ride.type,
        offerpool: widget.ride.id!,
        paid: false,
        price: widget.ride.pricePerSeat,
        seats: selectedSeat,
        quantity: selectedWeight,
        measure: selectedMeasure,
        countryCode: user.countryCode,
      );

      await RequestRideService.createRequestRide(requestRide);

      await NotificationService.sendRideNotification(
        recipientId: widget.ride.user,
        title: 'New Ride Request',
        body: 'A passenger has requested a ride',
        data: {
          'request_id': requestRide.id,
          'passenger_id': user.id,
          'type': 'ride_request',
          'pickup_location': widget.ride.pickupLocation.address,
          'dropoff_location': widget.ride.dropoffLocation.address,
          'trip_time': DateFormat(
            'MMM dd, yyyy HH:mm',
          ).format(widget.ride.dateTime.toDate()),
        },
        type: 'request',
      );

      if (widget.ride.type == 'passengers') {
        Navigator.pop(context);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => Home()),  //AppScreen(currentIndex: 2)),
          (route) => false,
        );
      } else if (widget.ride.type == 'goods') {
        Navigator.pop(context);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => Home()), //AppScreen(currentIndex: 2)),
          (route) => false,
        );
      }
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

  bool isValid() {
    return selectedSeat != 0 || selectedWeight != null;
  }

  @override
  Widget build(BuildContext context) {
    print(_isLoading);

    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: greenPrimary))
          : Form(
              key: _formKey,
              child: Stack(
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
                      Factory<PanGestureRecognizer>(
                        () => PanGestureRecognizer(),
                      ),
                      Factory<ScaleGestureRecognizer>(
                        () => ScaleGestureRecognizer(),
                      ),
                      Factory<TapGestureRecognizer>(
                        () => TapGestureRecognizer(),
                      ),
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
                    maxChildSize: 1,
                    snap: true,
                    builder: (context, scrollController) {
                      return Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          boxShadow: [
                            BoxShadow(color: Colors.black26, blurRadius: 10),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 50,
                              height: 5,
                              margin: EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            SizedBox(height: 8),
                            Expanded(
                              child: SingleChildScrollView(
                                controller: scrollController,
                                child: buildPickupDropLocn(
                                  context,
                                  widget.ride,
                                ),
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
                    child: Expanded(
                      child: FadedScaleAnimation(
                        scaleDuration: const Duration(milliseconds: 600),
                        child: BottomBar(
                          isValid: isValid(),
                          onTap: () async {
                            await _requestRider();
                          },
                          text: "Request Ride",
                          textColor: kWhiteColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget buildPickupDropLocn(
    BuildContext context,
    PassengerOfferPool location,
  ) {
    final locations = ref.read(locationProvider);
    final distance = LocationService.getDistanceOffer(
      widget.ride,
      locations,
    )!.toStringAsFixed(1);
    final totalDistance = LocationService.calculateDistance(
      location.pickupLocation,
      location.dropoffLocation,
    ).toStringAsFixed(1);
    return Container(
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                " ${formatDate(location.dateTime)} , ${formatTime(location.dateTime)} ",
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
                  "${location.selectedSeat} Seats",
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
                      fontSize: 14,
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
                      fontSize: 14,
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
                  fontSize: 11,
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
                formatTime(location.dateTime),
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
          SizedBox(height: 15),
          Text(
            "Passengers",
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          ProfileAvatar(pool: location),
          SizedBox(height: 20),
          if (widget.ride.type == 'passengers')
            DropdownButtonFormField<int>(
              iconSize: 25,
              itemHeight: 57,
              value: seats.any((seat) => seat["value"] == selectedSeat)
                  ? selectedSeat
                  : null,
              decoration: InputDecoration(
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[200]!, width: 1.0),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: kMainColor, width: 2.0),
                ),
              ),
              hint: Text("Select seats", style: TextStyle(color: Colors.grey)),
              style: Theme.of(
                context,
              ).textTheme.bodyLarge!.copyWith(fontSize: 13.5),
              icon: Icon(Icons.arrow_drop_down, color: Colors.grey),
              items: seats.map<DropdownMenuItem<int>>((seat) {
                return DropdownMenuItem<int>(
                  value: seat["value"],
                  child: Text(seat["label"]),
                );
              }).toList(),
              onChanged: (int? value) {
                setState(() {
                  selectedSeat = value!;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a seat count';
                }
                return null;
              },
            ),
          if (widget.ride.type == 'goods')
            DropdownButtonFormField<int>(
              iconSize: 25,
              itemHeight: 57,
              value: selectedWeight,
              decoration: InputDecoration(
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[200]!, width: 1.0),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: kMainColor, width: 2.0),
                ),
              ),
              hint: Text("Select weight", style: TextStyle(color: Colors.grey)),
              style: Theme.of(
                context,
              ).textTheme.bodyLarge!.copyWith(fontSize: 13.5),
              icon: Icon(Icons.arrow_drop_down, color: Colors.grey),
              items: weights.map<DropdownMenuItem<int>>((weight) {
                return DropdownMenuItem<int>(
                  value: weight["value"],
                  child: Text("${weight["label"]} (${weight["measure"]})"),
                );
              }).toList(),
              onChanged: (int? value) {
                setState(() {
                  selectedWeight = value;
                  final selectedItem = weights.firstWhere(
                    (weight) => weight["value"] == value,
                    orElse: () => {"measure": null},
                  );
                  selectedMeasure = selectedItem["measure"];
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a weight';
                }
                return null;
              },
            ),
        ],
      ),
    );
  }
}
