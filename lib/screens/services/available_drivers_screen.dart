import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ryde_rw/service/api_service.dart';
import 'package:ryde_rw/theme/colors.dart';

class AvailableDriversScreen extends StatefulWidget {
  const AvailableDriversScreen({super.key});

  @override
  State<AvailableDriversScreen> createState() => _AvailableDriversScreenState();
}

class _AvailableDriversScreenState extends State<AvailableDriversScreen> {
  List<dynamic> _drivers = [];
  bool _loading = true;

  static const _defaultLat = -1.9441;
  static const _defaultLng = 30.0619;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    double lat = _defaultLat;
    double lng = _defaultLng;
    try {
      final pos = await Geolocator.getCurrentPosition();
      lat = pos.latitude;
      lng = pos.longitude;
    } catch (_) {}

    try {
      final res = await ApiService.getNearbyDrivers(lat, lng);
      setState(() => _drivers = (res['drivers'] as List?) ?? []);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Available Drivers'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _drivers.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No available drivers nearby. Only verified, online drivers are shown.'),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _drivers.length,
                  itemBuilder: (context, index) {
                    final d = _drivers[index] as Map<String, dynamic>;
                    final vehicle = d['vehicle'] as Map<String, dynamic>?;
                    final distance = (d['distanceKm'] as num?)?.toDouble();
                    final age = d['ageYears'];
                    final experience = d['yearsExperience'];
                    final rating = (d['rating'] as num?)?.toDouble();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: primaryColor.withOpacity(0.15),
                                  child: Icon(Icons.person, color: primaryColor),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        d['name']?.toString() ?? 'Driver',
                                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                      ),
                                      if (rating != null)
                                        Text('★ ${rating.toStringAsFixed(1)} • ${d['totalTrips'] ?? 0} trips',
                                            style: TextStyle(color: kSimpleText, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                if (distance != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text('$distance km', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 12)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.location_on_outlined, size: 18, color: kSimpleText),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    d['address']?.toString() ?? 'Address not provided',
                                    style: TextStyle(color: kSimpleText, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (age != null)
                                  _chip(Icons.cake_outlined, '$age years old'),
                                if (experience != null)
                                  _chip(Icons.work_outline, '$experience yrs experience'),
                              ],
                            ),
                            if (vehicle != null) ...[
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: kLightGreyColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.directions_car, size: 18, color: primaryColor),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${vehicle['make']} ${vehicle['model']} (${vehicle['year']}) • ${vehicle['color']}',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: kLightGreyColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: kSimpleText),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
