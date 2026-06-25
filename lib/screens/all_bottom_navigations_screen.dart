import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ryde_rw/screens/chats/chats.dart';
import 'package:ryde_rw/screens/home/home.dart';
import 'package:ryde_rw/screens/more/more.dart';
import 'package:ryde_rw/screens/myTrips/trips.dart';
import 'package:ryde_rw/screens/services/services_hub_screen.dart';
import 'package:ryde_rw/shared/shared_states.dart';
import 'package:ryde_rw/theme/colors.dart';

class AllBottomNavigationsScreen extends ConsumerStatefulWidget {
  const AllBottomNavigationsScreen({super.key});

  @override
  ConsumerState<AllBottomNavigationsScreen> createState() =>
      _AllBottomNavigationsScreenState();
}

class _AllBottomNavigationsScreenState
    extends ConsumerState<AllBottomNavigationsScreen> {
  int _currentIndex = 0;
  List<Widget>? _screens;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeScreens();
  }

  void _initializeScreens() {
    try {
      _screens = [
        const Home(),
        const Trips(),
        const ServicesHubScreen(),
        More(),
      ];
      _isInitialized = true;
    } catch (e, stackTrace) {
      print('AllBottomNavigationsScreen: Error initializing screens: $e');
      print('Stack trace: $stackTrace');
      _isInitialized = false;
    }
  }

  void _openChats() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const Chats()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);

    if (user == null) {
      print('AllBottomNavigationsScreen: User is null, this might cause issues');
    }

    if (!_isInitialized || _screens == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Loading...'),
              if (!_isInitialized)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: () {
                      _initializeScreens();
                      setState(() {});
                    },
                    child: const Text('Retry'),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: _screens!,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openChats,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text('Chats'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index >= 0 && index < _screens!.length) {
            setState(() => _currentIndex = index);
          }
        },
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car_outlined),
            activeIcon: Icon(Icons.directions_car),
            label: 'Trips',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            activeIcon: Icon(Icons.apps),
            label: 'Services',
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
