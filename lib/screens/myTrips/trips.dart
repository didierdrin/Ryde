import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import '../home/searchdrivers.dart';
import '../home/searchpassenger.dart';
import './finding_pool_list.dart';
import './my_rides.dart';
import './offer_pool_list.dart';
import 'package:ryde_rw/service/request_rider_service.dart';
import 'package:ryde_rw/service/vehicle_service.dart';
import 'package:ryde_rw/shared/shared_states.dart';

class Trips extends ConsumerStatefulWidget {
  final int index;
  const Trips({super.key, this.index = 0});

  @override
  ConsumerState<Trips> createState() => _TripsState();
}

class _TripsState extends ConsumerState<Trips> with TickerProviderStateMixin {
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 1, vsync: this, initialIndex: 0);
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    try {
      final user = ref.watch(userProvider);
      
      if (user == null) {
        print('Trips: User is null, showing loading screen');
        return Scaffold(
          appBar: AppBar(
            title: Text('My Trips'),
            backgroundColor: Colors.white,
          ),
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

      print('Trips: User loaded successfully: ${user.id}');

      final vehicleAsyncValue = ref.watch(VehicleService.vehicleStream(user.id));
      final requestStreams = ref.watch(
        RequestRideService.allRequestRideStreamProvider,
      );
      final isLoading = vehicleAsyncValue.isLoading || requestStreams.isLoading;

      bool hasVehicle = vehicleAsyncValue.value != null;
      final requested = requestStreams.value ?? [];
      
      print('Trips: Vehicle status - hasVehicle: $hasVehicle, requests: ${requested.length}');

      int tabLength = hasVehicle ? 3 : 1;

      if (tabController.length != tabLength) {
        tabController.dispose();
        tabController = TabController(
          length: tabLength,
          vsync: this,
          initialIndex: widget.index < tabLength ? widget.index : 0,
        );
        print('Trips: TabController recreated with length: $tabLength');
      }
      return ModalProgressHUD(
        inAsyncCall: isLoading,
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: true,
            elevation: 0,
            centerTitle: true,
            backgroundColor: Colors.white,
            title: Text(
              "My Trips",
              style: Theme.of(
                context,
              ).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w600),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.history, color: Colors.grey[300], size: 17),
                onPressed: () {
                  print('Trips: History button pressed');
                },
              ),
            ],
            bottom: TabBar(
              controller: tabController,
              isScrollable: true,
              labelColor: Theme.of(context).primaryColor,
              indicatorSize: TabBarIndicatorSize.label,
              indicatorColor: Theme.of(context).primaryColor,
              indicatorWeight: 4.0,
              tabs: hasVehicle
                  ? [
                      // Tab(text: "My Rides"),
                      Tab(text: "My Trips"),
                      Tab(text: 'NearBy Passengers'),
                    ]
                  : [
                      Tab(text: "My Rides"),
                    ],
            ),
          ),
          backgroundColor: Colors.white,
          body: TabBarView(
            controller: tabController,
            children: hasVehicle
                ? [
                    // _buildSafeWidget(() => MyRidesTab(), 'MyRidesTab'),
                    _buildSafeWidget(() => OfferingTab(), 'OfferingTab'),
                    _buildSafeWidget(() => SearchPassengers(), 'SearchPassengers'),
                  ]
                : [
                    _buildSafeWidget(() => MyRidesTab(), 'MyRidesTab'),
                  ],
          ),
        ),
      );
    } catch (e, stackTrace) {
      print('Trips: Critical error in build method: $e');
      print('Stack trace: $stackTrace');
      return Scaffold(
        appBar: AppBar(
          title: Text('My Trips'),
          backgroundColor: Colors.white,
        ),
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

  Widget _buildSafeWidget(Widget Function() builder, String widgetName) {
    try {
      return builder();
    } catch (e, stackTrace) {
      print('Trips: Error building $widgetName: $e');
      print('Stack trace: $stackTrace');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text('Error loading $widgetName'),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                setState(() {});
              },
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }
  }
}

