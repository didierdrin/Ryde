import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ryde_rw/service/api_service.dart';
import 'package:ryde_rw/theme/colors.dart';

class MechanicsScreen extends StatefulWidget {
  const MechanicsScreen({super.key});

  @override
  State<MechanicsScreen> createState() => _MechanicsScreenState();
}

class _MechanicsScreenState extends State<MechanicsScreen> {
  List<dynamic> _mechanics = [];
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
      final res = await ApiService.getMechanics(lat, lng);
      setState(() => _mechanics = (res['mechanics'] as List?) ?? []);
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
        title: const Text('Find Mechanics'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _mechanics.isEmpty
              ? const Center(child: Text('No mechanics found nearby.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _mechanics.length,
                  itemBuilder: (context, index) {
                    final m = _mechanics[index] as Map<String, dynamic>;
                    final rating = (m['rating'] as num?)?.toDouble();
                    final distance = (m['distanceKm'] as num?)?.toDouble();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    m['name']?.toString() ?? '',
                                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                if (rating != null)
                                  Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 18),
                                      Text(rating.toStringAsFixed(1)),
                                    ],
                                  ),
                              ],
                            ),
                            if (m['specialty'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  m['specialty'].toString(),
                                  style: TextStyle(color: primaryColor, fontWeight: FontWeight.w500, fontSize: 13),
                                ),
                              ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.location_on_outlined, size: 18, color: kSimpleText),
                                const SizedBox(width: 6),
                                Expanded(child: Text(m['address']?.toString() ?? '', style: TextStyle(color: kSimpleText, fontSize: 13))),
                              ],
                            ),
                            if (distance != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 6, left: 24),
                                child: Text('$distance km away', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 13)),
                              ),
                            if (m['phoneNumber'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  children: [
                                    Icon(Icons.phone, size: 16, color: kSimpleText),
                                    const SizedBox(width: 6),
                                    Text(m['phoneNumber'].toString(), style: TextStyle(color: kSimpleText, fontSize: 13)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
