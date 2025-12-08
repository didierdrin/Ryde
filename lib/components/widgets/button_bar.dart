import 'package:flutter/material.dart';
import 'package:ryde_rw/theme/colors.dart';

class BottomBar extends StatelessWidget {
  final Function onTap;
  final String text;
  final Color? color;
  final Color? textColor;
  final bool isValid;

  const BottomBar({
    super.key,
    required this.onTap,
    required this.text,
    this.color,
    this.textColor,
    this.isValid = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isValid ? onTap as void Function()? : null,
      child: Container(
        decoration: BoxDecoration(
          color: color ?? primaryColor.withValues(alpha: isValid ? 1.0 : 0.7),
          borderRadius: const BorderRadius.all(Radius.circular(40)),
        ),
        height: 48.0,
        // margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Center(
          child: Text(
            text.toUpperCase(),
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
              fontSize: 15,
              letterSpacing: 3,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

