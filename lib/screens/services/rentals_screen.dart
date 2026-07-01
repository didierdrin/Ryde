import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ryde_rw/service/payment_checkout_service.dart';
import 'package:ryde_rw/service/payment_polling_service.dart';
import 'package:ryde_rw/widgets/order_placed_feedback.dart';
import 'package:ryde_rw/service/api_service.dart';
import 'package:ryde_rw/screens/services/services_history_action.dart';
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
      _load();
      _checkPendingRentalPaymentIfNeeded();
    }
  }

  bool _isAvailable(Map<String, dynamic> vehicle) {
    if (vehicle['isAvailable'] == false || vehicle['is_available'] == false) {
      return false;
    }
    final untilRaw = vehicle['rentedUntil'] ?? vehicle['rented_until'];
    if (untilRaw != null) {
      final parsed = DateTime.tryParse(untilRaw.toString().substring(0, 10));
      if (parsed != null) {
        final today = DateTime.now();
        final end = DateTime(parsed.year, parsed.month, parsed.day);
        final now = DateTime(today.year, today.month, today.day);
        if (!end.isBefore(now)) return false;
      }
    }
    return vehicle['isAvailable'] == true || vehicle['is_available'] == true;
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  int _rentalDays(DateTime start, DateTime end) {
    final diff = end.difference(start).inDays;
    return diff + 1;
  }

  Widget _statusBadge(bool available) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: available ? Colors.green.shade700 : Colors.amber.shade700,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        available ? 'Available' : 'Rented',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Future<void> _finalizeRentalPayment(
    String intentId,
    String vehicleLabel, {
    bool clientConfirmed = false,
  }) async {
    if (!mounted) return;
    if (clientConfirmed) {
      try {
        await ApiService.acknowledgeRentalPayment(intentId);
      } catch (_) {
        PaymentPollingService.syncRentalIntentInBackground(intentId);
      }
      if (!mounted) return;
      _pendingRentalIntentId = null;
      _pendingVehicleLabel = null;
      showOrderPlacedFeedback(
        context,
        message: 'Order placed! $vehicleLabel is booked.',
      );
      await _load();
      return;
    }

    final outcome = await PaymentPollingService.waitForRentalIntentCompleted(
      intentId,
      maxMs: 20000,
    );
    if (!mounted) return;
    if (outcome == 'COMPLETED') {
      _pendingRentalIntentId = null;
      _pendingVehicleLabel = null;
      showOrderPlacedFeedback(context, message: 'Order placed! $vehicleLabel is booked.');
      await _load();
    } else if (outcome == 'TIMEOUT') {
      _pendingRentalIntentId = null;
      _pendingVehicleLabel = null;
      showOrderPlacedFeedback(context);
      PaymentPollingService.syncRentalIntentInBackground(intentId);
      await _load();
    } else if (outcome == 'FAILED') {
      _pendingRentalIntentId = null;
      _pendingVehicleLabel = null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment was cancelled or failed.')),
      );
    }
  }

  Future<void> _checkPendingRentalPaymentIfNeeded() async {
    final intentId = _pendingRentalIntentId;
    final label = _pendingVehicleLabel ?? 'your vehicle';
    if (!mounted || intentId == null) return;
    if (_checkingPendingPayment) return;
    setState(() => _checkingPendingPayment = true);
    try {
      await _finalizeRentalPayment(intentId, label);
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

  Future<void> _showRentDialog(Map<String, dynamic> vehicle) async {
    final dailyRate = (vehicle['dailyRateWithoutDriver'] as num?)?.toDouble() ??
        (vehicle['dailyRate'] as num?)?.toDouble() ??
        0;
    final dailyRateWithDriver = (vehicle['dailyRateWithDriver'] as num?)?.toDouble() ?? dailyRate;
    if (dailyRate <= 0) return;

    final now = DateTime.now();
    DateTime startDate = DateTime(now.year, now.month, now.day);
    DateTime endDate = startDate.add(const Duration(days: 1));
    bool withDriver = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final days = _rentalDays(startDate, endDate);
          final rate = withDriver ? dailyRateWithDriver : dailyRate;
          final total = rate * days;

          Future<void> pickDate({required bool isStart}) async {
            final initial = isStart ? startDate : endDate;
            final picked = await showDatePicker(
              context: context,
              initialDate: initial,
              firstDate: isStart ? startDate : startDate,
              lastDate: DateTime(now.year + 2),
            );
            if (picked == null) return;
            setDialogState(() {
              if (isStart) {
                startDate = DateTime(picked.year, picked.month, picked.day);
                if (endDate.isBefore(startDate)) {
                  endDate = startDate;
                }
              } else {
                endDate = DateTime(picked.year, picked.month, picked.day);
              }
            });
          }

          return AlertDialog(
            title: Text('Rent ${vehicle['make']} ${vehicle['model']}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rental period', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('From'),
                    subtitle: Text(_formatDate(startDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => pickDate(isStart: true),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('To'),
                    subtitle: Text(_formatDate(endDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => pickDate(isStart: false),
                  ),
                  Text('$days day${days == 1 ? '' : 's'}', style: TextStyle(color: kSimpleText, fontSize: 13)),
                  const SizedBox(height: 12),
                  const Text('Option', style: TextStyle(fontWeight: FontWeight.w600)),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('No driver'),
                          selected: !withDriver,
                          onSelected: (_) => setDialogState(() => withDriver = false),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('With driver'),
                          selected: withDriver,
                          onSelected: (_) => setDialogState(() => withDriver = true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Total: RWF ${formatPriceWithCommas(total.round())}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Continue to pay')),
            ],
          );
        },
      ),
    );

    if (confirmed != true || !mounted) return;

    await _book(
      vehicle,
      rentalStartDate: _formatDate(startDate),
      rentalEndDate: _formatDate(endDate),
      withDriver: withDriver,
    );
  }

  Future<void> _book(
    Map<String, dynamic> vehicle, {
    required String rentalStartDate,
    required String rentalEndDate,
    bool withDriver = false,
  }) async {
    final id = vehicle['id']?.toString() ?? '';

    setState(() => _payingId = id);
    try {
      final invoiceRes = await ApiService.createInvoiceForAmount(
        vehicleRef: id,
        rentalStartDate: rentalStartDate,
        rentalEndDate: rentalEndDate,
        withDriver: withDriver,
      );
      final intentId = (invoiceRes['intentId'] ?? invoiceRes['intent_id'])?.toString();
      final vehicleLabel = '${vehicle['make']} ${vehicle['model']}';
      if (intentId != null && intentId.isNotEmpty) {
        _pendingRentalIntentId = intentId;
        _pendingVehicleLabel = vehicleLabel;
      }

      if (!mounted) return;
      final payResult = await PaymentCheckoutService.openCheckoutForInvoice(
        context,
        invoiceRes,
      );

      if (!mounted) return;

      if (payResult?.ok == true && intentId != null && intentId.isNotEmpty) {
        await _finalizeRentalPayment(intentId, vehicleLabel, clientConfirmed: true);
      } else if (payResult?.ok == false) {
        if (intentId != null && intentId.isNotEmpty) {
          await ApiService.cancelRentalPayment(intentId);
        }
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
        actions: servicesHistoryActions(context),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _vehicles.isEmpty
              ? const Center(child: Text('No rental vehicles listed yet.'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _vehicles.length,
                  itemBuilder: (context, index) {
                    final v = _vehicles[index] as Map<String, dynamic>;
                    final imageUrl = (v['imageUrl'] ?? _defaultCarImage).toString();
                    final dailyRate = (v['dailyRateWithoutDriver'] as num?)?.toDouble() ??
                        (v['dailyRate'] as num?)?.toDouble() ??
                        0;
                    final id = v['id']?.toString() ?? '$index';
                    final available = _isAvailable(v);
                    final rentedUntil = v['rentedUntil']?.toString();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
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
                              Positioned(
                                top: 12,
                                left: 12,
                                child: _statusBadge(available),
                              ),
                            ],
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
                                const SizedBox(height: 6),
                                _statusBadge(available),
                                const SizedBox(height: 4),
                                Text(
                                  '${v['year']} • ${v['color']} • ${v['type']}',
                                  style: TextStyle(color: kSimpleText, fontSize: 13),
                                ),
                                if (!available && rentedUntil != null && rentedUntil.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      'Rented until $rentedUntil',
                                      style: TextStyle(color: Colors.amber.shade800, fontSize: 12, fontWeight: FontWeight.w500),
                                    ),
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
                                    onPressed: !available || _payingId == id ? null : () => _showRentDialog(v),
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
                                        : Text(available ? 'Rent' : 'Currently rented'),
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
