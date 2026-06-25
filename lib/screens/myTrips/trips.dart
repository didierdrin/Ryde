import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ryde_rw/models/user.dart';
import 'package:ryde_rw/screens/trips/trip_detail_screen.dart';
import 'package:ryde_rw/service/api_service.dart';
import 'package:ryde_rw/service/realtime_location_tracker.dart';
import 'package:ryde_rw/shared/shared_states.dart';
import 'package:ryde_rw/widgets/nearby_trips_list.dart';

class Trips extends ConsumerStatefulWidget {
  const Trips({super.key});

  @override
  ConsumerState<Trips> createState() => _TripsState();
}

class _TripsState extends ConsumerState<Trips> {
  List<dynamic> _trips = [];
  bool _loading = true;
  String? _error;
  final _nearbyKey = GlobalKey<NearbyTripsListState>();

  String _formatRequestTime(BuildContext context, String raw) {
    if (raw.trim().isEmpty) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final localizations = MaterialLocalizations.of(context);
      final date = localizations.formatShortDate(dt);
      final time = localizations.formatTimeOfDay(TimeOfDay.fromDateTime(dt));
      return '$date • $time';
    } catch (_) {
      return raw;
    }
  }

  String _formatFare(dynamic fare) {
    if (fare == null) return '';
    if (fare is num) {
      final intish = fare.roundToDouble() == fare.toDouble();
      final value = intish ? fare.toInt().toString() : fare.toString();
      return '$value RWF';
    }
    final s = fare.toString().trim();
    if (s.isEmpty) return '';
    return s.toUpperCase().contains('RWF') || s.toUpperCase().contains('FRW') ? s : '$s RWF';
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'REQUESTED':
        return Colors.orange;
      case 'ACCEPTED':
        return Colors.blue;
      case 'IN_PROGRESS':
        return Colors.purple;
      case 'COMPLETED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiService.getMyTrips();
      final list = (res['trips'] as List?) ?? [];
      if (mounted) setState(() {
        _trips = list;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _openTripDetail(BuildContext context, User user, Map<String, dynamic> t) {
    openTripDetail(context, user, t).then((_) {
      _load();
      _nearbyKey.currentState?.reload();
    });
  }

  Widget _buildTripCard(BuildContext context, User user, Map<String, dynamic> t) {
    final tripId = tripStr(t, 'tripId');
    final pickup = tripStr(t, 'pickupAddress').trim();
    final dest = tripStr(t, 'destinationAddress').trim();
    final status = tripStr(t, 'status').trim();
    final fare = _formatFare(t['fare']);
    final requestTime = _formatRequestTime(context, tripStr(t, 'requestTime'));

    final statusColor = _statusColor(status);
    final showMeta = requestTime.isNotEmpty || tripId.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.12),
          child: Icon(Icons.local_taxi, color: statusColor),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                pickup.isEmpty ? 'Pickup location' : pickup,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                status.isEmpty ? 'UNKNOWN' : status.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.arrow_downward, size: 14, color: Colors.black54),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    dest.isEmpty ? 'Destination' : dest,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black87),
                  ),
                ),
              ],
            ),
            if (showMeta) ...[
              const SizedBox(height: 6),
              Text(
                [
                  if (requestTime.isNotEmpty) requestTime,
                  if (tripId.isNotEmpty) 'Trip ID: $tripId',
                ].join(' • '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
            if (fare.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Fare: $fare',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _openTripDetail(context, user, t),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Trips')),
        body: const Center(child: Text('Please log in')),
      );
    }

    final isDriver = user.isDriver;

    Widget tripsBody() {
      if (_loading) return const Center(child: CircularProgressIndicator());
      if (_error != null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              TextButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        );
      }
      if (_trips.isEmpty) return const Center(child: Text('No trips yet'));

      return RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: _trips.length,
          itemBuilder: (context, index) {
            final t = Map<String, dynamic>.from(_trips[index] as Map);
            return _buildTripCard(context, user, t);
          },
        ),
      );
    }

    if (!isDriver) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Trips'),
          backgroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _load();
                _nearbyKey.currentState?.reload();
              },
            ),
          ],
        ),
        body: tripsBody(),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Trips'),
          backgroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _load();
                _nearbyKey.currentState?.reload();
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'My Trips'),
              Tab(text: 'Nearby Passengers'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            tripsBody(),
            NearbyTripsList(
              key: _nearbyKey,
              user: user,
              onTripTap: (t) => _openTripDetail(context, user, t),
            ),
          ],
        ),
      ),
    );
  }
}
