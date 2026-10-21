import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nekosu/l10n/app_localizations.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:nekosu/app_theme.dart';
import 'package:nekosu/layout_insets.dart';
import 'package:nekosu/pages/app_list.dart';
import 'package:nekosu/pages/home.dart';
import 'package:nekosu/pages/modules.dart';
import 'package:nekosu/pages/settings.dart';
import 'package:nekosu/navbar.dart';
import 'package:nekosu/settings_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SettingsController.instance.load();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    SettingsController.instance.addListener(_settingsChanged);
  }

  @override
  void dispose() {
    SettingsController.instance.removeListener(_settingsChanged);
    super.dispose();
  }

  void _settingsChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsController.instance;
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final lightSeed = settings.usesDynamicColor
            ? lightDynamic?.primary ?? SettingsController.fallbackSeed
            : settings.seedColor;
        final darkSeed = settings.usesDynamicColor
            ? darkDynamic?.primary ?? SettingsController.fallbackSeed
            : settings.seedColor;
        final lightScheme = ColorScheme.fromSeed(
          seedColor: lightSeed,
          brightness: Brightness.light,
        );
        final darkBase = ColorScheme.fromSeed(
          seedColor: darkSeed,
          brightness: Brightness.dark,
        );
        final darkScheme = settings.amoled
            ? darkBase.copyWith(
                surface: Colors.black,
                surfaceContainer: Colors.black,
              )
            : darkBase;

        return MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en', ''), Locale('zh', '')],
          locale: settings.locale,
          theme: AppTheme.build(lightScheme),
          darkTheme: AppTheme.build(darkScheme),
          themeMode: settings.flutterThemeMode,
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
    final settings = SettingsController.instance;

    final List<Widget> _pages = [
      const HomePage(),
      const AppListPage(),
      const ModulesPage(),
      const SettingsPage(),
    ];

    final tabs = [
      NavBarTab(
        label: l10n.homeLabel,
        icon: const Icon(Icons.home_outlined),
        activeIcon: const Icon(Icons.home),
      ),
      NavBarTab(
        label: l10n.appsLabel,
        icon: const Icon(Icons.apps_outlined),
        activeIcon: const Icon(Icons.apps_rounded),
      ),
      NavBarTab(
        label: l10n.modulesLabel,
        icon: const Icon(Icons.extension_outlined),
        activeIcon: const Icon(Icons.extension_rounded),
      ),
      NavBarTab(
        label: l10n.settingsLabel,
        icon: const Icon(Icons.settings_outlined),
        activeIcon: const Icon(Icons.settings),
      ),
    ];

    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) => Scaffold(
        extendBody: settings.floatingNavBar,
        body: AppNavBarScope(
          floating: settings.floatingNavBar,
          child: _pages[_selectedIndex],
        ),
        bottomNavigationBar: settings.floatingNavBar
            ? ModernCapsuleNavBar(
                selectedIndex: _selectedIndex,
                onTabSelected: _selectTab,
                tabs: tabs,
              )
            : ModernNavigationBar(
                selectedIndex: _selectedIndex,
                onTabSelected: _selectTab,
                tabs: tabs,
              ),
      ),
    );
  }

  void _selectTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
