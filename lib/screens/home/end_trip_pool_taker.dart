import 'package:flutter/material.dart';
import 'package:ryde_rw/components/stars.dart';
import 'package:ryde_rw/components/widgets/color_button.dart';
import 'package:ryde_rw/screens/home/home.dart';

//import 'package:ryde_rw/screens/app_screen.dart';
import 'package:ryde_rw/theme/colors.dart';

class EndTripPoolTaker extends StatefulWidget {
  const EndTripPoolTaker({super.key});

  @override
  EndTripPoolTakerState createState() => EndTripPoolTakerState();
}

class EndTripPoolTakerState extends State<EndTripPoolTaker> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: backgroundColor,
        width: MediaQuery.of(context).size.width,
        child: Column(
          children: [
            Spacer(flex: 2),
            SizedBox(
              width: 220,
              child: Image.asset("assets/img_tripcomplete.png"),
            ),
            SizedBox(height: 40),
            Text(
              "Trip Completed",
              style: Theme.of(
                context,
              ).textTheme.bodyLarge!.copyWith(fontSize: 22),
            ),
            SizedBox(height: 10),
            Text(
              "Hope you had a great trip",
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium!.copyWith(fontSize: 15),
            ),
            Spacer(),
            ColorButton("Submit"),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}