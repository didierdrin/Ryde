import 'package:flutter/material.dart';
import 'package:ryde_rw/theme/colors.dart';

class ColorButton extends StatelessWidget {
  final String? title;
  final bool isValid;
  const ColorButton(this.title, {super.key, this.isValid = true});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: primaryColor.withValues(alpha: isValid ? 1 : 0.6),
      ),
      child: Center(
        child: Text(
          title!.toUpperCase(),
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
            fontSize: 15,
            letterSpacing: 3,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
