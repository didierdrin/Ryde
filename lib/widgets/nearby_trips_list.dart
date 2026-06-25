import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ryde_rw/models/user.dart';
import 'package:ryde_rw/service/nearby_trips_service.dart';
import 'package:ryde_rw/service/realtime_location_tracker.dart';
import 'package:ryde_rw/widgets/trip_list_avatar.dart';

class NearbyTripsList extends ConsumerStatefulWidget {
  final User user;
  final void Function(Map<String, dynamic> trip) onTripTap;
  final EdgeInsetsGeometry padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const NearbyTripsList({
    super.key,
    required this.user,
    required this.onTripTap,
    this.padding = const EdgeInsets.all(12),
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  ConsumerState<NearbyTripsList> createState() => NearbyTripsListState();
}

class NearbyTripsListState extends ConsumerState<NearbyTripsList> {
  List<Map<String, dynamic>> _trips = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => reload());
  }

  Future<void> reload() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final trips = await NearbyTripsService.load(ref);
      if (mounted) {
        setState(() {
          _trips = trips;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(_error!, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 16),
            TextButton(onPressed: reload, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_trips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 50, color: Colors.grey[400]),
            const SizedBox(height: 10),
            Text(
              'No passenger requests right now',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w300, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: reload,
      child: ListView.builder(
        padding: widget.padding,
        shrinkWrap: widget.shrinkWrap,
        physics: widget.physics,
        itemCount: _trips.length,
        itemBuilder: (context, index) {
          final t = _trips[index];
          final pickup = tripStr(t, 'pickupAddress').trim();
          final dest = tripStr(t, 'destinationAddress').trim();
          final passengerName = tripStr(t, 'passengerName').trim();
          final fare = formatTripFare(t['fare']);
          final distance = tripDouble(t, 'driverDistance');

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: TripListAvatar(
                imageUrl: tripProfileImage(t),
                fallbackIcon: Icons.person_pin_circle,
                fallbackColor: Colors.orange,
              ),
              title: Text(
                passengerName.isEmpty ? 'Passenger request' : passengerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    pickup.isEmpty ? 'Pickup location' : pickup,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dest.isEmpty ? 'Destination' : dest,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  if (distance != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${distance.toStringAsFixed(1)} km away',
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                  if (fare.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Fare: $fare',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => widget.onTripTap(t),
            ),
          );
        },
      ),
    );
  }
}
