import 'dart:io';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:ryde_rw/screens/signin_signup.dart';
import 'package:ryde_rw/service/local_storage_service.dart';
import 'package:ryde_rw/service/location_service.dart';
import 'package:ryde_rw/service/user_service.dart';
import 'package:ryde_rw/shared/shared_states.dart';
import 'package:ryde_rw/theme/colors.dart';
import 'package:ryde_rw/theme/style_text.dart';

import 'package:ryde_rw/utils/contants.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';


shareApp(String subject) async {
  String url = Platform.isAndroid ? playStore : appleStore;
  Share.share(url, subject: subject);
}

String formatPriceWithCommas(int price) {
  final formatter = NumberFormat('#,###');
  return formatter.format(price);
}

String formatPrice(int price) {
  return NumberFormat('#,##0', 'en_US').format(price);
}

void handlePriceChange(String value, TextEditingController controller) {
  int? val = int.tryParse(value.replaceAll(',', ''));
  if (val == null) {
    controller.value = const TextEditingValue(
      text: '',
      selection: TextSelection.collapsed(offset: ('').length),
    );
    return;
  }
  final formattedVal = formatPrice(val);
  controller.value = TextEditingValue(
    text: formattedVal,
    selection: TextSelection.collapsed(offset: formattedVal.length),
  );
}

InputDecoration inputDecorationWithLabel(
  String hint,
  String labelText, {
  Widget? prefix,
  Widget? suffix,
}) {
  return InputDecoration(
    prefix: prefix,
    suffix: suffix,
    hintStyle: AppStyles.accountTextStyle.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    hintText: hint,
    labelStyle: AppStyles.accountTextStyle,
    labelText: labelText,
    filled: true,
    alignLabelWithHint: true,
    fillColor: kWhiteColor,
    contentPadding: const EdgeInsets.all(15),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: kLightGreyColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: kMainColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: kLightGreyColor),
    ),
  );
}

String formatDate(DateTime date) {
  return DateFormat('MMMM d, yyyy').format(date);
}

String formatTime(DateTime date) {
  DateTime now = DateTime.now();

  // Normalize both dates to remove the time part for accurate day comparisons.
  DateTime today = DateTime(now.year, now.month, now.day);
  DateTime targetDate = DateTime(date.year, date.month, date.day);
  int dayDifference = targetDate.difference(today).inDays;

  // Format the time part.
  String timeFormatted = DateFormat.Hm().format(date);

  if (dayDifference == 0) {
    // The event is today.
    return 'Today at $timeFormatted';
  } else if (dayDifference == 1) {
    // The event is tomorrow.
    return 'Tomorrow at $timeFormatted';
  } else if (dayDifference > 1 && dayDifference < 7) {
    // The event is later this week, so show the weekday.
    String weekday = DateFormat.EEEE().format(date);
    return '$weekday at $timeFormatted';
  } else if (dayDifference >= 7 && dayDifference < 30) {
    // For dates more than a week away but still within the month.
    String weekday = DateFormat.EEEE().format(date);
    return 'Next week on $weekday at $timeFormatted';
  } else if (date.month != now.month || dayDifference >= 30) {
    // For dates in the next month or beyond, provide a full date.
    String fullDate = DateFormat.yMMMMd().format(date);
    return '$fullDate at $timeFormatted';
  } else {
    // Fallback to a standard date and time format.
    return DateFormat.yMd().add_Hm().format(date);
  }
}

dynamic showToast(
  BuildContext context,
  String message, {
  Toast toastLength = Toast.LENGTH_SHORT,
}) {
  return Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
    fontSize: 16.0,
  );
}

Future getUserCurrentLocation(WidgetRef ref) async {
  if (ref.read(locationProvider).isNotEmpty) return;
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (serviceEnabled) {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      bool isPermitted =
          permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
      if (isPermitted) {
        await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
              timeLimit: const Duration(seconds: 4),
            )
            .then((value) async {
              var address =
                  await LocationService.getCountryAddressFromCoordinates(
                    value.latitude,
                    value.longitude,
                  );
              final data = {
                ...address,
                'lat': value.latitude,
                'long': value.longitude,
                'heading': value.heading,
              };
              ref.read(locationProvider.notifier).state = data;
              LocalStorage.setUserLocation(data);
            })
            .catchError((_) {
              return throw Exception('location error');
            });
      } else {
        return throw Exception('error permission');
      }
    } catch (_) {
      return throw Exception('location error');
    }
  } else {
    return throw Exception('error service');
  }
}

void showLogoutBottomSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32.0)),
    ),
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: SizedBox(
          height: 230.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              Text("Logging out", style: AppStyles.headerTextStyle),
              const SizedBox(height: 40.0),
              InkWell(
                onTap: () async {
                  Navigator.pop(context);
                  await LocalStorage.removeUserLocation();
                  await LocalStorage.removeUser().then((v) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return const SigninSignup();
                        },
                      ),
                    );
                  });
                },
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    "Logout",
                    style: AppStyles.accountTextStyle.copyWith(
                      color: Color(0xffF15C5A),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    "Cancel",
                    style: AppStyles.accountTextStyle.copyWith(
                      color: const Color(0xff101010),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
            ],
          ),
        ),
      );
    },
  );
}

String removeZeros(String input) {
  int zerosToRemove = 3;
  StringBuffer result = StringBuffer();
  for (int i = input.length - 1; i >= 0; i--) {
    if (input[i] == '0' && zerosToRemove > 0) {
      zerosToRemove--;
    } else {
      result.write(input[i]);
    }
  }
  return result.toString().split('').reversed.join();
}

String capitalizeFirstLetter(String input) {
  if (input.isEmpty) return input;
  return input[0].toUpperCase() + input.substring(1).toLowerCase();
}

String formatnotDate(BuildContext context, DateTime date) {
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final yesterdayStart = todayStart.subtract(const Duration(days: 1));

  // AppLocalizations locale = AppLocalizations.of(context)!;
  String format = 'en'; //locale.localeName == 'en' ? 'en_US' : 'fr_FR';

  if (date.isAfter(todayStart)) {
    return 'Today';
  } else if (date.isAfter(yesterdayStart) && date.isBefore(todayStart)) {
    return 'Yesterday';
  } else {
    return DateFormat('d MMMM', format).format(date);
  }
}

String formatnotTime(BuildContext context, DateTime date) {
  // AppLocalizations locale = AppLocalizations.of(context)!;
  String format = 'en'; //locale.localeName == 'en' ? 'en_US' : 'fr_FR';
  return DateFormat('HH:mm', format).format(date);
}

Future<void> showLanguageSelectionModal(
  BuildContext context,
  WidgetRef ref,
) async {
  final prefs = await SharedPreferences.getInstance();

  return showModalBottomSheet(
    // ignore: use_build_context_synchronously
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32.0)),
    ),
    backgroundColor: Colors.white,
    builder: (BuildContext context) {
      return Container(
        height: 290.0,
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Text(
                "Select a language", // locale.selectLanguage,
                style: AppStyles.headerTextStyle,
              ),
            ),
            const SizedBox(height: 40.0),
            InkWell(
              onTap: () {
                // ref.read(localeProvider.notifier).state = const Locale('en');
                prefs.setString('locale', 'en');
                Navigator.pop(context);
              },
              child: Container(
                height: 60,
                padding: const EdgeInsets.symmetric(
                  vertical: 12.0,
                  horizontal: 16.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  // color: ref.watch(localeProvider) == const Locale('en')
                  //     ? const Color(0xff0ECB6F).withOpacity(0.1)
                  //     : Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(
                    color: Colors.black54,
                    // color: ref.watch(localeProvider) == const Locale('en')
                    //     ? const Color(0xff0ECB6F)
                    //     : const Color(0xffE0E0E0),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('English', style: AppStyles.accountTextStyle),
                    // if (ref.watch(localeProvider) == const Locale('en'))
                    //   const Icon(Icons.check_circle, color: Colors.green),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            InkWell(
              onTap: () {
                // ref.read(localeProvider.notifier).state = const Locale('fr');
                prefs.setString('locale', 'fr');
                Navigator.pop(context);
              },
              child: Container(
                height: 60,
                padding: const EdgeInsets.symmetric(
                  vertical: 12.0,
                  horizontal: 16.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  // color: ref.watch(localeProvider) == const Locale('fr')
                  //     ? const Color(0xff0ECB6F).withOpacity(0.1)
                  //     : Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(
                    color: Colors.black54,
                    // color: ref.watch(localeProvider) == const Locale('fr')
                    //     ? const Color(0xff0ECB6F)
                    //     : const Color(0xffE0E0E0),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('French', style: AppStyles.accountTextStyle),
                    // if (ref.watch(localeProvider) == const Locale('fr'))
                    //   const Icon(Icons.check_circle, color: Colors.green),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

String getAddressType(int index) {
  switch (index) {
    case 0:
      return 'home';
    case 1:
      return 'office';
    case 2:
      return 'other';
    default:
      return '';
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const double radiusOfEarthKm = 6371;
  final double dLat = _degreesToRadians(lat2 - lat1);
  final double dLon = _degreesToRadians(lon2 - lon1);
  final double a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(_degreesToRadians(lat1)) *
          cos(_degreesToRadians(lat2)) *
          sin(dLon / 2) *
          sin(dLon / 2);
  final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return radiusOfEarthKm * c;
}

double _degreesToRadians(double degrees) {
  return degrees * pi / 180;
}

bool isLocationNear(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
  double radiusKm,
) {
  return _calculateDistance(lat1, lon1, lat2, lon2) <= radiusKm;
}

// double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
//   const double radiusOfEarthKm = 6371;
//   final double dLat = _degreesToRadians(lat2 - lat1);
//   final double dLon = _degreesToRadians(lon2 - lon1);
//   final double a = sin(dLat / 2) * sin(dLat / 2) +
//       cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
//       sin(dLon / 2) * sin(dLon / 2);
//   final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
//   return radiusOfEarthKm * c;
// }

double degreesToRadians(double degrees) {
  return degrees * pi / 180;
}

DateTime truncateToDate(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

double determineRadius(double tripDistance) {
  if (tripDistance <= 15) {
    return 1.0; // 1 km for trips <= 15 km
  } else if (tripDistance > 15 && tripDistance <= 30) {
    return 2.0; // 2 km for trips between 15 and 30 km
  } else if (tripDistance > 30 && tripDistance <= 100) {
    return 5.0; // 5 km for trips between 31 and 100 km
  } else {
    return 10.0; // 10 km for trips > 100 km
  }
}

List<LatLng> decodePolyline(String polyline) {
  final List<LatLng> points = [];
  int index = 0, len = polyline.length;
  int lat = 0, lng = 0;

  while (index < len) {
    int shift = 0, result = 0;
    int b;
    do {
      b = polyline.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    lat += dlat;

    shift = 0;
    result = 0;
    do {
      b = polyline.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    lng += dlng;

    points.add(LatLng(lat / 1e5, lng / 1e5));
  }

  return points;
}

bool isLocationNearPolyline({
  required double userLat,
  required double userLng,
  required List<LatLng> polylinePoints,
  required double radiusKm,
}) {
  for (final point in polylinePoints) {
    final distance = _calculateDistance(
      userLat,
      userLng,
      point.latitude,
      point.longitude,
    );
    if (distance <= radiusKm) {
      return true; // User is near the route
    }
  }
  return false; // User is not near the route
}

double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const double radiusOfEarthKm = 6371;
  final double dLat = _degreesToRadians(lat2 - lat1);
  final double dLon = _degreesToRadians(lon2 - lon1);
  final double a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(_degreesToRadians(lat1)) *
          cos(_degreesToRadians(lat2)) *
          sin(dLon / 2) *
          sin(dLon / 2);
  final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return radiusOfEarthKm * c;
}

List<LatLng> decodePolylineD(String polyline) {
  final List<LatLng> points = [];
  int index = 0, len = polyline.length;
  int lat = 0, lng = 0;

  while (index < len) {
    int shift = 0, result = 0;
    int b;
    do {
      b = polyline.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    lat += dlat;

    shift = 0;
    result = 0;
    do {
      b = polyline.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    lng += dlng;

    points.add(LatLng(lat / 1e5, lng / 1e5));
  }

  return points;
}

String removeCountryCode(String phoneNumber) {
  if (phoneNumber.startsWith('+') && phoneNumber.length > 3) {
    return phoneNumber.substring(3);
  }
  return phoneNumber;
}

String getPhone(String phone) {
  return PhoneNumber.fromCompleteNumber(completeNumber: phone).number;
}

String getCountryCode(String phone) {
  return PhoneNumber.fromCompleteNumber(completeNumber: phone).countryISOCode;
}

String? getCountryName(String countryCode) {
  return countries.firstWhereOrNull((c) => c.code == countryCode)?.name;
}

Country? getCountry(String code) {
  return countries.firstWhereOrNull((c) => c.code == code);
}

bool isValidNumber(String phone) {
  if (phone.isEmpty || phone[0] != '+') return false;
  try {
    final number = PhoneNumber.fromCompleteNumber(completeNumber: phone);
    return number.isValidNumber();
  } catch (_) {
    return false;
  }
}

void showPermissionDeniedForeverDialog(BuildContext context) {
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
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            // Message
            Text(
              "You have permanently denied location access. Please enable it in your device settings to use this feature.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54),
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
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: BorderSide(color: Colors.grey),
                  ),
                  icon: Icon(Icons.close, color: Colors.grey),
                  label: Text("Cancel", style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

void showSuccessPopup(BuildContext context, String message) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle, color: Colors.green, size: 50),
              ),
              SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

