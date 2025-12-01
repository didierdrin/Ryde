import 'package:flutter/material.dart';

import 'package:ryde_rw/components/widgets/custom_write.dart';
import 'package:ryde_rw/theme/colors.dart';

class PrivacyPolicy extends StatelessWidget {
  const PrivacyPolicy({super.key});

  @override
  Widget build(BuildContext context) {
    

    return Scaffold(
      appBar: AppBar(elevation: 0, backgroundColor: backgroundColor),
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            color: backgroundColor,
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 25),
                    Text(
                      "Privacy Policy",
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge!.copyWith(fontSize: 22),
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      child: Text(
                        "How we work",
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium!.copyWith(fontSize: 15),
                      ),
                    ),
                    SizedBox(width: 20),
                  ],
                ),
                Spacer(),
                Expanded(
                  flex: 5,
                  child: Image.asset("assets/head_privacypolicy.png"),
                  
                ),
              ],
            ),
          ),
         Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: ListView(
                // crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      P(text: "lastupdate"),
                      const SizedBox(height: 15),
                      H2(text: "important"),
                      const SizedBox(height: 15),
                      P(text: "sub_"),
                      const SizedBox(height: 15),
                      H2(text: "one"),
                      const SizedBox(height: 15),
                      P(text: "oneone"),
                      const SizedBox(height: 15),
                      P(text: "onetwo"),
                      const SizedBox(height: 15),
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Column(
                          children: [
                            Li(text: "lione"),
                            Li(text: "litwo"),
                            Li(text: "lithree"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      H2(text: "two"),
                      const SizedBox(height: 15),
                      P(text: "twoone"),
                      const SizedBox(height: 15),
                      P(text: "twotwo"),
                      const SizedBox(height: 15),
                      P(text: "twothree"),
                      const SizedBox(height: 15),
                      P(text: "twofour"),
                      const SizedBox(height: 15),
                      H2(text: "three"),
                      const SizedBox(height: 15),
                      P(text: "threeone"),
                      const SizedBox(height: 15),
                      P(text: "r1"),
                      P(text: "r2"),
                      P(text: "r3"),
                      P(text: "r4"),
                      const SizedBox(height: 15),
                      P(text: "three2"),
                      const SizedBox(height: 15),
                      P(text: "Three"),
                      const SizedBox(height: 15),
                      P(text: "three4"),
                      const SizedBox(height: 15),
                      P(text: "three5"),
                      const SizedBox(height: 15),
                      P(text: "three6"),
                      const SizedBox(height: 15),
                      H2(text: "four"),
                      const SizedBox(height: 15),
                      P(text: "fourt"),
                      const SizedBox(height: 15),
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Column(
                          children: [
                            Li(text: "l1"),
                            Li(text: "l2"),
                            Li(text: "l3"),
                            Li(text: "l4"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      H2(text: "five"),
                      const SizedBox(height: 15),
                      P(text: "five1"),
                      const SizedBox(height: 15),
                      P(text: "five2"),
                      const SizedBox(height: 15),
                      P(text: "five3"),
                      const SizedBox(height: 15),
                      P(text: "five4"),
                      const SizedBox(height: 15),
                      H2(text: "six"),
                      const SizedBox(height: 15),
                      P(text: "six1"),
                      const SizedBox(height: 15),
                      P(text: "six2"),
                      const SizedBox(height: 15),
                      P(text: "six3"),
                      const SizedBox(height: 15),
                      P(text: "six4"),
                      const SizedBox(height: 15),
                      P(text: "six5"),
                      const SizedBox(height: 15),
                      H2(text: 'seven'),
                      const SizedBox(height: 15),
                      P(text: "seven1"),
                      const SizedBox(height: 15),
                      P(text: "seven2"),
                      const SizedBox(height: 15),
                      P(text: "seven3"),
                      const SizedBox(height: 15),
                      H2(text: "eight"),
                      const SizedBox(height: 15),
                      P(text: "ourservice"),
                      const SizedBox(height: 15),
                      H2(text: "nine"),
                      const SizedBox(height: 15),
                      P(text: "policy"),
                      const SizedBox(height: 15),
                      P(text: "No"),
                      const SizedBox(height: 15),
                      const SizedBox(height: 15),
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

