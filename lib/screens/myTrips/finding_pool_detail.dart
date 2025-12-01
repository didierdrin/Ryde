import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:ryde_rw/components/widgets/button_bar.dart';

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

class FindingPoolDetail extends ConsumerStatefulWidget {
  final String img;
  final String name;
  final bool isFindPool;
  final String id;
  final RequestRide offer;

  const FindingPoolDetail(
    this.img,
    this.name,
    this.isFindPool,
    this.id,
    this.offer, {
    super.key,
  });

  @override
  FindingPoolDetailConsumerState createState() =>
      FindingPoolDetailConsumerState();
}

class FindingPoolDetailConsumerState extends ConsumerState<FindingPoolDetail> {
  bool poolerDetails = false;
  double iconSize = 10;
  bool isRideRequested = false;
  int selectedSeat = 1;
  Set<Polyline> polylines = {};
  Set<Marker> _markers = {};
  PolylinePoints polylinePoints = PolylinePoints(
    apiKey: "",
  ); // provide google_api key
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

  @override
  Widget build(BuildContext context) {
    final locations = ref.read(locationProvider);
    final allOfferPoolStreams = ref.watch(OfferPoolService.offeringStreamsAll);

    final isLoading = allOfferPoolStreams.isLoading;

    final removeseatOffData = allOfferPoolStreams.value ?? [];

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
        inAsyncCall: isLoading,
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
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 25),
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
                                  formatTime(widget.offer.requestedTime),
                                  style: Theme.of(context).textTheme.bodyLarge!
                                      .copyWith(fontSize: 13.5),
                                ),
                              ],
                            ),
                            Icon(
                              Icons.more_vert,
                              color: Colors.grey[800],
                              size: 10,
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
                              ],
                            ),
                          ],
                        ),
                        Container(
                          width: MediaQuery.of(context).size.width,
                          height: !widget.isFindPool ? 440 : 600,
                          decoration: BoxDecoration(color: Colors.white),
                          child:  ListView(
                              physics: NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
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
                                                child:
                                                    CircularProgressIndicator(
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
                      if (!widget.offer.rejected) ...[
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

                                                        final check =
                                                            removeseatOffData
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
                                                            check.availableSeat
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

