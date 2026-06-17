import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nekosu/l10n/app_localizations.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:nekosu/pages/home.dart';
import 'package:nekosu/pages/settings.dart';
import 'package:nekosu/navbar.dart';
import 'package:nekosu/ffi.dart';

void main() {
  if (ncoreInit() < 0) {
    debugPrint("failed to init ncore");
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const _fallbackSeed = Colors.teal;

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final seedColor = lightDynamic?.primary ?? _fallbackSeed;

        final lightScheme = ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        );
        final darkScheme = ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        );

        return MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en', ''), Locale('zh', '')],
          theme: ThemeData(useMaterial3: true, colorScheme: lightScheme),
          darkTheme: ThemeData(useMaterial3: true, colorScheme: darkScheme),
          themeMode: ThemeMode.system,
          home: const MyHomePage(),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final List<Widget> _pages = [
      const HomePage(),
      Center(
        child: Text(l10n.searchPageText, style: const TextStyle(fontSize: 24)),
      ),
      const SettingsPage(),
    ];

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: ModernCapsuleNavBar(
        selectedIndex: _selectedIndex,
        onTabSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        tabs: [
          NavBarTab(
            label: l10n.homeLabel,
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
          ),
          NavBarTab(
            label: l10n.searchLabel,
            icon: const Icon(Icons.search_outlined),
            activeIcon: const Icon(Icons.search),
          ),
          NavBarTab(
            label: l10n.settingsLabel,
            icon: const Icon(Icons.settings_outlined),
            activeIcon: const Icon(Icons.settings),
          ),
        ],
      ),
    );
  }
}
