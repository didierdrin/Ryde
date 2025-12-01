import 'dart:async';
import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ryde_rw/screens/notifications.dart';
import 'package:ryde_rw/components/widgets/tab_comp.dart';
import 'package:ryde_rw/map_utils.dart';
import '../home/find_pools.dart';
import '../home/offer_pool.dart';
import 'package:ryde_rw/service/notification_service.dart';
import 'package:ryde_rw/service/user_location_service.dart';
import 'package:ryde_rw/shared/shared_states.dart';
import 'package:ryde_rw/theme/colors.dart';

class PublicHome extends ConsumerStatefulWidget {
  const PublicHome({super.key});

  @override
  PublicHomeConsumerState createState() => PublicHomeConsumerState();
}

class PublicHomeConsumerState extends ConsumerState<PublicHome> {
  final Completer<GoogleMapController> _mapController = Completer();
  GoogleMapController? mapStyleController;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool hasVehicle = false;

  @override
  Widget build(BuildContext context) {
    final notificationsStream = ref.watch(
      NotificationService.userNotificationStream,
    );
    notificationsStream.isLoading;

    final notifications = notificationsStream.value ?? [];
    final isNotified = notifications.where((e) => !e.isRead).isNotEmpty;
    final tabsLength = hasVehicle ? 2 : 1;

    return DefaultTabController(
      length: tabsLength,
      child: Scaffold(
        key: scaffoldKey,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () {
                      scaffoldKey.currentState!.openEndDrawer();
                    },
                    child: Container(
                      height: 45,
                      width: 45,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        size: 30,
                        color: Colors.black45,
                      ),
                    ),
                  ),
                  if (isNotified)
                    Positioned(
                      top: 8,
                      right: 4,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: kMainColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        // endDrawer: Notifications(
        //   onDelete: () async {
        //     Navigator.pop(context);
        //     await NotificationService.deleteAllNotifications(notifications);
        //   },
        // ),
        onEndDrawerChanged: (isOpened) async {
          if (!isOpened) {
            final ids = notifications
                .where((e) => !e.isRead)
                .map((item) => item.id)
                .toList();
            await NotificationService.readNotifications(ids);
          }
        },
        body: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            _buildGoogleMap(ref),
            FadedSlideAnimation(
              beginOffset: Offset(0, 0.4),
              endOffset: Offset(0, 0),
              slideCurve: Curves.linearToEaseOut,
              child: Container(
                margin: EdgeInsets.only(bottom: 50),
                width: MediaQuery.of(context).size.width,
                height: 390,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    SizedBox(height: 15),
                    Container(
                      height: 50,
                      width: 304,
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Color(0xff3FD390),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: TabBar(
                        indicator: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        labelColor: kMainColor,
                        unselectedLabelColor: kWhiteColor,
                        tabs: [
                          Tabcomp(icon: Icons.drive_eta, text: "Find Pool"),
                          Tabcomp(
                            icon: Icons.escalator_warning_outlined,
                            text: "Offer Pool",
                          ),
                        ].sublist(0, tabsLength),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            FadedSlideAnimation(
              beginOffset: Offset(0, 0.4),
              endOffset: Offset(0, 0),
              slideCurve: Curves.linearToEaseOut,
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: 360,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: TabBarView(
                    children: [FindPool(), OfferPool()].sublist(0, tabsLength),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleMap(WidgetRef ref) {
    final user = ref.watch(userProvider);
    final location = ref.watch(locationProvider);

    final defaultPosition = LatLng(
      location.isEmpty ? 0.0 : location['lat'],
      location.isEmpty ? 0.0 : location['long'],
    );
    final defaultZoom = location.isEmpty ? 0.0 : 14.345;
    if (user == null) {
      return GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: CameraPosition(
          target: defaultPosition,
          zoom: defaultZoom,
        ),
        onMapCreated: (controller) async {
          _mapController.complete(controller);
          controller.setMapStyle(mapStyle);
        },
        markers: {
          Marker(
            markerId: const MarkerId('defaultLocation'),
            position: defaultPosition,
            infoWindow: const InfoWindow(
              title: 'Default Location',
              snippet: 'No user data available',
            ),
          ),
        },
      );
    }

    final userLocationAsync = ref.watch(
      LocationTrackingService.userLocationStream(user.id),
    );

    return userLocationAsync.when(
      data: (userLocation) {
        if (userLocation == null) {
          return GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(
              target: defaultPosition,
              zoom: defaultZoom,
            ),
            onMapCreated: (controller) async {
              _mapController.complete(controller);
              controller.setMapStyle(mapStyle);
            },
            markers: {
              Marker(
                markerId: const MarkerId('defaultLocation'),
                position: defaultPosition,
                infoWindow: const InfoWindow(
                  title: 'Default Location',
                  snippet: 'No user location data available',
                ),
              ),
            },
          );
        }

        final Set<Marker> markers = {
          Marker(
            markerId: const MarkerId('currentLocation'),
            position: LatLng(
              userLocation.currentLocation.latitude,
              userLocation.currentLocation.longitude,
            ),
            infoWindow: InfoWindow(
              title: 'Your Location',
              snippet:
                  'Lat: ${userLocation.currentLocation.latitude}, Lng: ${userLocation.currentLocation.longitude}',
            ),
          ),
        };

        return GoogleMap(
          mapType: MapType.normal,
          initialCameraPosition: CameraPosition(
            target: LatLng(
              userLocation.currentLocation.latitude,
              userLocation.currentLocation.longitude,
            ),
            zoom: defaultZoom,
          ),
          onMapCreated: (controller) async {
            _mapController.complete(controller);
            controller.setMapStyle(mapStyle);
          },
          markers: markers,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) =>
          Center(child: Text('Failed to load map: $error')),
    );
  }
}
