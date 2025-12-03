import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ryde_rw/screens/home/home.dart';
import 'package:ryde_rw/screens/myTrips/trips.dart';
import 'package:ryde_rw/screens/chats/chats.dart';
import 'package:ryde_rw/screens/more/more.dart';
import 'package:ryde_rw/shared/shared_states.dart';

class AllBottomNavigationsScreen extends ConsumerStatefulWidget {
  const AllBottomNavigationsScreen({super.key});

  @override
  ConsumerState<AllBottomNavigationsScreen> createState() => _AllBottomNavigationsScreenState();
}

class _AllBottomNavigationsScreenState extends ConsumerState<AllBottomNavigationsScreen> {
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
        const Chats(),
        More(),
      ];
      _isInitialized = true;
      print('AllBottomNavigationsScreen: Screens initialized successfully');
    } catch (e, stackTrace) {
      print('AllBottomNavigationsScreen: Error initializing screens: $e');
      print('Stack trace: $stackTrace');
      _isInitialized = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    
    // Check if user is still valid
    if (user == null) {
      print('AllBottomNavigationsScreen: User is null, this might cause issues');
    }

    // Show loading screen if not initialized
    if (!_isInitialized || _screens == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading...'),
              if (!_isInitialized)
                Padding(
                  padding: EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: () {
                      _initializeScreens();
                      setState(() {});
                    },
                    child: Text('Retry'),
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
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          try {
            if (index >= 0 && index < _screens!.length) {
              setState(() {
                _currentIndex = index;
              });
              print('AllBottomNavigationsScreen: Navigated to tab $index');
            } else {
              print('AllBottomNavigationsScreen: Invalid tab index: $index');
            }
          } catch (e, stackTrace) {
            print('AllBottomNavigationsScreen: Error navigating to tab $index: $e');
            print('Stack trace: $stackTrace');
          }
        },
        selectedItemColor: Colors.black, //Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
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
