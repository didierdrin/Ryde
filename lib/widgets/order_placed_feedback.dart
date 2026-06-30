import 'package:flutter/material.dart';
import 'package:ryde_rw/theme/colors.dart';

void showOrderPlacedFeedback(BuildContext context, {String? message}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: kGreen,
      content: Text(message ?? 'Order placed!'),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
