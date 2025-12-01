import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ryde_rw/models/offer_pool_model.dart';
import 'package:ryde_rw/service/offer_pool_service.dart';
import 'package:ryde_rw/theme/colors.dart';

class ProfileAvatar extends ConsumerWidget {
  final PassengerOfferPool pool;

  const ProfileAvatar({super.key, required this.pool});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final poolStream = ref.watch(
      OfferPoolService.poolRealTimeStreamProvider(pool.id!),
    );
    return poolStream.when(
      data: (pool) {
        final totalSeats = pool.selectedSeat;
        final occupiedSeats = pool.availableSeat;

        List<Map<String, String?>> seats = List.generate(totalSeats!, (index) {
          if (index < occupiedSeats.length) {
            return {'status': 'occupied', 'user': occupiedSeats[index]};
          } else {
            return {'status': 'empty', 'user': null};
          }
        });

        return Padding(
          padding: const EdgeInsets.only(left: 17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: seats.length,
                  itemBuilder: (context, index) {
                    final seat = seats[index];
                    final isOccupied = seat['status'] == 'occupied';

                    return Padding(
                      padding: const EdgeInsets.only(right: 30),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ClipOval(
                            child: Container(
                              height: 60,
                              width: 60,
                              color: isOccupied ? kMainColor : Colors.grey[300],
                              child: isOccupied
                                  ? Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 24,
                                    )
                                  : Icon(
                                      Icons.event_seat,
                                      color: Colors.grey,
                                      size: 24,
                                    ),
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            textAlign: TextAlign.center,
                            isOccupied ? 'Occupied\n Seat' : 'Empty\n Seat',
                            style: TextStyle(
                              color: isOccupied ? Colors.blue : Colors.grey,
                              fontSize: 10,
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
      },
      loading: () => Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) =>
          Center(child: Text('Error loading pool: $error')),
    );
  }

  String maskPhoneNumber(String phoneNumber) {
    return phoneNumber.replaceRange(
      3,
      phoneNumber.length - 2,
      '*' * (phoneNumber.length - 5),
    );
  }
}

