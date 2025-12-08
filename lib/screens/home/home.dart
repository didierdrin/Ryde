import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ryde_rw/screens/notifications.dart';
import 'package:ryde_rw/components/widgets/tab_comp.dart';
import '../home/find_pools.dart';
import '../home/offer_pool.dart';
import 'package:ryde_rw/service/notification_service.dart';
import 'package:ryde_rw/service/offer_pool_service.dart';
import 'package:ryde_rw/service/request_rider_service.dart';
import 'package:ryde_rw/service/vehicle_service.dart';
import 'package:ryde_rw/shared/shared_states.dart';
import 'package:ryde_rw/theme/colors.dart';
import 'package:ryde_rw/provider/current_location_provider.dart';

class Home extends ConsumerStatefulWidget {
  const Home({super.key});

  @override
  HomeConsumerState createState() => HomeConsumerState();
}

class HomeConsumerState extends ConsumerState<Home> {
  final Completer<GoogleMapController> _mapController = Completer();
  GoogleMapController? mapStyleController;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool hasVehicle = false;

  @override
  Widget build(BuildContext context) {
    try {
      final user = ref.watch(userProvider);

      if (user == null) {
        print('Home: User is null, showing loading screen');
        return const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading user data...'),
              ],
            ),
          ),
        );
      }

      print('Home: User loaded successfully: ${user.id}');

      final vehicleAsyncValue = ref.watch(VehicleService.vehicleStream(user.id));
      hasVehicle = vehicleAsyncValue.value != null;
      print('Home: Vehicle status - hasVehicle: $hasVehicle');

      final notificationsStream = ref.watch(
        NotificationService.userNotificationStream,
      );
      
      final notifications = notificationsStream.value ?? [];
      final isNotified = notifications.where((e) => !e.isRead).isNotEmpty;
      final tabsLength = hasVehicle ? 2 : 1;
      print('Home: Notifications loaded - count: ${notifications.length}, unread: $isNotified');

      final diplayDriverNearYouStream = ref.watch(
        OfferPoolService.diplayDriverNearYou,
      );
      final diplayPassengerNearYouStream = ref.watch(
        RequestRideService.diplayPassengerNearYou,
      );

      final isLoading =
          diplayDriverNearYouStream.isLoading ||
          diplayPassengerNearYouStream.isLoading;
      final driverNearYou = diplayDriverNearYouStream.value ?? [];
      final passengerNearYou = diplayPassengerNearYouStream.value ?? [];
      print('Home: Nearby data - drivers: ${driverNearYou.length}, passengers: ${passengerNearYou.length}');

      if (isLoading) {
        print('Home: Still loading nearby data');
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading nearby rides...'),
              ],
            ),
          ),
        );
      }

      print('Home: Rendering main UI with tabsLength: $tabsLength');
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
                        try {
                          scaffoldKey.currentState?.openEndDrawer();
                        } catch (e) {
                          print('Home: Error opening drawer: $e');
                        }
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
        endDrawer: Notifications(
          onDelete: () async {
            Navigator.pop(context);
            await NotificationService.deleteAllNotifications(notifications);
          },
        ),
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
            _buildGoogleMap(ref, driverNearYou, passengerNearYou, hasVehicle),
            DraggableScrollableSheet(
              initialChildSize: 0.2,
              minChildSize: 0.2,
              maxChildSize: 0.5,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  child: Container(
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(0),
                        topRight: Radius.circular(0),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 12),
                          height: 4,
                          width: 100,
                          decoration: BoxDecoration(
                            color: kWhiteColor.withAlpha(90),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Container(
                          height: 50,
                          margin: EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 20,
                          ),
                          width: double.infinity,
                          padding: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Color(0xff000000), //Color(0xff3FD390),
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
                              Tabcomp(icon: Icons.drive_eta, text: "Get a Ride"),
                              // if (hasVehicle)
                              //   Tabcomp(
                              //     icon: Icons.escalator_warning_outlined,
                              //     text: "Set a Route",
                              //   ),
                            ],
                          ),
                        ),
                        // Tab content
                        Container(
                          height: MediaQuery.of(context).size.height * 0.5,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child: TabBarView(
                            children: [FindPool(), if (hasVehicle) OfferPool()],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),),
      );
    } catch (e, stackTrace) {
      print('Home: Critical error in build method: $e');
      print('Stack trace: $stackTrace');
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('Something went wrong'),
              SizedBox(height: 8),
              Text('Error: ${e.toString()}', style: TextStyle(fontSize: 12)),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {});
                },
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildGoogleMap(
    WidgetRef ref,
    List<dynamic> driverNearYou,
    List<dynamic> passengerNearYou,
    bool hasVehicle,
  ) {
    final currentLocationAsync = ref.watch(currentLocationProvider);
    
    return currentLocationAsync.when(
      data: (currentLocation) {
        Set<Marker> markers = {};

        return GoogleMap(
          mapType: MapType.normal,
          initialCameraPosition: CameraPosition(
            target: currentLocation,
            zoom: 15.0,
          ),
          onMapCreated: (controller) async {
            _mapController.complete(controller);
          },
          markers: markers,
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
      },
      loading: () => Container(
        color: Colors.grey[300],
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Container(
        color: Colors.grey[300],
        child: Center(
          child: Text('Error loading map: $error'),
        ),
      ),
    );
  }
}

