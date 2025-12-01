import 'package:flutter/material.dart';

import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import '../home/searchdrivers.dart';
import '../myTrips/drivers.dart';
import '../myTrips/finding_pool_list.dart';
import '../myTrips/offer_pool_list.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../myTrips/passengers.dart';
import 'package:ryde_rw/service/request_rider_service.dart';
import 'package:ryde_rw/service/vehicle_service.dart';
import 'package:ryde_rw/shared/shared_states.dart';

class MyTripss extends ConsumerStatefulWidget {
  final int index;
  const MyTripss({super.key, this.index = 0});

  @override
  MyTripsState createState() => MyTripsState();
}

class MyTripsState extends ConsumerState<MyTripss>
    with TickerProviderStateMixin {
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
    final user = ref.watch(userProvider)!;
    final vehicleAsyncValue = ref.watch(VehicleService.vehicleStream(user.id));
    final requestStreams = ref.watch(
      RequestRideService.allRequestRideStreamProvider,
    );
    final isLoading = vehicleAsyncValue.isLoading || requestStreams.isLoading;

    bool hasVehicle = vehicleAsyncValue.value != null;
    final requested = requestStreams.value ?? [];
    bool checkifDriverHasMadeRequest = requested.any(
      (request) => request.requestedBy == user.id,
    );

    // Determine number of tabs based on conditions
    int tabLength = 3; // 2 tabs if no vehicle

    if (tabController.length != tabLength) {
      tabController.dispose();
      tabController = TabController(
        length: tabLength,
        vsync: this,
        initialIndex: widget.index < tabLength ? widget.index : 0,
      );
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
              onPressed: () {},
            ),
          ],
          bottom: TabBar(
            controller: tabController,
            labelColor: Theme.of(context).primaryColor,
            indicatorSize: TabBarIndicatorSize.label,
            indicatorColor: Theme.of(context).primaryColor,
            indicatorWeight: 4.0,
            tabs: hasVehicle
                ? (checkifDriverHasMadeRequest
                      ? [
                          Tab(text: "My Trips"),
                          Tab(text: "Finding"),
                          Tab(text: 'Passengers'),
                          Tab(text: 'NearBy Drivers'),
                        ]
                      : [
                          Tab(text: "My Trips"),
                          Tab(text: 'Passengers'),
                          Tab(text: 'NearBy Drivers'),
                        ])
                : [
                    Tab(text: "My Trips"),
                    Tab(text: 'Drivers'),
                    Tab(text: 'NearBy Drivers'),
                  ],
          ),
        ),
        backgroundColor: Colors.white,
        body: TabBarView(
          controller: tabController,
          children: hasVehicle
              ? (checkifDriverHasMadeRequest
                    ? [
                        OfferingTab(),
                        // FindingTab(),
                        PassengersPool(),
                        Searchdrivers(),
                      ]
                    : [OfferingTab(), PassengersPool(), Searchdrivers()])
              : [FindingTab(), DriversPool(), Searchdrivers()],
        ),
      ),
    );
  }
}

