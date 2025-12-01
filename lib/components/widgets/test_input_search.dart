import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
// import 'package:map_autocomplete_field/map_autocomplete_field.dart';
import 'package:ryde_rw/components/widgets/color_button.dart';
import 'package:ryde_rw/service/address_service.dart';
import 'package:ryde_rw/service/location_service.dart';
import 'package:ryde_rw/service/place_name_service.dart';
import 'package:ryde_rw/service/place_services.dart';
import 'package:ryde_rw/shared/shared_states.dart';
import 'package:ryde_rw/theme/colors.dart';
import 'package:ryde_rw/utils/contants.dart';
import 'package:ryde_rw/utils/utils.dart';

class LocationModal extends ConsumerStatefulWidget {
  final Function(Map<String, dynamic>) onLocationSelected;
  final Future<Map<String, dynamic>> Function() fetchCurrentLocation;
  final bool iscurrentLocation;
  final String? selectedAddress;

  const LocationModal({
    super.key,
    required this.onLocationSelected,
    required this.fetchCurrentLocation,
    required this.iscurrentLocation,
    this.selectedAddress,
  });

  @override
  ConsumerState<LocationModal> createState() => _LocationModalState();
}

class _LocationModalState extends ConsumerState<LocationModal> {
  LatLng? _selectedLocation;
  String? _selectedAddress;
  GoogleMapController? _mapController;
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);

  final TextEditingController searchController = TextEditingController();
  double lat = 0.0;
  double long = 0.0;

  final List icons = [Icons.home, Icons.shop, Icons.escalator_warning_outlined];

  @override
  void initState() {
    super.initState();

    if (widget.selectedAddress != null && widget.selectedAddress!.isNotEmpty) {
      searchController.value = TextEditingValue(
        text: widget.selectedAddress ?? "",
      );
      _setLocationFromSearch(widget.selectedAddress ?? "");
      _selectedAddress = widget.selectedAddress;
    } else {
      final location = ref.read(locationProvider);
      if (location.isNotEmpty) {
        final lat = location['lat'];
        final long = location['long'];
        if (lat != null && long != null) {
          _selectedLocation = LatLng(lat, long);
          fetchAddress(_selectedLocation!);
        }
      }
    }
  }

  Future<void> _setLocationFromSearch(
    String query, {
    bool noMove = false,
  }) async {
    try {
      final place = await PlacesService.getPlaceDetails(query);

      if (place != null) {
        final location = place['geometry']['location'];
        LatLng latLng = LatLng(location['lat'], location['lng']);
        final address = place['name'];

        setState(() {
          if (!noMove) _selectedLocation = latLng;
          _selectedAddress = address;
          searchController.text = address;
        });

        if (_mapController != null && !noMove) {
          _mapController!.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
        }
      }
    } catch (e) {
      debugPrint('Error setting location from search: $e');
    }
  }

  void _onCameraMove(CameraPosition position) {
    setState(() {
      _selectedLocation = position.target;
      lat = position.target.latitude;
      long = position.target.longitude;
    });
  }

  Widget _buildGoogleMap() {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.35,
      child: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(
              target: _selectedLocation ?? const LatLng(0.0, 0.0),
              zoom: 15,
            ),
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              if (_selectedLocation != null) {
                controller.animateCamera(
                  CameraUpdate.newLatLngZoom(_selectedLocation!, 15),
                );
              }
            },
            onCameraMove: _onCameraMove,
            onCameraIdle: () async {
              if (_selectedLocation != null) {
                final placeId =
                    await PlacesService.fetchPlaceIdFromNearbySearch(
                      _selectedLocation!.latitude,
                      _selectedLocation!.longitude,
                    );
                await _setLocationFromSearch(placeId, noMove: true);
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
              Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
              Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
              Factory<VerticalDragGestureRecognizer>(
                () => VerticalDragGestureRecognizer(),
              ),
            },
          ),
          // Centered pin
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/map_pin.png', height: 50, width: 50),
                const SizedBox(height: 25),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.read(userProvider);
    // final region = ref.watch(regionProvider);
    final addressesAsync = ref.watch(
      addressesProvider(user?.phoneNumber ?? ''),
    );

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
              bottom: !widget.iscurrentLocation
                  ? MediaQuery.of(context).viewInsets.bottom
                  : 0,
            ),
            child: TypeAheadField(
              controller: searchController,
              builder: (context, controller, focusNode) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
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
                return await PlaceServices.placeSuggestions(
                  user?.countryCode ?? "+250",
                  pattern,
                );
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
                    data['description']?.toString() ?? '',
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
                searchController.text = data['description']?.toString() ?? '';
                _setLocationFromSearch(data['place_id']?.toString() ?? '');
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
          _buildGoogleMap(),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    if (widget.iscurrentLocation) const SizedBox(height: 16),
                    if (widget.iscurrentLocation)
                      if (_selectedAddress != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            "Selected Address: $_selectedAddress",
                            style: GoogleFonts.poppins(fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    const SizedBox(height: 16),
                    if (_selectedLocation != null)
                      GestureDetector(
                        onTap: () {
                          widget.onLocationSelected({
                            'latitude': _selectedLocation!.latitude,
                            'longitude': _selectedLocation!.longitude,
                            'address': _selectedAddress ?? 'Selected address',
                          });
                          if (Navigator.of(context).canPop()) {
                            Navigator.pop(context);
                          }
                        },
                        child: const ColorButton('Confirm address'),
                      ),
                    const SizedBox(height: 30),
                    Text(
                      "Use saved address",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 30),
                    if (user != null)
                      addressesAsync.when(
                        data: (addresses) {
                          if (addresses.isEmpty) {
                            return const Padding(
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
                            );
                          }
                          return ListView.builder(
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
                                    widget.onLocationSelected({
                                      'latitude':
                                          address?.location?['latitude'],
                                      'longitude':
                                          address?.location?['longitude'],
                                      'address':
                                          address?.addressString ?? 'Unknown',
                                    });
                                    if (Navigator.of(context).canPop()) {
                                      Navigator.pop(context);
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
                                    address?.addressString ??
                                        "No address saved",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: kGreyColor,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, stack) => Center(
                          child: Text(
                            'Error loading addresses',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
