import 'package:flutter/material.dart';

enum AppRoute { home, history, fmacRules, settings }

enum NavBarStyle { floating, normal }

class _NavItem {
  const _NavItem({
    required this.route,
    required this.label,
    required this.selectedIcon,
    required this.unselectedIcon,
  });
  final AppRoute route;
  final String label;
  final IconData selectedIcon;
  final IconData unselectedIcon;
}

const List<_NavItem> _navItems = [
  _NavItem(route: AppRoute.home,      label: 'Home',     selectedIcon: Icons.home,          unselectedIcon: Icons.home_outlined),
  _NavItem(route: AppRoute.history,   label: 'Apps',     selectedIcon: Icons.apps,          unselectedIcon: Icons.apps_outlined),
  _NavItem(route: AppRoute.fmacRules, label: 'Rules',    selectedIcon: Icons.rule,          unselectedIcon: Icons.rule_outlined),
  _NavItem(route: AppRoute.settings,  label: 'Settings', selectedIcon: Icons.settings,      unselectedIcon: Icons.settings_outlined),
];

class FloatingBottomNavigationBar extends StatelessWidget {
  const FloatingBottomNavigationBar({super.key, required this.currentRoute, required this.items, required this.onTap});
  final AppRoute currentRoute;
  final List<_NavItem> items;
  final ValueChanged<AppRoute> onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24).copyWith(bottom: 24),
        child: Align(
          child: Material(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(50),
            elevation: 8,
            shadowColor: Colors.black38,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: items.map((item) => _PillNavItem(
                  item: item,
                  selected: currentRoute == item.route,
                  onTap: () => onTap(item.route),
                )).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PillNavItem extends StatelessWidget {
  const _PillNavItem({required this.item, required this.selected, required this.onTap});
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        height: 48,
        width: selected ? 88.0 : 48.0,
        decoration: BoxDecoration(
          color: selected ? cs.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? item.selectedIcon : item.unselectedIcon,
              size: 22,
              color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: selected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        item.label,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: cs.onPrimaryContainer),
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.visible,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class NormalBottomNavigationBar extends StatelessWidget {
  const NormalBottomNavigationBar({super.key, required this.currentRoute, required this.items, required this.onTap});
  final AppRoute currentRoute;
  final List<_NavItem> items;
  final ValueChanged<AppRoute> onTap;

  @override
  Widget build(BuildContext context) {
    final idx = items.indexWhere((e) => e.route == currentRoute).clamp(0, items.length - 1);
    return NavigationBar(
      selectedIndex: idx,
      onDestinationSelected: (i) => onTap(items[i].route),
      destinations: items.map((item) => NavigationDestination(
        icon: Icon(item.unselectedIcon),
        selectedIcon: Icon(item.selectedIcon),
        label: item.label,
      )).toList(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, this.navBarStyle = NavBarStyle.floating});
  final NavBarStyle navBarStyle;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  AppRoute _current = AppRoute.home;

  static const _topLevel = {AppRoute.home, AppRoute.history, AppRoute.fmacRules, AppRoute.settings};

  void _navigate(AppRoute r) { if (_current != r) setState(() => _current = r); }

  Widget _page() => switch (_current) {
    AppRoute.home      => const _Placeholder('Home'),
    AppRoute.history   => const _Placeholder('Apps / History'),
    AppRoute.fmacRules => const _Placeholder('FMAC Rules'),
    AppRoute.settings  => const _Placeholder('Settings'),
  };

  @override
  Widget build(BuildContext context) {
    final floating = widget.navBarStyle == NavBarStyle.floating;
    final show = _topLevel.contains(_current);

    Widget animatedBar(Widget child) => AnimatedSlide(
      duration: const Duration(milliseconds: 200),
      offset: show ? Offset.zero : const Offset(0, 1),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: show ? 1.0 : 0.0,
        child: child,
      ),
    );

    return Scaffold(
      bottomNavigationBar: !floating && show
          ? animatedBar(NormalBottomNavigationBar(currentRoute: _current, items: _navItems, onTap: _navigate))
          : null,
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: KeyedSubtree(key: ValueKey(_current), child: _page()),
          ),
          if (floating)
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: animatedBar(FloatingBottomNavigationBar(currentRoute: _current, items: _navItems, onTap: _navigate)),
            ),
        ],
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder(this.label);
  final String label;

  @override
  Widget build(BuildContext context) =>
      Center(child: Text(label, style: Theme.of(context).textTheme.titleLarge));
}

void main() => runApp(MaterialApp(
  title: 'NekoSU',
  theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple),
  home: const MainScreen(navBarStyle: NavBarStyle.floating),
));