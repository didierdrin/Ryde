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
final rideOrdersStreamProvider = StreamProvider<List<RideOrder>>((ref) {
  final user = ref.read(userProvider);
  if (user == null) return Stream.value([]);
  
  final orderService = ref.watch(orderServiceProvider);
  return orderService.getRideOrdersStreamByUser(user.id);
});

// StreamProvider for request rides - keeping the original functionality
final requestRidesStreamProvider = StreamProvider<List<RequestRide>>((ref) {
  final user = ref.read(userProvider);
  if (user == null) return Stream.value([]);
  
  return ref.watch(RequestRideService.allRequestRideStreamProvider).when(
    data: (requests) => Stream.value(
      requests.where((request) => request.requestedBy == user.id).toList()
    ),
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

