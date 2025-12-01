import 'package:flutter/material.dart';
import 'package:ryde_rw/components/widgets/color_button.dart';

//import 'package:ryde_rw/screens/app_screen.dart';
import 'package:ryde_rw/theme/colors.dart';

class PoolingConfirmed extends StatelessWidget {
  const PoolingConfirmed({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 20),
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Spacer(flex: 1),
          ColorButton("My Trips"),
                
              
            
          ],
        ),
      ),
    );
  }
}

