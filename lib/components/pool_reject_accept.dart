import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ryde_rw/models/offer_pool_model.dart';
import 'package:ryde_rw/models/request_model.dart';
import 'package:ryde_rw/screens/chats/chat_page.dart';
import 'package:ryde_rw/service/chat_service.dart';
import 'package:ryde_rw/service/location_service.dart';
import 'package:ryde_rw/service/messages_service.dart';
import 'package:ryde_rw/service/offer_pool_service.dart';
import 'package:ryde_rw/service/request_rider_service.dart';
import 'package:ryde_rw/shared/shared_states.dart';
import 'package:ryde_rw/theme/colors.dart';
import 'package:ryde_rw/utils/utils.dart';

class PoolRejectAccept extends ConsumerWidget {
  final PassengerOfferPool offerPoo;
  final RequestRide offer;
  const PoolRejectAccept(this.offerPoo, this.offer, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
  
    //
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
                SizedBox(height: 14),
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: Icon(Icons.circle, color: kMainColor, size: 15),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        offer.pickupLocation.address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge!.copyWith(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(Icons.more_vert, color: kMainColor, size: 15),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: kMainColor,
                      size: 20,
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
                if (!offer.accepted && !offer.rejected && !offer.requested)
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(25),
                                ),
                              ),
                              isScrollControlled: true,
                              builder: (BuildContext context) {
                                return AnimatedPadding(
                                  padding: MediaQuery.of(context).viewInsets,
                                  duration: const Duration(milliseconds: 200),
                                  child: Container(
                                    padding: EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(25),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          spreadRadius: 5,
                                          blurRadius: 10,
                                          offset: Offset(0, -5),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.warning_amber_outlined,
                                          color: Colors.orange[600],
                                          size: 40,
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          "Are you sure you want to decline this offer?",
                                          style: GoogleFonts.mulish(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w300,
                                            color: Colors.black54,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        SizedBox(height: 24),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            ElevatedButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.transparent,
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 24,
                                                  vertical: 12,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  side: BorderSide(
                                                    color: Colors.grey[400]!,
                                                  ),
                                                ),
                                                elevation: 0,
                                              ),
                                              child: Text(
                                                "Cancel",
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w300,
                                                ),
                                              ),
                                            ),
                                            ElevatedButton(
                                              onPressed: () async {
                                                await RequestRideService.updateRequestRide(
                                                  offer.id!,
                                                  {'rejected': true},
                                                );
                                                await MessengerService.lifutiRejected(
                                                  offer,
                                                  context,
                                                );
                                                Navigator.pop(context);
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Color(
                                                  0xfffbe3e3,
                                                ),
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 24,
                                                  vertical: 12,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                elevation: 0,
                                              ),
                                              child: Text(
                                                "Yes, Decline",
                                                style: GoogleFonts.mulish(
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
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
                                "Decline", //locale?.decline ?? '',
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
                            showModalBottomSheet(
                              context: context,
                              useSafeArea: true,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                              ),
                              builder: (BuildContext context) {
                                return Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(height: 20),
                                      // Confirmation Message
                                      Text(
                                        "Are you sure you want to confirm this Ryde?",
                                        style: GoogleFonts.mulish(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black54,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: 20),
                                      // Action Buttons
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.transparent,
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 24,
                                                vertical: 12,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                side: BorderSide(
                                                  color: Colors.grey[400]!,
                                                ),
                                              ),
                                              elevation: 0,
                                            ),
                                            child: Text(
                                              "Cancel",
                                              style: GoogleFonts.mulish(
                                                color: Colors.black54,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ),
                                          ElevatedButton(
                                            onPressed: () async {
                                              print(offer.type);
                                              Navigator.pop(context);
                                              final String currentUser =
                                                  offer.requestedBy;
                                              final int userRequestedSeats =
                                                  offer.seats!;

                                              await RequestRideService.updateRequestRide(
                                                offer.id!,
                                                {'accepted': true},
                                              );

                                              offerPoo.availableSeat.add(
                                                currentUser,
                                              );

                                              await MessengerService.acceptedLifuti(
                                                offer,
                                                context,
                                              );
                                              await OfferPoolService.updateofferpool(
                                                offer.offerpool,
                                                {
                                                  'availableSeat':
                                                      offerPoo.availableSeat,
                                                  'emptySeat': 1,
                                                },
                                              );

                                              await OfferPoolService.updateofferpool(
                                                offer.offerpool,
                                                {'isSeatFull': false},
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              elevation: 0,
                                              backgroundColor: Theme.of(
                                                context,
                                              ).primaryColor,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 24,
                                                vertical: 12,
                                              ),
                                            ),
                                            child: Text(
                                              "Confirm",
                                              style: GoogleFonts.mulish(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
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
                          final currentUser = FirebaseAuth.instance.currentUser;
                          if (currentUser == null) return;

                          final chatId = await ChatService.getOrCreateChat(
                            currentUser.uid,
                            offer.requestedBy,
                          );

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatPage(
                                chatId: chatId,
                                otherUserId: offer.requestedBy,
                              ),
                            ),
                          );
                        },
                        child: SizedBox(
                          width: 30,
                          height: 30,
                          child: Icon(Icons.chat),
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
                            "Rejected", //locale?.rejected ?? '',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: Color(0xffdd142c),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                else if (offer.requested)
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
                          'waiting',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.primaryColor,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      GestureDetector(
                        onTap: () async {
                          final currentUser = FirebaseAuth.instance.currentUser;
                          if (currentUser == null) return;

                          final chatId = await ChatService.getOrCreateChat(
                            currentUser.uid,
                            offer.requestedBy,
                          );

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatPage(
                                chatId: chatId,
                                otherUserId: offer.requestedBy,
                              ),
                            ),
                          );
                        },
                        child: SizedBox(
                          width: 30,
                          height: 30,
                          child: Icon(Icons.chat),
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

