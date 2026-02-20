import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ryde_rw/models/address_model.dart';

class AddressService {
  static const String collection = 'addresses';

  static Future<void> saveAddress({
    required String phoneNumber,
    required String addressString,
    required String type,
    final Map<String, double>? location,
  }) async {
    // Stub: no Firestore. Use API/Neon if needed.
  }

  static Future<Map<String, Address>> getAddresses(String phoneNumber) async {
    return {};
  }

  static final addressesProviderd =
      StreamProvider.family<Map<String, Address>, String>((ref, phoneNumber) {
    return Stream.value({});
  });
}

final addressesProvider = StreamProvider.family<Map<String, Address>, String>((
  ref,
  phoneNumber,
) {
  return Stream.value({});
});
