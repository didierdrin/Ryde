import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ryde_rw/models/orders.dart';
import 'package:ryde_rw/models/request_model.dart';
import 'package:ryde_rw/models/ride_order.dart';
import 'package:ryde_rw/service/order_service.dart';
import 'package:ryde_rw/service/request_rider_service.dart';
import 'package:ryde_rw/shared/shared_states.dart';

// Instantiate the OrderService
final orderServiceProvider = Provider((ref) => OrderService());

// StreamProvider for all orders
final ordersStreamProvider = StreamProvider<List<UserOrder>>((ref) {
  final orderService = ref.watch(orderServiceProvider);
  return orderService.getAllOrdersStream();
});

// StreamProvider for a single order by ID
final orderStreamProvider = StreamProvider.family<UserOrder?, String>((
  ref,
  orderId,
) {
  final orderService = ref.watch(orderServiceProvider);
  return orderService.getOrderStreamById(orderId);
});

// StreamProvider for ride orders from Firebase
final rideOrdersStreamProvider = StreamProvider<List<RideOrder>>((ref) async* {
  final user = ref.watch(userProvider);
  print('=== RIDE_ORDERS_PROVIDER DEBUG ===');
  print('User from provider: ${user?.id}');
  
  if (user == null) {
    print('User is null, yielding empty list');
    yield [];
    return;
  }
  
  final orderService = ref.watch(orderServiceProvider);
  await for (final orders in orderService.getRideOrdersStreamByUserId(user.id)) {
    print('Provider received ${orders.length} orders');
    yield orders;
  }
});

// StreamProvider for request rides filtered by current user's ID (phone number)
final requestRidesStreamProvider = StreamProvider<List<RequestRide>>((ref) {
  final user = ref.watch(userProvider);
  
  if (user == null) {
    return Stream.value([]);
  }
  
  return ref.watch(RequestRideService.ridesRequestedByUserProvider(user.id)).when(
    data: (requests) => Stream.value(requests),
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

