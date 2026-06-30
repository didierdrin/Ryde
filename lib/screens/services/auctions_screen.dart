import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ryde_rw/service/api_service.dart';
import 'package:ryde_rw/screens/services/services_history_action.dart';
import 'package:ryde_rw/theme/colors.dart';
import 'package:ryde_rw/utils/utils.dart';

const _defaultImage =
    'https://images.unsplash.com/photo-1494976388531-d1058494cdd8?w=800&q=80';

class AuctionsScreen extends StatefulWidget {
  const AuctionsScreen({super.key});

  @override
  State<AuctionsScreen> createState() => _AuctionsScreenState();
}

class _AuctionsScreenState extends State<AuctionsScreen> {
  List<dynamic> _listings = [];
  bool _loading = true;
  String _filter = 'ALL';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final type = _filter == 'ALL' ? null : _filter;
      final res = await ApiService.getAuctionListings(type: type);
      setState(() => _listings = (res['listings'] as List?) ?? []);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showCreateDialog() async {
    final titleCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final makeCtrl = TextEditingController();
    final modelCtrl = TextEditingController();
    String listingType = 'SELL';

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New listing'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: listingType,
                items: const [
                  DropdownMenuItem(value: 'SELL', child: Text('Sell vehicle')),
                  DropdownMenuItem(value: 'BUY', child: Text('Want to buy')),
                ],
                onChanged: (v) => listingType = v ?? 'SELL',
                decoration: const InputDecoration(labelText: 'Type'),
              ),
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
              TextField(controller: makeCtrl, decoration: const InputDecoration(labelText: 'Make')),
              TextField(controller: modelCtrl, decoration: const InputDecoration(labelText: 'Model')),
              TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (RWF)')),
              TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Description')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              try {
                await ApiService.createAuctionListing({
                  'listingType': listingType,
                  'title': titleCtrl.text,
                  'make': makeCtrl.text,
                  'model': modelCtrl.text,
                  'price': double.tryParse(priceCtrl.text) ?? 0,
                  'description': descCtrl.text,
                  'imageUrl': _defaultImage,
                });
                if (ctx.mounted) Navigator.pop(ctx);
                _load();
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
            child: const Text('Publish'),
          ),
        ],
      ),
    );
  }

  Future<void> _purchase(String listingId, String title, num price) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm purchase'),
        content: Text('Buy "$title" for RWF ${formatPriceWithCommas(price.round())}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Buy')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ApiService.purchaseAuctionListing(listingId);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: kGreen, content: Text('Purchase recorded!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Vehicle Auction'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          ...servicesHistoryActions(context),
          IconButton(icon: const Icon(Icons.add), onPressed: _showCreateDialog),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: ['ALL', 'SELL', 'BUY'].map((f) {
                final selected = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f == 'ALL' ? 'All' : f == 'SELL' ? 'For Sale' : 'Wanted'),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _filter = f);
                      _load();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _listings.isEmpty
                    ? const Center(child: Text('No listings yet.'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _listings.length,
                        itemBuilder: (context, index) {
                          final item = _listings[index] as Map<String, dynamic>;
                          final imageUrl = (item['imageUrl'] ?? _defaultImage).toString();
                          final price = (item['price'] as num?) ?? 0;
                          final type = item['listingType']?.toString() ?? 'SELL';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Stack(
                                  children: [
                                    CachedNetworkImage(
                                      imageUrl: imageUrl,
                                      height: 160,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                    Positioned(
                                      top: 8,
                                      left: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: type == 'SELL' ? Colors.green : Colors.orange,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          type == 'SELL' ? 'For Sale' : 'Wanted',
                                          style: const TextStyle(color: Colors.white, fontSize: 11),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item['title']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      if (item['make'] != null)
                                        Text('${item['make']} ${item['model'] ?? ''}', style: TextStyle(color: kSimpleText, fontSize: 13)),
                                      const SizedBox(height: 6),
                                      Text('RWF ${formatPriceWithCommas(price.round())}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                      if (type == 'SELL')
                                        Padding(
                                          padding: const EdgeInsets.only(top: 10),
                                          child: SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              onPressed: () => _purchase(item['id'].toString(), item['title'].toString(), price),
                                              style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                                              child: const Text('Buy now'),
                                            ),
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
        ],
      ),
    );
  }
}
