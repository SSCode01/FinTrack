import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';

import 'dashboard_screen.dart';
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
    DashboardScreen(),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // intercept all back presses
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentIndex != 0) {
          // Go back to home tab instead of popping
          setState(() => _currentIndex = 0);
          _controller.jumpTo(0);
        } else {
          // Already on home — minimize app instead of closing
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0A1628),
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        extendBody: true,
        bottomNavigationBar: AnimatedNotchBottomBar(
          notchBottomBarController: _controller,
          color: const Color(0xFF0A1628),
          showLabel: true,
          notchColor: const Color(0xFF0D2137),
          kIconSize: 24,
          kBottomRadius: 20,
          bottomBarItems: const [
            BottomBarItem(
              inActiveItem: Icon(Icons.home_outlined, color: Colors.white70),
              activeItem: Icon(Icons.home, color: Color(0xFFFFD700)),
              itemLabel: 'Home',
            ),
            BottomBarItem(
              inActiveItem: Icon(Icons.people_outline, color: Colors.white70),
              activeItem: Icon(Icons.people, color: Color(0xFFFFD700)),
              itemLabel: 'Profiles',
            ),
            BottomBarItem(
              inActiveItem: Icon(Icons.history_outlined, color: Colors.white70),
              activeItem: Icon(Icons.history, color: Color(0xFFFFD700)),
              itemLabel: 'Past',
            ),
            BottomBarItem(
              inActiveItem:
                  Icon(Icons.dashboard_outlined, color: Colors.white70),
              activeItem: Icon(Icons.dashboard, color: Color(0xFFFFD700)),
              itemLabel: 'Dashboard',
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
      ),
    );
  }
}
