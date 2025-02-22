import 'package:adminlast/admin/addtrailor.dart';
import 'package:flutter/material.dart';

// Import your admin screens
import 'addcategory.dart'; // CategoriesScreen
import 'addstory.dart'; // AdminAddStoryScreen
import 'adminaddtopserachm.dart'; // AdminTopSearchScreen
import 'user.dart'; // UserScreen

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // The 5 screens for bottom nav
  final List<Widget> _screens = [
    const CategoriesScreen(), // 0: Categories
    const AdminAddStoryScreen(), // 1: Add Story
    AdminMovieScreen(), // 2: Add Movies
    TrailerListScreen(), // 3: Profile
    const UserScreen(), // 4: Users
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],

      // Bottom Navigation Bar with 5 items
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black, // Netflix-like black
        selectedItemColor: Colors.red, // Selected item color
        unselectedItemColor: Colors.white, // Unselected item color
        type: BottomNavigationBarType.fixed, // Show labels for all items

        currentIndex: _selectedIndex,
        onTap: _onItemTapped,

        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Categories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.amp_stories),
            label: 'Add Story',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.movie), label: 'Add Movies'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'tralor'),
          BottomNavigationBarItem(
            icon: Icon(Icons.supervised_user_circle),
            label: 'Users',
          ),
        ],
      ),
    );
  }
}
