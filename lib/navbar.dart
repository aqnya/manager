import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NavBarTab {
  const NavBarTab({required this.label, required this.icon, this.activeIcon});
  final String label;
  final Widget icon;
  final Widget? activeIcon;
}

class ModernCapsuleNavBar extends StatelessWidget {
  const ModernCapsuleNavBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  final List<NavBarTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.labelMedium;

    return NavigationBarTheme(
      data: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.primaryContainer,
        elevation: 0,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
            size: 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return labelStyle?.copyWith(
            color: states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          );
        }),
      ),
      child: NavigationBar(
        selectedIndex: selectedIndex,
        height: 80,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (index) {
          HapticFeedback.lightImpact();
          onTabSelected(index);
        },
        destinations: [
          for (final tab in tabs)
            NavigationDestination(
              icon: tab.icon,
              selectedIcon: tab.activeIcon ?? tab.icon,
              label: tab.label,
            ),
        ],
      ),
    );
  }
}
