import 'package:ryde_rw/service/api_service.dart';

/// Polls the backend until the IremboPay webhook updates payment status (Step 7).
class PaymentPollingService {
  static Future<String> waitForTripPaymentCompleted(
    String tripId, {
    int maxMs = 90000,
    Duration interval = const Duration(seconds: 2),
  }) async {
    final start = DateTime.now();
    while (DateTime.now().difference(start).inMilliseconds < maxMs) {
      final res = await ApiService.getPaymentByTrip(tripId);
      final payment = (res['payment'] as Map?)?.cast<String, dynamic>() ?? {};
      final status = _status(payment);
      if (status == 'COMPLETED') return 'COMPLETED';
      if (status == 'FAILED') return 'FAILED';
      await Future.delayed(interval);
    }
    return 'TIMEOUT';
  }

  static Future<String> waitForRentalIntentCompleted(
    String intentId, {
    int maxMs = 90000,
    Duration interval = const Duration(seconds: 2),
  }) async {
    final start = DateTime.now();
    while (DateTime.now().difference(start).inMilliseconds < maxMs) {
      final res = await ApiService.getRentalIntent(intentId);
      final intent = (res['intent'] as Map?)?.cast<String, dynamic>() ?? {};
      final status = _status(intent);
      if (status == 'COMPLETED') return 'COMPLETED';
      if (status == 'FAILED') return 'FAILED';
      await Future.delayed(interval);
    }
    return 'TIMEOUT';
  }

  static String messageForOutcome(String outcome, {String? successMessage}) {
    switch (outcome) {
      case 'COMPLETED':
      case 'CLIENT_CONFIRMED':
        return successMessage ?? 'Payment successful! Your order is confirmed.';
      case 'FAILED':
        return 'Payment failed or was cancelled.';
      default:
        return 'Payment submitted. If you completed checkout, confirmation may take a moment to sync.';
    }
  }

  /// Fire-and-forget webhook sync after IremboPay client callback.
  static void syncTripPaymentInBackground(String tripId) {
    waitForTripPaymentCompleted(tripId);
  }

  static void syncRentalIntentInBackground(String intentId) {
    waitForRentalIntentCompleted(intentId);
  }

  static String _status(Map<String, dynamic> row) =>
      (row['payment_status'] ?? row['paymentStatus'] ?? row['status'] ?? '')
          .toString()
          .toUpperCase();
}
