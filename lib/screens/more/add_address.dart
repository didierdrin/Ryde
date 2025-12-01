import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:ryde_rw/components/widgets/color_button.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

import 'package:ryde_rw/components/widgets/radio_widget.dart';
import 'package:ryde_rw/map_utils.dart';
import 'package:ryde_rw/service/place_services.dart';
import 'package:ryde_rw/shared/locations_shared.dart';
import 'package:ryde_rw/shared/shared_states.dart';
import 'package:ryde_rw/theme/colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ryde_rw/models/address_model.dart';
import 'package:ryde_rw/service/address_service.dart';
import 'package:google_fonts/google_fonts.dart';

class AddAddress extends ConsumerStatefulWidget {
  final int? defaultIndex;
  final Map<String, Address> addresses;
  const AddAddress({super.key, this.defaultIndex, required this.addresses});

  @override
  AddAddressState createState() => AddAddressState();
}

class AddAddressState extends ConsumerState<AddAddress> {
  int? activeIndex;
  Location? location;
  LatLng? selectedLocation;
  final TextEditingController addressController = TextEditingController();
  Map<String, Address> addresses = {};
  final Completer<GoogleMapController> _mapController = Completer();
  GoogleMapController? mapStyleController;
  bool _isSnackBarVisible = false, isLoading = false;

  @override
  void initState() {
    super.initState();
    activeIndex = widget.defaultIndex;

    final type = getAddressType(widget.defaultIndex);
    final address = widget.addresses[type];
    if (widget.defaultIndex != null && address != null) {
      location = Location(
        address: address.addressString,
        latitude: address.location!['latitude']!,
        longitude: address.location!['longitude']!,
      );
      addressController.text = location!.address;
      selectedLocation = location!.latLng();
    } else {
      final myLocation = ref.read(locationProvider);
      if (myLocation.containsKey('lat') && myLocation.containsKey('long')) {
        selectedLocation = LatLng(myLocation['lat'], myLocation['long']);
      }
    }
  }

  @override
  void dispose() {
    addressController.dispose();
    super.dispose();
  }

  void showSnackBar(BuildContext context, String message, {Color? color}) {
    if (!_isSnackBarVisible) {
      _isSnackBarVisible = true;
      ScaffoldMessenger.of(context)
          .showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: color ?? Colors.red,
            ),
          )
          .closed
          .then((_) {
            _isSnackBarVisible = false;
          });
    }
  }

  String? getAddressType(int? value) {
    switch (value) {
      case 1:
        return 'home';
      case 2:
        return 'office';
      case 3:
        return 'other';
      default:
        return null;
    }
  }

  void updateAddressField(int? value) {
    FocusScope.of(context).unfocus();
    setState(() {
      activeIndex = value;
    });
  }

  bool didChange() {
    return activeIndex != null && location != null;
  }

  Future<void> updateAddress() async {
    setState(() {
      isLoading = true;
    });
    late String type;
    switch (activeIndex) {
      case 1:
        type = 'home';
        break;
      case 2:
        type = 'office';
        break;
      case 3:
        type = 'other';
        break;
      default:
        return;
    }

    try {
      final user = ref.watch(userProvider)!;
      await AddressService.saveAddress(
        phoneNumber: user.phoneNumber,
        addressString: addressController.text,
        type: type,
        location: {
          'latitude': location!.latitude,
          'longitude': location!.longitude,
        },
      );

      Navigator.pop(context);
    } catch (e) {
      showSnackBar(context, "Failed to save address");
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> setLocationFromSearch(
    String query, {
    bool noMove = false,
    String? description,
  }) async {
    try {
      final place = await PlaceServices.getPlaceDetails(query);

      if (place != null) {
        final placeLocation = place['geometry']['location'];
        LatLng latLng = LatLng(placeLocation['lat'], placeLocation['lng']);
        final d = description ?? place['name'];
        setState(() {
          location = Location(
            address: d,
            latitude: latLng.latitude,
            longitude: latLng.longitude,
          );
          addressController.text = d;
          if (!noMove) selectedLocation = latLng;
        });
      }
    } catch (e) {
      debugPrint('Error setting location from search: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width,
              child: GoogleMap(
                mapType: MapType.normal,
                initialCameraPosition: CameraPosition(
                  target:
                      location?.latLng() ??
                      selectedLocation ??
                      const LatLng(0.0, 0.0),
                  zoom: 15,
                ),
                onMapCreated: (GoogleMapController controller) async {
                  _mapController.complete(controller);
                  controller.setMapStyle(mapStyle);
                },
                onCameraMove: (position) {
                  setState(() {
                    selectedLocation = position.target;
                  });
                },
                onCameraIdle: () async {
                  if (selectedLocation != null) {
                    final placeId = await PlaceServices.placeIdFromNearbySearch(
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
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/map_pin.png', height: 50, width: 50),
                  const SizedBox(height: 25),
                ],
              ),
            ),
          Stack(
                children: [
                  Container(
                    margin: EdgeInsets.only(bottom: 75),
                    width: MediaQuery.of(context).size.width,
                    height: 280,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: 15),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          height: 50,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: CustomRadioListTile(
                                  activeColor: kWhiteColor,
                                  inactiveColor: kWhiteColor,
                                  title: "Address",
                                  value: 1,
                                  groupValue: activeIndex,
                                  onChanged: (int? newValue) {
                                    updateAddressField(newValue);
                                  },
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 5,
                                ),
                                child: VerticalDivider(
                                  color: kWhiteColor,
                                  thickness: 1,
                                  width: 10,
                                ),
                              ),
                              Expanded(
                                child: CustomRadioListTile(
                                  activeColor: kWhiteColor,
                                  inactiveColor: kWhiteColor,
                                  title: "Office",
                                  value: 2,
                                  groupValue: activeIndex,
                                  onChanged: (int? newValue) {
                                    updateAddressField(newValue);
                                  },
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 5,
                                ),
                                child: VerticalDivider(
                                  color: kWhiteColor,
                                  thickness: 1,
                                  width: 10,
                                ),
                              ),
                              Expanded(
                                child: CustomRadioListTile(
                                  activeColor: kWhiteColor,
                                  inactiveColor: kWhiteColor,
                                  title: "Other",
                                  value: 3,
                                  groupValue: activeIndex,
                                  onChanged: (int? newValue) {
                                    updateAddressField(newValue);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              
            ),
            Container(
                width: MediaQuery.of(context).size.width,
                height: 285,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: ModalProgressHUD(
                  inAsyncCall: isLoading,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      height: 305,
                      child: Column(
                        children: [
                          SizedBox(height: 40),
                          TypeAheadField(
                            controller: addressController,
                            builder: (context, controller, focusNode) {
                              return TextField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: InputDecoration(
                                  filled: true,
                                  isDense: false,
                                  contentPadding: const EdgeInsets.only(
                                    top: 15,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.location_on,
                                    color: Colors.blueAccent,
                                    size: 24,
                                  ),
                                  hintText: "Write address landmark",
                                  hintStyle: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                  border: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.grey[200]!,
                                    ),
                                  ),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.grey[200]!,
                                    ),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.grey[200]!,
                                    ),
                                  ),
                                ),
                              );
                            },
                            suggestionsCallback: (pattern) async {
                              if (pattern.length < 2) return [];
                              final user = ref.read(userProvider);
                              // final region = ref.read(regionProvider);
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
                              addressController.text =
                                  data['description']?.toString() ?? '';
                              setLocationFromSearch(
                                data['place_id']?.toString() ?? '',
                                description: data['description']?.toString(),
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
                          SizedBox(height: 30),
                          GestureDetector(
                            onTap: () async {
                              if (!didChange()) return;
                              updateAddress();
                            },
                            child: ColorButton(
                              "Save Address",
                              isValid: didChange(),
                            ),
                          ),
                          SizedBox(height: 5),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            
          ],
        ),
      ),
    );
  }
}

