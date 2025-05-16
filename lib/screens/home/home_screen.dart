import 'package:flutter/material.dart';

import '../add_book/add_book_screen.dart';
import '../search/search_screen.dart';
import '../favorites/favorites_screen.dart';
import '../profile/profile_screen.dart';
import '../bidding/bids_screen.dart';
import 'package:rive_animation/services/auth_service.dart';
import 'components/home_content.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // Global key for accessing HomeContent state
  final GlobalKey<HomeContentState> _homeContentKey =
      GlobalKey<HomeContentState>();

  // Pages with HomeContent having a key
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeContent(key: _homeContentKey),
      const SearchScreen(),
      const AddBookScreen(),
      const FavoritesScreen(),
      const BidsScreen(),
      const ProfileScreen(),
    ];
  }

  // Method to refresh home content
  void _refreshHomeContent() {
    _homeContentKey.currentState?.refreshBooks();
  }

  void _onItemTapped(int index) {
    // If going to the add book screen, refresh on return
    if (index == 2) {
      Navigator.of(context)
          .push(MaterialPageRoute(
        builder: (context) => const AddBookScreen(),
      ))
          .then((bookAdded) {
        // If book was added, refresh the home content
        if (bookAdded == true) {
          _refreshHomeContent();
        }
      });
      return;
    }

    // If going to the bids screen, use direct navigation
    if (index == 4) {
      // Force clean restart of the BidsScreen to ensure data is fresh
      final bidScreen = const BidsScreen();
      Navigator.of(context)
          .push(MaterialPageRoute(
        builder: (context) => bidScreen,
      ))
          .then((_) {
        // When returning from bids, refresh the current page
        setState(() {
          // Refresh current view
        });
      });
      return;
    }

    // For other tabs, just change the selected index
    setState(() {
      _selectedIndex = index;

      // If navigating back to home from another tab, refresh the books
      if (index == 0 && _selectedIndex != 0) {
        _refreshHomeContent();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Student Book Exchange',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.favorite,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const FavoritesScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey[600],
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: 'Add Book',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border_outlined),
            activeIcon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            activeIcon: Icon(Icons.attach_money),
            label: 'Bids',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
