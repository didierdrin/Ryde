import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ryde_rw/screens/payments/irembopay_checkout.dart';
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

class _RentalsScreenState extends State<RentalsScreen> {
  List<dynamic> _vehicles = [];
  bool _loading = true;
  String? _payingId;

  @override
  void initState() {
    super.initState();
    _load();
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
      final checkoutUrl = (invoiceRes['checkoutUrl'] ?? invoiceRes['checkout_url'])?.toString();
      if (checkoutUrl == null || checkoutUrl.isEmpty) {
        throw Exception('Could not create payment invoice');
      }

      if (!mounted) return;
      final payResult = await Navigator.of(context).push<IremboPayCheckoutResult>(
        MaterialPageRoute(builder: (_) => IremboPayCheckoutScreen(checkoutUrl: checkoutUrl)),
      );

      if (payResult?.ok == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: kGreen,
            content: Text('Booking confirmed for ${vehicle['make']} ${vehicle['model']}'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
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
                                  'RWF ${formatPriceWithCommas(dailyRate)} / day',
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
}
