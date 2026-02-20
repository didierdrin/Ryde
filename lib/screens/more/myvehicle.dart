import 'package:ryde_rw/firestore_stub.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
// import 'package:ryde_rw/components/widgets/%20fle_picker_options_modal.dart';
import 'package:ryde_rw/components/widgets/button_bar.dart';
import 'package:ryde_rw/components/widgets/text_field.dart';
import 'package:ryde_rw/models/vehicle_model.dart';
import 'package:ryde_rw/service/firebase_storage.dart';
import 'package:ryde_rw/service/vehicle_service.dart';
import 'package:ryde_rw/shared/shared_states.dart';
import 'package:ryde_rw/theme/colors.dart';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:ryde_rw/utils/contants.dart';

class MyVehicleTab extends ConsumerStatefulWidget {
  const MyVehicleTab({super.key});

  @override
  MyVehicleTabState createState() => MyVehicleTabState();
}

class MyVehicleTabState extends ConsumerState<MyVehicleTab> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _vehicleTypeController = TextEditingController();
  final TextEditingController _vehicleRegNumberController =
      TextEditingController();
  final TextEditingController _tinController = TextEditingController();

  // State controlling whether the form is in editing mode.
  bool isEditing = false;
  bool isLoading = false, isSubmit = false;
  String bodyType = "Taxi/Cab";
  List<String> list = vehicleTypes;

  // Variables for document URLs and filenames.
  bool isDrivingLicenseLoading = false,
      isInsuranceLoading = false,
      isruraLicenceLoading = false;

  // Original values to restore if editing is canceled.
  String? originalVehicleMake, originalVehicleRegNumber, originTin;

  @override
  void initState() {
    super.initState();
    loadVehicleData();
  }

  Future<void> loadVehicleData() async {
    final vehicleAsyncValue = ref.read(
      VehicleService.vehicleStream(ref.read(userProvider)!.id),
    );
    if (vehicleAsyncValue.value != null) {
      final vehicle = vehicleAsyncValue.value!;
      setState(() {
        _vehicleTypeController.text = vehicle.vehicleMake;
        _vehicleRegNumberController.text = vehicle.vehicleRegNumber;
        _tinController.text = vehicle.tin ?? '';

        bodyType = vehicle.vehicleType ?? '';

        // Store the original values.
        originalVehicleMake = vehicle.vehicleMake;
        originalVehicleRegNumber = vehicle.vehicleRegNumber;
      });
    }
  }

  Future<void> saveVehicle(BuildContext context, bool isNew) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final user = ref.read(userProvider);
      if (user == null) return;

      if (isNew) {
        final vehicle = Vehicle(
          vehicleMake: _vehicleTypeController.text,
          vehicleRegNumber: _vehicleRegNumberController.text,
          tin: _tinController.text,
          userId: user.phoneNumber,
          createdOn: DateTime.now(),
          approved: true,
          active: true,
          vehicleType: bodyType,
        );

        await VehicleService().saveOrUpdateVehicle(vehicle, ref);
      } else {
        final data = {
          'vehicleMake': _vehicleTypeController.text,
          'vehicleRegNumber': _vehicleRegNumberController.text,
          'vehicleType': bodyType,
          'tin': _tinController.text,
        };
        await VehicleService.updateVehicle(user.phoneNumber, data);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green[700],
          content: Text("Vehicle and documents saved successfully!"),
        ),
      );

      // Update original values to match the saved data.
      setState(() {
        originalVehicleMake = _vehicleTypeController.text;
        originalVehicleRegNumber = _vehicleRegNumberController.text;
        originTin = _tinController.text;
        isEditing = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Color.fromARGB(255, 227, 85, 50),
          content: Text("Failed to save."),
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Revert all changes and exit editing mode.
  void cancelEditing() {
    setState(() {
      _vehicleTypeController.text = originalVehicleMake ?? "";
      _vehicleRegNumberController.text = originalVehicleRegNumber ?? "";
      _tinController.text = originTin ?? '';
      isEditing = false;
    });
  }

  @override
  void dispose() {
    _vehicleTypeController.dispose();
    _vehicleRegNumberController.dispose();
    _tinController.dispose();
    super.dispose();
  }

  bool isValid() {
    if (_formKey.currentState == null) {
      return false;
    } else {
      return _formKey.currentState!.validate() &&
          _vehicleTypeController.text.isNotEmpty &&
          _vehicleRegNumberController.text.isNotEmpty &&
          _tinController.text.isNotEmpty;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.read(userProvider)!;

    // Determine if any data already exists.
    bool hasData =
        _vehicleTypeController.text.isNotEmpty ||
        _vehicleRegNumberController.text.isNotEmpty;
    // Allow editing immediately if no data exists; otherwise, require tapping "Edit".
    bool canEdit = !hasData || isEditing;

    // Choose the button text based on whether data was already saved.
    final String submitOrUpdateText =
        (originalVehicleMake == null || originalVehicleMake!.isEmpty)
        ? "Submit"
        : "Update";

    final vehicleAsyncValue = ref.watch(VehicleService.vehicleStream(user.id));
    if (vehicleAsyncValue.value != null) {
      final vehicle = vehicleAsyncValue.value!;
      if (_vehicleTypeController.text.isEmpty) {
        _vehicleRegNumberController.text = vehicle.vehicleRegNumber;
      }
    }

    final myVehicle = vehicleAsyncValue.value;

    return ModalProgressHUD(
      inAsyncCall: isLoading,
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Form(
          key: _formKey,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              ListView(
                children: [
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // The text fields become editable if there's no data or editing is enabled.
                        TextFieldInput(
                          readOnly: !canEdit,
                          labelText: 'Vehicle make',
                          hintText: 'eg: TOYOTA',
                          controller: _vehicleTypeController,
                          validator: (value) {
                            if (!isSubmit) return null;
                            if (value == null || value.isEmpty) {
                              return "Vehicle make is required";
                            }

                            return null;
                          },
                          onChanged: (v) {
                            _formKey.currentState?.validate();
                          },
                        ),
                        TextFieldInput(
                          readOnly: !canEdit,
                          labelText: "Vehicle Registration",
                          hintText: 'eg: RAH 309',
                          controller: _vehicleRegNumberController,
                          validator: (value) {
                            if (!isSubmit) return null;
                            if (value == null || value.isEmpty) {
                              return "Vehicle Reg is required";
                            }

                            return null;
                          },
                          onChanged: (v) {
                            _formKey.currentState?.validate();
                          },
                        ),
                        TextFieldInput(
                          readOnly: !canEdit,
                          labelText: 'TIN Number',
                          hintText: 'Enter TIN Number here',
                          controller: _tinController,
                          onChanged: (v) {
                            _formKey.currentState?.validate();
                          },
                        ),
                        // File picker sections become enabled only if canEdit is true.
                        // Driving License
                        Text(
                          'Vehicle Type',
                          textAlign: TextAlign.start,
                          style: Theme.of(context).textTheme.bodyLarge!
                              .copyWith(color: Colors.grey, fontSize: 13.5),
                        ),
                        const SizedBox(height: 5),
                        DropdownButtonFormField<String>(
                          style: Theme.of(context).textTheme.bodyMedium!
                              .copyWith(color: Colors.grey, fontSize: 13.5),
                          decoration: InputDecoration(
                            isDense: true,
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey[200]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey[200]!),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.red),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.red),
                            ),
                            hintText: 'Select Vehicle Type',
                            hintStyle: Theme.of(context).textTheme.bodyLarge!
                                .copyWith(
                                  fontSize: 13.5,
                                  color: Colors.grey[400],
                                ),
                          ),
                          value: bodyType,
                          items: list
                              .map(
                                (option) => DropdownMenuItem(
                                  value: option,
                                  child: Text(option),
                                ),
                              )
                              .toList(),
                          onChanged: isEditing
                              ? (value) {
                                  if (value != null) {
                                    setState(() {
                                      bodyType = value;
                                    });
                                  }
                                }
                              : null,
                          validator: (value) => value == null
                              ? 'Please select vehicle type'
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (myVehicle?.approved != true)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Opacity(
                          opacity: 1,
                          child: BottomBar(
                            textColor: kWhiteColor,
                            color: isEditing
                                ? Colors.red
                                : (canEdit ? Colors.grey : Colors.black87),
                            onTap: () {
                              if (!isEditing) {
                                // Enter editing mode.
                                setState(() {
                                  isEditing = true;
                                  isSubmit = true;
                                });
                              } else {
                                // Cancel editing.
                                cancelEditing();
                              }
                            },
                            text: isEditing ? "Cancel" : "Edit",
                          ),
                        ),
                      
                    ),
                  // The Update (or Submit) button is active only when in editing mode.
                  if (myVehicle?.approved != true)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 0,
                      ),
                      child: Opacity(
                          opacity: canEdit || isEditing ? 1 : 0.5,
                          child: BottomBar(
                            textColor: kWhiteColor,
                            color: kMainColor,
                            onTap: canEdit || isEditing
                                ? () {
                                    setState(() {
                                      isSubmit = true;
                                    });
                                    if (_formKey.currentState!.validate()) {
                                      saveVehicle(context, myVehicle == null);
                                    }
                                  }
                                : () {},
                            text: submitOrUpdateText,
                          ),
                        ),
                      
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

