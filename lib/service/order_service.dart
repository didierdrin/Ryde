import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ryde_rw/models/orders.dart';
import 'package:ryde_rw/models/ride_order.dart';

class OrderService {
  final CollectionReference ordersCollection = FirebaseFirestore.instance
      .collection('orders');
  final CollectionReference rideOrdersCollection = FirebaseFirestore.instance
      .collection('ride_orders');

  // Stream to get all orders in real-time
  Stream<List<UserOrder>> getAllOrdersStream() {
    return ordersCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserOrder.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Stream to get a single order by ID in real-time
  Stream<UserOrder?> getOrderStreamById(String orderId) {
    return ordersCollection.doc(orderId).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return UserOrder.fromMap(snapshot.data() as Map<String, dynamic>);
      } else {
        return null; // Order not found
      }
    });
  }

  // Create ride order
  Future<void> createRideOrder(Map<String, dynamic> orderData) async {
    await rideOrdersCollection.add(orderData);
  }

  // Stream to get ride orders for current user by userId (phone number)
  Stream<List<RideOrder>> getRideOrdersStreamByUserId(String userId) {
    print('=== ORDER_SERVICE DEBUG ===');
    print('Querying ride_orders with userId: $userId');
    
    if (userId.isEmpty) {
      print('No userId provided, returning empty stream');
      return Stream.value([]);
    }
    
    return rideOrdersCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      print('Firebase snapshot received: ${snapshot.docs.length} documents');
      final orders = snapshot.docs.map((doc) {
        print('Document ID: ${doc.id}, Data: ${doc.data()}');
        return RideOrder.fromMap(doc.data() as Map<String, dynamic>, docId: doc.id);
      }).toList();
      print('Parsed ${orders.length} RideOrders');
      return orders;
    });
  }

  // Update ride order status
  Future<void> updateRideOrderStatus(String orderId, String status, {String? driverId}) async {
    final updateData = {'status': status};
    if (driverId != null) {
      updateData['driverId'] = driverId;
    }
    await rideOrdersCollection.doc(orderId).update(updateData);
  }
}

