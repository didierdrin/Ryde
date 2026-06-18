import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ryde_rw/screens/home/searchpassengers.dart';
import 'package:ryde_rw/service/api_service.dart';
import 'package:ryde_rw/service/realtime_location_tracker.dart';
import 'package:ryde_rw/shared/shared_states.dart';
import 'package:ryde_rw/theme/colors.dart';

class Trips extends ConsumerStatefulWidget {
  const Trips({super.key});

  @override
  ConsumerState<Trips> createState() => _TripsState();
}

class _TripsState extends ConsumerState<Trips> {
  List<dynamic> _trips = [];
  bool _loading = true;
  String? _error;

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
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.getMyTrips();
      final list = (res['trips'] as List?) ?? [];
      if (mounted) setState(() { _trips = list; _loading = false; });
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
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

    final isPassenger = (user.userType.toString().toUpperCase() == 'PASSENGER');

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
            final t = _trips[index] as Map<String, dynamic>;
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
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => _TripDetailScreen(
                      tripId: tripId,
                      pickupAddress: pickup,
                      destinationAddress: dest,
                      status: status,
                      fare: t['fare'],
                      requestTime: t['requestTime'] as String? ?? '',
                      pickupLat: tripDouble(t, 'pickupLatitude'),
                      pickupLng: tripDouble(t, 'pickupLongitude'),
                      destLat: tripDouble(t, 'destinationLatitude'),
                      destLng: tripDouble(t, 'destinationLongitude'),
                      user: user,
                    ),
                  ),
                ).then((_) => _load()),
              ),
            );
          },
        ),
      );
    }

    if (!isPassenger) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Trips'),
          backgroundColor: Colors.white,
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
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
            IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
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
            const SearchPassengersListPage(),
          ],
        ),
      ),
    );
  }
}

class _TripDetailScreen extends ConsumerStatefulWidget {
  final String tripId;
  final String pickupAddress;
  final String destinationAddress;
  final String status;
  final dynamic fare;
  final String requestTime;
  final double? pickupLat;
  final double? pickupLng;
  final double? destLat;
  final double? destLng;
  final dynamic user;

  const _TripDetailScreen({
    required this.tripId,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.status,
    required this.fare,
    required this.requestTime,
    this.pickupLat,
    this.pickupLng,
    this.destLat,
    this.destLng,
    required this.user,
  });

  @override
  ConsumerState<_TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends ConsumerState<_TripDetailScreen> {
  bool _actionLoading = false;
  late String _status;
  final _tracker = RealtimeLocationTracker();
  Map<String, dynamic>? _liveLocations;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _status = widget.status;
    WidgetsBinding.instance.addPostFrameCallback((_) => _initTracking());
  }

  Future<void> _initTracking() async {
    final user = widget.user;
    if (user == null) return;
    final isDriver = user.userType == 'DRIVER';
    await _tracker.startUploading(isDriver: isDriver);
    if (isTrackableTripStatus(_status)) {
      _tracker.startPolling(widget.tripId, (loc) {
        if (!mounted) return;
        setState(() => _liveLocations = loc);
      });
    }
  }

  @override
  void dispose() {
    _tracker.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{
      if (widget.pickupLat != null && widget.pickupLng != null)
        Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(widget.pickupLat!, widget.pickupLng!),
          infoWindow: InfoWindow(title: 'Pickup', snippet: widget.pickupAddress),
        ),
      if (widget.destLat != null && widget.destLng != null)
        Marker(
          markerId: const MarkerId('dest'),
          position: LatLng(widget.destLat!, widget.destLng!),
          infoWindow: InfoWindow(title: 'Destination', snippet: widget.destinationAddress),
        ),
    };

    final loc = _liveLocations;
    if (loc != null) {
      final driver = loc['driver'] as Map<String, dynamic>?;
      final passenger = loc['passenger'] as Map<String, dynamic>?;
      if (driver != null) {
        final lat = (driver['latitude'] as num?)?.toDouble();
        final lng = (driver['longitude'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          markers.add(
            Marker(
              markerId: const MarkerId('driver'),
              position: LatLng(lat, lng),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
              infoWindow: InfoWindow(
                title: 'Driver',
                snippet: driver['name']?.toString() ?? 'Driver',
              ),
            ),
          );
        }
      }
      if (passenger != null) {
        final lat = (passenger['latitude'] as num?)?.toDouble();
        final lng = (passenger['longitude'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          markers.add(
            Marker(
              markerId: const MarkerId('passenger'),
              position: LatLng(lat, lng),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
              infoWindow: InfoWindow(
                title: 'Passenger',
                snippet: passenger['name']?.toString() ?? 'Passenger',
              ),
            ),
          );
        }
      }
    }

    return markers;
  }

  void _startPollingIfNeeded() {
    if (isTrackableTripStatus(_status)) {
      _tracker.startPolling(widget.tripId, (loc) {
        if (!mounted) return;
        setState(() => _liveLocations = loc);
      });
    }
  }

  Future<void> _acceptTrip() async {
    setState(() => _actionLoading = true);
    try {
      await ApiService.acceptTrip(widget.tripId);
      if (mounted) {
        setState(() {
          _status = 'ACCEPTED';
          _actionLoading = false;
        });
        _startPollingIfNeeded();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trip accepted')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _actionLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _startTrip() async {
    setState(() => _actionLoading = true);
    try {
      await ApiService.startTrip(widget.tripId);
      if (mounted) {
        setState(() {
          _status = 'IN_PROGRESS';
          _actionLoading = false;
        });
        _startPollingIfNeeded();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trip started')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _actionLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _completeTrip() async {
    setState(() => _actionLoading = true);
    try {
      await ApiService.completeTrip(widget.tripId, 15);
      if (mounted) {
        _tracker.stopPolling();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trip completed')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _actionLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _cancelTrip() async {
    setState(() => _actionLoading = true);
    try {
      await ApiService.cancelTrip(widget.tripId);
      if (mounted) {
        _tracker.stopPolling();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trip cancelled')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _actionLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lat = widget.pickupLat ?? -1.9441;
    final lng = widget.pickupLng ?? 30.0619;
    final center = LatLng(lat, lng);
    final isDriver = widget.user?.userType == 'DRIVER';
    final tracking = isTrackableTripStatus(_status);

    return Scaffold(
      appBar: AppBar(title: const Text('Trip details')),
      body: Column(
        children: [
          SizedBox(
            height: 220,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(target: center, zoom: 12),
                  markers: _buildMarkers(),
                  myLocationEnabled: true,
                  onMapCreated: (c) => _mapController = c,
                ),
                if (tracking)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 8, color: Colors.white),
                          SizedBox(width: 4),
                          Text('Live', style: TextStyle(color: Colors.white, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Pickup: ${widget.pickupAddress}', style: const TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text('Destination: ${widget.destinationAddress}', style: const TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Text('Status: $_status'),
                if (widget.fare != null) Text('Fare: ${widget.fare} RWF'),
                const SizedBox(height: 24),
                if (isDriver && _status == 'REQUESTED')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _actionLoading ? null : _acceptTrip,
                      style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                      child: _actionLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Accept trip'),
                    ),
                  ),
                if (isDriver && _status == 'ACCEPTED')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _actionLoading ? null : _startTrip,
                      style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                      child: _actionLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Start trip'),
                    ),
                  ),
                if (isDriver && _status == 'IN_PROGRESS')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _actionLoading ? null : _completeTrip,
                      style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                      child: _actionLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Complete trip'),
                    ),
                  ),
                if (_status == 'REQUESTED' || _status == 'ACCEPTED')
                  const SizedBox(height: 8),
                if (_status == 'REQUESTED' || _status == 'ACCEPTED')
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _actionLoading ? null : _cancelTrip,
                      child: const Text('Cancel trip'),
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
