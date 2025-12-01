import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ryde_rw/components/widgets/polyline_google_map_driver.dart';
import 'package:ryde_rw/models/request_model.dart';
import 'package:ryde_rw/theme/colors.dart';
import 'package:ryde_rw/utils/utils.dart';

class PassengerAvailableCard extends ConsumerStatefulWidget {
  final String image;
  final String name;
  final String time;
  final int capacity;
  final VoidCallback? onTap;
  final String? distance;
  final bool isAvailable;
  final RequestRide passenger;

  const PassengerAvailableCard({
    super.key,
    required this.image,
    required this.name,
    required this.time,
    required this.capacity,
    this.onTap,
    this.distance,
    this.isAvailable = true,
    required this.passenger,
  });

  @override
  PassengerAvailableCardState createState() => PassengerAvailableCardState();
}

class PassengerAvailableCardState
    extends ConsumerState<PassengerAvailableCard> {
  bool isConfirmed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RideMapScreen(ride: widget.passenger),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 13, vertical: 2),
        padding: EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: widget.isAvailable ? Colors.white : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200, width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(Icons.person, color: Colors.grey[300], size: 56),
                  SizedBox(width: 3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.name,
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
                              widget.time,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium!.copyWith(fontSize: 10),
                            ),
                            if (widget.passenger.type == 'passengers') ...[
                              Text(
                                ' • ',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              Text(
                                '${widget.passenger.seats} Seats',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium!.copyWith(fontSize: 10),
                              ),
                            ],

                            if (widget.passenger.type == 'goods') ...[
                              Text(
                                ' • ',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              Text(
                                '${removeZeros(widget.passenger.quantity.toString())} ${widget.passenger.measure}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium!.copyWith(fontSize: 10),
                              ),
                            ],
                            SizedBox(width: 12),
                            if (widget.distance != null) ...[
                              Text(
                                ' • ',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              Text(
                                widget.distance!,
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
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.scale(
                  scale: 0.7,
                  child: CupertinoSwitch(
                    activeColor: kMainColor.withOpacity(0.9),
                    thumbColor: isConfirmed ? kWhiteColor : Colors.white,
                    trackColor: kMainColor.withOpacity(0.5),
                    value: isConfirmed,
                    onChanged: (value) {
                      setState(() {
                        isConfirmed = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

