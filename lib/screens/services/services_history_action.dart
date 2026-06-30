import 'package:flutter/material.dart';
import 'package:ryde_rw/screens/services/services_history_screen.dart';

List<Widget> servicesHistoryActions(
  BuildContext context, {
  Color? foregroundColor,
}) {
  final color = foregroundColor ?? Colors.white;
  return [
    TextButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ServicesHistoryScreen()),
        );
      },
      icon: Icon(Icons.history, color: color, size: 20),
      label: Text('History', style: TextStyle(color: color)),
    ),
  ];
}
