import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:ryde_rw/components/widgets/button_bar.dart';
import 'package:ryde_rw/components/widgets/entry_field.dart';

import 'package:ryde_rw/components/widgets/location_input_field.dart';
import 'package:ryde_rw/models/offer_pool_model.dart';
//import 'package:ryde_rw/screens/app_screen.dart';
import 'package:ryde_rw/service/offer_pool_service.dart';
import 'package:ryde_rw/shared/locations_shared.dart';
import 'package:ryde_rw/shared/shared_states.dart';
import 'package:ryde_rw/theme/colors.dart';
import 'package:ryde_rw/utils/utils.dart';
import 'package:ryde_rw/utils/contants.dart';

class OfferPool extends ConsumerStatefulWidget {
  const OfferPool({super.key});

  @override
  OfferPoolState createState() => OfferPoolState();
}

class OfferPoolState extends ConsumerState<OfferPool> {
  bool isLoading = false;
  Location? pickup, dropOff;
  final TextEditingController dateTimeController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? price;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _selectDateTime(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        DateTime selectedDate = DateTime.now();
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 300,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.dateAndTime,
                  use24hFormat: true,
                  minimumDate: DateTime.now(),
                  maximumDate: DateTime(2100),
                  initialDateTime: DateTime.now(),
                  onDateTimeChanged: (DateTime newDateTime) {
                    selectedDate = newDateTime;
                  },
                ),
              ),
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop(selectedDate);
                },
              ),
            ],
          ),
        );
      },
    ).then((selectedDate) {
      if (selectedDate != null) {
        final formattedDateTime = DateFormat(
          'yyyy-MM-dd HH:mm',
        ).format(selectedDate);
        dateTimeController.text = formattedDateTime;
      }
      _formKey.currentState?.validate();
    });
  }

  Future<void> _submitForm() async {
    setState(() {
      isLoading = true;
    });

    if (_formKey.currentState!.validate() && isValid()) {
      final user = ref.read(userProvider)!;
      final dateFormat = DateFormat("yyyy-MM-dd h:mm");
      DateTime parsedDate = dateFormat.parse(dateTimeController.text);
      Timestamp dateTime = Timestamp.fromDate(parsedDate);

      // Define the ±1-hour time window around the selected date and time.
      final lowerBound = Timestamp.fromDate(
        parsedDate.subtract(Duration(hours: 1)),
      );
      final upperBound = Timestamp.fromDate(parsedDate.add(Duration(hours: 1)));

      // Query Firestore for any existing offer pool by the same driver that matches the criteria.
      final duplicateQuery = await FirebaseFirestore.instance
          .collection(collections.offerpool)
          .where('user', isEqualTo: user.id)
          .where('pickupLocation.address', isEqualTo: pickup!.address)
          .where('dropoffLocation.address', isEqualTo: dropOff!.address)
          .where('dateTime', isGreaterThanOrEqualTo: lowerBound)
          .where('dateTime', isLessThanOrEqualTo: upperBound)
          .get();

      if (duplicateQuery.docs.isNotEmpty) {
        // If a duplicate exists, show an error message and stop further processing.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "A trip with the same pickup, destination, and time already exists.",
            ),
          ),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Continue with price parsing.
      final replaceprice = priceController.text.replaceAll(',', '');
      final price = int.parse(replaceprice);

      // Create a new offer pool entry.
      final offerpool = PassengerOfferPool(
        pickupLocation: pickup!,
        dropoffLocation: dropOff!,
        dateTime: dateTime,
        selectedSeat: 1,
        pricePerSeat: price,
        user: user.id,
        emptySeat: 1,
        countryCode: user.countryCode,
        type: 'passengers',
      );

      try {
        await OfferPoolService.createFindPool(offerpool);
        setState(() {
          isLoading = false;
        });

        dateTimeController.clear();
        priceController.clear();

        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) {
        //       return AppScreen(currentIndex: 1);
        //     },
        //   ),
        // );
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Color.fromARGB(255, 227, 85, 50),
            content: Text("Please fill all the fields."),
          ),
        );
      }
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Color.fromARGB(255, 227, 85, 50),
          content: Text("Please fill all the fields."),
        ),
      );
    }
  }

  bool isValid() {
    return pickup != null &&
        dropOff != null &&
        priceController.text.trim().isNotEmpty &&
        dateTimeController.text.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    // final region = ref.watch(regionProvider);
    print('object');

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: ModalProgressHUD(
        inAsyncCall: isLoading,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LocationInputField(
                  destination: true,
                  location: pickup,
                  useCurrent: true,
                  hint: 'From',
                  prefixIcon: Icon(Icons.circle, color: primaryColor, size: 17),
                  onSelected: (suggestion) {
                    setState(() {
                      pickup = suggestion;
                    });
                  },
                ),
                LocationInputField(
                  destination: true,
                  location: dropOff,
                  hint: 'To',
                  prefixIcon: Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 17,
                  ),
                  onSelected: (suggestion) {
                    setState(() {
                      dropOff = suggestion;
                    });
                  },
                ),
                Column(
                  children: [
                    GestureDetector(
                      onTap: () => _selectDateTime(context),
                      child: AbsorbPointer(
                        child: TextEntryField(
                          controller: dateTimeController,
                          hint: 'Date and time',
                          prefixIcon: Icon(
                            Icons.calendar_today,
                            color: Colors.grey,
                            size: 17,
                          ),
                        ),
                      ),
                    ),
                    TextFormField(
                      style: TextStyle(fontSize: 13.5),
                      controller: priceController,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: false,
                        signed: true,
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        hintText: 'Price per seat',
                        hintStyle: Theme.of(context).textTheme.bodyMedium!
                            .copyWith(color: Colors.grey, fontSize: 13.5),
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 24),
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(left: 10, right: 7),
                          child: Text(
                            "RWF",
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ),
                        prefixIconConstraints: BoxConstraints(
                          minWidth: 0,
                          minHeight: 0,
                        ),
                      ),
                      onChanged: (val) {
                        handlePriceChange(val, priceController);
                        setState(() {
                          price = priceController.text;
                        });
                      },
                      validator: (value) {
                        if ('$price'.isEmpty) {
                          return 'Please enter a price';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
                SizedBox(height: 20),
                BottomBar(
                    isValid: isValid(),
                    onTap: () {
                      _submitForm();
                    },
                    text: "Offer Ride",
                    textColor: kWhiteColor,
                  ),
                
                SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

