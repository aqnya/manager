import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _navBarHeight = 66.0;
const _navBarBottomGap = 12.0;
const _navBarSideGap = 20.0;

double floatingNavBarClearance(BuildContext context) {
  return MediaQuery.viewPaddingOf(context).bottom +
      _navBarHeight +
      _navBarBottomGap +
      18;
}

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
    final count = tabs.length;

    final alignmentX = count > 1
        ? -1.0 + (selectedIndex * 2 / (count - 1))
        : 0.0;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          _navBarSideGap,
          0,
          _navBarSideGap,
          _navBarBottomGap,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_navBarHeight / 2),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.16),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.06),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_navBarHeight / 2),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surfaceBright.withValues(alpha: 0.82),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.32),
                  ),
                ),
                child: SizedBox(
                  height: _navBarHeight,
                  child: Stack(
                    children: [
                      AnimatedAlign(
                        alignment: Alignment(alignmentX, 0),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        child: FractionallySizedBox(
                          widthFactor: 1 / count,
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: scheme.primaryContainer,
                                borderRadius: BorderRadius.circular(
                                  (_navBarHeight - 10) / 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Material(
                        type: MaterialType.transparency,
                        child: Row(
                          children: List.generate(
                            count,
                            (index) => Expanded(
                              child: _TabItem(
                                tab: tabs[index],
                                selected: selectedIndex == index,
                                scheme: scheme,
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  onTabSelected(index);
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.tab,
    required this.selected,
    required this.scheme,
    required this.onTap,
  });

  final NavBarTab tab;
  final bool selected;
  final ColorScheme scheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final contentColor = selected
        ? scheme.onPrimaryContainer
        : scheme.onSurfaceVariant;

    return Semantics(
      selected: selected,
      button: true,
      label: tab.label,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: IconTheme(
                key: ValueKey<bool>(selected),
                data: IconThemeData(
                  color: contentColor,
                  size: selected ? 26 : 24,
                ),
                child: (selected && tab.activeIcon != null)
                    ? tab.activeIcon!
                    : tab.icon,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: contentColor,
              ),
              child: Text(
                tab.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
