import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../home/searchpooler.dart';
import 'package:ryde_rw/shared/locations_shared.dart';
import 'package:ryde_rw/shared/shared_states.dart';

class Searchdrivers extends ConsumerWidget {
  const Searchdrivers({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = ref.read(locationProvider);
    
    // Handle null or incomplete location data
    if (l == null || !l.containsKey('lat') || !l.containsKey('long')) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Getting your location...'),
          ],
        ),
      );
    }
    
    final myLocation = Location.fromData(l);
    return OfferPoolListPage(
      driverStartLocation: myLocation,
      driverEndLocation: myLocation,
    );
  }
}

