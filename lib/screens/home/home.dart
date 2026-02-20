import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ryde_rw/provider/current_location_provider.dart';
import 'package:ryde_rw/service/api_service.dart';
import 'package:ryde_rw/shared/shared_states.dart';
import 'package:ryde_rw/theme/colors.dart';
import 'package:ryde_rw/utils/contants.dart';

class Home extends ConsumerStatefulWidget {
  const Home({super.key});

  @override
  ConsumerState<Home> createState() => _HomeState();
}

class _HomeState extends ConsumerState<Home> {
  final _pickupController = TextEditingController();
  final _destinationController = TextEditingController();
  double? _pickupLat, _pickupLng, _destLat, _destLng;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _pickupLat = pos.latitude;
      _pickupLng = pos.longitude;
      final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      final p = placemarks.isNotEmpty ? placemarks.first : null;
      final addr = p != null ? '${p.street}, ${p.locality}, ${p.country}' : 'Current location';
      if (mounted) {
        setState(() {
          _pickupController.text = addr;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not get location');
    }
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  int _estimateFare(double km) {
    if (km <= 1) return 1500;
    if (km <= 30) return 1500 + ((km - 1) * 900).round();
    return 1500 + (29 * 900) + ((km - 30) * 700).round();
  }

  Future<void> _requestTrip() async {
    final user = ref.read(userProvider);
    if (user == null) return;
    if (user.userType != 'PASSENGER') {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only passengers can request a trip')),
      );
      return;
    }
    if (_pickupLat == null || _pickupLng == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Set pickup location (use current or enter address)')),
      );
      return;
    }
    String destAddress = _destinationController.text.trim();
    if (destAddress.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter destination address')),
      );
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final destList = await locationFromAddress(destAddress);
      if (destList.isEmpty) {
        if (mounted) setState(() { _loading = false; _error = 'Destination not found'; });
        return;
      }
      _destLat = destList.first.latitude;
      _destLng = destList.first.longitude;
      // Prefer Google Directions driving distance; fallback to haversine
      double distance = (await ApiService.getRouteDistanceKm(
        _pickupLat!, _pickupLng!, _destLat!, _destLng!,
        googleMapsApiKey: apiKey,
      )) ?? _haversine(_pickupLat!, _pickupLng!, _destLat!, _destLng!);
      final fare = _estimateFare(distance);
      await ApiService.requestTrip({
        'pickupLatitude': _pickupLat,
        'pickupLongitude': _pickupLng,
        'pickupAddress': _pickupController.text.trim(),
        'destinationLatitude': _destLat,
        'destinationLongitude': _destLng,
        'destinationAddress': destAddress,
        'distance': distance,
        'fare': fare.toDouble(),
      });
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip requested successfully')),
        );
        _destinationController.clear();
      }
    } catch (e) {
      if (mounted) setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // Kigali, Rwanda
  static const LatLng _kigaliCenter = LatLng(-1.9441, 30.0619);

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final locationAsync = ref.watch(currentLocationProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: locationAsync.when(
        data: (_) => Stack(
          children: [
            GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: _kigaliCenter,
                zoom: 14,
              ),
              markers: {
                if (_pickupLat != null && _pickupLng != null)
                  Marker(
                    markerId: const MarkerId('pickup'),
                    position: LatLng(_pickupLat!, _pickupLng!),
                  ),
                if (_destLat != null && _destLng != null)
                  Marker(
                    markerId: const MarkerId('dest'),
                    position: LatLng(_destLat!, _destLng!),
                  ),
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
            SafeArea(
              child: DraggableScrollableSheet(
                initialChildSize: 0.35,
                minChildSize: 0.2,
                maxChildSize: 0.5,
                builder: (context, scrollController) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        user.isPassenger ? 'Book a ride' : 'Your trips',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (user.isPassenger) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _pickupController,
                          decoration: InputDecoration(
                            labelText: 'Pickup',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.my_location),
                              onPressed: _useCurrentLocation,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _destinationController,
                          decoration: const InputDecoration(
                            labelText: 'Destination',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 8),
                          Text(_error!, style: const TextStyle(color: Colors.red)),
                        ],
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _requestTrip,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Request trip', style: TextStyle(color: Colors.white),),
                          ),
                        ),
                      ] else
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            'Open Trips tab to see and accept ride requests.',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        loading: () => Stack(
          children: [
            GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: _kigaliCenter,
                zoom: 14,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
            const Center(child: CircularProgressIndicator()),
          ],
        ),
        error: (e, _) => Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Location error: $e'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(currentLocationProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
