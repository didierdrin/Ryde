import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ryde_rw/service/local_storage_service.dart';
import 'package:ryde_rw/config/api_config.dart';

class ApiService {
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<String?> getToken() async {
    return await LocalStorage.getToken();
  }

  /// Get driving distance in km via Google Directions API. Returns null if key is missing or request fails.
  static Future<double?> getRouteDistanceKm(
    double originLat, double originLng,
    double destLat, double destLng,
    {String? googleMapsApiKey}
  ) async {
    if (googleMapsApiKey == null || googleMapsApiKey.isEmpty) return null;
    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=$originLat,$originLng'
        '&destination=$destLat,$destLng'
        '&key=$googleMapsApiKey'
      );
      final response = await http.get(uri);
      if (response.statusCode != 200) return null;
      final data = json.decode(response.body) as Map<String, dynamic>?;
      if (data == null || data['status'] != 'OK') return null;
      final routes = data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return null;
      final legs = (routes.first as Map<String, dynamic>)['legs'] as List<dynamic>?;
      if (legs == null || legs.isEmpty) return null;
      final distance = (legs.first as Map<String, dynamic>)['distance'] as Map<String, dynamic>?;
      if (distance == null) return null;
      final meters = (distance['value'] as num?)?.toDouble();
      if (meters == null) return null;
      return meters / 1000.0;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    final body = response.body.isNotEmpty
        ? (json.decode(response.body) as Map<String, dynamic>? ?? {})
        : <String, dynamic>{};
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    final err = body['error']?.toString() ?? 'Request failed';
    final details = body['details']?.toString();
    throw Exception(details != null && details.isNotEmpty ? '$err: $details' : err);
  }

  // Auth endpoints
  static Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(userData),
    );
    final data = await _handleResponse(response);
    if (data['token'] != null) {
      await LocalStorage.setToken(data['token']);
    }
    return data;
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );
    final data = await _handleResponse(response);
    if (data['token'] != null) {
      await LocalStorage.setToken(data['token']);
    }
    return data;
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/profile'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/auth/profile'),
      headers: await _getHeaders(),
      body: json.encode(data),
    );
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updatePassengerProfile(Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/passengers/profile'),
      headers: await _getHeaders(),
      body: json.encode(data),
    );
    return await _handleResponse(response);
  }

  // Passenger endpoints
  static Future<Map<String, dynamic>> getPassengerProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/passengers/profile'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updatePassengerLocation(
      double latitude, double longitude) async {
    final response = await http.put(
      Uri.parse('$baseUrl/passengers/location'),
      headers: await _getHeaders(),
      body: json.encode({'latitude': latitude, 'longitude': longitude}),
    );
    return await _handleResponse(response);
  }

  // Driver endpoints
  static Future<Map<String, dynamic>> getDriverProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/drivers/profile'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateDriverProfile(Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/drivers/profile'),
      headers: await _getHeaders(),
      body: json.encode(data),
    );
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateVehicle(Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/drivers/vehicle'),
      headers: await _getHeaders(),
      body: json.encode(data),
    );
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateDriverLocation(
      double latitude, double longitude) async {
    final response = await http.put(
      Uri.parse('$baseUrl/drivers/location'),
      headers: await _getHeaders(),
      body: json.encode({'latitude': latitude, 'longitude': longitude}),
    );
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> toggleDriverAvailability(bool isAvailable) async {
    final response = await http.put(
      Uri.parse('$baseUrl/drivers/availability'),
      headers: await _getHeaders(),
      body: json.encode({'isAvailable': isAvailable}),
    );
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> registerVehicle(Map<String, dynamic> vehicleData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/drivers/vehicle'),
      headers: await _getHeaders(),
      body: json.encode(vehicleData),
    );
    return await _handleResponse(response);
  }

  // Trip endpoints
  static Future<Map<String, dynamic>> requestTrip(Map<String, dynamic> tripData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/trips'),
      headers: await _getHeaders(),
      body: json.encode(tripData),
    );
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getMyTrips({String? status}) async {
    final url = status != null 
        ? '$baseUrl/trips/my-trips?status=$status'
        : '$baseUrl/trips/my-trips';
    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getAvailableTrips(
      double latitude, double longitude) async {
    final response = await http.get(
      Uri.parse('$baseUrl/trips/available?latitude=$latitude&longitude=$longitude'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getTripById(String tripId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/trips/$tripId'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getTripLocations(String tripId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/trips/$tripId/locations'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> acceptTrip(String tripId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/trips/$tripId/accept'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> startTrip(String tripId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/trips/$tripId/start'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> completeTrip(String tripId, int duration) async {
    final response = await http.post(
      Uri.parse('$baseUrl/trips/$tripId/complete'),
      headers: await _getHeaders(),
      body: json.encode({'duration': duration}),
    );
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> cancelTrip(String tripId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/trips/$tripId/cancel'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  // Payment endpoints
  static Future<Map<String, dynamic>> getPaymentByTrip(String tripId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/payments/trip/$tripId'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> createPaymentInvoice(String paymentId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments/$paymentId/create-invoice'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> completePayment(
      String paymentId, String transactionRef) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments/$paymentId/complete'),
      headers: await _getHeaders(),
      body: json.encode({'transactionRef': transactionRef}),
    );
    return await _handleResponse(response);
  }

  // Notification endpoints
  static Future<Map<String, dynamic>> getNotifications({bool? isRead}) async {
    final url = isRead != null
        ? '$baseUrl/notifications?isRead=$isRead'
        : '$baseUrl/notifications';
    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getUnreadCount() async {
    final response = await http.get(
      Uri.parse('$baseUrl/notifications/unread-count'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> markNotificationAsRead(String notificationId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/notifications/$notificationId/read'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> markAllNotificationsAsRead() async {
    final response = await http.put(
      Uri.parse('$baseUrl/notifications/read-all'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  // Rating endpoints
  static Future<Map<String, dynamic>> createRating(Map<String, dynamic> ratingData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ratings'),
      headers: await _getHeaders(),
      body: json.encode(ratingData),
    );
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getRatingsByTrip(String tripId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/ratings/trip/$tripId'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  // Chat endpoints
  static Future<Map<String, dynamic>> getChatConversations() async {
    final response = await http.get(
      Uri.parse('$baseUrl/chats/conversations'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getChatMessages(String tripId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/chats/conversations/$tripId/messages'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> sendChatMessage(String tripId, String text) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chats/conversations/$tripId/messages'),
      headers: await _getHeaders(),
      body: json.encode({'text': text}),
    );
    return await _handleResponse(response);
  }

  // Rentals
  static Future<Map<String, dynamic>> getRentalVehicles() async {
    final response = await http.get(
      Uri.parse('$baseUrl/rentals'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> createInvoiceForAmount({
    double? amount,
    String? address,
    String? vehicleRef,
    String? rentalStartDate,
    String? rentalEndDate,
    bool withDriver = false,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments/create-invoice-for-amount'),
      headers: await _getHeaders(),
      body: json.encode({
        if (amount != null) 'amount': amount,
        if (address != null) 'address': address,
        if (vehicleRef != null) 'vehicleRef': vehicleRef,
        if (rentalStartDate != null) 'rentalStartDate': rentalStartDate,
        if (rentalEndDate != null) 'rentalEndDate': rentalEndDate,
        'withDriver': withDriver,
      }),
    );
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getRentalIntent(String intentId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/payments/rental-intent/${Uri.encodeComponent(intentId)}'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getRentalHistory() async {
    final response = await http.get(
      Uri.parse('$baseUrl/payments/rental-history'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> acknowledgeRentalPayment(String intentId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments/rental-intent/${Uri.encodeComponent(intentId)}/acknowledge'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  static Future<void> cancelRentalPayment(String intentId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payments/rental-intent/${Uri.encodeComponent(intentId)}/cancel'),
        headers: await _getHeaders(),
      );
      await _handleResponse(response);
    } catch (_) {}
  }

  // Auctions
  static Future<Map<String, dynamic>> getAuctionListings({String? type}) async {
    final url = type != null
        ? '$baseUrl/auctions?type=${Uri.encodeComponent(type)}'
        : '$baseUrl/auctions';
    final response = await http.get(Uri.parse(url), headers: await _getHeaders());
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> createAuctionListing(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auctions'),
      headers: await _getHeaders(),
      body: json.encode(data),
    );
    return await _handleResponse(response);
  }

  static Future<Map<String, dynamic>> purchaseAuctionListing(String listingId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auctions/$listingId/purchase'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  // Mechanics
  static Future<Map<String, dynamic>> getMechanics(double latitude, double longitude, {double radius = 15}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/mechanics?latitude=$latitude&longitude=$longitude&radius=$radius'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }

  // Nearby drivers
  static Future<Map<String, dynamic>> getNearbyDrivers(double latitude, double longitude, {double radius = 10}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/drivers/nearby?latitude=$latitude&longitude=$longitude&radius=$radius'),
      headers: await _getHeaders(),
    );
    return await _handleResponse(response);
  }
}
