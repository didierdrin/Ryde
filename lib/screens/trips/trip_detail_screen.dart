import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ryde_rw/models/user.dart';
import 'package:ryde_rw/service/api_service.dart';
import 'package:ryde_rw/service/realtime_location_tracker.dart';
import 'package:ryde_rw/theme/colors.dart';

Future<dynamic> openTripDetail(
  BuildContext context,
  User user,
  Map<String, dynamic> trip,
) {
  return Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => TripDetailScreen.fromTripMap(user: user, trip: trip),
    ),
  );
}

class TripDetailScreen extends ConsumerStatefulWidget {
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
  final User user;

  const TripDetailScreen({
    super.key,
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

  factory TripDetailScreen.fromTripMap({
    required User user,
    required Map<String, dynamic> trip,
  }) {
    return TripDetailScreen(
      tripId: tripStr(trip, 'tripId'),
      pickupAddress: tripStr(trip, 'pickupAddress').trim(),
      destinationAddress: tripStr(trip, 'destinationAddress').trim(),
      status: tripStr(trip, 'status').trim(),
      fare: trip['fare'],
      requestTime: tripStr(trip, 'requestTime'),
      pickupLat: tripDouble(trip, 'pickupLatitude'),
      pickupLng: tripDouble(trip, 'pickupLongitude'),
      destLat: tripDouble(trip, 'destinationLatitude'),
      destLng: tripDouble(trip, 'destinationLongitude'),
      user: user,
    );
  }

  @override
  ConsumerState<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends ConsumerState<TripDetailScreen> {
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
    await _tracker.startUploading(isDriver: widget.user.isDriver);
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
        final lat = tripDouble(driver, 'latitude');
        final lng = tripDouble(driver, 'longitude');
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
        final lat = tripDouble(passenger, 'latitude');
        final lng = tripDouble(passenger, 'longitude');
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip accepted — find it under My Trips')),
        );
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
        Navigator.pop(context, true);
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
        Navigator.pop(context, true);
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
    final isDriver = widget.user.isDriver;
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
                        child: _actionLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Accept trip'),
                      ),
                    ),
                  if (isDriver && _status == 'ACCEPTED')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _actionLoading ? null : _startTrip,
                        style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                        child: _actionLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Start trip'),
                      ),
                    ),
                  if (isDriver && _status == 'IN_PROGRESS')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _actionLoading ? null : _completeTrip,
                        style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                        child: _actionLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Complete trip'),
                      ),
                    ),
                  if (_status == 'REQUESTED' || _status == 'ACCEPTED') const SizedBox(height: 8),
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
