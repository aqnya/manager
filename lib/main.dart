import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'home.dart';
import 'glass_nav_bar.dart';

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

@override
Widget build(BuildContext context) {
  return Scaffold(
    extendBody: true,
    body: IndexedStack(index: _index, children: _pages),
    bottomNavigationBar: _GlassNavBar(
      selectedIndex: _index,
      onTap: (i) => setState(() => _index = i),
    ),
  );
}
}