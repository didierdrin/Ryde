import 'package:flutter/material.dart';
import 'package:ryde_rw/screens/home/home.dart';
import 'package:ryde_rw/screens/myTrips/trips.dart';
import 'package:ryde_rw/screens/chats/chats.dart';
import 'package:ryde_rw/screens/more/more.dart';

class AllBottomNavigationsScreen extends StatefulWidget {
  const AllBottomNavigationsScreen({super.key});

  @override
  State<AllBottomNavigationsScreen> createState() => _AllBottomNavigationsScreenState();
}

class _AllBottomNavigationsScreenState extends State<AllBottomNavigationsScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const Home(),
    const Trips(),
    const Chats(),
    More(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home,),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'Trips',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
      ),
    );
  }
}  
