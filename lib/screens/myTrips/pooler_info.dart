import 'dart:async';

import 'package:animation_wrappers/animation_wrappers.dart';
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

  // ignore: use_key_in_widget_constructors
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
    // var locale = AppLocalizations.of(context);

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
              : Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    FadedSlideAnimation(
                      beginOffset: Offset(0, 0.4),
                      endOffset: Offset(0, 0),
                      slideCurve: Curves.linearToEaseOut,
                      child: Container(
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
                                    "${"Ride starts soon"} 25 Mar, 10:30 am",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge!
                                        .copyWith(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  Icon(
                                    Icons.more_vert,
                                    color: Colors.grey,
                                    size: 17,
                                  ),
                                ],
                              ),
                              SizedBox(height: 15),
                              Row(
                                children: [
                                  Icon(
                                    Icons.directions_walk,
                                    color: Colors.grey[400],
                                    size: 10,
                                  ),
                                  SizedBox(width: 20),
                                  Text(
                                    "520m ${"to Pickup Point"}",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge!
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
                                    Icons.circle,
                                    color: primaryColor,
                                    size: 10,
                                  ),
                                  SizedBox(width: 20),
                                  Text(
                                    "Hamilton Bridge",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge!
                                        .copyWith(fontSize: 13.5),
                                  ),
                                  Spacer(),
                                  Text(
                                    "9:58 am",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge!
                                        .copyWith(fontSize: 13.5),
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
                                    "42.3km ${"Drive"}",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge!
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
                                  Text(
                                    "World Trade Point",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge!
                                        .copyWith(fontSize: 13.5),
                                  ),
                                  Spacer(),
                                  Text(
                                    "9:58 am",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge!
                                        .copyWith(fontSize: 13.5),
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
                                    Icons.directions_walk,
                                    color: Colors.grey[400],
                                    size: 10,
                                  ),
                                  SizedBox(width: 20),
                                  Text(
                                    "380m ${"from Drop Point"}",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge!
                                        .copyWith(
                                          color: Colors.grey[300],
                                          fontSize: 11,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    FadedSlideAnimation(
                      beginOffset: Offset(0, 0.4),
                      endOffset: Offset(0, 0),
                      slideCurve: Curves.linearToEaseOut,
                      child: SingleChildScrollView(
                        child: Container(
                          margin: EdgeInsets.only(
                            top: MediaQuery.of(context).size.height - 165,
                          ),
                          width: MediaQuery.of(context).size.width,
                          height: 600,
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
                          child: ListView(
                            physics: NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            // crossAxisAlignment: CrossAxisAlignment.start,
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
                                onTap: () {
                                  setState(() {
                                    poolerDetails = !poolerDetails;
                                  });
                                },
                                leading: SizedBox(
                                  height: 50,
                                  child: Image.asset(widget.img),
                                ),
                                title: Row(
                                  children: [
                                    Text(
                                      widget.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge!
                                          .copyWith(fontSize: 15),
                                    ),
                                    Spacer(),
                                    Text(
                                      "\$3.50",
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
                                    Text(
                                      "Bank of USA",
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Color(0xffa8aeb2),
                                      ),
                                    ),
                                    Spacer(),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.directions_bike,
                                          size: iconSize,
                                          color: Color(0xffa8aeb2),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          child: Icon(
                                            Icons.circle,
                                            size: 4,
                                            color: Color(0xffa8aeb2),
                                          ),
                                        ),
                                        Icon(
                                          Icons.account_circle,
                                          size: iconSize,
                                          color: Color(0xffa8aeb2),
                                        ),
                                        Icon(
                                          Icons.account_circle,
                                          size: iconSize,
                                          color: Color(0xffa8aeb2),
                                        ),
                                        Icon(
                                          Icons.account_circle,
                                          size: iconSize,
                                          color: Color(0xffa8aeb2),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 10,
                                    ),
                                    child: Text(
                                      "Co-passengers",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge!
                                          .copyWith(
                                            fontSize: 13.5,
                                            color: Color(0xffb3b3b3),
                                          ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          children: [
                                            CircleAvatar(
                                              backgroundImage: AssetImage(
                                                "assets/profiles/img1.png",
                                              ),
                                            ),
                                            SizedBox(height: 5),
                                            Text(
                                              "Samantha \nSmith",
                                              textAlign: TextAlign.center,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge!
                                                  .copyWith(fontSize: 10),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          children: [
                                            CircleAvatar(
                                              child: Icon(
                                                Icons.account_circle,
                                                color: Colors.white,
                                              ),
                                            ),
                                            SizedBox(height: 5),
                                            Text(
                                              "Empty \nSeat",
                                              textAlign: TextAlign.center,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium!
                                                  .copyWith(
                                                    fontSize: 10,
                                                    color: Colors.grey[300],
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          children: [
                                            CircleAvatar(
                                              child: Icon(
                                                Icons.account_circle,
                                                color: Colors.white,
                                              ),
                                            ),
                                            SizedBox(height: 5),
                                            Text(
                                              "Empty \nSeat",
                                              textAlign: TextAlign.center,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium!
                                                  .copyWith(
                                                    fontSize: 10,
                                                    color: Colors.grey[300],
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          children: [
                                            CircleAvatar(
                                              child: Icon(
                                                Icons.account_circle,
                                                color: Colors.white,
                                              ),
                                            ),
                                            SizedBox(height: 5),
                                            Text(
                                              "Empty \nSeat",
                                              textAlign: TextAlign.center,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium!
                                                  .copyWith(
                                                    fontSize: 10,
                                                    color: Colors.grey[300],
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    child: Divider(
                                      color: Colors.grey[200],
                                      thickness: 5,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Rider Rating",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge!
                                                  .copyWith(
                                                    fontSize: 13.5,
                                                    color: Color(0xffb3b3b3),
                                                  ),
                                            ),
                                            SizedBox(height: 10),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 5,
                                              ),
                                              height: 17,
                                              width: 45,
                                              decoration: BoxDecoration(
                                                color: Colors.green[500],
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.star,
                                                    size: iconSize,
                                                    color: Colors.amber,
                                                  ),
                                                  Text(
                                                    "4.5",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Ride with",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge!
                                                  .copyWith(
                                                    fontSize: 13.5,
                                                    color: Color(0xffb3b3b3),
                                                  ),
                                            ),
                                            SizedBox(height: 10),
                                            Text(
                                              "249 People",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge!
                                                  .copyWith(fontSize: 13.5),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "joined",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge!
                                                  .copyWith(
                                                    fontSize: 13.5,
                                                    color: Color(0xffb3b3b3),
                                                  ),
                                            ),
                                            SizedBox(height: 10),
                                            Text(
                                              "in 2018",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge!
                                                  .copyWith(fontSize: 13.5),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    child: Divider(
                                      color: Colors.grey[200],
                                      thickness: 5,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Vehicle Info",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge!
                                                  .copyWith(
                                                    fontSize: 13.5,
                                                    color: Color(0xffb3b3b3),
                                                  ),
                                            ),
                                            SizedBox(height: 5),
                                            Row(
                                              children: [
                                                Text(
                                                  "Toyota Matrix",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyLarge!
                                                      .copyWith(fontSize: 13.5),
                                                ),
                                                SizedBox(width: 10),
                                                Text(
                                                  "Hatchback | NYC55142",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyLarge!
                                                      .copyWith(
                                                        fontSize: 11,
                                                        color: Color(
                                                          0xffb3b3b3,
                                                        ),
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 15),
                                        Text(
                                          "Facilities",
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge!
                                              .copyWith(
                                                fontSize: 13.5,
                                                color: Color(0xffb3b3b3),
                                              ),
                                        ),
                                        SizedBox(height: 5),
                                        Text(
                                          "Listening to Music",
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge!
                                              .copyWith(fontSize: 13.5),
                                        ),
                                        SizedBox(height: 15),
                                        Text(
                                          "Instructions",
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge!
                                              .copyWith(
                                                fontSize: 13.5,
                                                color: Color(0xffb3b3b3),
                                              ),
                                        ),
                                        SizedBox(height: 5),
                                        Text(
                                          "No Smoking",
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

                              // Spacer(),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      color: Colors.white,
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
                            child: IconButton(
                              icon: Icon(Icons.chat, color: primaryColor),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatPage(),
                                  ),
                                );
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
                                // setState(() {
                                //   tripPoolinfo = true;
                                // });
                              },
                              child: FadedScaleAnimation(
                                scaleDuration: const Duration(
                                  milliseconds: 600,
                                ),
                                child: Container(
                                  height: 53,
                                  width: double.infinity,
                                  padding: EdgeInsetsDirectional.only(
                                    end: 50,
                                    start: 25,
                                    top: 15,
                                    bottom: 15,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  child: Center(
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.call,
                                          size: 20,
                                          color: Colors.white,
                                        ),
                                        Spacer(),
                                        Text(
                                          "Call Rider".toUpperCase(),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge!
                                              .copyWith(
                                                fontSize: 16,
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
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
          riideRoute
              ? Positioned(
                  right: 30,
                  bottom: 320,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EndTripPooler(),
                        ),
                      );
                    },
                    child: FadedScaleAnimation(
                      scaleDuration: const Duration(milliseconds: 600),
                      child: Container(
                        height: 40,
                        width: 180,
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
                                "DIRECTION", // locale!.direction.toUpperCase(),
                                style: Theme.of(context).textTheme.bodyLarge!
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
                )
              : SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget offerRide(BuildContext context) {
    return FadedSlideAnimation(
      beginOffset: Offset(0, 0.4),
      endOffset: Offset(0, 0),
      slideCurve: Curves.linearToEaseOut,
      child: Container(
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
                  "${"Ride starts on"}25 Jun, 10:30 am",
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
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge!.copyWith(fontSize: 13.5),
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
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge!.copyWith(fontSize: 13.5),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Text(
                    "Co-passengers",
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      fontSize: 13.5,
                      color: Color(0xffb3b3b3),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      CircleAvatar(
                        backgroundImage: AssetImage("assets/profiles/img1.png"),
                      ),
                      SizedBox(height: 5),
                      Text(
                        "Samantha \nSmith",
                        textAlign: TextAlign.center,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge!.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      CircleAvatar(child: Icon(Icons.add, color: Colors.white)),
                      SizedBox(height: 5),
                      Text(
                        "Empty \nSeat",
                        textAlign: TextAlign.center,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium!.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      CircleAvatar(child: Icon(Icons.add, color: Colors.white)),
                      SizedBox(height: 5),
                      Text(
                        "Empty \nSeat",
                        textAlign: TextAlign.center,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium!.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      CircleAvatar(child: Icon(Icons.add, color: Colors.white)),
                      SizedBox(height: 5),
                      Text(
                        "Empty \nSeat",
                        textAlign: TextAlign.center,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium!.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
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
              child: FadedScaleAnimation(
                scaleDuration: const Duration(milliseconds: 600),
                child: ColorButton("Start Ride"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget rideRoute(BuildContext context) {
  return FadedSlideAnimation(
    beginOffset: Offset(0, 0.4),
    endOffset: Offset(0, 0),
    slideCurve: Curves.linearToEaseOut,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      height: 340,
      width: MediaQuery.of(context).size.width,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    "Ride route", // locale.rideRoute,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
              Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Text(
                  "Start Ride",
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium!.copyWith(fontSize: 12),
                ),
              ),
              Row(
                children: [
                  Icon(Icons.circle, color: Colors.green, size: 13),
                  SizedBox(width: 15),
                  Text(
                    "1024, Central Park, Hemilton, New York",
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge!.copyWith(fontSize: 12),
                  ),
                ],
              ),
              Icon(Icons.more_vert, size: 13, color: Colors.grey),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Row(
                  children: [
                    Text(
                      "Pick up", //locale.pickup,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium!.copyWith(fontSize: 12),
                    ),
                    SizedBox(width: 5),
                    Text(
                      "Samantha Saint",
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        fontSize: 12,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Icon(Icons.arrow_upward, color: Colors.green, size: 13),
                  SizedBox(width: 15),
                  Text(
                    "Hemilton Bridge, New York",
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge!.copyWith(fontSize: 12),
                  ),
                ],
              ),
              Icon(Icons.more_vert, size: 13, color: Colors.grey),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Row(
                  children: [
                    Text(
                      "Pick up", // locale.pickup,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium!.copyWith(fontSize: 12),
                    ),
                    SizedBox(width: 5),
                    Text(
                      "Peter Taylor",
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        fontSize: 12,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Icon(Icons.arrow_upward, color: Colors.green, size: 13),
                  SizedBox(width: 15),
                  Text(
                    "City Parle Park, Hemilton, New York",
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge!.copyWith(fontSize: 12),
                  ),
                ],
              ),
              Icon(Icons.more_vert, size: 13, color: Colors.grey),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Row(
                  children: [
                    Text(
                      "Drop", //locale.drop,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium!.copyWith(fontSize: 12),
                    ),
                    SizedBox(width: 5),
                    Text(
                      "Peter Taylor",
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        fontSize: 12,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Icon(Icons.arrow_downward, color: Colors.red, size: 13),
                  SizedBox(width: 15),
                  Text(
                    "1024, Central Park, Hemilton, New York",
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge!.copyWith(fontSize: 12),
                  ),
                ],
              ),
              Icon(Icons.more_vert, size: 13, color: Colors.grey),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Row(
                  children: [
                    Text(
                      "Drop", //locale.drop,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium!.copyWith(fontSize: 12),
                    ),
                    SizedBox(width: 5),
                    Text(
                      "Samantha Smith",
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        fontSize: 12,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Icon(Icons.arrow_downward, color: Colors.red, size: 13),
                  SizedBox(width: 15),
                  Text(
                    "Golden Street, New York",
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge!.copyWith(fontSize: 12),
                  ),
                ],
              ),
              Icon(Icons.more_vert, size: 13, color: Colors.grey),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Row(
                  children: [
                    Text(
                      "End trip", //locale.endTrip,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium!.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.red, size: 13),
                  SizedBox(width: 15),
                  Text(
                    "M141, Food Center, Hemilton, Illinois",
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge!.copyWith(fontSize: 12),
                  ),
                ],
              ),
              Spacer(),
            ],
          ),
        ],
      ),
    ),
  );
}
