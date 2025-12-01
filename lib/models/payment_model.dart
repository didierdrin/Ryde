import 'package:cloud_firestore/cloud_firestore.dart';

class Payment {
  final double amount;
  final String providerCode;
  final String method;
  final String rideId;
  final bool nfcTransaction;
  final String userId;
  final String transactionId;
  final String transactionType;
  final String countryCode;
  final String paymentId;
  final String currency;
  final String status;
  final Timestamp timestamp;

  Payment({
    required this.amount,
    required this.providerCode,
    required this.method,
    required this.rideId,
    required this.nfcTransaction,
    required this.userId,
    required this.transactionId,
    required this.transactionType,
    required this.countryCode,
    required this.paymentId,
    required this.currency,
    required this.status,
    required this.timestamp,
  });

  factory Payment.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Payment(
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      providerCode: data['providerCode']?.toString() ?? '',
      method: data['method']?.toString() ?? 'Unknown',
      rideId: data['rideId']?.toString() ?? '',
      nfcTransaction: data['nfcTransaction'] as bool? ?? false,
      userId: data['userId']?.toString() ?? '',
      transactionId: data['transactionId']?.toString() ?? '',
      transactionType: data['transactionType']?.toString() ?? '',
      countryCode: data['countryCode']?.toString() ?? '',
      paymentId: data['paymentId']?.toString() ?? '',
      currency: data['currency']?.toString() ?? 'Unknown',
      status: data['status']?.toString() ?? 'unknown',
      timestamp: data['timestamp'] as Timestamp? ?? Timestamp.now(),
    );
  }
}

