import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ryde_rw/components/widgets/color_button.dart';

import 'package:ryde_rw/map_utils.dart';
import '../chats/chat_page.dart';
import '../home/end_trip_pool_taker.dart';
import '../home/end_trip_pooler.dart';
import 'package:ryde_rw/theme/colors.dart';

class TripPoolerInfo extends StatelessWidget {
  final String img;
  final String name;
  final bool tripPool;

  const TripPoolerInfo(this.img, this.name, [this.tripPool = false]);

  @override
  Widget build(BuildContext context) {
    return TripPoolerInfoBody(img, name, tripPool);
  }
}

class TripPoolerInfoBody extends StatefulWidget {
  final String img;
  final String name;
  final bool tripPool;

  const TripPoolerInfoBody(this.img, this.name, [this.tripPool = false]);

  @override
  TripPoolerInfoBodyState createState() => TripPoolerInfoBodyState();
}

class TripPoolerInfoBodyState extends State<TripPoolerInfoBody> {
  bool riideRoute = false;
  bool poolerDetails = false;
  late bool tripPoolinfo;
  double iconSize = 10;
  final Completer<GoogleMapController> _mapController = Completer();
  GoogleMapController? mapStyleController;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    tripPoolinfo = widget.tripPool;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: kGooglePlex,
              markers: _markers,
              onMapCreated: (GoogleMapController controller) async {
                _mapController.complete(controller);
                mapStyleController = controller;
                mapStyleController!.setMapStyle(mapStyle);
                setState(() {
                  _markers.add(
                    Marker(
                      markerId: MarkerId('mark1'),
                      position: LatLng(37.42796133580664, -122.085749655962),
                      icon: markerss.first,
                    ),
                  );
                  _markers.add(
                    Marker(
                      markerId: MarkerId('mark2'),
                      position: LatLng(37.42496133180663, -122.081743655960),
                      icon: markerss[1],
                    ),
                  );
                  _markers.add(
                    Marker(
                      markerId: MarkerId('mark3'),
                      position: LatLng(37.42196183580660, -122.089743655967),
                      icon: markerss[2],
                    ),
                  );
                });
              },
            ),
          ),
          tripPoolinfo
              ? riideRoute
                  ? rideRoute(context)
                  : offerRide(context)
              : Container(
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
                              "Ride starts soon 25 Mar, 10:30 am",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge!
                                  .copyWith(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Spacer(),
                            Icon(
                              Icons.more_vert,
                              color: Colors.grey,
                              size: 17,
                            ),
                          ],
                        ),
                        SizedBox(height: 15),
                        Text(
                          "520m to Pickup Point",
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge!
                              .copyWith(
                                color: Colors.grey[300],
                                fontSize: 11,
                              ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          "Hamilton Bridge - 9:58 am",
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge!
                              .copyWith(fontSize: 13.5),
                        ),
                        SizedBox(height: 10),
                        Text(
                          "42.3km Drive",
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge!
                              .copyWith(
                                color: Colors.grey[300],
                                fontSize: 11,
                              ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          "World Trade Point - 9:58 am",
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge!
                              .copyWith(fontSize: 13.5),
                        ),
                        SizedBox(height: 10),
                        Text(
                          "380m from Drop Point",
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge!
                              .copyWith(
                                color: Colors.grey[300],
                                fontSize: 11,
                              ),
                        ),
                        Spacer(),
                        Row(
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
                              child: IconButton(
                                icon: Icon(Icons.chat, color: primaryColor),
                                onPressed: () {
                                  // Chat functionality disabled - needs user ID
                                },
                              ),
                            ),
                            SizedBox(width: 20),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EndTripPoolTaker(),
                                    ),
                                  );
                                },
                                child: Container(
                                  height: 40,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(25),
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  child: Center(
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.navigation,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                        Spacer(),
                                        Text(
                                          "DIRECTION",
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge!
                                              .copyWith(
                                                fontSize: 15,
                                                letterSpacing: 2,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget offerRide(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      height: 300,
      width: MediaQuery.of(context).size.width,
      child: Column(
        children: [
          Row(
            children: [
              Text(
                "Ride starts on 25 Jun, 10:30 am",
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              Icon(Icons.more_vert, color: Colors.grey),
            ],
          ),
          Spacer(),
          Row(
            children: [
              Icon(Icons.circle, color: Colors.green, size: 13),
              SizedBox(width: 15),
              Text(
                "1024, Central Park, Hemilton, New York",
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 13.5),
              ),
            ],
          ),
          Spacer(),
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.red, size: 13),
              SizedBox(width: 15),
              Text(
                "M141, Food Center, Hemilton, Illinois",
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 13.5),
              ),
            ],
          ),
          Spacer(),
          GestureDetector(
            onTap: () {
              setState(() {
                riideRoute = true;
              });
            },
            child: ColorButton("Start Ride"),
          ),
        ],
      ),
    );
  }
}

Widget rideRoute(BuildContext context) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    height: 340,
    width: MediaQuery.of(context).size.width,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Ride route",
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 13.5,
          ),
        ),
        SizedBox(height: 20),
        Text(
          "Start Ride",
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 12),
        ),
        Row(
          children: [
            Icon(Icons.circle, color: Colors.green, size: 13),
            SizedBox(width: 15),
            Text(
              "1024, Central Park, Hemilton, New York",
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 12),
            ),
          ],
        ),
        SizedBox(height: 10),
        Text(
          "Pick up Samantha Saint",
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 12),
        ),
        Row(
          children: [
            Icon(Icons.arrow_upward, color: Colors.green, size: 13),
            SizedBox(width: 15),
            Text(
              "Hemilton Bridge, New York",
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 12),
            ),
          ],
        ),
        SizedBox(height: 10),
        Text(
          "End trip",
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 12),
        ),
        Row(
          children: [
            Icon(Icons.location_on, color: Colors.red, size: 13),
            SizedBox(width: 15),
            Text(
              "M141, Food Center, Hemilton, Illinois",
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 12),
            ),
          ],
        ),
      ],
    ),
  );
}