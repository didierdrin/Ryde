import 'dart:async';
import 'package:ryde_rw/firestore_stub.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:ryde_rw/components/widgets/button_bar.dart';
import 'package:ryde_rw/components/widgets/entry_field.dart';
import 'package:ryde_rw/components/widgets/location_input_field.dart';
import 'package:ryde_rw/components/widgets/dropoff_location_input_field.dart';
import 'package:ryde_rw/models/request_model.dart';
import 'package:ryde_rw/service/request_rider_service.dart';
import 'package:ryde_rw/service/order_service.dart';
import 'package:ryde_rw/shared/locations_shared.dart';
import 'package:ryde_rw/shared/shared_states.dart';
import 'package:ryde_rw/theme/colors.dart';
import 'package:ryde_rw/utils/contants.dart';
import 'package:ryde_rw/config/irembopay_config.dart';
import 'package:ryde_rw/screens/payments/irembopay_webview_screen.dart';
import 'package:ryde_rw/service/api_service.dart';
import 'dart:math';

class FindPool extends ConsumerStatefulWidget {
  const FindPool({super.key});

  @override
  FindPoolState createState() => FindPoolState();
}

class FindPoolState extends ConsumerState<FindPool> {
  bool isLoading = false;
  Location? pickup, dropOff;
  final TextEditingController dateTimeController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isNowSelected = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    dateTimeController.dispose();
    super.dispose();
  }

  // To be replaced with a pricing_service.dart

  // Compute the distance in kilometers using the Haversine formula.
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371; // Earth's radius in km.
    double dLat = _deg2rad(lat2 - lat1);
    double dLon = _deg2rad(lon2 - lon1);
    double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) {
    return deg * (pi / 180);
  }

  /// Raw fare in RWF for Irembo invoice and display.
  int _estimatedPriceRwf() {
    if (pickup == null || dropOff == null) return 0;
    final distance = calculateDistance(
      pickup!.latitude,
      pickup!.longitude,
      dropOff!.latitude,
      dropOff!.longitude,
    );
    final km = distance.ceil();
    int price;
    if (km <= 1) {
      price = 1500;
    } else if (km <= 30) {
      price = 1500 + (km - 1) * 900;
    } else {
      price = 1500 + (29 * 900) + ((km - 30) * 700);
    }
    return price;
  }

  // Compute the estimated price based on the distance and pricing model.
  String getEstimatedPrice() {
    final price = _estimatedPriceRwf();
    if (price == 0) return '0';
    return NumberFormat('#,###').format(price);
  }

  // End of pricing calculation logic

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

  Future<dynamic> loginModal() async {
    return await showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Builder(
          builder: (context) {
            return ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
              children: [
                Text(
                  'Login to Find Driver',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 10),
                BottomBar(
                  onTap: () async {
                    // final value = await Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder: (context) {
                    //       return const Login(isLoggedIn: true);
                    //     },
                    //   ),
                    // );
                    // Navigator.pop(context, value);
                  },
                  text: "Login",
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitForm() async {
    final user = ref.read(userProvider);
    if (user == null) {
      await loginModal();
      setState(() {
        isLoading = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    if (_formKey.currentState!.validate() && isValid()) {
      final user = ref.read(userProvider)!;
      DateTime parsedDate = isNowSelected ? DateTime.now() : DateFormat("yyyy-MM-dd h:mm").parse(dateTimeController.text);
      Timestamp requestedTimestamp = Timestamp.fromDate(parsedDate);

      // Define the time window: one hour before and after the selected time
      final lowerBound = Timestamp.fromDate(
        parsedDate.subtract(Duration(hours: 1)),
      );
      final upperBound = Timestamp.fromDate(parsedDate.add(Duration(hours: 1)));

      // Query for duplicate requests matching the criteria:
      final duplicateQuery = await FirebaseFirestore.instance
          .collection(
            collections.request,
          ) // Ensure this is the same collection name as in your RequestRideService
          .where('pickupLocation.address', isEqualTo: pickup!.address)
          .where('dropoffLocation.address', isEqualTo: dropOff!.address)
          .where(
            'requestedBy',
            isEqualTo: user.id,
          ) // check for duplicates only for this user
          .where('requestedTime', isGreaterThanOrEqualTo: lowerBound)
          .where('requestedTime', isLessThanOrEqualTo: upperBound)
          .get();

      if (duplicateQuery.docs.isNotEmpty) {
        if (!mounted) return;
        // Show an error message if a duplicate is found
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

      final selectedVehicle = await selectVehicleType();
      if (selectedVehicle == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      final type = ["Taxi/Cab", "Moto"].contains(selectedVehicle)
          ? 'passengers'
          : 'goods';

      final requestRide = RequestRide(
        rider: '',
        requestedBy: user.id,
        pickupLocation: pickup!,
        dropoffLocation: dropOff!,
        requestedTime: requestedTimestamp.toDate(),
        createdAt: DateTime.now(),
        rejected: false,
        accepted: false,
        offerpool: '',
        paid: false,
        price: _estimatedPriceRwf(),
        type: type,
        seats: 1,
        countryCode: user.countryCode,
      );

      try {
        final fare = _estimatedPriceRwf();
        final distanceKm = calculateDistance(
          pickup!.latitude,
          pickup!.longitude,
          dropOff!.latitude,
          dropOff!.longitude,
        );

        final tripRes = await ApiService.requestTrip({
          'pickupLatitude': pickup!.latitude,
          'pickupLongitude': pickup!.longitude,
          'pickupAddress': pickup!.address,
          'destinationLatitude': dropOff!.latitude,
          'destinationLongitude': dropOff!.longitude,
          'destinationAddress': dropOff!.address,
          'distance': distanceKm,
          'fare': fare,
        });

        final trip = tripRes['trip'];
        final rydeTripId = trip is Map<String, dynamic>
            ? (trip['trip_id'] ?? trip['tripId'])?.toString()
            : null;
        if (rydeTripId == null || rydeTripId.isEmpty) {
          throw Exception('Trip created but missing id from server');
        }

        await RequestRideService.createRequestRide(requestRide);

        final orderData = {
          'userId': user.id,
          'from': pickup!.address,
          'to': dropOff!.address,
          'dateTime': DateFormat('yyyy-MM-dd HH:mm').format(parsedDate),
          'vehicleType': selectedVehicle,
          'estimatedPrice': getEstimatedPrice(),
          'rydeTripId': rydeTripId,
          'createdAt': Timestamp.now(),
          'status': 'pending',
        };

        await OrderService().createRideOrder(orderData);

        if (!mounted) return;
        setState(() {
          isLoading = false;
        });

        _showPaymentBottomSheet(selectedVehicle, parsedDate, rydeTripId);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                e.toString().replaceFirst('Exception: ', ''),
              ),
            ),
          );
        }
        setState(() {
          isLoading = false;
        });
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  String iconPath(String type) {
    switch (type) {
      case 'Taxi/Cab':
        return 'assets/icons/1.png';
      case 'Moto':
        return 'assets/icons/3.png';
      case 'Truck':
        return 'assets/icons/2.png';
      case 'Three Wheels':
        return 'assets/icons/4.png';
      default:
        return 'assets/icons/1.png';
    }
  }

  Future<String?> selectVehicleType() {
    String? value;
    return showModalBottomSheet(
      useSafeArea: true,
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, updateValue) {
            return ListView(
              shrinkWrap: true,
              padding: EdgeInsets.all(20),
              children: [
                Text(
                  'Select Vehicle Type',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                ListView.separated(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final type = vehicleTypes[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: value == type
                            ? kMainColor.withValues(alpha: 0.3)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: value == type
                              ? kMainColor
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        leading: Image.asset(
                          iconPath(type),
                          width: 70,
                          height: 70,
                        ),
                        onTap: () {
                          updateValue(() {
                            value = type == value ? null : type;
                          });
                        },
                        title: Text(
                          type,
                          style: Theme.of(context).textTheme.bodyMedium!
                              .copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (context, index) {
                    return Divider(color: Colors.grey.withValues(alpha: .5));
                  },
                  itemCount: vehicleTypes.length,
                ),
                BottomBar(
                  onTap: () {
                    if (value != null) {
                      Navigator.pop(context, value);
                    }
                  },
                  isValid: value != null,
                  text: 'Confirm',
                ),
              ],
            );
          },
        );
      },
    );
  }

  bool isValid() {
    return pickup != null &&
        dropOff != null &&
        (isNowSelected || dateTimeController.text.trim().isNotEmpty);
  }

  Future<void> _openIremboFromSheet(
    BuildContext sheetContext,
    void Function(void Function()) setModalState,
    String vehicleType,
    String rydeTripId,
    bool Function() getPaying,
    void Function(bool) setPaying,
  ) async {
    if (getPaying()) return;
    if (!IremboPayConfig.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'IremboPay not configured. Build with --dart-define=IREMBOPAY_PUBLIC_KEY=pk_…',
          ),
        ),
      );
      return;
    }
    setPaying(true);
    setModalState(() {});
    try {
      final payRes = await ApiService.getPaymentByTrip(rydeTripId);
      final payment = payRes['payment'] as Map<String, dynamic>?;
      final paymentId = payment?['payment_id']?.toString();
      final payStatus = payment?['payment_status']?.toString() ?? '';
      if (paymentId == null || paymentId.isEmpty) {
        throw Exception('No payment record for this trip');
      }
      if (payStatus == 'COMPLETED') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This trip is already paid.')),
          );
        }
        return;
      }

      final inv = await ApiService.createPaymentInvoice(paymentId);
      final invoiceNumber = inv['invoiceNumber']?.toString();
      if (invoiceNumber == null || invoiceNumber.isEmpty) {
        throw Exception('Could not create payment invoice');
      }
      if (!mounted || !sheetContext.mounted) return;
      Navigator.pop(sheetContext);
      if (!context.mounted) return;
      final ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (context) => IremboPayWebViewScreen(invoiceNumber: invoiceNumber),
        ),
      );
      if (!mounted) return;
      if (ok == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Confirming payment…')),
        );
        final outcome = await ApiService.waitForTripPaymentStatus(rydeTripId);
        if (!mounted) return;
        if (outcome == 'COMPLETED') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment successful'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (outcome == 'FAILED') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment failed')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment still processing — check again later.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      setPaying(false);
      if (sheetContext.mounted) {
        setModalState(() {});
      }
    }
  }

  void _showPaymentBottomSheet(
    String vehicleType,
    DateTime dateTime,
    String rydeTripId,
  ) {
    var paying = false;
    bool getPaying() => paying;
    void setPaying(bool v) {
      paying = v;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.fromLTRB(24, 10, 24, 30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Trip Summary',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 25),
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: kLightGreyColor.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Column(
                            children: [
                              Icon(Icons.circle, color: kMainColor, size: 14),
                              Container(
                                height: 30,
                                width: 2,
                                color: kDisabledColor.withValues(alpha: 0.2),
                                margin: EdgeInsets.symmetric(vertical: 4),
                              ),
                              Icon(Icons.location_on, color: kMainColor, size: 20),
                            ],
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Pickup', style: TextStyle(color: kSimpleText, fontSize: 12)),
                                SizedBox(height: 2),
                                Text(
                                  pickup!.address,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: kTextColor,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 16),
                                Text('Drop-off', style: TextStyle(color: kSimpleText, fontSize: 12)),
                                SizedBox(height: 2),
                                Text(
                                  dropOff!.address,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: kTextColor,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfoItem(
                          'Date',
                          DateFormat('MMM dd, HH:mm').format(dateTime),
                          Icons.calendar_today_rounded,
                        ),
                        _buildVehicleItem(vehicleType, iconPath(vehicleType)),
                        _buildInfoItem(
                          'Price',
                          '${getEstimatedPrice()} FRW',
                          Icons.payments_outlined,
                        ),
                      ],
                    ),
                    SizedBox(height: 30),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        color: kMainColor.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: kMainColor.withValues(alpha: 0.08)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Pay securely with IremboPay',
                            style: TextStyle(
                              color: kSimpleText,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 12),
                          BottomBar(
                            text: paying ? 'Please wait…' : 'Pay with IremboPay',
                            isValid: !paying,
                            onTap: () => _openIremboFromSheet(
                              sheetContext,
                              setModalState,
                              vehicleType,
                              rydeTripId,
                              getPaying,
                              setPaying,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    TextButton(
                      onPressed: paying ? null : () => Navigator.pop(sheetContext),
                      child: Text(
                        'Dismiss',
                        style: TextStyle(
                          color: kSimpleText,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kLightGreyColor.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 24, color: kMainColor),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: kSimpleText, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kTextColor),
        ),
      ],
    );
  }

  Widget _buildVehicleItem(String label, String iconPath) {
    return Column(
      children: [
         Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kLightGreyColor.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: Image.asset(iconPath, width: 24, height: 24, color: kMainColor),
        ),
        SizedBox(height: 8),
        Text(
          "Vehicle",
          style: TextStyle(fontSize: 12, color: kSimpleText, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kTextColor),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: ModalProgressHUD(
        progressIndicator: CircularProgressIndicator(
          color: Colors.black,
        ), //greenPrimary),
        inAsyncCall: isLoading,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: MediaQuery.removePadding(
            context: context,
            removeBottom: true,
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  top: 16.0,
                  bottom: 16.0, //MediaQuery.of(context).viewInsets.bottom + 16.0,
                ),
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
                    prefixIcon: Icon(
                      Icons.circle,
                      color: primaryColor,
                      size: 17,
                    ),
                    onSelected: (suggestion) {
                      setState(() {
                        pickup = suggestion;
                      });
                    },
                  ),
                  DropoffLocationInputField(
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
                  const SizedBox(height: 10,),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => isNowSelected = true),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isNowSelected ? primaryColor : Colors.transparent,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: primaryColor),
                            ),
                            child: Text(
                              'Now',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isNowSelected ? Colors.white : primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: !isNowSelected
                            ? GestureDetector(
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
                              )
                            : GestureDetector(
                                onTap: () => setState(() => isNowSelected = false),
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(color: primaryColor),
                                  ),
                                  child: Text(
                                    'Later',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                 
                  SizedBox(height: 20),
                  BottomBar(
                    isValid: isValid(),
                    onTap: () {
                      _submitForm();
                    },
                    text: "Pay",
                    textColor: kWhiteColor,
                  ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),),
    );
  }
}

