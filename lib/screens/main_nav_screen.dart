import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'profiles_screen.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    ProfilesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E7D32),

      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),

      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() => _currentIndex = index);
          },

          backgroundColor: const Color(0xFF2E7D32).withOpacity(0.95),
          selectedItemColor: const Color(0xFFFFD700),
          unselectedItemColor: Colors.white70,

          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
          ),

          showUnselectedLabels: true,

          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Profiles',
            ),
          ],
        ),
      ),
    );
  }
}