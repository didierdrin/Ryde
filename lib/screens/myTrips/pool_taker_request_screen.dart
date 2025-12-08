import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:ryde_rw/components/pool_reject_accept.dart';
import 'package:ryde_rw/components/whatsapp_pool_accept.dart';
import 'package:ryde_rw/components/widgets/color_button.dart';
import 'package:ryde_rw/models/offer_pool_model.dart';
import 'package:ryde_rw/models/whatsapp_model.dart';
import '../myTrips/pool_taker_accepted_offer.dart';
import 'package:ryde_rw/service/offer_pool_service.dart';
import 'package:ryde_rw/service/request_rider_service.dart';
import 'package:ryde_rw/service/user_service.dart';
import 'package:ryde_rw/service/whatsapp_service.dart';

class PoolTakerRequestScreen extends ConsumerStatefulWidget {
  final PassengerOfferPool offerPool;
  const PoolTakerRequestScreen({super.key, required this.offerPool});

  @override
  ConsumerState<PoolTakerRequestScreen> createState() =>
      _PoolTakerRequestScreenState();
}

class _PoolTakerRequestScreenState
    extends ConsumerState<PoolTakerRequestScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final requestonOfferPoolStreams = ref.watch(
      RequestRideService.offerpoolsForRiderProvider(widget.offerPool.id!),
    );
    final whatsappOfferPoolStreams = ref.watch(
      WhatsappService.offerpoolsForRiderProvider(widget.offerPool.id!),
    );
    final userstream = ref.watch(UserService.usersStream);
    final offerpool = ref.watch(
      OfferPoolService.poolRealTimeStreamProvider(widget.offerPool.id!),
    );
    final isLoading =
        requestonOfferPoolStreams.isLoading ||
        userstream.isLoading ||
        whatsappOfferPoolStreams.isLoading ||
        offerpool.isLoading;

    final requestonoffer = (requestonOfferPoolStreams.value ?? []).where((e) {
      print(e.price);
      return e.rider == widget.offerPool.user && e.cancelled != true;
    }).toList();

    final whatsappOffer = (whatsappOfferPoolStreams.value ?? [])
        .where((e) => e.rider == widget.offerPool.user && e.cancelled != true)
        .toList();

    final List<Request> requests = [
      ...requestonoffer.map(
        (order) => Request(
          date: order.createdAt!,
          isOrder: true,
          requestPool: order,
          requested: order.requested,
        ),
      ),
      ...whatsappOffer.map(
        (reservation) => Request(
          date: reservation.createdAt!,
          isOrder: false,
          whatsappPool: reservation,
        ),
      ),
    ];

    requests.sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Take Request", //locale?.poolTakerRequest ?? '',
          style: theme.textTheme.titleSmall?.copyWith(fontSize: 16),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ModalProgressHUD(
        inAsyncCall: isLoading,
        child: Container(
          margin: EdgeInsets.only(top: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              if (requests.isEmpty && !isLoading)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 200),
                      Icon(
                        Icons.drive_eta_rounded,
                        size: 50,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 10),
                      Text(
                        'No Request Found',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.all(15),
                  itemCount: requests.length,
                  itemBuilder: (BuildContext context, index) {
                    final offer = requests[index];

                    if (offer.isOrder) {
                      return PoolRejectAccept(
                        widget.offerPool,
                        offer.requestPool!,
                      );
                    } else {
                      return WhatsappPoolAccept(
                        widget.offerPool,
                        offer.whatsappPool!,
                      );
                    }
                  },
                  separatorBuilder: (context, index) {
                    return SizedBox(height: 10);
                  },
                ),
              ),
              if (!widget.offerPool.completed) ...[
                SafeArea(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PoolTakerAcceptedOffer(
                            offerpool: widget.offerPool,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: ColorButton(
                          widget.offerPool.isRideStarted
                              ? 'View Details'
                              : "Start ride",
                        ),
                      
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Column buildColumn(ThemeData theme, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          child: Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 14),
          ),
        ),
        SizedBox(height: 15),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          child: Text(
            subtitle,
            style: theme.textTheme.titleSmall?.copyWith(fontSize: 14),
          ),
        ),
      ],
    );
  }
}

