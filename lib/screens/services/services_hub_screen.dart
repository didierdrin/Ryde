import 'package:flutter/material.dart';
import 'package:ryde_rw/screens/services/auctions_screen.dart';
import 'package:ryde_rw/screens/services/available_drivers_screen.dart';
import 'package:ryde_rw/screens/services/mechanics_screen.dart';
import 'package:ryde_rw/screens/services/rentals_screen.dart';
import 'package:ryde_rw/theme/colors.dart';

class ServicesHubScreen extends StatelessWidget {
  const ServicesHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _ServiceItem(
        icon: Icons.car_rental,
        title: 'Rentals',
        subtitle: 'Rent a car with photos & pay online',
        screen: const RentalsScreen(),
      ),
      _ServiceItem(
        icon: Icons.gavel,
        title: 'Vehicle Auction',
        subtitle: 'Buy or sell vehicles',
        screen: const AuctionsScreen(),
      ),
      _ServiceItem(
        icon: Icons.build_circle_outlined,
        title: 'Find Mechanics',
        subtitle: 'Auto repair shops near you',
        screen: const MechanicsScreen(),
      ),
      _ServiceItem(
        icon: Icons.person_search,
        title: 'Available Drivers',
        subtitle: 'Address, distance, age & experience',
        screen: const AvailableDriversScreen(),
      ),
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Ryde Services'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: primaryColor.withOpacity(0.12),
                child: Icon(item.icon, color: primaryColor),
              ),
              title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(item.subtitle, style: TextStyle(fontSize: 12, color: kSimpleText)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => item.screen),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ServiceItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget screen;

  _ServiceItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.screen,
  });
}
