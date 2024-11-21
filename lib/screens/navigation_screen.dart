// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:mds/screens/accounts/accounts_screen.dart';
import 'package:mds/screens/dashboard/dashboard.dart';
import 'package:mds/screens/profile/profile_screen.dart';
import 'package:mds/screens/statistics/stats_screen.dart';

class BottomNavScreen extends StatefulWidget {
  const BottomNavScreen({super.key});

  @override
  _BottomNavScreenState createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  final List<Widget> _screens = [
    const Dashboard(),
    const StatsScreen(),
    const AccountsScreen(),
    const ProfileScreen(),
  ];
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
      
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedItemColor: const Color.fromRGBO(255, 111, 97, 1),
        unselectedItemColor: Colors.grey.shade500,
        elevation: 0.0,
        items: [
          buildNavBarItem(0, IconlyLight.home, 'Home'),
          buildNavBarItem(1, IconlyLight.chart, 'Statistics'),
          buildNavBarItem(2, IconlyLight.swap, 'Accounts'),
          buildNavBarItem(3, IconlyLight.profile, 'Profile'),
        ],
      ),
    );
  }

  BottomNavigationBarItem buildNavBarItem(
      int index, IconData icon, String label) {
    return BottomNavigationBarItem(
      label: label,
      icon: Icon(
        icon,
        color: _currentIndex == index
            ? const Color.fromRGBO(255, 111, 97, 1)
            : Colors.grey.shade700,
        size: 35, // Set the size of the icon to 35
      ),
    );
  }
}
