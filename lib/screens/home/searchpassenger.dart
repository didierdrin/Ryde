import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../home/searchpassengers.dart';
import '../home/searchpooler.dart';
import 'package:ryde_rw/shared/locations_shared.dart';
import 'package:ryde_rw/shared/shared_states.dart';
import 'package:url_launcher/url_launcher.dart';

class SearchPassengers extends ConsumerWidget {
  const SearchPassengers({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = ref.read(locationProvider);
    final myLocation = Location.fromData(l);
    return SearchPassengersListPage(
      driverStartLocation: myLocation,
      driverEndLocation: myLocation,
    );
  }
}
