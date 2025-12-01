import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import '../home/searchdrivers.dart';
import '../home/searchpassenger.dart';
import './finding_pool_list.dart';
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
    final user = ref.watch(userProvider)!;

    final vehicleAsyncValue = ref.watch(VehicleService.vehicleStream(user.id));
    final requestStreams = ref.watch(
      RequestRideService.allRequestRideStreamProvider,
    );
    final isLoading = vehicleAsyncValue.isLoading || requestStreams.isLoading;

    bool hasVehicle = vehicleAsyncValue.value != null;
    final requested = requestStreams.value ?? [];
    bool driverHasMadeRequest = requested.any((request) {
      return request.requestedBy == user.id;
    });

    int tabLength = hasVehicle ? (driverHasMadeRequest ? 3 : 3) : 2;

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
            isScrollable: true,
            labelColor: Theme.of(context).primaryColor,
            indicatorSize: TabBarIndicatorSize.label,
            indicatorColor: Theme.of(context).primaryColor,
            indicatorWeight: 4.0,
            tabs: hasVehicle
                ? (driverHasMadeRequest
                      ? [
                          Tab(text: "My Trips"),
                          Tab(text: 'NearBy Passengers'),
                          Tab(text: 'NearBy Drivers'),
                        ]
                      : [
                          Tab(text: "My Trips"),
                          Tab(text: 'NearBy Passengers'),
                          Tab(text: 'NearBy Drivers'),
                        ])
                : [
                    Tab(text: "My Trips"),
                    // Tab(text: 'NearBy Passengers'),
                    Tab(text: 'NearBy Drivers'),
                  ],
          ),
        ),
        backgroundColor: Colors.white,
        body: TabBarView(
          controller: tabController,
          children: hasVehicle
              ? (driverHasMadeRequest
                    ? [
                        OfferingTab(),
                        // FindingTab(),
                        SearchPassengers(),
                        Searchdrivers(),
                      ]
                    : [OfferingTab(), SearchPassengers(), Searchdrivers()])
              : [
                  FindingTab(),
                  // DriversPool(),
                  // SearchPassengers(),
                  Searchdrivers(),
                ],
        ),
      ),
    );
  }
}

