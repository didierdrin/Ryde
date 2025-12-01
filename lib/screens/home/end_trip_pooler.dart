import 'package:flutter/material.dart';
import 'package:ryde_rw/components/stars.dart';
import 'package:ryde_rw/components/widgets/color_button.dart';

import '../home/end_trip_pool_taker.dart';
import 'package:ryde_rw/theme/colors.dart';

class EndTripPooler extends StatelessWidget {
  const EndTripPooler({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: GestureDetector(
        onTap: () {
          Navigator.pop(context);
          Navigator.pop(context);
          Navigator.pop(context);
          Navigator.pop(context);
        },
        child: Container(
          height: 55,
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: ColorButton("Submit"),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Container(
        color: backgroundColor,
        width: MediaQuery.of(context).size.width,
        child: Column(
          children: [
            Spacer(flex: 2),
            Container(
                  width: MediaQuery.of(context).size.width,
                  height: 350,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 13,
                        ),
                        child: Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Rate Ride Taker",
                                  style: Theme.of(context).textTheme.bodyMedium!
                                      .copyWith(
                                        fontSize: 13.5,
                                        color: Color(0xffa3bccf),
                                      ),
                                ),
                                Text(
                                  "Samantha Smith",
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge!.copyWith(fontSize: 17),
                                ),
                              ],
                            ),
                            Spacer(),
                            SizedBox(
                              height: 60,
                              child: Image.asset("assets/profiles/img1.png"),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Stars(),
                      ),
                      Divider(thickness: 7, color: Colors.grey[200]),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Rate Ride Taker",
                                  style: Theme.of(context).textTheme.bodyMedium!
                                      .copyWith(
                                        fontSize: 13.5,
                                        color: Color(0xffa3bccf),
                                      ),
                                ),
                                Text(
                                  "Peter Taylor",
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge!.copyWith(fontSize: 17),
                                ),
                              ],
                            ),
                            Spacer(),
                            SizedBox(
                              height: 60,
                              child: Image.asset("assets/profiles/img4.png"),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Stars(),
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

