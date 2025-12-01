import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:ryde_rw/service/place_services.dart';
import 'package:ryde_rw/shared/shared_states.dart';
import 'package:ryde_rw/theme/colors.dart';
import 'package:ryde_rw/utils/contants.dart';

class LocationTypeAheadField extends ConsumerStatefulWidget {
  final Function(dynamic) onSelected;
  final bool readOnly;
  final String? hint;
  final Widget? suffixIcon;
  final TextEditingController controller;

  const LocationTypeAheadField({
    super.key,
    required this.onSelected,
    this.readOnly = false,
    this.hint,
    this.suffixIcon,
    required this.controller,
  });

  @override
  LocationTypeAheadFieldState createState() => LocationTypeAheadFieldState();
}

class LocationTypeAheadFieldState
    extends ConsumerState<LocationTypeAheadField> {
  @override
  Widget build(BuildContext context) {
    final user = ref.read(userProvider);
    // final region = ref.read(regionProvider);
    final code = user?.countryCode ?? "+250";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
      child: TypeAheadField(
        controller: widget.controller,
        builder: (context, controller, focusNode) {
          return TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: !widget.readOnly,
            decoration: InputDecoration(
              filled: true,
              isDense: false,
              contentPadding: const EdgeInsets.only(top: 15),
              prefixIcon: Icon(
                Icons.location_on,
                color: primaryColor,
                size: 20,
              ),
              suffixIcon: widget.suffixIcon,
              hintText: widget.hint,
              hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: const Color(0xffb2b2b2),
                fontSize: 13.5,
              ),
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
            ),
          );
        },
        suggestionsCallback: (pattern) async {
          if (pattern.length < 2) return [];
          return await PlaceServices.placeSuggestions(code, pattern);
        },
        itemBuilder: (context, suggestion) {
          final data = suggestion as Map<String, dynamic>;
          return ListTile(
            leading: const Icon(Icons.location_on, color: Colors.blueAccent),
            title: Text(
              data['description'] ?? '',
              style: const TextStyle(fontSize: 12.0),
            ),
            tileColor: Colors.grey[200],
          );
        },
        onSelected: widget.onSelected,
        emptyBuilder: (context) => Container(
          height: 50,
          child: const Center(child: Text('No locations found')),
        ),
      ),
    );
  }
}
