import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ryde_rw/service/payment_checkout_service.dart';
import 'package:ryde_rw/service/payment_polling_service.dart';
import 'package:ryde_rw/widgets/payment_confirm_dialog.dart';
import 'package:ryde_rw/service/api_service.dart';
import 'package:ryde_rw/theme/colors.dart';
import 'package:ryde_rw/utils/utils.dart';

const _defaultCarImage =
    'https://images.unsplash.com/photo-1494976388531-d1058494cdd8?w=800&q=80';

class RentalsScreen extends StatefulWidget {
  const RentalsScreen({super.key});

  @override
  State<RentalsScreen> createState() => _RentalsScreenState();
}

class _RentalsScreenState extends State<RentalsScreen> with WidgetsBindingObserver {
  List<dynamic> _vehicles = [];
  bool _loading = true;
  String? _payingId;
  String? _pendingRentalIntentId;
  String? _pendingVehicleLabel;
  bool _checkingPendingPayment = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPendingRentalPaymentIfNeeded();
    }
  }

  Future<void> _confirmRentalPayment(
    String intentId,
    String vehicleLabel, {
    bool clientConfirmed = false,
  }) async {
    if (!mounted) return;
    final outcome = await showPaymentConfirmDialog(
      context,
      title: 'Rental payment',
      successMessage: 'Booking confirmed for $vehicleLabel. Payment successful!',
      clientConfirmed: clientConfirmed,
      poll: () => PaymentPollingService.waitForRentalIntentCompleted(
        intentId,
        maxMs: clientConfirmed ? 90000 : 20000,
      ),
    );
    if (!mounted) return;
    if (clientConfirmed || outcome == 'COMPLETED' || outcome == 'CLIENT_CONFIRMED') {
      _pendingRentalIntentId = null;
      _pendingVehicleLabel = null;
    } else if (outcome == 'TIMEOUT' && !clientConfirmed) {
      _pendingRentalIntentId = null;
      _pendingVehicleLabel = null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Payment submitted. If you completed checkout in the browser, your booking is confirmed.',
          ),
        ),
      );
      PaymentPollingService.syncRentalIntentInBackground(intentId);
    } else if (outcome == 'FAILED') {
      _pendingRentalIntentId = null;
      _pendingVehicleLabel = null;
    }
  }

  Future<void> _checkPendingRentalPaymentIfNeeded() async {
    final intentId = _pendingRentalIntentId;
    final label = _pendingVehicleLabel ?? 'your vehicle';
    if (!mounted || intentId == null) return;
    if (_checkingPendingPayment) return;
    setState(() => _checkingPendingPayment = true);
    try {
      await _confirmRentalPayment(intentId, label);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _checkingPendingPayment = false);
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getRentalVehicles();
      setState(() => _vehicles = (res['vehicles'] as List?) ?? []);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _book(Map<String, dynamic> vehicle) async {
    final id = vehicle['id']?.toString() ?? '';
    final dailyRate = (vehicle['dailyRate'] as num?)?.toDouble() ?? 0;
    if (dailyRate <= 0) return;

    setState(() => _payingId = id);
    try {
      final invoiceRes = await ApiService.createInvoiceForAmount(dailyRate, vehicleRef: id);
      final intentId = (invoiceRes['intentId'] ?? invoiceRes['intent_id'])?.toString();
      final vehicleLabel = '${vehicle['make']} ${vehicle['model']}';
      if (intentId != null && intentId.isNotEmpty) {
        _pendingRentalIntentId = intentId;
        _pendingVehicleLabel = vehicleLabel;
      }

      final payResult = await PaymentCheckoutService.openCheckoutForInvoice(
        context,
        invoiceRes,
      );

      if (!mounted) return;

      if (payResult?.ok == true && intentId != null && intentId.isNotEmpty) {
        await _confirmRentalPayment(intentId, vehicleLabel, clientConfirmed: true);
      } else if (payResult?.ok == false) {
        _pendingRentalIntentId = null;
        _pendingVehicleLabel = null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment was cancelled or failed.')),
        );
      } else if (intentId != null && intentId.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment opened in your browser. Return here when finished.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final message = _friendlyPaymentError(e);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _payingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Rentals'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _vehicles.isEmpty
              ? const Center(child: Text('No rental vehicles available.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _vehicles.length,
                  itemBuilder: (context, index) {
                    final v = _vehicles[index] as Map<String, dynamic>;
                    final imageUrl = (v['imageUrl'] ?? _defaultCarImage).toString();
                    final dailyRate = (v['dailyRate'] as num?)?.toDouble() ?? 0;
                    final id = v['id']?.toString() ?? '$index';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 180,
                            width: double.infinity,
                            child: CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(color: kLightGreyColor),
                              errorWidget: (_, __, ___) => CachedNetworkImage(
                                imageUrl: _defaultCarImage,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${v['make']} ${v['model']}',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${v['year']} • ${v['color']} • ${v['type']}',
                                  style: TextStyle(color: kSimpleText, fontSize: 13),
                                ),
                                if (v['description'] != null) ...[
                                  const SizedBox(height: 8),
                                  Text(v['description'].toString(), style: TextStyle(color: kSimpleText, fontSize: 13)),
                                ],
                                const SizedBox(height: 12),
                                Text(
                                  'RWF ${formatPriceWithCommas(dailyRate.round())} / day',
                                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _payingId == id ? null : () => _book(v),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    child: _payingId == id
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          )
                                        : const Text('Book & Pay'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  String _friendlyPaymentError(Object e) {
    var message = e.toString().replaceFirst('Exception: ', '');
    if (message.toLowerCase().contains('irembopay') &&
        message.toLowerCase().contains('not configured')) {
      return 'Payment is not configured on the API server. Set IREMBOPAY_PUBLIC_KEY on '
          'the backend or use the production API (default, no --dart-define=API_BASE_URL).';
    }
    return message;
  }
}
