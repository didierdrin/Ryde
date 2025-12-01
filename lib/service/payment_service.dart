import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ryde_rw/models/payment_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PaymentsService {
  final CollectionReference paymentsCollection = FirebaseFirestore.instance
      .collection('payments');

  // Fetch a single payment by userId and specific payment ID format
  Future<Payment?> getUserData(String userId) async {
    try {
      DocumentSnapshot doc = await paymentsCollection.doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return Payment.fromFirestore(doc);
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  // Fetch all payments for a specific user by userId
  Future<List<Payment>> getAllPaymentsForUser(String userId) async {
    QuerySnapshot querySnapshot = await paymentsCollection
        .where('userId', isEqualTo: userId)
        .get();
    return querySnapshot.docs.map((doc) => Payment.fromFirestore(doc)).toList();
  }

  // Fetch all payments in the collection
  Future<List<Payment>> getAllPayments() async {
    QuerySnapshot querySnapshot = await paymentsCollection.get();
    return querySnapshot.docs.map((doc) => Payment.fromFirestore(doc)).toList();
  }
}

// Payment transactions provider
final paymentTransactionsProvider =
    FutureProvider.family<List<Payment>, String>((ref, userId) async {
      final service = PaymentsService();
      return await service.getAllPaymentsForUser(userId);
    });
