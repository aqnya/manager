import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

class HazeSliverAppBar extends StatelessWidget {
  const HazeSliverAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
  });

  final Widget title;
  final Widget? leading;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SliverAppBar(
      pinned: true,
      title: title,
      leading: leading,
      actions: actions,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: SizedBox.expand(
            child: ColoredBox(
              color: scheme.surfaceContainer.withValues(alpha: 0.78),
            ),
          ),
        ),
      ),
    );
  }
}
