import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlassWidgets.initialize();
  runApp(LiquidGlassWidgets.wrap(const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const _defaultColorSeed = Colors.blueAccent;

  @override
  Widget build(BuildContext context) {
    final lightScheme = ColorScheme.fromSeed(seedColor: _defaultColorSeed);
    final darkScheme = ColorScheme.fromSeed(
      seedColor: _defaultColorSeed,
      brightness: Brightness.dark,
    );

    return MaterialApp(
      theme: ThemeData(useMaterial3: true, colorScheme: lightScheme),
      darkTheme: ThemeData(useMaterial3: true, colorScheme: darkScheme),
      themeMode: ThemeMode.system,
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _index = 0;

  final List<Widget> _pages = const [
    RootHomePage(),
    Center(child: Text('历史页面')),
    Center(child: Text('设置页面')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: GlassBottomBar(
        selectedIndex: _index,
        onTabSelected: (index) => setState(() => _index = index),
        tabs: const [
          GlassBottomBarTab(
            label: '首页',
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
          ),
          GlassBottomBarTab(
            label: '历史',
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
          ),
          GlassBottomBarTab(
            label: '设置',
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
          ),
        ],
      ),
    );
  }
}