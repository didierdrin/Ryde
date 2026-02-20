import 'package:cached_network_image/cached_network_image.dart';
import 'package:ryde_rw/firestore_stub.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ryde_rw/theme/colors.dart';
import 'package:ryde_rw/utils/utils.dart';

class DriverCustomListItem extends ConsumerWidget {
  final String image;
  final String name;
  final String? type;
  final String? quantity;
  final String? measure;
  final String fromLocation;
  final String distance;
  final bool isBike;
  final List<IconData> icons;
  final String destination;
  final Timestamp? time;
  final int? index;
  final Function() onTap;

  const DriverCustomListItem({
    required this.image,
    required this.name,
    this.type,
    this.quantity,
    this.measure,
    required this.fromLocation,
    required this.distance,
    required this.isBike,
    required this.icons,
    required this.destination,
    required this.time,
    required this.onTap,
    this.index,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  width: 57,
                  height: 57,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: image,
                      placeholder: (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) =>
                          Image.asset('assets/replace.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            // Details Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and price row
                  Row(
                    children: [
                      Text(
                        name,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge!.copyWith(fontSize: 13.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  // Location and icons
                  Row(
                    children: [
                      const Spacer(),
                      if (type == 'passenger')
                        Row(
                          children: [
                            Icon(
                              index == 2
                                  ? Icons.directions_bike
                                  : Icons.drive_eta,
                              size: 10,
                              color: Colors.grey[300],
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                              ),
                              child: Icon(
                                Icons.circle,
                                size: 3,
                                color: Colors.grey[300],
                              ),
                            ),
                            index != 2
                                ? Icon(
                                    Icons.account_circle,
                                    size: 10,
                                    color: Colors.grey[300],
                                  )
                                : SizedBox.shrink(),
                            Icon(
                              Icons.account_circle,
                              size: 10,
                              color: Colors.grey[300],
                            ),
                            Icon(
                              Icons.account_circle,
                              size: 10,
                              color: Colors.grey[300],
                            ),
                          ],
                        ),
                      if (type == 'goods')
                        Row(
                          children: [
                            Text(
                              '$quantity ${capitalizeFirstLetter(measure!)}',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.directions_run,
                            size: 10,
                            color: Colors.grey[300],
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: 10,
                            color: Colors.grey[300],
                          ),
                          Icon(
                            Icons.drive_eta,
                            size: 10,
                            color: Colors.grey[300],
                          ),
                          SizedBox(width: 5),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              Icons.circle,
                              size: 4,
                              color: Colors.grey[300],
                            ),
                          ),
                          SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              fromLocation,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          Text(
                            formatTime(time!.toDate()),
                            style: TextStyle(color: Colors.black, fontSize: 10),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.089,
                          ),
                          Icon(
                            Icons.more_vert,
                            size: 10,
                            color: Colors.grey[300],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.drive_eta,
                            size: 10,
                            color: Colors.grey[300],
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: 10,
                            color: Colors.grey[300],
                          ),
                          Icon(
                            Icons.directions_run,
                            size: 10,
                            color: Colors.grey[300],
                          ),
                          SizedBox(width: 5),
                          Icon(
                            Icons.keyboard_arrow_down,
                            size: 10,
                            color: Colors.grey[300],
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              destination,
                              maxLines: 1,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

