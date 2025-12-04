import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:map_autocomplete_field/map_autocomplete_field.dart';
import 'package:ryde_rw/components/widgets/color_button.dart';
import 'package:ryde_rw/models/address_model.dart';
import 'package:ryde_rw/service/address_service.dart';
import 'package:ryde_rw/service/place_services.dart';
import 'package:ryde_rw/shared/locations_shared.dart';
import 'package:ryde_rw/shared/shared_states.dart';
import 'package:ryde_rw/theme/colors.dart';
import 'package:ryde_rw/utils/contants.dart';
import 'package:ryde_rw/utils/utils.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:ryde_rw/provider/current_location_provider.dart';
import 'package:geolocator/geolocator.dart';

class LocationSearchModal extends ConsumerStatefulWidget {
  final bool destination;
  final Location? location;
  final bool useCurrent;
  final Function(Location) onLocationSelected;
  const LocationSearchModal({
    required this.destination,
    required this.onLocationSelected,
    required this.location,
    this.useCurrent = false,
    super.key,
  });

  @override
  LocationSearchModalState createState() => LocationSearchModalState();
}

class LocationSearchModalState extends ConsumerState<LocationSearchModal> {
  GoogleMapController? mapController;
  Location? location;
  String? address;
  LatLng? selectedLocation;
  final TextEditingController searchController = TextEditingController();
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  bool preventOnCameraIdle = false;
  final List icons = [Icons.home, Icons.shop, Icons.escalator_warning_outlined];

  @override
  void initState() {
    super.initState();
    if (widget.location != null) {
      location = widget.location;
      searchController.text = widget.location?.address ?? '';
    }
  }

  Future<void> setLocationFromSearch(
    String query, {
    bool noMove = false,
    String? description,
  }) async {
    try {
      if (description != null) {
        setState(() {
          preventOnCameraIdle = true;
        });
      }
      final place = await PlaceServices.getPlaceDetails(query);

      if (place != null) {
        final placeLocation = place['geometry']['location'];
        LatLng latLng = LatLng(placeLocation['lat'], placeLocation['lng']);
        final d = description ?? place['name'];
        setState(() {
          address = d;
          location = Location(
            address: d,
            latitude: latLng.latitude,
            longitude: latLng.longitude,
          );
          searchController.text = d;
          if (!noMove) selectedLocation = latLng;
        });

        if (mapController != null && !noMove) {
          mapController!.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
        }
      }
      await Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          preventOnCameraIdle = false;
        });
      });
    } catch (e) {
      debugPrint('Error setting location from search: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.read(userProvider);
    // final region = ref.watch(regionProvider);
    final code = user?.countryCode ?? "+250";
    print('User country code: $code');
    Map<String, Address> addresses = {};
    if (user != null) {
      final addressesStream = ref.watch(addressesProvider(user.phoneNumber));
      addresses = addressesStream.value ?? {};
    }
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Select Location",
              style: GoogleFonts.poppins(fontSize: 18, letterSpacing: 1.5),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: 16.0,
              right: 16,
              bottom: !widget.destination
                  ? MediaQuery.of(context).viewInsets.bottom
                  : 0,
            ),
            child: TypeAheadField(
              controller: searchController,
              builder: (context, controller, focusNode) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      setState(() {
                        address = value.trim();
                        location = Location(
                          address: value.trim(),
                          latitude: -1.9441,
                          longitude: 30.0619,
                        );
                        selectedLocation = LatLng(-1.9441, 30.0619);
                      });
                      if (mapController != null) {
                        mapController!.animateCamera(
                          CameraUpdate.newLatLngZoom(LatLng(-1.9441, 30.0619), 15),
                        );
                      }
                    }
                  },
                  decoration: InputDecoration(
                    filled: true,
                    isDense: false,
                    contentPadding: const EdgeInsets.only(top: 15),
                    prefixIcon: Icon(
                      Icons.location_on,
                      color: Colors.blueAccent,
                      size: 24,
                    ),
                    hintText: "Search location",
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
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
                try {
                  // Convert phone code to country code
                  String countryCode = 'RW'; // Default to Rwanda
                  if (code == '+250') countryCode = 'RW';
                  else if (code == '+1') countryCode = 'US';
                  else if (code == '+44') countryCode = 'GB';
                  else if (code == '+33') countryCode = 'FR';
                  
                  final results = await PlaceServices.placeSuggestions(countryCode, pattern);
                  print('Search results for "$pattern": ${results.length} found');
                  return results;
                } catch (e) {
                  print('Error in placeSuggestions: $e');
                  return [];
                }
              },
              itemBuilder: (context, suggestion) {
                final data = suggestion as Map<String, dynamic>;
                return ListTile(
                  leading: Icon(
                    Icons.location_on,
                    color: Colors.blueAccent,
                    size: 24,
                  ),
                  title: Text(
                    data['description'] ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    "Tap to select location",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  tileColor: Colors.grey.shade100,
                );
              },
              onSelected: (suggestion) {
                final data = suggestion as Map<String, dynamic>;
                searchController.text = data['description'] ?? '';
                setLocationFromSearch(
                  data['place_id'],
                  description: data['description'],
                );
                FocusScope.of(context).requestFocus(FocusNode());
              },
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
          const SizedBox(height: 16),
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.35,
            child: Stack(
              children: [
                Consumer(
                  builder: (context, ref, child) {
                    final currentLocationAsync = ref.watch(currentLocationProvider);
                    
                    return currentLocationAsync.when(
                      data: (currentLocation) {
                        return GoogleMap(
                          mapType: MapType.normal,
                          initialCameraPosition: CameraPosition(
                            target: location?.latLng() ?? currentLocation,
                            zoom: 15,
                          ),
                          onMapCreated: (GoogleMapController controller) {
                            mapController = controller;
                            if (location != null) {
                              controller.animateCamera(
                                CameraUpdate.newLatLngZoom(location!.latLng(), 15),
                              );
                            }
                          },
                          onCameraMove: (position) {
                            setState(() {
                              selectedLocation = position.target;
                            });
                          },
                          onCameraIdle: () async {
                            if (preventOnCameraIdle) return;
                            if (selectedLocation != null) {
                              final placeId =
                                  await PlaceServices.placeIdFromNearbySearch(
                                    selectedLocation!.latitude,
                                    selectedLocation!.longitude,
                                  );
                              await setLocationFromSearch(placeId, noMove: true);
                            }
                          },
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                          zoomControlsEnabled: true,
                          zoomGesturesEnabled: true,
                          scrollGesturesEnabled: true,
                          rotateGesturesEnabled: true,
                          tiltGesturesEnabled: true,
                          compassEnabled: true,
                          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                            Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
                            Factory<ScaleGestureRecognizer>(
                              () => ScaleGestureRecognizer(),
                            ),
                            Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
                            Factory<VerticalDragGestureRecognizer>(
                              () => VerticalDragGestureRecognizer(),
                            ),
                          },
                        );
                      },
                      loading: () => Container(
                        color: Colors.grey[300],
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (error, stack) => Container(
                        color: Colors.grey[300],
                        child: Center(
                          child: Text('Error loading map: $error'),
                        ),
                      ),
                    );
                  },
                ),

                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/pin.png', height: 50, width: 50),
                      const SizedBox(height: 25),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    if (widget.destination) const SizedBox(height: 16),
                    if (widget.destination)
                      if (location != null || address != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            "Selected Address: ${location?.address ?? address}",
                            style: GoogleFonts.poppins(fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    const SizedBox(height: 16),
                    if (widget.useCurrent) ...[
                      const SizedBox(height: 30),
                      GestureDetector(
                        onTap: () async {
                          try {
                            final position = await Geolocator.getCurrentPosition(
                              desiredAccuracy: LocationAccuracy.high,
                            );
                            final currentLocation = Location(
                              address: 'Current Location',
                              latitude: position.latitude,
                              longitude: position.longitude,
                            );
                            widget.onLocationSelected(currentLocation);
                            if (Navigator.of(context).canPop()) {
                              Navigator.pop(context);
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error getting current location: $e')),
                            );
                          }
                        },
                        child: const ColorButton('Use Current Location'),
                      ),
                    ],
                    const SizedBox(height: 30),
                    Text(
                      "Use saved address",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 30),
                    if (addresses.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 60),
                        child: Center(
                          child: Text(
                            "No addresses found",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                      ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: addresses.length,
                      itemBuilder: (BuildContext context, int index) {
                        final addressType = getAddressType(index);
                        final address = addresses[addressType];

                        return Container(
                          margin: EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 0.5,
                            ),
                          ),
                          child: ListTile(
                            onTap: () {
                              if (address != null) {
                                setState(() {
                                  location = Location(
                                    address: address.addressString,
                                    latitude: address.location!['latitude']!,
                                    longitude: address.location!['longitude']!,
                                  );
                                });
                                widget.onLocationSelected(location!);
                                if (Navigator.of(context).canPop()) {
                                  Navigator.pop(context);
                                }
                              }
                            },
                            leading: Icon(
                              icons[index],
                              color: primaryColor,
                              size: 22,
                            ),
                            title: Text(
                              capitalizeFirstLetter(address?.type ?? ''),
                              style: GoogleFonts.poppins(fontSize: 14),
                            ),
                            subtitle: Text(
                              address?.addressString ?? "No address saved",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: kGreyColor,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (widget.destination && (location != null || address != null))
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: GestureDetector(
                  onTap: () {
                    if (location != null) {
                      widget.onLocationSelected(location!);
                      if (Navigator.of(context).canPop()) {
                        Navigator.pop(context);
                      }
                    }
                  },
                  child: const ColorButton('Confirm Drop-off Location'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

