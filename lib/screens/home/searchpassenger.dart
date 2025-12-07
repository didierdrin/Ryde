import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../home/searchpassengers.dart';

class SearchPassengers extends ConsumerWidget {
  const SearchPassengers({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SearchPassengersListPage();
  }
}

