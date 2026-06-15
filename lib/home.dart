import 'package:flutter/material.dart';
import 'navbar.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('You have pushed the button this many times:'),
          ],
        ),
      ),
      bottomNavigationBar: ModernCapsuleNavBar(
        selectedIndex: _selectedIndex,
        onTabSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        tabs: const [
          NavBarTab(
            label: 'Home',
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
          ),
          NavBarTab(
            label: 'Search',
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
          ),
          NavBarTab(
            label: 'Settings',
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
          ),
        ],
      ),
    );
  }
}
