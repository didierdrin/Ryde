import 'dart:async';
// import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:animation_wrappers/Animations/faded_scale_animation.dart';
import 'package:animation_wrappers/Animations/faded_slide_animation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ryde_rw/components/widgets/color_button.dart';

import 'package:ryde_rw/map_utils.dart';
import '../chats/chat_page.dart';
import '../home/end_trip_pool_taker.dart';
import '../home/end_trip_pooler.dart';
import 'package:ryde_rw/theme/colors.dart';

class PoolerInfo extends StatefulWidget {
  final String img;
  final String name;
  final bool isFindPool;

  const PoolerInfo(this.img, this.name, this.isFindPool, {super.key});

  @override
  PoolerInfoState createState() => PoolerInfoState();
}

class PoolerInfoState extends State<PoolerInfo> {
  bool poolerDetails = false;

  double iconSize = 10;

  bool isRideRequested = false;

  final Completer<GoogleMapController> _mapController = Completer();
  GoogleMapController? mapStyleController;
  final Set<Marker> _markers = {};

  @override
  void initState() {
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
                      icon: markerss[0],
                    ),
                  );
                });
              },
            ),
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
                              "${"Ride starts on"} 25 Mar, 10:30 am",
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
                            Text(
                              "Hamilton Bridge",
                              style: Theme.of(
                                context,
                              ).textTheme.bodyLarge!.copyWith(fontSize: 13.5),
                            ),
                            Spacer(),
                            Text(
                              "9:58 am",
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
                              "42.3km ${"Drive"}",
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
                            Text(
                              "World Trade Point",
                              style: Theme.of(
                                context,
                              ).textTheme.bodyLarge!.copyWith(fontSize: 13.5),
                            ),
                            Spacer(),
                            Text(
                              "9:58 am",
                              style: Theme.of(
                                context,
                              ).textTheme.bodyLarge!.copyWith(fontSize: 13.5),
                            ),
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
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge!.copyWith(fontSize: 15),
                                ),
                                Spacer(),
                                Text(
                                  "\$3.50",
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge!.copyWith(fontSize: 15),
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
                                widget.isFindPool
                                    ? Row(
                                        children: [
                                          Icon(
                                            Icons.directions_bike,
                                            size: iconSize,
                                            color: Colors.grey[300],
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
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
                                  ? Row(
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
                                    )
                                  : SizedBox.shrink(),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                child: Divider(thickness: 3),
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
                                          widget.isFindPool
                                              ? "Rider Rating"
                                              : "Rating",
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium!
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
                                          height: 19,
                                          width: 45,
                                          decoration: BoxDecoration(
                                            color: Colors.green[500],
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.star,
                                                size: 13,
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
                                              .bodyMedium!
                                              .copyWith(
                                                fontSize: 13.5,
                                                color: Color(0xffb3b3b3),
                                              ),
                                        ),
                                        SizedBox(height: 10),
                                        Text(
                                          "249 ${"people"}",
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
                                              .bodyMedium!
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
                                child: Divider(thickness: 3),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    widget.isFindPool
                                        ? Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Vehicle Info",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium!
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
                                                        .copyWith(
                                                          fontSize: 13.5,
                                                        ),
                                                  ),
                                                  SizedBox(width: 10),
                                                  Text(
                                                    "Hatchback | NYC55142",
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium!
                                                        .copyWith(fontSize: 11),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          )
                                        : SizedBox.shrink(),
                                    SizedBox(height: 15),
                                    Text(
                                      widget.isFindPool
                                          ? "Facilities"
                                          : "Hobbies",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium!
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
                                      widget.isFindPool
                                          ? "Instructions"
                                          : "Bio",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium!
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
                          border: Border.all(color: primaryColor, width: 1.5),
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
                            if (isRideRequested) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => widget.isFindPool
                                      // ? PoolingConfirmed()
                                      ? EndTripPoolTaker()
                                      : EndTripPooler(),
                                ),
                              );
                            } else {
                              setState(() {
                                isRideRequested = true;
                              });
                            }
                          },
                          child: FadedScaleAnimation(
                            scaleDuration: const Duration(milliseconds: 600),
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
                                        borderRadius: BorderRadius.circular(30),
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
                                                  fontWeight: FontWeight.bold,
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
    );
  }
}
