import 'package:flutter/material.dart';

class Tabcomp extends StatelessWidget {
  final IconData icon;
  final String text;

  const Tabcomp({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          SizedBox(width: 10),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  // color: isActive ? kMainColor : kWhiteColor,
                ),
          ),
        ],
      ),
    );
  }
}
