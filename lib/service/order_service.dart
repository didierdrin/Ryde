import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ryde_rw/models/orders.dart';

class OrderService {
  final CollectionReference ordersCollection = FirebaseFirestore.instance
      .collection('orders');

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
}
