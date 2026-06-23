import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ryde_rw/provider/current_location_provider.dart';
import 'package:ryde_rw/service/payment_checkout_service.dart';
import 'package:ryde_rw/service/api_service.dart';
import 'package:ryde_rw/service/realtime_location_tracker.dart';
import 'package:ryde_rw/shared/shared_states.dart';
import 'package:ryde_rw/theme/colors.dart';
import 'package:ryde_rw/utils/contants.dart';

class Home extends ConsumerStatefulWidget {
  const Home({super.key});

  @override
  ConsumerState<Home> createState() => _HomeState();
}

class _HomeState extends ConsumerState<Home> with WidgetsBindingObserver {
  final _pickupController = TextEditingController();
  final _destinationController = TextEditingController();
  double? _pickupLat, _pickupLng, _destLat, _destLng;
  bool _loading = false;
  String? _error;
  String _selectedService = vehicleTypes.first;
  String? _pendingPaymentTripId;
  bool _checkingPendingPayment = false;
  final _tracker = RealtimeLocationTracker();
  Map<String, dynamic>? _liveLocations;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initTracking());
  }

  Future<void> _initTracking() async {
    final user = ref.read(userProvider);
    if (user == null) return;
    await _tracker.startUploading(isDriver: user.isDriver);
    await _loadActiveTripTracking();
  }

  Future<void> _loadActiveTripTracking() async {
    try {
      final res = await ApiService.getMyTrips();
      final active = findActiveTrip((res['trips'] as List?) ?? []);
      if (!mounted || active == null) return;
      final tripId = tripStr(active, 'tripId');
      if (tripId.isEmpty || !isTrackableTripStatus(tripStr(active, 'status'))) {
        return;
      }
      _tracker.startPolling(tripId, (loc) {
        if (!mounted) return;
        setState(() => _liveLocations = loc);
      });
    } catch (_) {}
  }

  Set<Marker> _buildMapMarkers(dynamic user) {
    final markers = <Marker>{
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
    };

    final loc = _liveLocations;
    if (loc == null) return markers;

    final driver = loc['driver'] as Map<String, dynamic>?;
    final passenger = loc['passenger'] as Map<String, dynamic>?;

    if (user.isPassenger && driver != null) {
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
              snippet: driver['name']?.toString() ?? 'Your driver',
            ),
          ),
        );
      }
    }

    if (user.isDriver && passenger != null) {
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

    return markers;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tracker.dispose();
    _pickupController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPendingPaymentIfNeeded();
    }
  }

  Future<void> _checkPendingPaymentIfNeeded() async {
    final tripId = _pendingPaymentTripId;
    if (!mounted || tripId == null) return;
    if (_checkingPendingPayment) return;
    setState(() => _checkingPendingPayment = true);
    try {
      final outcome = await _waitForTripPaymentCompleted(tripId);
      if (!mounted) return;
      final msg = outcome == 'COMPLETED'
          ? 'Payment successful!'
          : outcome == 'FAILED'
              ? 'Payment failed or was cancelled.'
              : 'Payment is processing. Please check again shortly.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      if (outcome == 'COMPLETED' || outcome == 'FAILED') {
        _pendingPaymentTripId = null;
        if (outcome == 'COMPLETED') {
          await _loadActiveTripTracking();
        }
      }
    } catch (_) {
      // Ignore transient errors on resume; user can retry by resuming again.
    } finally {
      if (mounted) setState(() => _checkingPendingPayment = false);
    }
  }

  Future<void> _useCurrentLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
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
      if (mounted) {
        setState(() => _error = 'Could not get location');
      }
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

  String iconPath(String type) {
    switch (type) {
      case 'Taxi/Cab':
        return 'assets/icons/1.png';
      case 'Moto':
        return 'assets/icons/3.png';
      case 'Truck':
        return 'assets/icons/2.png';
      case 'Three Wheels':
        return 'assets/icons/4.png';
      default:
        return 'assets/icons/1.png';
    }
  }

  Future<String> _waitForTripPaymentCompleted(String tripId, {int maxMs = 45000}) async {
    final start = DateTime.now();
    while (DateTime.now().difference(start).inMilliseconds < maxMs) {
      final res = await ApiService.getPaymentByTrip(tripId);
      final payment = (res['payment'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
      final status = (payment['payment_status'] ?? '').toString().toUpperCase();
      if (status == 'COMPLETED') return 'COMPLETED';
      if (status == 'FAILED') return 'FAILED';
      await Future.delayed(const Duration(seconds: 2));
    }
    return 'TIMEOUT';
  }

  Future<void> _payNow() async {
    final user = ref.read(userProvider);
    if (user == null) {
      return;
    }
    if (user.userType != 'PASSENGER') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Only passengers can request a trip')),
        );
      }
      return;
    }
    if (_pickupLat == null || _pickupLng == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Set pickup location (use current or enter address)')),
        );
      }
      return;
    }
    String destAddress = _destinationController.text.trim();
    if (destAddress.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter destination address')),
        );
      }
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
      final tripRes = await ApiService.requestTrip({
        'pickupLatitude': _pickupLat,
        'pickupLongitude': _pickupLng,
        'pickupAddress': _pickupController.text.trim(),
        'destinationLatitude': _destLat,
        'destinationLongitude': _destLng,
        'destinationAddress': destAddress,
        'distance': distance,
        'fare': fare.toDouble(),
        'serviceType': _selectedService, // all orders are instant now
      });

      final trip = (tripRes['trip'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
      final tripId = (trip['trip_id'] ?? trip['tripId'] ?? '').toString();
      if (tripId.isEmpty) {
        throw Exception('Trip created but missing trip id');
      }

      final paymentRes = await ApiService.getPaymentByTrip(tripId);
      final payment = (paymentRes['payment'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
      final paymentId = (payment['payment_id'] ?? payment['paymentId'] ?? '').toString();
      if (paymentId.isEmpty) {
        throw Exception('Payment record not found for this trip');
      }

      final invoiceRes = await ApiService.createPaymentInvoice(paymentId);
      final invoiceNumber = (invoiceRes['invoiceNumber'] ?? '').toString();
      if (invoiceNumber.isEmpty) {
        throw Exception('Could not create payment invoice');
      }

      if (mounted) {
        setState(() => _loading = false);
      }

      if (!mounted) {
        return;
      }

      _pendingPaymentTripId = tripId;
      await _loadActiveTripTracking();

      if (!mounted) return;

      final checkoutUrl = PaymentCheckoutService.resolveCheckoutUrl(invoiceRes);
      final payResult = await PaymentCheckoutService.openCheckout(context, checkoutUrl);

      if (!mounted) return;

      if (payResult?.ok == true) {
        final outcome = await _waitForTripPaymentCompleted(tripId);
        if (!mounted) return;
        final msg = outcome == 'COMPLETED'
            ? 'Payment successful!'
            : outcome == 'FAILED'
                ? 'Payment failed or was cancelled.'
                : 'Payment is processing. Please check again shortly.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        if (outcome == 'COMPLETED' || outcome == 'FAILED') {
          _pendingPaymentTripId = null;
        }
        _destinationController.clear();
      } else if (payResult?.ok == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment was cancelled or failed. You can try again.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment opened in your browser. Return here when finished.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        var message = e.toString().replaceFirst('Exception: ', '');
        if (message.toLowerCase().contains('irembopay') &&
            message.toLowerCase().contains('not configured')) {
          message =
              'Could not start payment on this API server. The app opens '
              'https://ryde-backend-production.up.railway.app for checkout — '
              'run without --dart-define=API_BASE_URL or configure IremboPay on your backend.';
        }
        setState(() {
          _loading = false;
          _error = message;
        });
      }
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
              markers: _buildMapMarkers(user),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
            if (_liveLocations != null && isTrackableTripStatus(tripStr(_liveLocations!, 'status')))
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 8, color: Colors.white),
                      SizedBox(width: 6),
                      Text('Live tracking', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
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
                        user.isPassenger ? 'Get a ride' : 'Your trips',
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
                        InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Service',
                            border: OutlineInputBorder(),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedService,
                              isExpanded: true,
                              items: vehicleTypes.map((t) {
                                return DropdownMenuItem<String>(
                                  value: t,
                                  child: Row(
                                    children: [
                                      Image.asset(iconPath(t), width: 22, height: 22),
                                      const SizedBox(width: 10),
                                      Text(t),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: _loading ? null : (v) {
                                if (v == null) return;
                                setState(() => _selectedService = v);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _payNow,
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
                                : const Text('Pay Now', style: TextStyle(color: Colors.white),),
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
