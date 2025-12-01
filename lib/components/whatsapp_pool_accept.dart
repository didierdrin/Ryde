import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ryde_rw/models/offer_pool_model.dart';
import 'package:ryde_rw/models/whatsapp_model.dart';
import 'package:ryde_rw/service/offer_pool_service.dart';
import 'package:ryde_rw/service/whatsapp_service.dart';
import 'package:ryde_rw/shared/shared_states.dart';
import 'package:ryde_rw/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsappPoolAccept extends ConsumerWidget {
  final PassengerOfferPool offerPool;
  final WhatsappModel offer;
  const WhatsappPoolAccept(this.offerPool, this.offer, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final region = ref.read(regionProvider);
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: theme.scaffoldBackgroundColor,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: ClipOval(
                  child: CachedNetworkImage(
                    height: 47,
                    width: 47,
                    imageUrl: 'assets/1.png',
                    fit: BoxFit.cover,
                    progressIndicatorBuilder: (context, url, progress) =>
                        Center(
                          child: SizedBox(
                            height: 50,
                            width: 50,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              value: progress.progress,
                            ),
                          ),
                        ),
                    errorWidget: (context, url, error) =>
                        Image.asset('assets/1.png'),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        offer.requestedBy,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    Text(
                      "RWF" + formatPriceWithCommas(offer.price!),
                      style: theme.textTheme.titleSmall,
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.verified_user_sharp,
                      color: theme.primaryColor,
                      size: 12,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                        ),
                      ),
                    ),
                    Text(
                      offer.type == 'passengers'
                          ? '${offer.seats} seats'
                          : (offer.measure == 'ton'
                                ? '${removeZeros('${offer.quantity}')} ${offer.measure}'
                                : '${offer.quantity} ${offer.measure}'),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                SizedBox(height: 14),
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.circle,
                        color: Colors.grey[300],
                        size: 5,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        offer.pickupLocation.address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge!.copyWith(fontSize: 10),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Icon(
                    Icons.more_vert,
                    color: Colors.grey[400],
                    size: 10,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.grey[300],
                      size: 12,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        offer.dropoffLocation.address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge!.copyWith(fontSize: 10),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14),
                if (!offer.accepted && !offer.rejected)
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            await WhatsappService.updateRequestRide(offer.id!, {
                              'rejected': true,
                            });
                            // await MessengerService.lifutiRejected(
                            //     offer, context);
                          },
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              color: Color(0xfffbe3e3),
                            ),
                            child: Center(
                              child: Text(
                                "Decline", 
                                style: Theme.of(context).textTheme.bodyLarge!
                                    .copyWith(
                                      fontSize: 10,
                                      color: Color(0xffdd142c),
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final String currentUser = offer.requestedBy;
                            final int userRequestedSeats = offer.seats!;
                            final int driverAvailableSeats =
                                offerPool.selectedSeat!;

                            if (offer.type == 'passengers') {
                              if (offerPool.selectedSeat! >=
                                  offerPool.availableSeat.length) {
                                await WhatsappService.updateRequestRide(
                                  offer.id!,
                                  {'accepted': true},
                                );

                                for (int i = 0; i < userRequestedSeats; i++) {
                                  offerPool.availableSeat.add(currentUser);
                                }

                                final emptySeats =
                                    driverAvailableSeats -
                                    offerPool.availableSeat.length;

                                // await MessengerService.acceptedLifuti(
                                //     offer, context);
                                await OfferPoolService.updateofferpool(
                                  offer.offerpool,
                                  {
                                    'availableSeat': offerPool.availableSeat,
                                    'emptySeat': emptySeats,
                                  },
                                );

                                if (emptySeats == 0) {
                                  await OfferPoolService.updateofferpool(
                                    offer.offerpool,
                                    {'isSeatFull': true},
                                  );
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'OOPS! Fail to approve pool seat full',
                                    ),
                                    backgroundColor: Colors.red,
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                              }
                            } else if (offer.type == 'goods') {
                              final driverQuantity = offerPool.quantity;
                              final offerQuantity = offer.quantity;
                              if (driverQuantity! >= offerQuantity!) {
                                final remainQuantity =
                                    driverQuantity - offerQuantity;

                                await WhatsappService.updateRequestRide(
                                  offer.id!,
                                  {'accepted': true},
                                );

                                offerPool.availableSeat.add(currentUser);

                                if (remainQuantity >= 1000) {
                                  await OfferPoolService.updateofferpool(
                                    offer.offerpool,
                                    {
                                      'availableSeat': offerPool.availableSeat,
                                      'quantity': remainQuantity,
                                      'measure': 'ton',
                                    },
                                  );
                                } else {
                                  await OfferPoolService.updateofferpool(
                                    offer.offerpool,
                                    {
                                      'availableSeat': offerPool.availableSeat,
                                      'quantity': remainQuantity,
                                      'measure': 'kg',
                                    },
                                  );
                                }

                                await OfferPoolService.updateofferpool(
                                  offer.offerpool,
                                  {
                                    'availableSeat': offerPool.availableSeat,
                                    'quantity': remainQuantity,
                                  },
                                );

                                // await MessengerService.acceptedLifuti(
                                //     offer, context);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'OOPS! Fail to approve Ryde Goods full',
                                    ),
                                    backgroundColor: Colors.red,
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                              }
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              color: Theme.of(context).primaryColor,
                            ),
                            child: Center(
                              child: Text(
                                "Accept", //locale?.accept ?? '',
                                style: Theme.of(context).textTheme.bodyLarge!
                                    .copyWith(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                else if (offer.accepted)
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: theme.primaryColor,
                        size: 18,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Accepted", // locale?.accepted ?? '',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.primaryColor,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      GestureDetector(
                        onTap: () async {
                          final phone = offer.requestedBy.replaceFirst('+', '');
                          ;
                          final Uri url = Uri.parse('https://wa.me/$phone');

                          try {
                            if (await canLaunchUrl(url)) {
                              await launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Could not launch WhatsApp.'),
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: Fail')),
                            );
                          }
                        },
                        child: SizedBox(
                          width: 30,
                          height: 30,
                          child: Image.asset(
                            width: 30,
                            height: 30,
                            'assets/whatsapp.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  )
                else if (offer.rejected)
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Color(0xffdd142c),
                        size: 18,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            "Rejected", // locale?.rejected ?? '',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: Color(0xffdd142c),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

