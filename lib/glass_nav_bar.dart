import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

class GlassNavBar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const GlassNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  State<GlassNavBar> createState() => _GlassNavBarState();
}

class _GlassNavBarState extends State<GlassNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  double _currentIndex = 0;

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, '首页'),
    (Icons.history_outlined, Icons.history_rounded, '历史'),
    (Icons.settings_outlined, Icons.settings_rounded, '设置'),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.selectedIndex.toDouble();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
  }

  @override
  void didUpdateWidget(covariant GlassNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.selectedIndex != oldWidget.selectedIndex) {
      final from = _currentIndex;
      final to = widget.selectedIndex.toDouble();

      _anim = Tween<double>(begin: from, end: to).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );

      _currentIndex = to;
      _controller.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, bottom > 0 ? bottom + 8 : 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: GlassContainer(
          quality: GlassQuality.standard,
          child: SizedBox(
            height: 56,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final itemWidth = width / _items.length;

                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final t = _controller.isAnimating
                        ? _anim.value
                        : _currentIndex;

                    return Stack(
                      children: [
                        Positioned(
                          left: t * itemWidth,
                          width: itemWidth,
                          top: 6,
                          bottom: 6,
                          child: _LiquidIndicator(),
                        ),

                        Row(
                          children: List.generate(_items.length, (i) {
                            final item = _items[i];

                            final dist = (t - i).abs().clamp(0.0, 1.0);
                            final selectedT = 1 - dist;

                            return Expanded(
                              child: _NavItemWidget(
                                icon: item.$1,
                                activeIcon: item.$2,
                                label: item.$3,
                                t: selectedT,
                                onTap: () {
                                  if (i == widget.selectedIndex) return;
                                  HapticFeedback.selectionClick();
                                  widget.onTap(i);
                                },
                              ),
                            );
                          }),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _LiquidIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(28),
      ),
    );
  }
}

class _NavItemWidget extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final double t; // 0~1 插值
  final VoidCallback onTap;

  const _NavItemWidget({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.t,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final color = Color.lerp(scheme.onSurfaceVariant, scheme.primary, t)!;

    final scale = 0.9 + (t * 0.15);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32),
        child: Center(
          child: Transform.scale(
            scale: scale,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(t > 0.5 ? activeIcon : icon, size: 22, color: color),
                ClipRect(
                  child: Align(
                    widthFactor: t,
                    child: Opacity(
                      opacity: t,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
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
    );
  }
}
