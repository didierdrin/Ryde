import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:ryde_rw/theme/colors.dart';
import 'package:ryde_rw/utils/contants.dart';
import 'package:ryde_rw/service/place_services.dart';
import 'package:ryde_rw/shared/shared_states.dart';

class LocationAutocompleteFieldSelect extends ConsumerStatefulWidget {
  final TextEditingController controller;
  // final Function(Map<String, dynamic> locationData) onSuggestionSelected;
  final Function(Map<String, dynamic>) onSuggestionSelected;
  final TextStyle? hintStyle;
  final TextCapitalization textCapitalization;
  final bool readOnly;
  final int? maxLength;
  final TextInputType keyboardType;
  final int maxLines;
  final String? label;
  final String? hint;
  final Widget? prefix;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final InputBorder? border;
  final String? image;
  final Function(BuildContext)? onTap;
  final bool destination;

  const LocationAutocompleteFieldSelect({
    super.key,
    required this.controller,
    required this.onSuggestionSelected,
    this.hintStyle,
    this.textCapitalization = TextCapitalization.sentences,
    this.readOnly = false,
    this.maxLength,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.label,
    this.hint,
    this.prefix,
    this.prefixIcon,
    this.suffixIcon,
    this.border,
    this.image,
    this.onTap,
    this.destination = false,
  });

  @override
  LocationAutocompleteFieldState createState() =>
      LocationAutocompleteFieldState();
}

class LocationAutocompleteFieldState
    extends ConsumerState<LocationAutocompleteFieldSelect> {
  double? currentLatitude;
  double? currentLongitude;
  String? currentAddress;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _openLocationModal(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.8,
          ),
          // child: LocationSearchModal(
          //   destination: widget.destination,
          //   onLocationSelected: (Map<String, dynamic> locationData) {
          //     widget.controller.text = locationData['address'];
          //     widget.onSuggestionSelected(locationData);
          //     setState(() {
          //       currentLatitude = locationData['latitude'];
          //       currentLongitude = locationData['longitude'];
          //       currentAddress = locationData['address'];
          //     });
          //     print(currentAddress);
          //     print(currentLatitude);
          //     if (Navigator.of(context).canPop()) {
          //       Navigator.pop(context);
          //     }
          //   },
          //   selectedAddress: currentAddress,
          //   selectedLocation:
          //       (currentLatitude != null && currentLongitude != null)
          //           ? LatLng(currentLatitude!, currentLongitude!)
          //           : null,
          // ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
      child: GestureDetector(
        onTap: () => _openLocationModal(context),
        child: AbsorbPointer(
          child: TypeAheadField<Map<String, dynamic>>(
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
                  prefix: widget.prefix,
                  prefixIcon: widget.prefixIcon,
                  suffixIcon: widget.suffixIcon,
                  labelText: widget.label,
                  hintText: widget.hint,
                  hintStyle: widget.hintStyle,
                  border:
                      widget.border ??
                      UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                  enabledBorder:
                      widget.border ??
                      UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                  focusedBorder:
                      widget.border ??
                      UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                ),
              );
            },
            suggestionsCallback: (pattern) async {
              if (pattern.length < 2) return [];
              final user = ref.read(userProvider);
              // final region = ref.read(regionProvider);
              final code = user?.countryCode ?? "+250";
              return await PlaceServices.placeSuggestions(code, pattern);
            },
            itemBuilder: (context, suggestion) {
              final data = suggestion;
              return Container(
                color: Colors.grey[200],
                child: ListTile(
                  leading: const Icon(
                    Icons.location_on,
                    color: Color.fromARGB(255, 75, 138, 55),
                  ),
                  title: Text(
                    data['description'] ?? "No description available",
                    style: const TextStyle(fontSize: 12.0),
                  ),
                ),
              );
            },
            onSelected: widget.onSuggestionSelected,
            emptyBuilder: (context) => Container(
              height: 50,
              child: Center(
                child: Text(
                  'No locations found',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Location Permission Denied"),
          content: Text("Please allow location access to use this feature."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void showPermissionDeniedForeverDialog() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon at the top
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_off_outlined,
                  color: Colors.redAccent,
                  size: 30,
                ),
              ),
              SizedBox(height: 16),
              // Title
              Text(
                "Permission Denied",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
              SizedBox(height: 8),
              // Message
              Text(
                "You have permanently denied location access. Please enable it in your device settings to use this feature.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  fontWeight: FontWeight.w300,
                ),
              ),
              SizedBox(height: 24),
              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await Geolocator.openAppSettings();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kMainColor,
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: Icon(Icons.settings, color: Colors.white),
                    label: Text(
                      "Open Settings",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      side: BorderSide(
                        color: Colors.redAccent.withOpacity(0.1),
                      ),
                    ),
                    icon: Icon(Icons.close, color: Colors.redAccent),
                    label: Text(
                      "Cancel",
                      style: GoogleFonts.poppins(color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Error"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }
}
