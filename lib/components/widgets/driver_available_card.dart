import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ryde_rw/components/widgets/display_available_driver_google_map.dart';
import 'package:ryde_rw/models/offer_pool_model.dart';
import 'package:ryde_rw/theme/colors.dart';
import 'package:ryde_rw/utils/utils.dart';

class DriverAvailableCard extends ConsumerWidget {
  final String image;
  final String name;
  final String time;
  final int capacity;
  final String price;
  final VoidCallback? onTap;
  final String? distance;
  final bool isAvailable;
  final PassengerOfferPool ride;

  const DriverAvailableCard({
    super.key,
    required this.image,
    required this.name,
    required this.time,
    required this.capacity,
    required this.price,
    required this.ride,
    this.onTap,
    this.distance,
    this.isAvailable = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DisplayAvailableDriverGoogleMap(ride: ride),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 13, vertical: 2),
        padding: EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: isAvailable ? Colors.white : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200, width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Image.asset(width: 80, height: 80, image),
                  SizedBox(width: 3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: greenPrimary,
                            ),
                            Text(
                              time,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium!.copyWith(fontSize: 10),
                            ),

                            if (ride.type == 'passengers') ...[
                              Text(
                                ' • ',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              Text(
                                '$capacity Seats',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium!.copyWith(fontSize: 10),
                              ),
                            ],

                            if (ride.type == 'goods') ...[
                              Text(
                                ' • ',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              Text(
                                removeZeros(ride.quantity.toString()) +
                                    ride.measure.toString(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium!.copyWith(fontSize: 10),
                              ),
                            ],

                            if (distance != null) ...[
                              Text(
                                ' • ',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              Text(
                                distance!,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 5, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                price,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isAvailable ? Colors.green : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
