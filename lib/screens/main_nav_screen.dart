import 'package:flutter/material.dart';
import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';

import 'home_screen.dart';
import 'profiles_screen.dart';
import 'past_transactions_screen.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  final NotchBottomBarController _controller =
      NotchBottomBarController(index: 0);

  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    ProfilesScreen(),
    PastTransactionsScreen(),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E7D32),

      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),

      extendBody: true,

      bottomNavigationBar: AnimatedNotchBottomBar(
        notchBottomBarController: _controller,
        color: const Color(0xFF2E7D32),
        showLabel: true,
        notchColor: const Color(0xFF1B5E20),
        kIconSize: 24,
        kBottomRadius: 20,
        bottomBarItems: const [
          BottomBarItem(
            inActiveItem: Icon(
              Icons.home_outlined,
              color: Colors.white70,
            ),
            activeItem: Icon(
              Icons.home,
              color: Color(0xFFFFD700),
            ),
            itemLabel: 'Home',
          ),
          BottomBarItem(
            inActiveItem: Icon(
              Icons.people_outline,
              color: Colors.white70,
            ),
            activeItem: Icon(
              Icons.people,
              color: Color(0xFFFFD700),
            ),
            itemLabel: 'Profiles',
          ),
          BottomBarItem(
            inActiveItem: Icon(
              Icons.history_outlined,
              color: Colors.white70,
            ),
            activeItem: Icon(
              Icons.history,
              color: Color(0xFFFFD700),
            ),
            itemLabel: 'Past',
          ),
        ],
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        itemLabelStyle: const TextStyle(
          color: Color(0xFFFFD700),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
